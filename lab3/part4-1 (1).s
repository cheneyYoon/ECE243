          .text                  
          .global _start                  
_start: LDR R8, =0xFFFEC600 //TIMER ADDRESS
		LDR R2, =2000000
		STR R2, [R8]
		MOV R2, #0b011  //A=1, E=1   A->auto-reload, E->start timer
		STR R2,[R8, #0x8]  //Start timer
		
		MOV	  R4, #0			// R4 -> bit pattern
		MOV	  R5, #0		// R5 -> number displayed
		
		MOV   R6, #0
		
		LDR R11, =0xFF200020  //HEX ADDRESS 

DISPLAY:   //DISPLAY R5 and R6 Values	  
		  
		  MOV	  R0, R5		
		  BL	  DIVIDE			
                                   
		  MOV     R7, R1        
          BL      SEG7_CODE       
          MOV     R4, R0        
          MOV     R0, R7       
                                    
          BL      SEG7_CODE       
          LSL     R0, #8
          ORR     R4, R0
		  
		  MOV	  R0, R6		
		  BL	  DIVIDE		
                                   
		  MOV     R7, R1 
          BL      SEG7_CODE 
		  LSL     R0, #16
          ORR     R4, R0        
          MOV     R0, R7          
		  
          BL      SEG7_CODE       
          LSL     R0, #24
          ORR     R4, R0
		  STR	  R4, [R11]		
		  

DELAY:   //WAIT for timer delay to finish		
		LDR R2,[R8, #0xc] //get status
		CMP R2, #0  
		BEQ DELAY //if 0, counter still didn't finish\\
		STR R2, [R8, #0xc] //clear 
		B INCREMENT

PAUSE:	  MOV	  R10, #0b1111	
		  STR	  R10, [R11, #0x3c]
WAIT:	  LDR	  R3, [R11, #0x3c]	 
		  CMP	  R3, #0
		  BEQ	  WAIT
		  STR	  R10, [R11, #0x3c]	//clear 
		  B		  DISPLAY			 


INCREMENT: //Increment R5 Value

		  ADD	  R5, #1			//increment number by 1
		  CMP	  R5, #60			//restart
		  MOVEQ	  R5, #0
		  ADDEQ   R6, #1
		  
		  LDR	  R3, [R11, #0x3c]
		  CMP	  R3, #0
		  BNE	  PAUSE				//pause if button pushed
		  B DISPLAY
		  

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

