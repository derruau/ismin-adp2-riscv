.section .start;
.globl start;

start:
	addi x5,x0,15
	add  x6,x0,x0
	add  x7,x0,x0
	add  x8,x0,x0
lab1:	
	j lab2          // Dépendance de contrôle de type J;
	nop             // On a besoin de 1 NOP
	addi x7,x7,1    //
	
lab2:	
	addi x6,x6,1    // Dépendance de données
	bge x5,x6,lab1  //
	nop             // Dépendance de contrôle avec instruction type B: 
	nop             // On a besoin de 2 NOP.
	addi x8,x8,1    // Dépendance de données
	addi x8,x8,1    //
lab3 :  
	j lab3			// Condition de stop du testbench: 
	nop				// avoir 5 fois j lab3 suivi d'un nop

.end start
