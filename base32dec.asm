SECTION .data
	BASE32_TABLE: db "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
	invalidInputText: db "Invalid Input"
	
SECTION .bss
	input: resb 4096
	inputLen: resb 4096
	output: resb 1	

SECTION .text
	global _start
	
_start:
	nop

setupRead:
	xor rax, rax		; rax contains the current input size
	xor r10, r10		; r10 contains the final input size
	
Read:
	mov rax, 0 		; Code for Sys_write call
	mov rdi, 0		; Standard Input
	mov rsi, input		; Pass offset to the input
	mov rdx, inputLen	; Pass number of bytes to read
	add rsi, r10		; offset the pointer by the amount of characters read before Enter
	syscall

	sub rsi, r10		; move the input pointer back to the start of the input

	cmp r10, 0		
	jne checkShouldReadAnotherLine

	cmp eax, 0		; check if the input is ctrl-d
	je _done		; then end the program

checkShouldReadAnotherLine:
	add rax, r10		; add the input size to rax
	mov r10, rax		; save the input size in r10 cause rax will get overridden
	cmp byte [rsi+rax-1], 10 ; compare the last character to new line
	jne prepareRegisters	 ; if the last character if the input is not a new line then decode

	dec r10			; decrement r10 to override the new line
	jmp Read		; read more after the new line

prepareRegisters:
	mov dl, 0		; is the current encoded character to put out
	mov r8, 0		; is the counter for the loop in the base32 table
	mov r9, 0		; holds the offset
	mov r12, 0		; holds the turn number
	mov r13, 0		; holds the result of f(turn)
	mov rdx, 0		; holds the decoded characters
	
	xor rcx, rcx		; clear rcx to 0

	;; f(turn) = (turn * 5) % 8. the result gets saved in ah
	;; tells us how many bits we need from the next 5 bits
nextTurn:
	inc r12			; increment the turn number
	mov al, r12b		; move the turn number to al
	mov bl, 5		; move the multiplier 5 to bl
	mul bl			; multiply al * bl
	mov bl, 8		; move the divider 8 to bl
	div bl			; divide by bl
	mov bl, ah		; move the result of the equation f(turn) to bl
	mov r13b, bl		; move f(turn) to r13b
	
readOneCharacter:
	cmp rcx, r10		; compare the input pointer offset to the inital input size
	je _done		; end if we read all characters
	mov al, [rsi+rcx]	; mov the character offset by rcx to al

convertToBase32Index:
	cmp al, 61		; cmp al to the ascii code of the equal sign
	je _done		; end if we got an equal sign
	
lookupInBase32Table:
	mov bl, [BASE32_TABLE+r8] ; move on character from the base32 table to bl
	cmp al, bl		  ; compare the input character to the char in the base32 table
	je moveCharToOutput	  ; move the char to the output
	inc r8			  ; increment the counter for the lookup
	cmp r8, 32		  ; compare the base32 index to 32
	je invalidInput		  ; if the base32 index reaches 32 there's a invalid char in the input
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
	push rsi
	call printOutput
	pop rsi
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

invalidInput:
	mov rax, 1		; Code for Sys_write call
	mov rdi, 1		; Standard Output
	mov rsi, invalidInputText ; Address of the invalid input message
	mov rdx, 13		  ; Size of the output
	syscall

endWithError:
	mov rax, 60
	mov rdi, 1
	syscall
