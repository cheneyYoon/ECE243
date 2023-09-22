/* Program that converts a binary number to decimal */
.text // executable code follows
.global _start
_start:
		MOV R4, #N
		MOV R5, #Digits // R5 points to the decimal digits storage location
	
		LDR R4, [R4] // R4 holds N
		MOV R0, R4 // parameter for DIVIDE goes in R0
		
		//example R4 = 9876
		
		MOV R3, #1000 //DIVISOR
		
		BL DIVIDE // R0÷R3  R1 Gets 1st Digit of 4 digit num, R0 gets remainder
		
		//  R1 = 9   R0 = 876 
		
		STRB R1, [R5, #3] // [09][][][] 
		
		MOV R3, #100     // Set divisor to 100
		
		BL DIVIDE // R0÷R3   R1 = 8, R0 = 76
		
		STRB R1, [R5, #2] // [09][08][][]
		
		MOV R3, #10      // Divisor = 10
		
		BL DIVIDE  	 // R0÷R3   R1 = 7,  R2 = 6
		
		STRB R1, [R5, #1] // [09][08][07][]
		
		STRB R0, [R5] // [09][08][07][06]
		
END:	B END

/* Subroutine to perform the integer division R0 / 10.
* Returns: quotient in R1, and remainder in R0 */

DIVIDE: MOV R2, #0
CONT:   CMP R0, R3
		BLT DIV_END
		SUB R0, R3
		ADD R2, #1
		B CONT
DIV_END: 
		MOV R1, R2 // quotient in R1 (remainder in R0)
		MOV PC, LR
N: 		.word 9876 // the decimal number to be converted
Digits: .space 4 // storage space for the decimal digits
.end