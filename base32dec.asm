SECTION .data
	BASE32_TABLE: db "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
	
SECTION .bss
	input: resb 4096
	inputLen: resb 4096
	output: resb 4096	

SECTION .text
	global _start
	
_start:
	nop

Read:
	mov rax, 0 		; Code for Sys_write call
	mov rdi, 0		; Standard Input
	mov rsi, input		; Pass offset to the input
	mov rdx, inputLen	; Pass number of bytes to read
	syscall

	cmp eax, 0		; check if the input is ctrl-d
	je _done		; then end the program

prepareRegisters:
	mov dl, 0		; is the current encoded character to put out
	mov r10, rax		; move the amount of characters from the input to r10
	mov r8, 0		; is the counter for the loop in the base32 table
	mov r9, 0		; holds the offset. Where we place the bits in the current byte
	mov r11, 0		; holds the amount of equal signs
	mov r12, 0		; holds the bits we need to finish the current byte
	mov rdx, 0		; holds the decoded characters
	
	xor rcx, rcx		; clear rcx to 0
	
readOneCharacter:
	mov al, [rsi+rcx]	; mov the character offset by rcx to al

convertToBase32Index:
	;; compare al to the ascii code 61 for '='
	;; shift left by one here to insert the 0 bit
	;; im not quite sure how im gonna handle the output so ill leave this open for now
	cmp al, 61		; check if we got an equal sign
	je increaseAmountOfEqualSigns
	
lookupInBase32Table:
	mov bl, [BASE32_TABLE+r8] ; move on character from the base32 table to bl
	cmp al, bl		  ; compare the input character to the char in the base32 table
	je moveCharToOutput	  ; move the char to the output
	inc r8			  ; increment the counter for the lookup
	jmp lookupInBase32Table	  ; back to looping over the table
	
moveCharToOutput:
	mov al, r8b		; move the base32 char to al
	xor r8, r8		; reset the loop counter to zero
	cmp r9, 3		; compares the offset to 3
	je toCurrentPrintAndIncrement
	jle toCurrentIncrement
	jge toCurrentPrintToNext


toCurrentPrintAndIncrement:

toCurrentIncrement:
T1:	
	push rcx       ; save rcx
	mov bl, al	; move the base32 char to bl
	;; calculate the shift amount
	mov cl, 3		; move 3 to cl
	sub cl, r9b		; 3 - offset
	shl bl, cl		; set the bits in the correct offset position
	add dl, bl		; add the 5 bits in bl to dl

	;; calculate the new offset: 8 - shifted amount
	mov bl, 8		; move 8 to bl
	sub bl, cl		; subtract the shifted amount from bl
	mov r9b, bl		; update the offset

	;; set the amount of bits we need from the next char: 8 - offset
	mov bl, 8		; move 8 to bl
	sub bl, r9b		; subtract the offset from 8
	mov r12b, bl		; update the bits we need from the next char
	
	pop rcx			; restore rcx
	inc rcx			; increment the offset counter
	jmp readOneCharacter	; read the next character

toCurrentPrintToNext:
	push rcx		; save rcx
	mov bl, al		; move the base32 char to bl

	;; calculate the shift amount: 5 - bits needed (r12b)
	mov cl, 5		; mov 5 to cl
	sub cl, r12b		; subtract the bits needed from cl

	shr bl, cl		; shift the unneeded bits away
	add dl, bl		; add the bits in to the previous bits in dl
	;; update the new bits needed: 5 - shifted amount
	mov bl, 5		; move 5 to bl
	sub bl, cl		; subtract the shifted amount from bl
	mov r12b, bl		; update the bits needed
	
	jmp printOutput

	xor r9b, r9b		; reset the offset to zero
	pop rcx			; restore rcx


	
	cmp rcx, r10		; compare the pointer offset to the initial input length
	je _done		; end for now TODO
	jmp readOneCharacter	; read the next character

increaseAmountOfEqualSigns:
T:	
	inc r11			; increases amount of equal signs by 1
	inc rcx			; increment rcx to then get the next char from the input
	cmp rcx, r10		; compare the pointer offset to the initial input length
	je moveEqualSignsToOutput ; move the equal signs to the output
	jmp readOneCharacter
	
	
moveEqualSignsToOutput:
	shr rdx, 5		; shift right 5 back
	mov rcx, r11		; move the amount of equal signs to rcx
	shl rdx, cl		; shift left by the amount of equal signs
	shr rdx, 8		; shift right 8 to remove the unused last 8 bits
	
	mov [output], rdx
printOutput:
	mov [output], rdx
	mov rax, 1		; Code for Sys_write call
	mov rdi, 1		; Standard Output
	mov rsi, output		; Address of the output
	mov rdx, 1		; Size of the output
	syscall

	
_done:
	mov rax, 60
	xor rdi, rdi
	syscall
	
