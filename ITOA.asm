global _start

section .data
sys_write  equ 1
sys_exit   equ 60
stdout     equ 1
newline    equ 10
n          dq 80  ; Número a convertir
base       dq 10  ; Base de n
digitos db '0123456789ABCDEF'     ; Caracteres que representan los dígitos en base 16

section .bss
buffer     resb 100   ; Buffer para almacenar la cadena de caracteres convertida

section .text
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

_start:
    ; Llama a ITOA para convertir n a cadena
    mov rdi, buffer
    mov rsi, [n]
    mov rbx, [base]; Establece la base (Se puede cambiar)
    call itoa
    mov r8, rax  ; Almacena la longitud de la cadena
    
    ; Añade un salto de línea
    mov byte [buffer + r8], newline
    inc r8
    
    ; Termina la cadena con null
    mov byte [buffer + r8], 0
    
    ; Escribe en stdout
    mov rdi, stdout
    mov rsi, buffer
    mov rdx, r8
    mov rax, sys_write
    syscall
    
    ; Salida
    mov rdi, 0
    mov rax, sys_exit
    syscall
