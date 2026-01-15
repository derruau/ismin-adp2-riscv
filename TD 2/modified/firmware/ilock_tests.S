.section .start;
.globl start;



start:
	//test n°1 pas de dépendances
	addi x1,x0,1
	addi x2,x0,2
	addi x3,x0,3
	addi x4,x0,4
	addi x5,x0,5
	nop
	nop
	nop
	nop

	
	//tests de dépendances de donnée entre différents étages

	// test n°2
	//rd=x2 rs2=x2
	//le mov x1,x2 doit être effectif => x1=x2=3
	// initialisation des registres utilisés pour le test
	addi x1,x0,2 
	addi x2,x0,3
	nop
	nop
	nop

	add x2,x0,x2
	add x1,x0,x2
	nop
	nop
	nop
	
	add x2,x0,x2
	nop
	add x1,x0,x2
	nop
	nop

	add x2,x0,x2
	nop
	nop
	add x1,x0,x2
	nop
	
  	add x2,x0,x2
	nop
	nop
	nop
	add x1,x0,x2

	// test n°3
        //rd=x2 rs1=x2
	//le mov x1,x2 doit être effectif => x1=x2=5
	// initialisation des registres utilisés pour le test
	addi x1,x0,4 
	addi x2,x0,5
	nop
	nop
	nop

	add x2,x0,x2
	add x1,x2,x0
	nop
	nop
	nop
	
	add x2,x0,x2
	nop
	add x1,x2,x0
	nop
	nop

	add x2,x0,x2
	nop
	nop
	add x1,x2,x0
	nop
	
  	add x2,x0,x2
	nop
	nop
	nop
	add x1,x2,x0


	//test n°4
	// Verifiez que l'interlock n'est pas activé 
	// x1 = base address of Ram=0x10800
	lui x1,0x11
	nop
	nop
	nop
	nop
	addi x1,x1,-2048
	nop
	nop
	nop
	nop

	//init de x2
	addi x2,x0,0x6
	nop
	nop
	nop
	nop
	
	sb x2,2(x1)	// Format de l'instruction: sb rs2,offset(rs1) 
				// => Stocke le contenu de x2 (0x6) dans le 2eme byte de DRAM 
	add x3,x2,x2
	nop
	nop
	nop

	sb x2,2(x1)
	nop
	add x3,x2,x2
	nop
	nop

	sb x2,2(x1)
	nop
	nop
	add x3,x2,x2
	nop

	sb x2,2(x1)
	nop
	nop
	nop
	add x3,x2,x2

	addi x3,x0,0x7
	nop
	nop
	nop
	nop
	
	sb x3,3(x1)
	add x4,x3,x3
	nop
	nop
	nop

	sb x3,3(x1)
	nop
	add x4,x3,x3
	nop
	nop

	sb x3,3(x1)
	nop
	nop
	add x4,x3,x3
	nop

	sb x3,3(x1)
	nop
	nop
	nop
	add x4,x3,x3


	
	//test n° 5 de dépendance de contrôle sur les sauts
	//l'addittion qui suit le saut n'est pas effuctée et le saut est effectif
	jal lab1
	addi x1,x0,165
	nop
	nop
	nop


	// test n °6 de dépendance de contrôle sur les brachements
	// les deux additions qui suivent le branchement ne sont pas effectuéees et le branchement est effectif 
lab1:	//init de x2
	addi x2,x0,0x8
	nop
	nop
	nop
	nop
	beq x0,x0, lab2
	add x2,x2,x2
	add x2,x2,x2
	nop
	nop
	nop

	
lab2:	j lab2
	nop
	nop
	nop



.end start
