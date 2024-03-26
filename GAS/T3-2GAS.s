.section .data
sys_write = 1
sys_exit = 60
stdout = 1
newline: .byte 10
n: .quad 12345   # Número a convertir
base: .quad 16
digitos: .ascii "0123456789ABCDEF"     # Caracteres que representan los dígitos en base 16

.section .bss
buffer: .skip 100   # Buffer para almacenar la cadena de caracteres convertida

.section .text
# Definición de la función ITOA
itoa:
    movq %rsi, %rax             # Mueve el número a convertir (en rsi) a rax
    xorq %rcx, %rcx             # Inicializa rcx como 0 (contador de posición en la cadena)
    movq %rdi, %r9              # Usa r9 como el puntero al buffer
  
.loop:
    xorq %rdx, %rdx          # Limpia rdx para la división
    divq %r10                # Divide rax por rbx
    cmpq $10, %r10
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

    
.global _start

_start:

    # Llama a ITOA para convertir n a cadena
    movq $buffer, %rdi
    movq n(%rip), %rsi
    movq base(%rip), %r10  
    call itoa
    movq %rax, %r8  # Almacena la longitud de la cadena
    
    # Null-terminate the string
    movb $0, (%rdi, %r8)
    
    # Escribe en stdout
    movq $stdout, %rdi
    movq $buffer, %rsi
    movq %r8, %rdx
    movq $sys_write, %rax
    syscall
    
    # Print a newline
    movq $stdout, %rdi
    movq $newline, %rsi
    movq $1, %rdx
    movq $sys_write, %rax
    syscall
    
    # Salida
    xorq %rdi, %rdi
    movq $sys_exit, %rax
    syscall
