default rel
bits 64

segment .data
    fmt db "The square of %d is: %d", 0xd, 0xa, 0  ; message to display the result with printf
    num equ 46340                                  ; max possible value for 32 squaring: 46340

segment .text

global main
global square_int         ; export the function

extern _CRT_INIT
extern ExitProcess
extern printf


; Example function
square_int:
    ; Prepare stack for the callee
    push rbp              ; Save stack base pointer of the caller to the stack
    mov  rbp, rsp         ; Copy value of stack pointer of the caller to the base pointer register
    sub  rsp, 32          ; Add shadow space by growing (down) the stack by 32 bytes
		
    ; Do stuff (in this example the input integer is squared and returned to the caller)
    mov eax, ecx          ; Copy the first integer argument to the source register (for 32bit)
    mov edx, ecx          ; Copy the first integer argument to the destination register (for 32bit)
    mul eax               ; Square the given value by multipication destination (edx) with source (eax) -> result will be in edx:eax
    and rax, 0x00000000ffffffff ; Clear upper part of rax
    shl rdx, 32           ; Shift the edx part to position
    or  rax, rdx          ; Combine upper and lower part
		
    ; Restore stack of the caller before leaving the function
    ; The first two lines could be replaced by directive leave
    ;leave
    mov rsp, rbp          ; The stack is now pointing to the stack of the caller again
    pop rbp               ; Get the stack base pointer saved for the caller
    ret                   ; Get the address of the caller from the stack and jump back to the caller


; Main entry point of the program (when linked with MSVC)
main:
    ; Prepare stack for main function
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32
		
    call    _CRT_INIT    ; Init c run time variables
		
    mov     rcx, num     ; Load some integer for testing
    call    square_int   ; Call the example function
		
    ; Display the result via printf
    lea     rcx, [fmt]
    mov     rdx, num     ; First arg for printf (the number to be sqared)
    mov     r8, rax      ; Second arg for printf (the result)
		
    call    printf

    ; Clean up
    xor     rax, rax
    call    ExitProcess