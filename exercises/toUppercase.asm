section .data
	hardcodedInputSize equ 16
section .bss
	input resb 16
section .text
	global	_start
_start:
	nop
	;; get input
	mov rax, 0		; Code for Sys_write call
	mov rdi, 0		; Standard Input
	mov rsi, input		; adress of the input
	mov rdx, hardcodedInputSize	; Size of the input
	syscall

	mov ebx, input		; location of the input into ebx
	
T:	
	;; transform input to uppercase
ToUppercase:
	sub byte [ebx], 32	; subtract 32 to get the uppercase character
	inc ebx			; ??
	dec eax			; loop decrement. eax already has the size of the input +?
	jnz ToUppercase		; loop again
	
	;; print transformed input
	mov rax, 1		; Code for Sys_write call
	mov rdi, 1		; Standard Output
	mov rsi, input		; adress of the input
	mov rdx, hardcodedInputSize
	syscall

	;; exit with code 0
	mov rax, 60
	mov rdi, 0
	syscall
	nop
