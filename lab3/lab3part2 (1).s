.text                  
.global _start                  

_start:                             
		  MOV	  R4, #0			// R4 bit pattern
		  MOV	  R5, #0			// R5 value
		  
DISPLAY:  
          LDR     R8, =0xFF200020   // address of HEX1-0
		  MOV	  R0, R5
		  BL	  DIVIDE			// ones digit will be in R0; tens
                                    // digit in R1
		  MOV     R7, R1          // save the tens digit
          BL      SEG7_CODE       
          MOV     R4, R0          // save bit code
          MOV     R0, R7          // retrieve the tens digit, get bit
                                    // code
          BL      SEG7_CODE       
          LSL     R0, #8
          ORR     R4, R0
		  STR	  R4, [R8]			//Display the number
		  
		  
		  ADD	  R5, #1			//increment number by 1
		  CMP	  R5, #100			//starts at 0 again after 99
		  MOVEQ	  R5, #0
		  
		  LDR	  R3, [R8, #0x3c]
		  CMP	  R3, #0
		  BNE	  PAUSE				//pause if button pushed
		  
DO_DELAY: LDR 	  R9, =200000000 // for CPUlator use =500000
SUB_LOOP: SUBS 	  R9, R9, #1
		  BNE SUB_LOOP
		  
		  B		  DISPLAY			//display number continuously



PAUSE:	  MOV	  R10, #0b1111		//clear edgecapture bits
		  STR	  R10, [R8, #0x3c]
WAIT:	  LDR	  R3, [R8, #0x3c]	//loop until a button is pushed again
		  CMP	  R3, #0
		  BEQ	  WAIT
		  STR	  R10, [R8, #0x3c]	//clear edgecapture bits
		  B		  DISPLAY			//start increasing counter again





SEG7_CODE:  MOV R1, #BIT_CODES
			ADD R1, R0 // index into the BIT_CODES "array"
			LDRB R0, [R1] // load the bit pattern (to be returned)
			MOV PC, LR          

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .space   2    
 
DIVIDE: MOV R2, #0
CONT:   CMP R0, #10
		BLT DIV_END
		SUB R0, #10
		ADD R2, #1
		B CONT
DIV_END: 
		MOV R1, R2 // quotient in R1 (remainder in R0)
		MOV PC, LR  
