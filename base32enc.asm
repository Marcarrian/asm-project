SECTION .data			; Section containing initialised data
	table: db "ABCD"
	
SECTION .bss			; Section containing uninitialized data
	output resb 16		; output of string encoded in base32
	
SECTION .text			; Section containing code
	global 	_start		; Linker needs this to find the entry point!
	
_start:
	nop
	call _printInputA
	
	mov rax, 60		; Code for exit
	mov rdi, 0		; Return a code of zero
	syscall			; Make kernel call

_printInputA:
	mov rax, [table]	; move the table into rax
T:	



	
	mov rax, 1		; Code for Sys_write call
	mov rdi, 1		; Specify File Descriptor 1: Standard Output	
	mov rdx, 2		; Pass the length of the message
				; rcx = integer value of "A" = 65 mov rcx, 65
	syscall
	ret
