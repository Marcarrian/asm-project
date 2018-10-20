section .data
	inputSize equ 16
section .bss
	input resb 16
section .text
	global	_start
_start:
	nop
loop:	
	;; get input
	mov rax, 0		; Code for Sys_write call
	mov rdi, 0		; Standard Input
	mov rsi, input		; Adress of the input
	mov rdx, inputSize	; Size of the input
	syscall

	cmp eax, 0		; if CTRL-D is pressed code 0 gets set in eax
	je done			; end the program if CTRL-D is pressed
	
	mov ebx, input		; mov address of the input into ebx
	mov ecx, inputSize	; size of the input
	
toUppercase:
	;; if al < a then jmp endUppercase
	mov bpl, 'a'		; value of 'a'
	mov spl, [ebx]		; current char
	cmp spl, bpl		; compare current char to 'a'	
	jl nextChar		; if spl is less than bpl

	;; if al > z then jmp endUppercase
	mov bpl, 'z'		; value of 'z'
	mov spl, [ebx]		
	cmp spl, bpl
	jg nextChar		; if spl is greater than bpl
	
	sub byte [ebx], 32	; subtract 32 to get the uppercase character
	
nextChar:
	inc ebx			; point to the next char
	dec ecx			; loop decrement
	jnz toUppercase		; loop again if not zero
	
	;; print transformed input
	mov rax, 1		; Code for Sys_write call
	mov rdi, 1		; Standard Output
	mov rsi, input		; adress of the input
	mov rdx, inputSize	; DONT length needs to be dinamically
	syscall

	jmp loop

done:	
	;; exit with code 0
	mov rax, 60
	mov rdi, 0
	syscall
	nop
