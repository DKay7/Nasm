section .text
global Printf
extern main

;-------------------------------------------------------------------------
; MACRO SECTION
;-------------------------------------------------------------------------
%macro process_number 1 
        push    rax
        push    rcx
        mov     rax, [rbp + rcx]
        push    %1
        push    rax
        call    PrintNum
        add     rsp, 16
        pop     rcx
        pop     rax
        add     rcx, 8
%endmacro

;-------------------------------------------------------------------------
; FUNC SECTION
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------
;   putc
;   print one char to the stdout. Attention: this programm uses 
;   bufferisation and don't flush it's bufffer on last call
;   
;   Expects:    Character in the stack
;   Note:       CDECL
;   Destroys:   None
;-------------------------------------------------------------------------

putc:
    push    rbp
    mov     rbp, rsp

    push    rsi 
    push    rdi
    push    rdx
    push    rbx

    mov rax, [buf_cur_len]

    mov     rdi, [buf_cur_len]
    mov     rsi, buf_len
    sub     rsi, 1

    cmp rdi, rsi
    jl .putc_to_buffer

    .drop_buffer:
        call    FlushBuffer
        jmp     .putc_to_buffer

    .putc_to_buffer:
        mov     bl,     byte [rbp + 16]
        mov     rdi,    buffer
        add     rdi,    [buf_cur_len]
        mov     byte    [rdi],  bl
        add     qword   [buf_cur_len], 1

    pop     rbx
    pop     rdx
    pop     rdi
    pop     rsi 
    pop     rbp

    ret

;-------------------------------------------------------------------------
;   FlushBuffer:
;   Print's programm buffer to the screen
;   
;   Expects:    None
;   Note:       CDECL            
;   Destroys:   None
;-------------------------------------------------------------------------
FlushBuffer:
    push    rbp
    mov     rbp, rsp
    push    rsi
    push    rdi
    
    mov     rsi, buffer
    mov     rdx, [buf_cur_len]
    push    rax
    push    rcx
    call PrintBuffer
    pop     rcx
    pop     rax

    mov     qword [buf_cur_len], 0
    
    pop     rdi
    pop     rsi
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

Printf:
    pop rax
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi
    push rax

    push rbp 
    mov  rbp, rsp

    xor     rax, rax
    mov     rsi, qword [rbp + 16]       ; format line
    mov     rcx, 24                     ; first arg offset

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
        process_number 2
        jmp .start_str_processor

    .PROCEESS_DIGIT_8:
        process_number 8
        jmp .start_str_processor

    .PROCEESS_DIGIT_10:
        process_number 10
        jmp .start_str_processor

    .PROCEESS_DIGIT_16:
        process_number 16
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
        push    rax
        call    putc
        pop     rax
        jmp .start_str_processor
    
    .start_str_processor:
        lodsb
        cmp     rax, 0

    jne .sring_processor

    .end_printf:
        call    FlushBuffer

        pop     rbp

        pop rax
        add rsp, 48
        push rax        ; push ret addres

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

    ; Flushing buffer because we will need it
    call    FlushBuffer

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

    mov     rsi, [rbp + 16]

    jmp .start_str_processor
    .string_processor:
        push    rax
        call    putc
        add     rsp, 8
        .start_str_processor:
        lodsb
        cmp     rax, 0
    jne .string_processor


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

jmp_table:  dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   a
            dq    Printf.PROCEESS_DIGIT_2                   ;   b
            dq    Printf.PROCESS_CHAR                       ;   c
            dq    Printf.PROCEESS_DIGIT_10                  ;   d
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   e
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   f
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   g
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   h
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   i
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   j
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   k
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   l
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   m
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   n
            dq    Printf.PROCEESS_DIGIT_8                   ;   o
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   p
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   q
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   r
            dq    Printf.PROCEESS_STRING                    ;   s
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   t
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   u
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   v
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   w
            dq    Printf.PROCEESS_DIGIT_16                  ;   x
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   y
            dq    Printf.PRINT_SYMBOL_AFTER_PERCENT         ;   z


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

buffer      times 4096 db 0
buf_len     equ $ - buffer
buf_cur_len dq  0
my_ascii    db  "0123456789ABCDEF", 0
