bits 64
default rel

segment .data
    number_to_guess         dq 0
    input_message           db "Guess a number between 1 and 10:", 0xd, 0xa, 0
    invalid_message         db "Invalid input!", 0xd, 0xa, 0
		input_format            db "%d", 0
    smaller_message         db "The number is smaller!", 0xd, 0xa, 0
    bigger_message          db "The number is bigger!", 0xd, 0xa, 0
		success_message         db "Congratulation! You guessed the correct number!", 0xd, 0xa, 0
    lose_message            db "You lose! The correct number is %d", 0xd, 0xa, 0
    remaining_tries         db 3
    quit_message            db "Thanks for playing! Bye!", 0xd, 0xa, 0
    min_input               equ 1
    max_input               equ 10
    input_number            db 0
    input_buffer times 255  db 0   ; Important: Put this variable as last to avoid messing 
                                   ; up the consecutive variables if the player 
                                   ; inserts more than one char via scanf
    
segment .text
global main
extern ExitProcess
extern _CRT_INIT

extern printf
extern scanf
extern srand, rand

main:
    ; Init main
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32
    call    _CRT_INIT

    ; Init random generator
    mov     rcx, 42                  ; TODO: Replace this by current system time or similar
    call    srand                    ; Set seed
    
new_game:
    ; Reset game state
    mov     al, 3
    mov     [remaining_tries], al
    
    ; Create a random number between 1 and 10 (number_to_guess = (rand % 10) +1)
    call    rand                     ; rax contains a random number
    ; Modulo: For 64 bit: DIV operator: Divides RDX:RAX by SRC -> RAX contains result, RDX contains RDX:RAX mod SRC
    mov     rdx, 0                   ; Clear remainder register
    mov     rcx, 10                  ; divisor
    div     rcx                      ; divide rdx:rax by rcx
    inc     rdx                      ; (rand % 10) + 1
    mov     [number_to_guess], rdx   ; Save random number to variable
    
next_guess:
    ; Reduce remaining tries
    dec     byte [remaining_tries]

guess_again:   
    ; Print input message
    lea     rcx, [input_message]
    call    printf
    
		; Read input
    lea     rcx, [input_format]      ; First argument of scanf: format string
    lea     rdx, input_buffer      ; Second argument of scanf: where to store the result
    mov     rax, 0
    call    scanf
    mov byte al, [input_buffer]
    mov byte [input_number], al
    
    ; Check if input is in valid range
    cmp byte [input_number], 1
    jl      invalid_input
    cmp byte [input_number], 10
    jg      invalid_input
    
    ; Check number
    mov     al, [number_to_guess]
    cmp     al, [input_number]
    jl      smaller
    jg      bigger
    je      success
    
invalid_input:
    lea     rcx, [invalid_message]
    call    printf
    jmp     guess_again
    
smaller:
    lea     rcx, [smaller_message]    
    jmp     check_if_lost            ; Check if maximum number of tries are reached
    
bigger:
    lea     rcx, [bigger_message]
    jmp     check_if_lost            ; Check if maximum number of tries are reached
    
check_if_lost:
    mov     al, [remaining_tries]
    cmp     al, 0
    jle     lose                     ; If there are no remaining tries are left, print the lose message                
    call    printf                   ; Else print the smaller or bigger message (depending on first condition)   
    jmp     next_guess
    
lose:
    lea     rcx, [lose_message]
    mov     rdx, [number_to_guess]
    call    printf
    jmp     new_game
    
success:
    lea     rcx, [success_message]   
    call    printf                   ; Print sucess message
    jmp     new_game
    
quit:
    ; Print quit message
    lea     rcx, [quit_message]
    call    printf
    
    ; Clean up main
    xor     rax, rax
    call    ExitProcess