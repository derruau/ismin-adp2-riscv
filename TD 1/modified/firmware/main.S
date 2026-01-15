.section .start;
.globl start;

start:
	li  t0, 0x3
	li  t1, 0x8
	add t2, t0, t1 # Dépendance de données
    li  t3, 0x10
    li  t4, 0x11
    sub t5, t3, t4 # Dépendance de données
lab1 :  j  lab1
	nop

.end start
