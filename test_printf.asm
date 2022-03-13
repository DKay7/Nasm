global _start

section .text
;-------------------------------------------------------------------------
; MAIN SECTION
;-------------------------------------------------------------------------
_start:     
            ; push        33
            ; push        100
            ; push        3802
            ; push        str_to_prnt
            push        string
            call        Printf

            mov         rax, 60                 
            xor         rdi, rdi                
            syscall
            %include    "printf_asm.asm"
            
;-------------------------------------------------------------------------

section .DATA

string      db  "Aboba\n", 0
str_to_prnt db  "love", 0