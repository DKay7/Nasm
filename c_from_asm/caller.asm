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
    mov     rsi, str_
    mov     rdx, 0xEDA
    mov     rcx, 100
    mov     r8, 33
    mov     rax, 0
    call    printf  WRT ..plt; printf(format, ...)
    ret

;-------------------------------------------------------------------------

section .data
  str_   db "love", 0
  format db "I %s %x %d%%%c", 10, 0