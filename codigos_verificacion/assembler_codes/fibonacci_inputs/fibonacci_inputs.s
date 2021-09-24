.text

main:
	sw      s0, (sp)                # se guarda s0 en la dirección apuntada por el stack pointer
	add     s0, x0, sp              # s0 = sp
	addi    sp, sp, -16             # se reserva espacio para 4 words (4bytes*4=16): sp -= 16
	li      x17, 5                  # syscall 5: GetInt
	ecall                           # Get int: INIT_ARG en a0
	add     a1, x0, a0	    		# a1 = a0
	sw      a1, -4(s0)              # Se guarda a1
	ebreak                          # Simplemente para ayudar a diferenciar cada input
	li      x17, 5                  # syscall 5: GetInt
	ecall                           # Get int: MAX_ARG en a0
	add     a2, x0, a0	        	# a2 = a0
	sw      a2, -8(s0)              # Se guarda a2
    # Hay espacio sin utilizar para otra variable en -12(s0).
	# Pero el stack pointer debe ser "16-byte aligned" (https://riscv.org/wp-content/uploads/2015/01/riscv-calling.pdf P3)
loop:
    add     a0, x0, a1              # a0 = a1 -> permite mostrar a1 (el argumento de entrada a la función fibonacci)
	jal     ra, fibonacci           # Se llama la función, recibe arg en a0
	lw      a1, -4(s0)              # Se recupera el arg de entrada a la función
	li      x17, 1                  # syscall 1: PrintInt
	ecall                           # Print int de la respuesta ya almacenada en a0
	addi    a1, a1, 1	            # arg++
	sw      a1, -4(s0)		        # se guarda en nuevo argumento
	ble     a1, a2, loop
done:
	li      x17, 10                 # syscall 10: Exit
	ecall

# int fibonacci(int n){ if(n <= 2) return 1; else return fibonacci(n-1) + fibonacci(n-2); }
fibonacci:      # Recibe n en a0 y retorna el resultado en el mismo registro
	# Se almacenan los registros
	sw      s0, (sp)                # se guarda s0 en la dirección apuntada por el stack pointer
	add     s0, x0, sp              # s0 = sp
	# Se necesita 1 variable local + sp + ra: 3 words en el stack
	# (recordar: el stack pointer debe ser "16-byte aligned")
	# 3 words*4 bytes/address = 12 bytes, pero el sp debe apuntar al siguiente espacio disponible: sp-16
	addi    sp, sp, -16
	sw      ra, -4(s0)	            # Se guarda: Dirección de retorno
	sw      a0, -8(s0)              # Se guarda: Argumento de entrada
	addi    a1, x0, 2               # a1 = 2
	ble     a0, a1, fib_basecase    # if(n <= 2) -> fib_basecase
	# 1era llamada recursiva: fibonacci(n-1)
	addi    a0, a0, -1              # n-1
	jal     ra, fibonacci           # a0 <- fib(n-1)
	sw      a0, -12(s0)             # -12(s0) <- a0
	# 2da llamada recursiva: fibonacci(n-2)
	lw      a0, -8(s0)              # a0 <- n
	addi    a0, a0, -2              # n-2
	jal     ra, fibonacci           # a0 <- fib(n-2)
	# return fibonacci(n-1) + fibonacci(n-2);
	lw      a1, -12(s0)             # a1 <- fib(n-1)
	add     a0, a0, a1              # a0 <- fibonacci(n-1) + fibonacci(n-2)
	jal     x0, fib_ret
fib_basecase:   # if(n <= 2) return 1;
	addi    a0, x0, 1               # a0 = 1
fib_ret:        # return
	lw      ra, -4(s0)              # Se restaura la dirección de retorno
	lw      s0, (s0)                # Se recupera el stack pointer
	jalr    x0, ra, 0               # Se vuelve a la dirección donde se invocó la función