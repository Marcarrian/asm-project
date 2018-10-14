SECTION .data			; Section containing initialised data
	table: db "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
	
SECTION .bss			; Section containing uninitialized data
	input:	resb 16
	output:	resb 16		; output of string encoded in base32
	
SECTION .text			; Section containing code
	global 	_start		; Linker needs this to find the entry point!
	
_start:
	nop
	call _getInput
	call _encodeToBase32
	call _printOutput
	call _done
	nop

_getInput:
	mov rax, 0		; Code for Sys_write call
	mov rdi, 0		; Standard Input
	mov rsi, input		; adress of the input
	mov rdx, 16		; will be the size (should be dinamically maybe?)
	syscall
	
_encodeToBase32:
	mov rbx, input		; move the adress of the input into rbx
	mov [output], rbx	; move rbx into the value(?) of output
T:	

_printOutput:
	mov rax, 1		; Code for Sys_write call
	mov rdi, 1		; Standard Output
	mov rsi, [output]	; Adress of the output
	mov rdx, 16		; Length of the output (hardcoded for now)
	syscall			; Make kernel call	

_done:
	mov rax, 60		; Code for exit
	xor rdi, rdi		; Return a code of zero
	syscall			; Make kernel call
