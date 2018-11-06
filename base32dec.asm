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
	mov r9, 0		; holds the offset
	mov r11, 0		; holds the amount of equal signs
	mov r12, 0		; holds the turn number
	mov r13, 0		; holds the result of f(turn)
	mov rdx, 0		; holds the decoded characters
	
	xor rcx, rcx		; clear rcx to 0

	;; f(turn) = (turn * 5) % 8. the result gets saved in ah
	;; tells us how many bits we need from the next byte
nextTurn:
	inc r12			; increment the turn number
	mov al, r12b		; move the turn number to al
	mov bl, 5		; move the multiplier 5 to bl
	mul bl			; multiply al * bl
	mov bl, 8		; move the divider 8 to bl
	div bl			; divide by bl
	mov bl, ah		; move the result of the equation f(turn) to bl
	mov r13b, bl
	
readOneCharacter:
T:
	cmp rcx, r10	       ; compare the input pointer offset to the inital input size
	je _done
	mov al, [rsi+rcx]	; mov the character offset by rcx to al

convertToBase32Index:
	;; compare al to the ascii code 61 for '='
	;; shift left by one here to insert the 0 bit
	;; im not quite sure how im gonna handle the output so ill leave this open for now
	cmp al, 61		; check if we got an equal sign
	je _done
	
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
	jl toCurrentIncrement
	jg toCurrentPrintToNext


toCurrentPrintAndIncrement:
	mov bl, al		; move the base32 char to bl
	add dl, bl		; add bl to the previous bits in dl
	push rcx
	call printOutput
	pop rcx
	xor r9, r9		; reset the offset to 0
	xor dl, dl		; reset dl to 0
	inc rcx			; increment the offset input pointer
	jmp nextTurn

toCurrentIncrement:
	push rcx		; save rcx
	mov bl, al		; move the base32 char to bl
	cmp r13, 5		; compare f(turn) to 5
	jge get5Bits
	jl getFTurnBits

get5Bits:
	;; position the 5 bits according to the offset
	shl bl, 3		; get the 5 bits to the front
	mov cl, r9b		; move the offset to cl
	shr bl, cl		; shift right by cl

	add dl, bl		; add the bits to dl
	add cl, 5		; add 5 to cl
	mov r9b, cl		; update the offset
	pop rcx			; restore rcx
	inc rcx			; increment the input pointer offset
	jmp nextTurn

getFTurnBits:
	;; get f(turn) amount of bits to the front: 8 - r13b
	mov cl, 8		; move 8 to cl
	sub cl, r13b		; subtract r13b from cl
	shl bl, cl		; shift left bl by cl

	;; position the bits according to the offset
	mov cl, r9b		; move the offset to cl
	shr bl, cl		; shift right bl by cl

	add cl, r13b		; calculate the new offset
	mov r9b, r13b		; update the offset
	pop rcx			; restore rcx
	inc rcx			; increment the input pointer offset
	jmp nextTurn

toCurrentPrintToNext:
	push rcx		; save rcx
	mov bl, al 		; move the base32 char to bl

	;; save the bits, which we're gonna use in the next byte
	mov cl, 8
	sub cl, r13b
	shl al, cl
	mov r9b, r13b		; update the offset
	
	;; get 5 - f(turn) bits
	mov cl, r13b		; move f(turn) to cl
	shr bl, cl		; shift right by cl to get 5 - f(turn) bits
	
	add dl, bl		; add the bits in bl to dl
	push rsi
	push rax
	call printOutput
	pop rax
	pop rsi
	pop rcx			; restore rcx

	mov dl, al		; move the leftover bits to dl
	inc rcx			; increment the offset pointer countery
	
	jmp nextTurn

increaseAmountOfEqualSigns:
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
	ret
	
_done:
	mov rax, 60
	xor rdi, rdi
	syscall
	
