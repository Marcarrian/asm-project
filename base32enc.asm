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

T0:				; check the content of  eax here

	;; Set up the registers for the process buffer step
	xor ecx, ecx		; Clear line string pointer to 0
	
	mov dil, 0		; sil holds the current turn number
	mov r9b, 0		; r9b holds the offset
	mov bl, 0		; bl holds the return of f(turn)
	
Scan:
	xor eax, eax		; Clear eax to 0

	;; f(turn) = (turn * 5) % 8. the result gets saved in ah
	;; if f(turn) < 5 then f(turn) = amount of bits from next byte
nextTurn:
	inc dil			; increment the turn
	mov al, dil		; move the turn number to al
	mov bl, 5		; move the multiplier 5 to bl
	mul bl			; multiply al * bl
	mov bl, 8		; move the divider to bl
	div bl			; divide bl
	mov bl, ah		; move the remainder of the equation to bl

T:	
	
	mov al, [rsi+rcx]	; put the char + the offset of the input in al

	cmp r9b, 3		; compare the offset to 3
	jle fromCurrent		; if < 3 
	je currentAndIncrement	; if = 3
	Jg fromCurrentAndNext	; if > 3

	;; we have enough bits and dont need any from the next byte
fromCurrent:
	push cx			; save cx to the stack

T1:
	mov cl, 3		; the shift amount is 3 by default (to get the first 5 bits)
	sub cl, r9b		; the shift amount minus the offset
	shr al, cl		; shift right al by the amount in cl
	and al, 1Fh		; mask out the first 5 bits
	
	;; set the offset: 8 - cl (shifted amount)
	mov dl, 8		; mov 8 to dl
	sub dl, cl		;  
	mov r9b, dl

	pop cx			; get cx from the stack
	call lookupAndSaveToOutput
	
	jmp nextTurn
	

currentAndIncrement:
	shr al, 3
	;; PRINT AL
	inc rcx
	jmp nextTurn

	;; we need bits from the current one AND from the next one
fromCurrentAndNext:
	push cx			; save cx to the stack
	;; i want to null out the left bits by shifting left
	;; then shift right again by the correct amount to put them in place for the
	;; next bits from the next byte
	mov cl, r9b		; move the offset to cl
	shl al, cl		; shift left by the offset to null out the left bits

	;; al should be 8
	mov cl, 8		; mov 8 to cl
	sub cl, r9b		; - offset
	shr al, cl		; shift back right by 8 - offset
	;; al should be 4

T2:
	pop cx			; get cx from the stack
	
	;; increment and get the first bits from the next byte

	;; here we should check the end condition
	;; if we're done, call lookUpAndSaveToOutput and done
	
	
	inc rcx			; next byte
	mov dl, [rsi+rcx]	; mov the next byte to al

	push cx			; save cx to the stack
	
	;; 8 - f(turn) where f(turn) is the amount of bits we need from this byte
	mov cl, 8		; mov 8 to cl
	sub cl, bl		; - f(turn)
	shr dl, cl		; shift right by the amount of bits

	add al, dl		; add the bits from the previous byte to the bits from the current byte
	;; al should be 5
	pop cx			; retore cx from the stack
	cmp al, 0		; compare al to 0
	je _done		; if al 0 then end NOT SURE YET
	call lookupAndSaveToOutput
	
	mov r9b, bl		; move f(turn) to the offset

	pop cx			; restore cx from the stack
	jmp nextTurn
	
	call _done
	nop

lookupAndSaveToOutput:
T4:
	push rcx		; save rcx to the stack
	push rax
	push rdi
	push rsi
	push rdx

	mov cl, al		; move the offset generated before
	mov al, [BASE32_TABLE+rcx] ; get the base32 character by the offset in rcx	
	mov [output], al
			
_printOutput:
T5:	
	mov rax, 1		; Code for Sys_write call
	mov rdi, 1		; Standard Output
	mov rsi, output		; Adress of the output
	mov rdx, 16		; size of the input
	syscall			; Make kernel call

	pop rdx
	pop rsi
	pop rdi
	pop rax
	pop rcx
	ret
	
_done:
	mov rax, 60		; Code for exit
	xor rdi, rdi		; Return a code of zero
	syscall			; Make kernel call
