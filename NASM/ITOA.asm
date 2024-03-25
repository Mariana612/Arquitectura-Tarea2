; Creditos a Russ Ross por la base de la implementacion de ITOA. Link al video: https://www.youtube.com/watch?v=D7gabV6tWCE

global _start

section .data
	text1 db "Ingrese un numero", 0xA ;len 18
	n          dq 80  ; Número a convertir
	digitos db '0123456789ABCDEF'     ; Caracteres que representan los dígitos en base 16
	errorCode db "Error: Ingrese un numero valido", 0xA;

section .bss
	num1 resb 101
	num2 resb 101
	num3 resb 101

	buffer     resb 100   ; Buffer para almacenar la cadena de caracteres convertida
	base resq 8;

section .text

_start:
	call _printText1	;Hace print inicial
	call _getText		;Consigue el texto del usuario


	mov [num2], rax		;carga el primer numero en num2
	xor rax, rax		;reinicia rax
	mov byte[num1], 0	;reinicia num1
	
	call _printText1	;Hace print inicial
	call _getText		;Consigue el texto del usuario

		
	mov [num3], rax		;carga el primer numero en num3

	;--------------------------------------------------------CODIGO NUEVO

    	mov qword [base], 10
    	; Llama a ITOA para convertir n a cadena
    	mov rdi, buffer
    	mov rsi, [num2]
    	mov rbx, [base]; Establece la base (Se puede cambiar)
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
    	
	call _finishCode

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
