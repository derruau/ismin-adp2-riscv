// Programme de multiplication entre x1 et x2
// Le résultat de la multiplication est stocké dans x7
// Exemple:
// x1 = 0xA5A5 et x2 = 0x7 => x7 =0x48783 


// Ce programme est équivalent à ce programme en C:
// int main() {
//     unsigned int x1, x2, x3, x4, x5, x6, x7;
//
//     x5 = 0;
//     x4 = 0;
//    
//     x6 = 15;
//     x1 = 0xA5A5
//     x2 = 7;
//
//     do {
//         x3 = x1 & 1;
//
//         if (x3 != 0) {
//             x4 += x2;
//         }
//
//         x1 = x1 >> 1;
//         x2 = x2 << 1;
//
//         x5++;
//        
//     } while (x6 >= x5);
//
//     x7 = x4;
//
//     return 0;
// }

.section .start
.globl start
.globl lab
.globl shifter

start:
	// Dans x1: 0xA5A5
	// Dans x2; 0x7
	// Dans x6: x0F
	addi x6,x0,15
	lui  x1,0xA
	addi x1,x1,0x5A5
	addi x2,x0,7
lab:
	// Si x3 % 2 == 0, goto lab1
	// Sinon, x4 += x2
	andi x3,x1,1
	beqz x3,lab1
	add  x4,x4,x2
lab1:
	// Appelle la fonction shifter
	// x5 += 1
	// Si x6 >= x5, aller à lab
	// Sinon x7 = x4
	jal  x8,shifter
	addi x5,x5,1
	bge  x6,x5,lab
	add  x7,x0,x4
lab3:
	j    lab3
	nop
	nop

.section .way2
shifter :
	// Divise x1 par 2
	// Divise x2 par 2
	// Retourne après le jal  x8,shifter
	srai x1,x1,1
	slli x2,x2,1
	jalr x0,x8
	nop // La gestion de JALR n'est pas implémenté
	nop 