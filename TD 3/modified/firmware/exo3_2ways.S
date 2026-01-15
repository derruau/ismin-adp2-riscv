
	
	.section .start
	.globl start
	.globl lab
	.globl shifter



start: 	
	addi x6,x0,15
	// a=0xA5A5
	lui x1,0xA
	nop
	nop
	nop
        addi x1,x1,0x5A5
	// b=7
	addi x2,x0,7
        nop
	nop
	//  bit 0 de a
lab:	andi x3,x1,1
	nop
	nop
	nop
	// si le bit 0 de a est  zero on accumule b*2
	beqz x3,lab1
	// on acummule
	nop
	nop
	add x4,x4,x2
lab1:   // on decale a vers la droite
	//srai x1,x1,1
	// on decale b vers la gauche
	//slli x2,x2,1
	jal  x8,shifter
	nop

	addi x5,x5,1
	nop
	nop
	nop
	bge  x6,x5,lab
	nop
	nop
	//resultat final dans x7 =0x48783
        add x7,x0,x4
lab3:	j lab3
	nop
	nop

.section .way2
shifter :
	srai x1,x1,1
	slli x2,x2,1
	jalr x0,x8
	nop
	nop
	



	
	
	



