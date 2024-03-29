; Creditos a Russ Ross por la base de la implementacion de ITOA. Link al video: https://www.youtube.com/watch?v=D7gabV6tWCE

global _start

section .data
	text1 db "Ingrese un numero", 0xA ;len 18
	digitos db '0123456789ABCDEF'     ; Caracteres que representan los dígitos en base 16
	errorCode db "Error: Ingrese un numero valido", 0xA;
	processNum dq 0
	counterSumNum dq 2
	flag1 db 0
	flagSpCase db 0
	negSign db "-" ;len 2
	sumPrint db "Print de sumas:", 0xA ;len 15
	restPrint db "Print de restas:", 0xA ;len 15
	overflowMsg db "ERROR: Overflow", 0xA
	compare_num dq "18446744073709551615"
	compare_numTest dq "857565"

section .bss
	num1 resq 13
	num2 resq 13
	num3 resq 13
	length resb 1


	buffer     resb 101   ; Buffer para almacenar la cadena de caracteres convertida
	base resq 8;

section .text

;------------------ MAIN ------------------------
_start:
	call _printText1		;Hace print inicial
	call _getText			;Consigue el texto del usuario


	mov qword [num2], rax		;carga el primer numero en num2
	xor rax, rax			;reinicia rax
	mov byte[num1], 0		;reinicia num1
	
	call _printText1		;Hace print inicial
	call _getText			;Consigue el texto del usuario

		
	mov qword [num3], rax		;carga el primer numero en num3

	;------------------INICIO ITOA------------------------

	;#SUMA
	call _printSum
	mov rax, [num2]
    	add rax, [num3]			;Hace la suma
	jc _overflowDetected		;check de overflow
	mov [processNum], rax		;inicio itoa suma
	call _processLoop

	_continueProcess:

	;#RESTA
	call _printRest
	mov qword [counterSumNum],2	;reinicia el contador del loop
	call _specialCaseSub		;realiza chequeo de casos especiales (numeros de len 20)

	mov rax, [num2]			
    	sub rax, [num3]			;realiza resta
	call _compare			;compara si el resultado es caso especial o no		
	

	mov [processNum], rax		;inicio itoa resta
	call _processLoop
	;------------------FIN ITOA---------------------------

	call _finishCode

;-------------- FIN MAIN ------------------------

_overflowDetected:
	mov rax, 1
	mov rdi, 1
	mov rsi, overflowMsg
	mov rdx, 16
	syscall
	jmp _continueProcess


_compare: 
	cmp byte [flagSpCase], 1
	je _testNegSpecialCase
	js _testNeg

_testNegSpecialCase:
	;call _finishError
	test rax, rax		;realiza test a ver si el numero es negativo ;18446744073709551614
    	jns _makeNeg
	js _exitFunction
	
_testNeg:
	test rax, rax		;realiza test a ver si el numero es negativo ;18446744073709551615
    	jns _exitFunction  	;si no es negativo salta a string directamente ;8446744073709551614

_makeNeg:
	neg rax			;vuelve positivo el numero
	mov byte[flag1], 1
	ret

;------------------ATOI---------------------------------------
_AtoiStart:
	xor rbx, rbx		;reinicia el registro
	xor rax, rax		;reinicia el registro
	lea rcx, [num1]		;ingresa el numero 1 a rcx
	jmp _Atoi

_Atoi:
	mov bl, byte[rcx]
	cmp bl, 0xA		
	je _exitFunction	;se asegura de que sea el final del string

	sub rbx,30h		;resta 30h al string para volverlo el numero
	imul rax, 10 		;multiplica el numero almacenado en rax x 10 para volverlo decimal
	add rax, rbx		;agrega el ultimo numero obtenido a rax (ej: 10+3=13)	


	xor rbx,rbx		;reinicia el registro
	inc rcx			;incrementa x 1 el rcx (obtiene el siguiente caracter
	jmp _Atoi		;realiza loop

_exitFunction: 
	ret
;----------------- END ATOI ---------------------------------

;----------------- CHEQUEO DE ERRORES -----------------------

;---#chequea que el caracter ingresado sea un int
_inputCheck:  			
				
	mov rsi, num1		; direccion del buffer de ingreso
    	xor rcx, rcx		; Clear counter

	check_input:

		movzx rax, byte [rsi + rcx]		;Carga el byte actual
        	cmp rax, 0xA
        	je input_valid				;Final del string alcanzado
        	cmp rax, '0'
        	jb _finishError				;Revisa caracteres no imprimibles
        	cmp rax, '9'
        	ja _finishError				;Revisa caracteres no imprimibles
        	inc rcx					;Mover al siguente byte
        	jmp check_input

	input_valid:
		ret

;---#SPECIAL CASE
_specialCaseSub: 

	mov rax, [num2]
	call _countInt
	;---------------

	cmp byte [length], 20
	je _num20
	
	mov rax, [num3]
	call _countInt

	cmp byte [length], 20
	jne _exitFunction
	mov byte [flagSpCase], 1
	ret

	;CALL _finishError

	
	_num20:
		mov rax, [num3]
		call _countInt

		cmp byte [length], 20
		je _exitFunction
		mov byte [flagSpCase], 1
		;CALL _printText1
		ret
		


;---#CALCULA LA LONGITUD DE UN NUMERO

_countInt:
	mov byte [length], 0
divide_loop:
    
    test rax, rax
    jz _exitFunction
    
    ; Increment counter
    inc byte [length]
    
    ; Divide rax by 10
    mov rbx, 10
    xor rdx, rdx ; Clear rdx for division
    div rbx
    
    ; Repeat the loop
    jmp divide_loop

;---#CALCULA LA LONGITUD DE UN STRING	
_lengthCheck:
    xor rax, rax                  ; Clear rax register
    mov rdi, num1               ; Load address of the string into rdi
    
length_loop:
    cmp byte [rdi + rax], 0      ; Compare the byte at the current position with null terminator
    je length_done                 ; If null terminator is found, jump to count_done
    inc rax                       ; Increment the counter
    jmp length_loop                ; Continue looping

length_done:
	cmp rax, 21
	jg _finishError
	cmp rax, 21
	je _startNumCheck
	ret

;---#CALCULA SI EL NUMERO ES MENOR O IGUAL A 18446744073709551615
_startNumCheck:
  ; Initialize pointers to the end of strings
    mov rsi, num1 + 19		;Point to the last character of num1 (assuming 13 qwords)
    mov rdi, compare_num +19	;Point to the last character of compare_num (19 characters)

compare_loop:
    ; Load current characters from both strings
    movzx rax, byte [rsi]             ; Load character from num1
    movzx rbx, byte [rdi]             ; Load character from compare_num
    
    ; Compare characters
    cmp rax, rbx               ; Compare characters
    jg _finishError            ; If num1's current digit is greater, jump
    jl end_of_strings          ; If num1's current digit is less, jump
    
    
    ; Move to previous digits
    sub rsi, 1                 ; Move to previous character of num1 (8 bytes for qword)
    sub rdi, 1                 ; Move to previous character of compare_num (8 bytes for qword)
    
    ; Check for beginning of strings
    cmp rsi, -1              ; Check if beginning of num1 reached
    jl end_of_strings          ; If beginning of num1 reached, exit loop
    
    ; Continue loop
    jmp compare_loop
    end_of_strings:
    ret

;--------------END CHEQUEO DE ERRORES------------------------

;--------------ITOA -----------------------------------------

;---#LOOP PARA REALIZAR ITOA
_processLoop:
	cmp qword [counterSumNum],17
	je _exitFunction
	cmp byte[flag1], 1	;se asegura de que el primer numero sea o no negativo
	je _printNeg		;realiza print del simbolo negativo

_continueLoop:
	call _startItoa
	inc qword [counterSumNum]
	jmp _processLoop

;---#ITOA INICIO
_startItoa:
    	; Llama a ITOA para convertir n a cadena
    	mov rdi, buffer
    	mov rsi, [processNum]
    	mov rbx, [counterSumNum]; Establece la base (Se puede cambiar)
    	call itoa
    	mov r8, rax  ; Almacena la longitud de la cadena
    
    	; Añade un salto de línea
    	mov byte [buffer + r8], 10
    	inc r8
    
    	; Termina la cadena con null
   	 mov byte [buffer + r8], 0

   	jmp _printItoa

; Definición de la función ITOA
itoa:
    	mov rax, rsi    ; Mueve el número a convertir (en rsi) a rax
    	mov rsi, 0      ; Inicializa rsi como 0 (contador de posición en la cadena)
    	mov r10, rbx    ; Usa rbx como la base del número a convertir

.loop:
	xor rdx, rdx       ; Limpia rdx para la división
    	div r10            ; Divide rax por rbx
    	cmp rbx, 10
    	jbe .lower_base_digits ; Salta si la base es menor o igual a 10
    
    	; Maneja bases mayores que 10
    	movzx rdx, dl
    	mov dl, byte [digitos + rdx]
    	jmp .store_digit
    
.lower_base_digits:
    	; Maneja bases menores o iguales a 10
    	add dl, '0'    ; Convierte el resto a un carácter ASCII
    	jmp .store_digit
    
.store_digit:
    	mov [rdi + rsi], dl  ; Almacena el carácter en el buffer
    	inc rsi              ; Se mueve a la siguiente posición en el buffer
    	cmp rax, 0           ; Verifica si el cociente es cero
    	jg .loop             ; Si no es cero, continúa el bucle
    
    	; Invierte la cadena
    	mov rdx, rdi
    	lea rcx, [rdi + rsi - 1]
    	jmp .reversetest
    
.reverseloop:
   	mov al, [rdx]
    	mov ah, [rcx]
    	mov [rcx], al
    	mov [rdx], ah
    	inc rdx
    	dec rcx
    
.reversetest:
    	cmp rdx, rcx
    	jl .reverseloop
    
    	mov rax, rsi  ; Devuelve la longitud de la cadena
    	ret

;----------------- END ITOA -------------------

;----------------- PRINTS ---------------------
_printText1:			;texto inicial
	mov rax, 1
	mov rdi, 1
	mov rsi, text1
	mov rdx, 18
	syscall 
	ret

_getText:			;obtiene el texto
	mov rax, 0
	mov rdi, 0
	mov rsi, num1
	mov rdx, 101
	syscall 
	call _inputCheck	;se asegura de que se ingrese unicamente numeros
	call _lengthCheck
	call _AtoiStart
	ret

_printNeg:
	mov rax, 1
	mov rdi, 1
	mov rsi, negSign
	mov rdx, 1 
	syscall
	jmp _continueLoop

_printSum:
	mov rax, 1
	mov rdi, 1
	mov rsi, sumPrint
	mov rdx, 16 ; 
	syscall
	ret

_printRest:
	mov rax, 1
	mov rdi, 1
	mov rsi, restPrint
	mov rdx, 17 ; 
	syscall
	ret

_printItoa:
   	; Escribe en stdout
   	mov rdi, 1
    	mov rsi, buffer
    	mov rdx, r8
    	mov rax, 1
    	syscall
    	
	ret

;---------------- END PRINTS --------------------
;-------------------- Finalizacion de codigo 

_finishError:			;finaliza codigo
	mov rax, 1
	mov rdi, 1
	mov rsi, errorCode
	mov rdx, 32
	syscall 

_finishCode:			;finaliza codigo
	mov rax, 60
	mov rdi, 0
	syscall


