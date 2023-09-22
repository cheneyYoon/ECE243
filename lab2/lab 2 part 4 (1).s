.global _start


_start:		MOV R4, #TEST_NUM
			MOV R5, #0
			MOV R6, #0

MAIN_LOOP:  LDR R1, [R4], #4
			CMP R1, #0
			BEQ DISPLAY	
			
			BL ONES
			CMP R5, R0
			MOVLT R5, R0
			
			BL ZEROS
			CMP R6, R0
			MOVLT R6, R0
			  
			MOV R3, #VARIABLES
			LDR R3, [R3]
			
			EOR R1, R1, R3
			MOV R3, #0   //Clear R3
			
			BL ONES
			CMP R8, R0
			MOVLT R8, R0
			
			BL ZEROS
			CMP R9, R0
			MOVLT R9, R0
			
			CMP R8, R9
			MOVGE R7, R8
			MOVLT R7, R9
			
			MOV R12, #RESULT_NUMS
			STR R5, [R12]
			STR R6, [R12, #4]
			STR R7, [R12, #8]
			
			MOV R8, #0
			MOV R9, #0  //Clear R8, R9
			MOV R0, #0
					
			B MAIN_LOOP
			
//DISP:		BL DISPLAY

END: 		B END

TEST_NUM:   
			.word 0b01010101111
			.word 0x0
			
VARIABLES:
			.word 0xAAAAAAAA
			.word 0xFFFFFFFF
			
RESULT_NUMS:
			.space 4 //R5
			.space 4 //R6
			.space 4 //R7

ONES:		MOV R0, #0
			PUSH {R1, R2}

LOOP:		CMP R1, #0 // loop until the data contains no more 1’s
			BEQ END_ONES
			LSR R2, R1, #1 // perform SHIFT, followed by AND
			AND R1, R1, R2
			ADD R0, #1
			B LOOP
			
END_ONES:	POP {R1, R2}
			MOV PC, LR


ZEROS:		MOV R0, #0
			PUSH {R1, R2, R3}
			
			MOV R3, #VARIABLES
			LDR R3, [R3, #4]
			
			EOR R1, R1, R3

LOOPZ:		CMP R1, #0 // loop until the data contains no more 1’s
			BEQ END_ZEROS	
			
			LSR R2, R1, #1 // perform SHIFT, followed by AND
			AND R1, R1, R2
			ADD R0, #1
			B LOOPZ
			
END_ZEROS:	POP {R1, R2, R3}
			MOV PC, LR
			
		
/* Program that converts a binary number to decimal */

SEG7_CODE:  MOV R1, #BIT_CODES
			ADD R1, R0 // index into the BIT_CODES "array"
			LDRB R0, [R1] // load the bit pattern (to be returned)
			MOV PC, LR  
 

DIVIDE: MOV R2, #0
CONT:   CMP R0, #10
		BLT DIV_END
		SUB R0, #10
		ADD R2, #1
		B CONT
DIV_END: 
		MOV R1, R2 // quotient in R1 (remainder in R0)
		MOV PC, LR    
		
		
DISPLAY: 	 
			LDR R8, =0xFF200020 // base address of HEX3-HEX0
			
			MOV R0, R5 // display R5 on HEX1-0
			BL DIVIDE // ones digit will be in R0; tens
			// digit in R1
			MOV R9, R1 // save the tens digit
			BL SEG7_CODE
			MOV R4, R0 // save bit code
			MOV R0, R9 // retrieve the tens digit, get bit
			// code
			BL SEG7_CODE
			LSL R0, #8
			ORR R4, R0
			
			MOV R0, R6 // display R5 on HEX1-0
			BL DIVIDE // ones digit will be in R0; tens
			// digit in R1
			MOV R9, R1 // save the tens digit
			BL SEG7_CODE
			MOV R10, R0 // save bit code
			MOV R0, R9 // retrieve the tens digit, get bit
			// code
			BL SEG7_CODE
			LSL R0, #8
			ORR R10, R0
			
			LSL R10, #16
			ORR R4, R10
			
			STR R4, [R8]
			
			LDR R8, =0xFF200030
			
			MOV R0, R7 // display R5 on HEX1-0
			BL DIVIDE // ones digit will be in R0; tens
			// digit in R1
			MOV R9, R1 // save the tens digit
			BL SEG7_CODE
			MOV R4, R0 // save bit code
			MOV R0, R9 // retrieve the tens digit, get bit
			// code
			BL SEG7_CODE
			LSL R0, #8
			ORR R4, R0
			
			STR R4, [R8]
			
			B END
			
			 
		
		

BIT_CODES: .byte 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
		   .byte 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111

 
			