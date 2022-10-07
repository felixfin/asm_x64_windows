bits 64
default rel

segment .data
    input_message  db "Input a number:", 0xd, 0xa, 0
		input_format   db "%d", 0
    input_number   dq 0
		output_message db "You inserted the following number: %d", 0xd, 0xa, 0

segment .text
global main
extern ExitProcess
extern _CRT_INIT

extern printf
extern scanf

main:
    ; Init main
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32
    call    _CRT_INIT

    ; Print input message
    lea     rcx, [input_message]
    call    printf
    
		; Read input
    lea     rcx, [input_format] ; First argument of scanf: format string
    lea     rdx, [input_number] ; Second argument of scanf: where to store the result
    call    scanf
    
    ; Print output message
    lea     rcx, [output_message]
    mov     rdx, [input_number]
    call    printf
    
    ; Clean up main
    xor     rax, rax
    call    ExitProcess