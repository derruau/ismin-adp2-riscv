.section .start;
.globl start;

start:
	add  x1, x2, x3 
    beq  x0, x0, lab1
    sub  x6, x1, x3 
    addi  x3, x4, 10 
    add  x3, x4, x7
lab1: 
    beq  x0, x0, lab2
    sub  x6, x1, x3 
    addi  x3, x4, 10
    add  x3, x4, x7
lab2: 
    beq  x0, x0, lab3
    sub  x6, x1, x3 
    addi  x3, x4, 10
    add  x3, x4, x7
lab3: 
    beq  x0, x0, lab4
    sub  x6, x1, x3 
    addi  x3, x4, 10 
    add  x3, x4, x7

lab4:
    j lab4
    nop
.end start
