SECTION .data			; Section containing initialised data
	BASE32_TABLE: db "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
	base32 equ 5 		; group into 5 bits
	offset equ 0		; offset from where we start counting 5 bits
	
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

	mov r8b, 1		; r8b holds the current turn
	
Scan:
	xor eax, eax		; Clear eax to 0

	;; Get a character from the input and put it in both rax and rbx
	mov cl, [rsi+rcx]	; put the char + the offset of the input in cl	
	mov dl, cl		; copy cl into dl

	;; f(turn) = (turn * 5) % 8. the result gets saved in ah
	;; if f(turn) = 0 then read next byte
	;; else if f(turn) < 5 then f(turn) = number of bits we need from next byte
	;; else for this turn we don't need any bits from the next byte and just take 5
nextTurn:
	inc r8b			; increment turn number
	mov al, r8b		; move the turn number to al
	mov bl, 5		; move the multiplier 5 to bl
	mul bl			; multiply bl
	mov bl, 8		; move the divider to cl
	div bl			; divide cl

	jmp readFiveBits

readFiveBits:
	shl cl, offset
	
	
	;; somehow we need to keep track of how many bits are already used in the current byte




	
	and bl, 7h		; keep the last 3 bits
	shl bl, 2		; shift left to make space for the next 2 bits
	
	
T:	
	inc ecx			; end of byte reached, increment

	mov al, [rsi+rcx]	; get the next char ('B' to test)
	mov cl, al		; copy al to cl
	shr al, 6		; shift right to only keep the last 2 bits
	

	add bl, al		; add the 2 bits in al to bl OUTPUT BL

	mov bl, cl		; copy cl to bl
	and bl, 1h		; keep the last bit
	
	shl cl, 1		; xx11 1101 -> shift 1 and keep the 5 bits OUTPUT CL
	
	inc rcx			; end of byte reached, increment
	mov al, [rsi+rcx]	; move the next byte into al
	;; we kept one bit from before in bl we only need the first 4 bits from al xxxx 1111
	mov cl, al		; copy al to cl
	
	shr al, 3		; shift 4 bits to the right
	xor al, 1		; make the last one a zero
	add al, bl		; add the bit from beore to al
	
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
