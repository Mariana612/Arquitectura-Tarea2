; Creditos a Russ Ross por la base de la implementacion de ITOA. Link al video: https://www.youtube.com/watch?v=D7gabV6tWCE

global _start

section .data
	text1 db "Ingrese un numero", 0xA ;len 18
	prompt db "Que desea realizar? 1. suma 2. resta 3. division 4. multiplicacion",0xA ;len 67
	digitos db '0123456789ABCDEF'     ; Caracteres que representan los dígitos en base 16
	errorCode db "Error: Ingrese un numero valido", 0xA;
	processNum dq 0
	counterSumNum dq 2
	flag1 db 0
	negSign db "-" ;len 2
	sumPrint db "Print de sumas:", 0xA ;len 15
	restPrint db "Print de restas:", 0xA ;len 15
	multPrint db "Print de multiplicaciones:", 0xA; len 26
	texto db 25,0, 26 dup('$')
	longitud db 0,0,'$'
	option: times 34 db 0


section .bss
	num1 resq 13
	num2 resq 13
	num3 resq 13
	
	buffer     resb 101   ; Buffer para almacenar la cadena de caracteres convertida
	base resq 8;

section .text

_start:
	call _printOptions
	

	call _printText1	;Hace print inicial
	call _getText		;Consigue el texto del usuario

	mov qword [num2], rax		;carga el primer numero en num2
	xor rax, rax		;reinicia rax
	mov byte[num1], 0	;reinicia num1
	
	call _printText1	;Hace print inicial
	call _getText		;Consigue el texto del usuario

		
	mov qword [num3], rax		;carga el primer numero en num3
	movzx eax, byte[option]	;Comapre imputs

	cmp eax, '1'
	je _opSuma

	cmp eax, '2'
	je _opResta

	;cmp eax, '3'
	;je _opDiv

	;cmp eax, '4'
	;je _opMult
	

;------------------ OPCIONES ------------------------
_opSuma:
	call _printSum

	mov rax, [num2]
    	add rax, [num3]   ; Hace la suma
	mov [processNum], rax
	call _processLoop
	call _finishCode	
	;ret

_opResta:

	call _printRest
	mov qword [counterSumNum],2
	mov rax, [num2]
    	sub rax, [num3]
	call _testNeg
	mov [processNum], rax
	call _processLoop
	call _finishCode
	;ret

;_opDiv:



_opMult:
	call _printMult
	mov rax, [num2]
	mul rax, [num3]
	mov [processNum], rax
	call _processLoop
	call _finishCode
	;ret

;-----------------FIN OPCIONES------------------------

_contarCadena:
	MOV AH, 0AH		 ;Lectura de la cadena
	LEA DX, texto
	int 21h
	mov ax,0
	mov al, texto[1]
	aam			;Divide en decenas y unidades
	ADD AX,3030H 		;Conversion a ASCII
	mov longitud[0], AH     ;Decenas
	mov longitud[1], AL     ;Unidades

_testNeg:
	test rax, rax		;realiza test a ver si el numero es negativo
    	jns _exitFunction  	;si no es negativo salta a string directamente
	neg rax			;vuelve positivo el numero
	mov byte[flag1], 1
	ret
	
_processLoop:
	cmp qword [counterSumNum],17
	je _exitFunction
	cmp byte[flag1], 1	;se asegura de que el primer numero sea o no negativo
	je _printNeg		;realiza print del simbolo negativo

_continueLoop:
	call _startItoa
	inc qword [counterSumNum]
	jmp _processLoop
	
_printNeg:
	mov rax, 1
	mov rdi, 1
	mov rsi, negSign
	mov rdx, 1 ; 
	syscall
	jmp _continueLoop

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
    
   	; Escribe en stdout
   	mov rdi, 1
    	mov rsi, buffer
    	mov rdx, r8
    	mov rax, 1
    	syscall
    	
	ret

;------------------OBTENER TEXTO------------------------
_printOptions:
	mov edx, 67
	mov ecx, prompt
	mov ebx, 1 
	mov eax, 4
	int 0x80

_getOptions:
	;lee el imput del user
	mov edx, 34
	mov ecx,option
	mov ebx, 0 ; 0 por que es stdin
	mov eax, 3; System read
	int 0x80
	ret

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
	call _AtoiStart
;---------------FIN OBTENER TEXTO------------------------

;------------------ATOI------------------------
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

;------------------CHEQUEO DE ERRORES------------------------
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

;--------------------------------------------------------CODIGO NUEVO
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

;-------------------- PRINTS --------------------

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

_printMult:
	mov rax, 1
	mov rdi, 1
	mov rsi, multPrint
	mov rdx, 26;
	syscall
	ret

;-------------------- Finalizacion de codigo --------------------

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

