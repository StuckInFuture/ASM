.MODEL flat, stdcall
.STACK 100h
.DATA  
msg1 DB "Enter first operand: ",0Dh,0Ah,'$'
msg2 DB 0Dh,0Ah,"Enter second operand: ",0Dh,0Ah,'$'
msg3 DB 0Dh, 0Ah,"Enter operations: ",0Dh,0Ah,'$'
msg4 DB 0Dh,0Ah,"Result: ",0Dh,0Ah,'$'
msg5 DB 0Dh,0Ah,"Error",0Dh,0Ah,'$'
msg6 DB 0Dh,0Ah,"OVERFLOW",0Dh,0Ah,'$'
max_length equ 8
 
first_operand_str DB max_length dup('$')
second_operand_str DB max_length dup('$') 
answer_str DB 0Dh,0Ah,"+00000000", '$'
operation DB 4 dup('$')

first_operand DW 0
second_operand DW 0


ten DB 010h
isError DB 0
isNegative DB 0 



.CODE   

str_output macro current_str ;вывод
    push ax
    mov ah, 09h
    lea dx, current_str
    int 21h
    pop ax
endm

str_input macro current_str   ;ввод
    push ax
    mov ah, 0Ah
    lea dx, current_str
    int 21h
    pop ax
endm

str_check macro current_str    ;проверка введенного числа и преобразование строки в число
   local @str_is_negative, @check_plus, @shift_plus, @goNextCheck, @goCheckSign, @negative, @error, @goEnd 
   push bx
   mov si, 2
   mov ax, 0
   mov isNegative, 0
   cmp current_str[si], '-'
     je @str_is_negative      
     jne @check_plus
   @str_is_negative:
     mov isNegative, 1
     inc si
     jmp @goNextCheck
   @check_plus:
     cmp current_str[si], '+'
        je @shift_plus
        jne @goNextCheck
     @shift_plus:
        inc si
   @goNextCheck:
     cmp current_str[si], '0'
        jl @error
     cmp current_str[si], '9'
        jg @error
     mov bx, 10
     mul bx
     jo @error   ;если переполнение
     mov bx, 0
     mov bl, current_str[si]
     sub bl, '0'
     add ax, bx
     jo @error
     inc si
     cmp current_str[si], '$'
        je @goCheckSign
        jne @goNextCheck 
   @goCheckSign:
     cmp isNegative, 1
        je @negative
        jne @goEnd 
     @negative:
        neg ax   ;смена знака числа(доп. код), not+inc
        jmp @goEnd      
   @error:
     mov isError, 1 
   @goEnd:
     pop bx
endm
   
str_preparation macro current_str  ;убираем символ enter
    mov si, 1
    xor bx,bx
    mov bl, current_str[si]
    add si, bx
    inc si
    mov current_str[si], '$'
    mov isError, 0
endm

operation_add macro
    local @error, @goEnd 
    mov ax, first_operand
    add ax, second_operand
    jo @error
    jmp @goEnd
    @error:
        mov isError, 1
    @goEnd:  
endm 

operation_sub macro
    local @error, @goEnd
    mov ax, first_operand
    sub ax, second_operand
    jo @error
    jmp @goEnd
    @error:
        mov isError, 1
    @goEnd:    
endm

check_sign_operands macro   ;првоеряем знаки для умножения и деления
    local @first_negative, @first_active, @go_next, @go_end, @second_negative, @second_active
    cmp first_operand, 0
        jl @first_negative
        jge @first_active
    @first_negative:
        mov isNegative, 1
        neg first_operand
        jmp @go_next
    @first_active:
        mov isNegative, 0
    @go_next:
    cmp second_operand, 0
        jl @second_negative
        jge @go_end
    @second_negative:
        xor isNegative, 1
        neg second_operand    
    @go_end:    
endm

operation_mul macro
    local @error, @goEnd
    check_sign_operands
    mov ax, first_operand
    mul second_operand 
endm 

operation_div macro
    local @error, @goEnd
    xor dx,dx
    check_sign_operands
    mov ax, first_operand
    div second_operand   
    jo @error
    jmp @goEnd
    @error:
        mov isError, 1
    @goEnd:
endm

operation_remdiv macro  ;остаток от деления
    local @error, @goEnd
    check_sign_operands
    mov isNegative, 0
    xor dx,dx
    mov ax, first_operand
    div second_operand
    mov ax, dx   
    jo @error
    jmp @goEnd
    @error:
        mov isError, 1
    @goEnd:
endm


add_symbol macro
    local @add_ah_65, @go_next, @add_ah_48, @add_al_65, @add_al_48, @go_end 
    cmp ah, 9
    jg @add_ah_65
    jle @add_ah_48
    @add_ah_65:
        add ah, 037h   ;перевод цифр A-F в символы
        jmp @go_next
    @add_ah_48:
        add ah, 030h   ;перевод цифр 0-9 в символы
    @go_next:
    
    cmp al, 9
    jg @add_al_65
    jle @add_al_48
    @add_al_65:
        add al, 037h
        jmp @go_end
    @add_al_48:
        add al, 030h
    @go_end:
    mov answer_str[si], ah
    dec si
    mov answer_str[si], al
    dec si
    
    
endm


convert_str_to_int macro
    local @skip_negative, _loop, @add_minus, @add_plus, @output_str, @delete_this, @go_end 
    cmp ax, 0 
    jg @skip_negative
    neg ax
    mov isNegative, 1
    @skip_negative:
    mov bx, 0
    mov si, 10
    
    mov bl, ah    ;bl исп для хранения
    mov bh, 0
    mov ah, 0
    div ten   ;делим на 16
    add_symbol   ;перевод в аски код
    
    mov ax, bx
    div ten
    add_symbol
    
    mov al, dl
    mov ah, 0
    div ten
    add_symbol
    
    
    mov al, dh
    mov ah, 0
    div ten
    add_symbol    ;проводим данные оперции с dh dl ah al
    
    cmp isNegative, 1
        je @add_minus
        jne @add_plus
    @add_minus:
        mov answer_str[si], '-'
        jmp @output_str
    @add_plus:
        mov answer_str[si], '+' 
    @output_str:
    
    mov si, 0    ; убираем $ в строке ответа с первой позиции
    cmp answer_str[si], '$'
        je @delete_this
        jne @go_end
                           
    @delete_this:
        mov answer_str[si], ' '
    
    
    @go_end:
    str_output answer_str            
endm

begin:
    mov ax, @data
    mov ds, ax
    mov es,ax
    xor ax,ax
    
    firstInput:  ;ввод, пока не введено корректное число
        str_output msg1   ;вывод сообщения о вводе
        str_input first_operand_str  ;ввод строки с клавиатуры
        str_preparation first_operand_str   ;убираем enter
        str_check first_operand_str    ;проверям на правильность и переводим в число
        cmp isError, 1
            je output_error
            jne go_input_second
        output_error:
            str_output msg5
            jmp firstInput
    go_input_second:
        mov first_operand, ax
            
    secondInput:
        str_output msg2
        str_input second_operand_str
        str_preparation second_operand_str
        str_check second_operand_str
        cmp isError, 1
            je _output_error
            jne go_input_operation
        _output_error:
            str_output msg5
            jmp secondInput  
     go_input_operation:
        mov second_operand, ax
        
     thirdInput:   ;ввод знака операции
        str_output msg3
        str_input operation
        
        xor bx,bx
        mov si, 1
        mov bl, operation[si]
        mov isError, 0
        cmp bl, 1   ;проверка, что символ введен один
            jne __output_error
        inc si
        
        mov isNegative, 0
            
        _go_check_add:    
        cmp operation[si], '+'
            je _operation_add
            jne _go_check_sub
        _operation_add:
            xor dx,dx
            operation_add
            jmp _check_error
            
        _go_check_sub:             
        cmp operation[si], '-'
            je _operation_sub
            jne _go_check_mul
        _operation_sub:
            xor dx,dx
            operation_sub
            jmp _check_error
        
        _go_check_mul:    
        cmp operation[si], '*'
            je _operation_mul
            jne _go_check_div
        _operation_mul:
            operation_mul
            jmp _check_error
            
        _go_check_div:    
        cmp operation[si], '/'
            je _operation_div
            jne _go_check_remdiv
        _operation_div:
            cmp second_operand, 0
            je __output_overflow
            operation_div
            jmp _check_error
            
        _go_check_remdiv:
        cmp operation[si], '%'
            je _operation_remdiv
            jne __output_error
        _operation_remdiv:
            cmp second_operand, 0
            je __output_overflow
            operation_remdiv
            jmp _check_error
  
        _check_error:
            cmp isError, 1
                je __output_overflow
                jne _output_end_answer
        
        
        __output_overflow:
            str_output msg6
            jmp _goEnd
            
        __output_error:
            str_output msg5
            jmp thirdInput 
       
       _output_end_answer:
       
       mov bx, ax     
       convert_str_to_int 
       _goEnd: 
       mov ah, 4ch
       int 21h
end begin