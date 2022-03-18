default rel

extern add
extern printf
global main

;-------------------------------------------------------------------------

section .text

main:
    mov     rdi,  6
    mov     rsi, 10
    mov     rax, 0
    call    add     ; add(6, 10)

    mov     rdi, format
    mov     rsi, rax
    mov     rax, 0
    call    printf  WRT ..plt; printf(format, eax)

    ret

;-------------------------------------------------------------------------

section .data
  format db "%d", 10, 0