SECTION .data			; Section containing initialised data
	BASE32_TABLE: db "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
	base32 equ 5 		; group into 5 bits
	testLookUp equ 18	; should be 'S' from the table
	
SECTION .bss			; Section containing uninitialized data
	input:	resb 16
	inputLen equ 16
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

	mov rbp, rax		; Save # of byes from from input for later

	;; Set up the registers for the process buffer step
	mov rsi, input		; Place address of input buffer into rsi
	mov rdi, output		; Place address of output into rdi
	xor ecx, ecx		; Clear line string pointer to 0

Scan:
	xor eax, eax		; Clear eax to 0

	;; Get a character from the input and put it in both rax and rbx
	mov al, [rsi]		; for now put the first byte (the first char) into al

	;; test inrement ecx
	inc rcx
	mov al, [rsi+rcx]
	
	mov bl, al		; copy al into bl
T:	
	;; Look up the first 5 bits from BASE32_TABLE
	shr al, 3		; Shift 3 bits to the right to get the first 5 bits

	and bl, 3h		; keep the last 3 bits
	shl bl, 2		; shift by 2 to make space for the next 2 bits

	inc ecx

	mov al, [rsi]		; get the next char ('B' to test)
	shr al, 6		; shift right to only keep the last 2 bits

	add bl, al		; add the 2 bits in al to bl
	
	
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
