SECTION .data			; Section containing initialised data
	BASE32_TABLE: db "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
	base32 equ 5 		; group into 5 bits
	
SECTION .bss			; Section containing uninitialized data
	input:	resb 16
	inputLen equ 16
	bitsNext resb 1		; the amount of bits we need from the next byte
	offset resb 1		; offset from where we start counting 5 bits
	output:	resb 16		; output of string encoded in base32
	
SECTION .text			; Section containing code
	global 	_start		; Linker needs this to find the entry point!
	
_start:
	nop

	;; Read a buffer of the input
Read:
	mov rax, 0		; Code for Sys_write call
	mov rdi, 0		; Standard Input
	mov rsi, input		; Pass offset of the input
	mov rdx, inputLen	; Pass number of bytes to read
	syscall

	;; Set up the registers for the process buffer step
	mov rsi, input		; Place address of input buffer into rsi
	mov rdi, output		; Place address of output into rdi
	xor ecx, ecx		; Clear line string pointer to 0

	mov r8b, 0		; r8b holds the current turn
	mov r9b, 0		; r9b holds the offset
	mov r10b, 0		; r10 hold the bits we need from the next byte f(turn)
	
Scan:
	xor eax, eax		; Clear eax to 0

	;; f(turn) = (turn * 5) % 8. the result gets saved in ah
nextTurn:
	inc r8b			; increment turn number
	mov al, r8b		; move the turn number to al
	mov bl, 5		; move the multiplier 5 to bl
	mul bl			; multiply bl
	mov bl, 8		; move the divider to cl
	div bl			; divide cl
	mov r11, ah		; move the remainder of the equation to r10

	mov al, [rsi+rcx]	; put the char + the offset of the input in al
T:

	cmp r9b, 3
	jle fromCurrent		; if < 3 
	je currentAndIncrement	; if = 3
	Jg fromCurrentAndNext	; if > 3

	;; we have enough bits and dont need any from the next byte
fromCurrent:
	push cx			; save cl to the stack
	push dx			; save dl to the stack
	
	mov cl, 3		; the shift amount is 3 by default (to get the first 5 bits)
	sub cl, r9b		; the shift amount minus the offset
	shr al, cl		; shift right al by the amount in cl
	;; set the offset: 8 - cl (shifted amount)
	mov dl, 8		; mov 8 to dl
	sub dl, cl		;  
	mov r9b, dl

	pop dx
	pop cx
	
	jmp nextTurn
	

currentAndIncrement:
	shr al, 3
	;; output al
	inc rcx
	jmp nextTurn

fromCurrentAndNext:
	shl al, r9b		; we null out the left bits
	push cx			; save cx to the stack

	;; shift right so we just have enough space for the bits from the next byte
	mov dl, 8		; 8
	sub dl, r9b		; - offset
	sub dl, r10b		; - f(turn)
	
	shr al, dl		; shift right by 8 - offset - f(turn)
	mov cl, al		; save the bits from the current byte to cl

	;; increment and get the first bits from the next byte
	inc rcx			; next byte
	mov al, [rsi+rcx]	; mov the next byte to al

	;; 8 - f(turn)
	mov dl, 8		; mov 8 to dl
	sub dl, r10b		; - f(turn)
	shr al, dl		; shift right by the amount of bits
	mov r9b, r10b		; move f(turn) to the offset

	pop cx			; restore cx from the stack
	jmp nextTurn
	
	
	mov cl, [BASE32_TABLE]	
	mov [output], ebx
	call _printOutput
	
	call _done
	nop
		
_printOutput:
	mov rax, 1		; Code for Sys_write call
	mov rdi, 1		; Standard Output
	mov rsi, [output]	; Adress of the output
	mov rdx, 16		; size of the input
	syscall			; Make kernel call	

_done:
	mov rax, 60		; Code for exit
	xor rdi, rdi		; Return a code of zero
	syscall			; Make kernel call
