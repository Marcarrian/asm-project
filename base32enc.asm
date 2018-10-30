SECTION .data			; Section containing initialised data
	BASE32_TABLE: db "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
	base32 equ 5 		; group into 5 bits
	equalSign: db "="
	
SECTION .bss			; Section containing uninitialized data
	input:	resb 256
	inputLen equ 256
	bitsNext resb 1		; the amount of bits we need from the next byte
	offset resb 1		; offset from where we start counting 5 bits
	output:	resb 1		; output of string encoded in base32
	
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

	cmp eax, 0
	je _done
	
	;; Set up the registers for the process buffer step
	xor ecx, ecx		; Clear line string pointer to 0y
	
	mov dil, 0		; sil holds the current turn number
	mov r9b, 0		; r9b holds the offset
	mov r10, rax		; r10 holds the amount of characters from the input + 1
	mov bl, 0		; bl holds the return of f(turn)
	mov r8, 0		; amount of output characters
	
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

	mov al, [rsi+rcx]	; put the char + the offset of the input in al

	cmp r9b, 3		; compare the offset to 3
	je currentAndIncrement 	; if == 3
	jle fromCurrent		; if < 3 
	Jg fromCurrentAndNext	; if > 3

	;; we have enough bits and dont need any from the next byte
fromCurrent:
	push cx			; save cx to the stack

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
	and al, 1Fh		; get the last 5 bits
	mov r9, 0		; set the offset back to 0
	push rcx
	call lookupAndSaveToOutput
	pop rcx

	inc rcx
	cmp rcx, r10		; test end condition
	je _printEqualSigns	;
	
	jmp nextTurn

	;; we need bits from the current one AND from the next one
fromCurrentAndNext:
	push cx			; save cx to the stack
	;; i want to null out the left bits by shifting left
	;; then shift right again by the correct amount to put them in place for the
	;; next bits from the next byte
	mov cl, r9b		; move the offset to cl
	shl al, cl		; shift left by the offset to null out the left bits
	shr al, 3		; shift back right by 3
	
	pop cx			; get cx from the stack

	cmp rcx, r10
	je _lookupAndPrintEqualSigns	
	
	;; inrement and get the first bits from the next byte
	inc rcx			; next byte
	
	;; check the end condition here already?
	
	mov dl, [rsi+rcx]	; mov the next byte to dl

	push cx			; save cx to the stack
	
	;; 8 - f(turn) where f(turn) is the amount of bits we need from this byte
	mov cl, 8		; mov 8 to cl
	sub cl, bl		; - f(turn)
	shr dl, cl		; shift right by the amount of bits

	add al, dl		; add the bits from the previous byte to the bits from the current byte
	;; al should be 5
	pop cx			; retore cx from the stack

	push cx			; save cx to the stack
	call lookupAndSaveToOutput
	pop cx			; restore cx
	
	push cx			; save
	cmp rcx, r10		; compare the input counter to the initial input length
	pop cx			; restore
	je _printEqualSigns	; if the input counter is equal to the initial length we're done
	;; aka we gotta print the equal signs first
	
	mov r9b, bl		; move f(turn) to the offset
	
	jmp nextTurn
	nop

lookupAndSaveToOutput:
	push rcx		; save rcx to the stack
	push rax
	push rdi
	push rsi
	push rdx
	mov cl, al		; move the offset generated before
	mov al, [BASE32_TABLE+rcx] ; get the base32 character by the offset in rcx	
	mov [output], al
			
_printOutput:	
	mov rax, 1		; Code for Sys_write call
	mov rdi, 1		; Standard Output
	mov rsi, output		; Adress of the output
	mov rdx, 1		; size of the output
	syscall			; Make kernel call

	pop rdx
	pop rsi
	pop rdi
	pop rax
	pop rcx
	inc r8
	cmp r8, 9	     ; if we already put out 8 characters reset it to 1
	je resetCountTo1
	jne donePrinting

resetCountTo1:
	mov r8, 1

donePrinting:
	ret

_lookupAndPrintEqualSigns:
	call lookupAndSaveToOutput
	jmp _printEqualSigns
	
;;; print the correct amount of equal signs
;;; this is achieved by subtracting 8 from rcx
_printEqualSigns:
	mov rax, r8
	mov rcx, 8
	sub rcx, rax
loop:
	cmp rcx, 0
	je _done

	push rcx
	push rax
	push rdi
	push rsi
	push rdx
	call _printOneEqualSign
	pop rdx
	pop rsi
	pop rdi
	pop rax
	pop rcx
	dec rcx
	jmp loop

_printOneEqualSign:
	mov rax, 1
	mov rdi, 1
	mov rsi, equalSign	; equal sign
	mov rdx, 1		; output length of 1
	syscall
	ret
	
_done:
	mov rax, 60		; Code for exit
	xor rdi, rdi		; Return a code of zero
	syscall			; Make kernel call
