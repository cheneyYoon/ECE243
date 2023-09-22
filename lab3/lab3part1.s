.global _start


_start:		MOV R4, #TEST_NUM
			MOV R5, #0
			MOV R6, #0
			MOV R3, #ADDRESS
			LDR R3, [R3]			
			MOV R7, #NUMBER

MAIN_LOOP: 
			LDR R5, [R7]			
			MOV R6, #0
			
			B DISPLAY
			
CON:		LDR R0, [R3, #0x30]	 
			CMP	R0, #0
			BEQ NO_KEY
			
WAIT:   	LDR R0, [R3, #0x30]	 
			CMP	R0, #0
			BNE PRESSED_FLAG 
		
NO_KEY:	
			
			CMP R6, #1
			MOVEQ R5, #0
			
			CMP R6, #2
			ADDEQ R5, #1 
			
			CMP R6, #3
			SUBEQ R5, #1 
			
			CMP R6, #4
			MOVEQ R5, #10

			
			STR R5, [R7]
			B MAIN_LOOP
		 
//NO_KEY:  B DISPLAY
			
//DISP:		BL DISPLAY

END: 		B END


CHECK_NINE:
			CMP R5, #9
			MOVEQ R6, #5
			B P_CONT1
			
CHECK_ZERO:
			CMP R5, #0
			MOVEQ R6, #5
			B P_CONT2

PRESSED_FLAG:

			CMP	R0, #0b1
			MOVEQ R6, #1
			
			CMP R0, #0b10
			MOVEQ R6, #2
			
			BEQ CHECK_NINE
P_CONT1:		
			CMP R0, #0b100
			MOVEQ R6, #3					
			
			BEQ CHECK_ZERO
P_CONT2: 
			
			CMP R0, #0b1000
			MOVEQ R6, #4	
			
			CMP R5, #10 
			MOVEQ R6, #1
			
			B WAIT


ADDRESS:   .word 0xFF200020

TEST_NUM:   
			.word 0x1452BCDE
			.word 0x0
			
VARIABLES:
			.word 0xAAAAAAAA
			.word 0xFFFFFFFF
			
NUMBER:
			.word 0x00000000

 
			
		
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
			
			CMP R6, #4
			MOV R0, R5 // display R5 on HEX1-0
			BLEQ DIVIDE // ones digit will be in R0; tens
			// digit in R1
			MOV R9, R1 // save the tens digit
			BL SEG7_CODE
			MOV R4, R0 // save bit code
						
			STR R4, [R8]					 
			
			B WAIT
	

BIT_CODES: .byte 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
		   .byte 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111,
		   .byte 0b00000000