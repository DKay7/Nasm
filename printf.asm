global _start

section .text
;-------------------------------------------------------------------------
; MAIN SECTION
;-------------------------------------------------------------------------
_start:     push        33
            push        100
            push        3802
            push        str_to_prnt
            push        string
            call        printf

            mov         rax, 60                 
            xor         rdi, rdi                
            syscall

;-------------------------------------------------------------------------
; FUNC SECTION
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------
;   putc
;   print one char to the stdout.
;   
;   Expects:    Character in the stack
;   Note:       CDECL
;   Destroys:   None
;-------------------------------------------------------------------------

putc:
    push    rbp
    mov     rbp, rsp

    push    rdi 
    push    rsi 
    push    rdx

    mov     rax, 1
    mov     rdi, 1
    mov     rsi, rbp
    add     rsi, 16
    mov     rdx, 1
    syscall

    pop     rdx 
    pop     rsi 
    pop     rdi 
    pop     rbp

    ret

;-------------------------------------------------------------------------
;   PrintBuffer
;   prints the given buffer to the console
;   
;   Expects:    Addres of the buffer in rsi
;               Length of the buffer in rdx
;               
;   Destroys:   RAX, RDI, RCX
;-------------------------------------------------------------------------
PrintBuffer:

    mov     rax, 1
    mov     rdi, 1
    syscall

    ret

;-------------------------------------------------------------------------
;   pritnf
;   realization of a C standart function printf
;   
;   Expects:    one required argument -- 0-terminated string, and, maybe, 
;               additional arguments
;   Note:       CDECL
;   Destroys:   None
;-------------------------------------------------------------------------

printf:
    push    rbp
    mov     rbp, rsp
    push    rsi
    push    r9
    push    rbx

    mov     rsi, [rbp + 16]
    mov     rcx, 24             ; first arg offset

    jmp .start_str_processor

    .sring_processor:
        cmp     al, "%"
        je      .percent_found

        cmp     al, "\"
        je      .backslash_found

        jmp     .PRINT_SYMBOL

    .backslash_found:
        lodsb
        cmp     al, '"'
        je      .end_process_backslash

        cmp     al, "\"
        je      .end_process_backslash

        mov     al, byte [escape_seq + rax - "a"]

        .end_process_backslash:
            jmp     .PRINT_SYMBOL

    .percent_found:
        lodsb
        cmp     al, "%"
        je      .PRINT_SYMBOL                                       ; double percent
        
        cmp     rax, 0          
        je      .end_printf                                         ; string ended

        mov r9, qword [jmp_table + 8 * (rax - "a")]
        jmp r9
    
    .PROCESS_CHAR:
        mov     rax, [rbp + rcx]
        add     rcx, 8
        jmp     .PRINT_SYMBOL
        
    .PROCEESS_DIGIT_2:
        push    rax
        push    rcx
        mov     rax, [rbp + rcx]
        push    2
        push    rax
        call    PrintNum
        add     rsp, 16
        pop     rcx
        pop     rax
        add     rcx, 8

        jmp .start_str_processor

    .PROCEESS_DIGIT_8:
        push    rax
        push    rcx
        mov     rax, [rbp + rcx]
        push    8
        push    rax
        call    PrintNum
        add     rsp, 16
        pop     rcx
        pop     rax
        add     rcx, 8
        jmp .start_str_processor

    .PROCEESS_DIGIT_10:
        push    rax
        push    rcx
        mov     rax, [rbp + rcx]
        push    10
        push    rax
        call    PrintNum
        add     rsp, 16
        pop     rcx
        pop     rax
        add     rcx, 8
        jmp .start_str_processor

    .PROCEESS_DIGIT_16:
        push    rax
        push    rcx
        mov     rax, [rbp + rcx]
        push    16
        push    rax
        call    PrintNum
        add     rsp, 16
        pop     rcx
        pop     rax
        add     rcx, 8
        jmp .start_str_processor
    
    .PROCEESS_STRING:
        push    rax
        push    rcx
        mov     rax, [rbp + rcx]
        push    rax
        call    PrintString
        add     rsp, 8

        pop     rcx
        pop     rax
        add     rcx, 8
        jmp     .start_str_processor

    .PRINT_SYMBOL_AFTER_PERCENT:
        push    rcx
        push    rax
        push    "%"
        call    putc
        add     rsp, 8
        pop     rax
        pop     rcx
        jmp .PRINT_SYMBOL

    .PRINT_SYMBOL:
        push    rcx
        push    rax
        call    putc
        pop     rax
        pop     rcx
        jmp .start_str_processor
    
    .start_str_processor:
        lodsb
        cmp     rax, 0

    jne .sring_processor

    .end_printf:
        pop     rbx
        pop     r9
        pop     rsi
        pop     rbp

        ret


;-------------------------------------------------------------------------
;   PrintNum
;   prints digit from string to console 
;   
;   Expects:    Number to print and the base in the stack
;   Note:       CDECL    
;-------------------------------------------------------------------------
PrintNum:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    rsi
    push    r9

    xor r9, r9
    mov rsi, buffer + buf_len - 1
    mov rax, [rbp + 16]      ; number
    mov rbx, [rbp + 24]      ; base

    .iterate_over_number:
        xor rdx, rdx
        div rbx
        mov cl, byte [my_ascii + rdx]
        mov [rsi], byte cl 
        dec rsi
        inc r9

        cmp rax, 0
    jne .iterate_over_number

    inc rsi
    mov rdx, r9
    call PrintBuffer
    
    pop r9
    pop rsi
    pop rbx
    pop rbp
    ret

;-------------------------------------------------------------------------
;   PrintString
;   prints string to console 
;   
;   Expects:    String addres in the stack
;   Note:       CDECL    
;   Destroys:   RDX, RAX
;-------------------------------------------------------------------------
PrintString:
    push    rbp
    mov     rbp, rsp
    push    rdi
    push    rsi
    push    rdx
    push    rax

    mov     rsi, [rbp + 16]
    call    strlen
    pop     rax

    mov     rdx, rcx
    call    PrintBuffer

    pop     rdx
    pop     rsi
    pop     rdi
    pop     rbp
    ret


;-------------------------------------------------------------------------
;   StrLen
;   counts the len of the string 
;   
;   Expects:    String addres in the stack
;   Note:       CDECL    
;   Returns:    RCX -- string length
;   Destroys:   RAX, RCX
;-------------------------------------------------------------------------
strlen:
    push    rbp
    mov     rbp, rsp
    push    rsi

    xor     rcx, rcx
    xor     rax, rax
    mov     rsi, [rbp + 16]

    lodsb
    cmp al, 0
    je .return     ; if string contains only 0-terminator char

    .process_str:
        inc rcx
        lodsb
        cmp al, 0
    jne .process_str

    .return:
        pop rsi
        pop rbp
        ret

;-------------------------------------------------------------------------
; DATA SECTION
;-------------------------------------------------------------------------

section .data

jmp_table:  dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   a
            dq    printf.PROCEESS_DIGIT_2                   ;   b
            dq    printf.PROCESS_CHAR                       ;   c
            dq    printf.PROCEESS_DIGIT_10                  ;   d
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   e
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   f
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   g
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   h
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   i
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   j
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   k
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   l
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   m
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   n
            dq    printf.PROCEESS_DIGIT_8                   ;   o
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   p
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   q
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   r
            dq    printf.PROCEESS_STRING                    ;   s
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   t
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   u
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   v
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   w
            dq    printf.PROCEESS_DIGIT_16                  ;   x
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   y
            dq    printf.PRINT_SYMBOL_AFTER_PERCENT         ;   z


escape_seq: db 0x07     ;   \a 	0x07 	Звуковой сигнал
            db 0x08     ;   \b 	0x08 	Перевод каретки на одно значение назад
            db 0x00     ;   c
            db 0x00     ;   d
            db 0x00     ;   e
            db 0x0c     ;   \f 	0x0c 	Новая страница
            db 0x00     ;   g
            db 0x00     ;   h
            db 0x00     ;   i
            db 0x00     ;   j
            db 0x00     ;   k
            db 0x00     ;   l
            db 0x00     ;   m
            db 0x0a     ;   \n 	0x0a 	Перевод строки
            db 0x00     ;   o
            db 0x00     ;   p
            db 0x00     ;   q
            db 0x0d     ;   \r 	0x0d 	Возврат каретки
            db 0x00     ;   s
            db 0x09     ;   \t 	0x09 	Табуляция
            db 0x00     ;   u
            db 0x0b     ;   \v 	0x0b 	Вертикальная табуляция
            db 0x00     ;   w
            db 0x00     ;   x
            db 0x00     ;   y
            db 0x00     ;   z

; \" 	0x22 	Двойная кавычка
; \\ 	0x5с 	Обратный слеш

buffer      times 256 db '0'
buf_len     equ $ - buffer
my_ascii    db "0123456789ABCDEF", 0

;-------------------------------------------------------------------------

string      db  "I %s %x %d%% %c \n", 0
str_to_prnt db  "love", 0

; TODO add buferisation
