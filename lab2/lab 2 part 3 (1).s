.global _start


_start:		MOV R4, #TEST_NUM
			MOV R5, #0
			MOV R6, #0

MAIN_LOOP:  LDR R1, [R4], #4
			CMP R1, #0
			BEQ END
			
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
			MOVGT R7, R8
			MOVLT R7, R9
			
			MOV R8, #0
			MOV R9, #0  //Clear R8, R9
			
					
			B MAIN_LOOP

END: 		B END

TEST_NUM:   
			.word 0xABC 
			.word 0x0
			
VARIABLES:
			.word 0xAAAAAAAA
			.word 0xFFFFFFFF

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