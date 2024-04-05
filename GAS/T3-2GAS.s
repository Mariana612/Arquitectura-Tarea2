.section .data

	text1: .asciz "Ingrese un numero\n"          # len 18

	digitos: .asciz "0123456789ABCDEF"          # Caracteres que representan los dígitos en base 16

	errorCode: .asciz "Error: Ingrese un numero valido\n"

	processNum: .quad 0

	counterSumNum: .quad 2

	flag1: .byte 0

	flagSpCase: .byte 0

	negSign: .asciz "-"                       # len 2

	sumPrint: .asciz "Print de sumas:\n"      # len 15

	restPrint: .asciz "Print de restas:\n"    # len 15

	overflowMsg: .asciz "ERROR: Overflow\n"

	compare_num: .quad 18446744073709551615

	compare_numTest: .quad 857565

	num1: .skip 13

	num2: .skip 13

	num3: .skip 13

	length: .byte 1

	buffer: .skip 101
	
	newline: .asciz "\n"  # Define un carácter de nueva línea
	
	SYS_WRITE = 1
	STDOUT = 1

.section .text

.global _start

_start:
    movq $text1, %rax
    call _genericprint     
    call _getText         # Consigue el texto del usuario

    movq %rax, num2       # carga el primer numero en num2
    xorq %rax, %rax       # reinicia rax
    movb $0, num1         # reinicia num1

    movq $text1, %rax
    call _genericprint  
        
    call _getText         # Consigue el texto del usuario

    movq %rax, num3       # carga el primer numero en num3

    # ------------------ INICIO ITOA ------------------------

    # SUMA
    movq $sumPrint, %rax
    call _genericprint
    movq num2(%rip), %rax
    addq num3(%rip), %rax      # Hace la suma
    jc _overflowDetected       # check de overflow
    movq %rax, processNum(%rip)    # inicio itoa suma
    call _processLoop

_continueProcess:
    # RESTA
    movq $restPrint, %rax
    call _genericprint
    movq $2, counterSumNum(%rip)   # reinicia el contador del loop
    call _specialCaseSub       # realiza chequeo de casos especiales (numeros de len 20)
    movq num2(%rip), %rax
    subq num3(%rip), %rax      # realiza resta
    call _compare          # compara si el resultado es caso especial o no
    movq %rax, processNum(%rip)    # inicio itoa resta
    call _processLoop

    # ------------------ FIN ITOA ---------------------------

    call _finishCode

# -------------- FIN MAIN ----------------------------------

_compare:
    cmpb $1, flagSpCase(%rip)
    je _testNegSpecialCase
    js _testNeg

_testNegSpecialCase:
    testq %rax, %rax      # realiza test a ver si el numero es negativo
    jns _makeNeg
    js _exitFunction

_testNeg:
    testq %rax, %rax      # realiza test a ver si el numero es negativo
    jns _exitFunction     # si no es negativo salta a string directamente

_makeNeg:
    negq %rax         # vuelve positivo el numero
    movb $1, flag1(%rip)    # indica que el numero es negativo
    ret

# ----------------- ATOI ----------------------------------

_AtoiStart:
    xorq %rbx, %rbx        # reinicia el registro
    xorq %rax, %rax        # reinicia el registro
    leaq num1(%rip), %rcx      # ingresa el num1 a rcx
    jmp _Atoi

_Atoi:
    movb (%rcx), %bl
    cmpb $0xA, %bl
    je _exitFunction       # se asegura de que sea el final del string
    sub $0x30, %rbx        # resta 30h al string para volverlo el numero
    imul $10, %rax         # multiplica el numero almacenado en rax x 10 para volverlo decimal
    add %rbx, %rax         # agrega el ultimo numero obtenido a rax (ej: 10+3=13)
    xorq %rbx, %rbx        # reinicia el registro
    inc %rcx               # incrementa x 1 el rcx (obtiene el siguiente caracter
    jmp _Atoi              # realiza loop

_exitFunction:
    ret

# ----------------- END ATOI ----------------------------------

# ----------------- CHEQUEO DE ERRORES ------------------------

_inputCheck:
    movq $num1, %rsi          # direccion del buffer de ingreso
    xorq %rcx, %rcx           # Clear counter

check_input:
    movzbq (%rsi,%rcx), %rax     # Carga el byte actual
    cmp $0xA, %rax
    je input_valid           # Final del string alcanzado
    cmp $'0', %rax
    jb _finishError          # Revisa caracteres no imprimibles
    cmp $'9', %rax
    ja _finishError          # Revisa caracteres no imprimibles
    inc %rcx                 # Mover al siguiente byte
    jmp check_input

input_valid:
    ret

# SPECIAL CASE
# handling de errores que causa que la funcion no pueda manejar numeros de 20 de largo,
# al contar el primer 1 como un numero negativo
_specialCaseSub:
    movq num2(%rip), %rax
    call _countInt           # calcula lngitud de numero2
    cmpb $20, length(%rip)     # compara que el tamano es 20
    je _num20

    movq num3(%rip), %rax
    call _countInt
    cmpb $20, length(%rip)
    jne _exitFunction        # si ambos son menores a 20, no es caso especial
    movb $1, flagSpCase(%rip)   # caso especial
    ret

_num20:
    movq num3(%rip), %rax   # calcula lngitud de numero3
    call _countInt
    cmpb $20, length(%rip)
    je _exitFunction        # si ambos son de longitud 20 entonces no es caso especial
    movb $1, flagSpCase(%rip)   # es caso especial
    ret

# CALCULA LA LONGITUD DE UN NUMERO
_countInt:
    movb $0, length(%rip)
divide_loop:
    testq %rax, %rax
    jz _exitFunction
    incb length(%rip)         # incrementa contador
    movq $10, %rbx            # Divide rax por 10
    xorq %rdx, %rdx           # reinicia rdx para la division
    divq %rbx
    jmp divide_loop           # loop

# CALCULA LA LONGITUD DE UN STRING
_lengthCheck:
    xorq %rax, %rax                      # Clear registro de rax
    leaq num1(%rip), %rdi                # carga la direccion de memoria de num1 en rdi

length_loop:
    cmpb $0, (%rdi,%rax)                 # observa si tiene terminacion nula
    je length_done
    inc %rax                             # Incrementa contador
    jmp length_loop                      # loop

length_done:
    cmp $21, %rax
    jg _finishError                      # error si es mas largo a 21
    cmp $21, %rax
    je _startNumCheck                    # continua
    ret

_startNumCheck:
    leaq num1(%rip), %rdi                 # Apunta al ultimo caracter del numero ingresado (se asume que siempre son 20 caracteres)
    leaq compare_num(%rip), %rdi           # Apunta al ultimo caracter del numero a comparar (se asume que siempre son 20 caracteres)

compare_loop:
    movzbl (%rsi), %eax                  # Carga el caracter del num1
    movzbl (%rdi), %ebx                  # Carga el caracter del compare_num

    cmp %ebx, %eax                        # Compara los caracteres
    jg _finishError                       # Si el caracter del num1 es mayor, da error
    jl end_of_strings                    # Si el caracter del num1 es mayor, finaliza

    dec %rsi                             # Se aumenta al caracter que se esta apuntando
    dec %rdi                             # Se aumenta al caracter que se esta apuntando

    cmp $-1, %rsi                        # Chequea si se finalizo de comparar
    jl end_of_strings                    # finaliza loop

    jmp compare_loop                     # loop

end_of_strings:
    ret

# -------------- END CHEQUEO DE ERRORES ------------------------

# -------------- ITOA -----------------------------------------

# LOOP PARA REALIZAR ITOA
_processLoop:

    cmpq $17, counterSumNum(%rip)  # Ajusta el límite del contador
    je _exitFunction
    
    cmpq $101, counterSumNum(%rip)    # Verificar si el contador ha excedido el tamaño del buffer
    jge _exitFunction                  # Salir si el contador excede el tamaño del buffer

    cmpb $1, flag1(%rip)            # se asegura de que el primer numero sea o no negativo
    je _printNeg                    # realiza print del simbolo negativo

_continueLoop:
    movq counterSumNum(%rip), %rbx       # Asigna la base dinámicamente
    call _startItoa
    incq counterSumNum(%rip)
    call _printNewLine
    jmp _processLoop

# ITOA INICIO
_startItoa:
    # Llama a ITOA para convertir n a cadena
    leaq buffer(%rip), %rdi
    movq processNum(%rip), %rsi
    movq counterSumNum(%rip), %r10       # Establece la base 
    call itoa
    movq %rax, %r8                        # Almacena la longitud de la cadena

    # Añade un salto de línea
    movb $'\n', buffer(%rax, %r8)

    # Termina la cadena con null
    movb $0, (%rdi, %r8)
    
    movq $buffer, %rax
    jmp _genericprint
    
# Definición de la función ITOA

itoa:

    movq %rsi, %rax             # Mueve el número a convertir (en rsi) a rax
    xorq %rcx, %rcx             # Inicializa rcx como 0 (contador de posición en la cadena)
    movq %rdi, %r9              # Usa r9 como el puntero al buffer
    movq %r10, %rbx              # Carga la base desde el registro r10

.loop:

    xorq %rdx, %rdx          # Limpia rdx para la división
    divq %rbx                # Divide rax por la base
    cmpq $10, %rbx
    jbe .lower_base_digits   # Salta si la base es menor o igual a 10

    # Maneja bases mayores que 10
    movzb %dl, %rdx
    movb digitos(%rdx), %dl   
    jmp .store_digit

.lower_base_digits:
    # Maneja bases menores o iguales a 10
    addb $'0', %dl   # Convierte el resto a un carácter ASCII
    jmp .store_digit

.store_digit:
    movb %dl, (%r9, %rcx)   
    incq %rcx               
    cmpq $0, %rax           
    jg .loop                

    # Reverse the string
    movq %rcx, %rdx         
    leaq -1(%rcx, %r9), %rsi
    movq %r9, %rdi

.reverseloop:
    movb (%rdi), %al        
    movb (%rsi), %ah
    movb %al, (%rsi)
    movb %ah, (%rdi)
    incq %rdi
    decq %rsi
    cmpq %rdi, %rsi         
    jg .reverseloop         

    movq %rcx, %rax         
    ret

# -------------- END ITOA -------------------

#---------------PRINT GENERICO---------------

_genericprint:
	movq $0, %rdx
	pushq %rax

_printLoop:
	movb (%rax), %cl
	cmpb $0, %cl
	je _endPrint
	incq %rdx
	incq %rax
	jmp _printLoop

_endPrint:
	movq $SYS_WRITE, %rax
	movq $STDOUT, %rdi
	popq %rsi
	syscall

	ret

# -------------- PRINTS ---------------------

_getText:                              # obtiene el texto
    movq $0, %rax
    movq $0, %rdi
    leaq num1(%rip), %rsi
    movq $101, %rdx
    syscall
    call _inputCheck                      # se asegura de que se ingrese unicamente numeros
    call _lengthCheck
    call _AtoiStart
    ret

_printNeg:
    movq $1, %rax
    movq $1, %rdi
    leaq negSign(%rip), %rsi
    movq $1, %rdx
    syscall
    jmp _continueLoop


    
_printNewLine:
    movq $1, %rdi
    leaq newline(%rip), %rsi  # newline es una etiqueta que contiene el carácter de nueva línea
    movq $1, %rdx
    movq $1, %rax
    syscall
    ret

_overflowDetected:                   # check de overflow
    movq $1, %rax
    movq $1, %rdi
    leaq overflowMsg(%rip), %rsi
    movq $16, %rdx
    syscall
    jmp _continueProcess

_finishError:           # finaliza codigo
    movq $errorCode, %rdi  # Carga la dirección de la cadena errorCode en el registro de destino (rdi)
    call _genericprint     # Llama a la función _genericprint

_finishCode:                        # finaliza codigo
    movq $60, %rax
    xorq %rdi, %rdi
    syscall


