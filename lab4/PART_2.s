 /*********************************************************************************
* Initialize the exception vector table
********************************************************************************/
		.section .vectors, "ax"
		B _start // reset vector
		.word 0 // undefined instruction vector
		.word 0 // software interrrupt vector
		.word 0 // aborted prefetch vector
		.word 0 // aborted data vector
		.word 0 // unused vector
		B IRQ_HANDLER // IRQ interrupt vector
		.word 0 // FIQ interrupt vector
/*********************************************************************************
* Main program
********************************************************************************/
.text
.global _start
_start:
	/* Set up stack pointers for IRQ and SVC processor modes */
	
	MOV R0, #0b11010011  //SVC mode stack pointer
	MSR CPSR, R0
	LDR SP, =0x20000

	MOV R0, #0b11010010  //IRQ mode stack pointer
	MSR CPSR, R0
	LDR SP, =0x40000

	BL CONFIG_GIC // configure the GIC 	
	
	//Configure the TIMER to enable interrupts
	LDR	   	 R0, =0xFFFEC600 
	LDR	 	 R1, =50000000
	STR	 	 R1, [R0]
	MOV	 	 R1, #0b111
	STR	 	 R1, [R0, #0x8] 
	
	// Configure the KEY pushbutton port to generate interrupts
	LDR R0, =0xFF200050
	MOV R1, #0xF
	STR R1, [R0, #0x8]		



	// enable IRQ interrupts in the processor
	MOV R0, #0b01010011
	MSR CPSR, R0 

	
LOOP:
	LDR R5, =0xFF200000 // LEDR base address
	LDR R3, COUNT // global variable
	STR R3, [R5] // write to the LEDR lights
	B LOOP
 
 
	
             .global  IRQ_HANDLER
IRQ_HANDLER:
             PUSH     {R0-R5, LR}
     
             /* Read the ICCIAR from the CPU interface */
             LDR      R4, =0xFFFEC100
             LDR      R5, [R4, #0xC]        // read from ICCIAR
    
			 MOV R0, #0
			 MOV R1, #0
CHECK_KEYS:  CMP      R5, #73
			 MOVEQ R0, #1 
			 
CHECK_TIMER: CMP R5, #29
			 MOVEQ R1, #1
			 B YE
			 
			
UNEXPECTED:  BEQ   UNEXPECTED           // if not recognized, stop here
        
YE:			 CMP R0, #1
             BLEQ KEY_ISR
			 CMP R1, #1 
			 BLEQ TIMER_ISR
			 ORR R1, R0
			 CMP R1, #0
			 BEQ UNEXPECTED
EXIT_IRQ:
             /* Write to the End of Interrupt Register (ICCEOIR) */
             STR      R5, [R4, #0x10]        // write to ICCEOIR
        
             POP      {R0-R5, LR}
             SUBS     PC, LR, #4
    
	
	
             .global  KEY_ISR
KEY_ISR:        
             	PUSH	 {R0-R7,LR}
				LDR      R3, =0xFF200050    // pushbutton KEY port base address
				LDR      R2, [R3, #0xC]        // read Edgecapture
				CMP		 R2, #1
				BEQ		 CLEAR 
				
				LDR		 R0, =RUN
				LDR		 R1, [R0]
				EOR		 R1, #1
				STR		 R1, [R0]   //if ruun 0, store 1, if runs 1 store 0
				
CLEAR:			STR      R2, [R3, #0xC]        // clear the interrupt
				POP		 {R0-R7,LR}				

                MOV      PC, LR
				
							
				
DONE:			STR      R2, [R3, #0xC]        // clear the interrupt
				POP		 {R0-R7,LR}				

                MOV      PC, LR
				
			 
.global  TIMER_ISR

TIMER_ISR:        
            PUSH	 {R0-R7,LR}
			LDR	   	 R3, =0xFFFEC600	 
			
			LDR		 R0, =RUN
			LDR		 R0, [R0]
			
			LDR		 R1, =COUNT
			LDR		 R1, [R1]
			
			ADD		 R1, R0



			STR		 R1, [R1]	 

			STR		 R0, [R3, #0xC]  //clear F bit (status register)			
			POP		 {R0-R7,LR}
			MOV      PC, LR
	
	
	
	
	
	
/* Global variables */

.global COUNT
COUNT: .word 0x0 // used by timer


.global RUN // used by pushbutton KEYs
RUN: .word 0x1 // initial value to increment
	// COUNT
	
	
	
	
/*
* Configure the Generic Interrupt Controller (GIC)
*/
/* Interrupt controller (GIC) CPU interface(s) */
		
		
		        .equ      EDGE_TRIGGERED,    0x1
               .equ      LEVEL_SENSITIVE,   0x0
               .equ      CPU0,              0x01    // bit-mask; bit 0 represents cpu0
               .equ      ENABLE,            0x1

               .equ      KEY0,              0b0001
               .equ      KEY1,              0b0010
               .equ      KEY2,              0b0100
               .equ      KEY3,              0b1000

               .equ      IRQ_MODE,          0b10010
               .equ      SVC_MODE,          0b10011

               .equ      INT_ENABLE,        0b01000000
               .equ      INT_DISABLE,       0b11000000
			   
			   
			   

                .global  CONFIG_GIC
CONFIG_GIC:
                PUSH     {LR}
                MOV      R0, #29
                MOV      R1, #CPU0
                BL       CONFIG_INTERRUPT
                
                /* Enable the KEYs interrupts */
                MOV      R0, #73
                MOV      R1, #CPU0
                /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
                BL       CONFIG_INTERRUPT

                /* configure the GIC CPU interface */
                LDR      R0, =0xFFFEC100        // base address of CPU interface
                /* Set Interrupt Priority Mask Register (ICCPMR) */
                LDR      R1, =0xFFFF            // enable interrupts of all priorities levels
                STR      R1, [R0, #0x04]
                /* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
                 * allows interrupts to be forwarded to the CPU(s) */
                MOV      R1, #1
                STR      R1, [R0]
    
                /* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
                 * allows the distributor to forward interrupts to the CPU interface(s) */
                LDR      R0, =0xFFFED000
                STR      R1, [R0]    
    
                POP      {PC}

/* 
 * Configure registers in the GIC for an individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target
*/
CONFIG_INTERRUPT:
                PUSH     {R4-R5, LR}
    
                /* Configure Interrupt Set-Enable Registers (ICDISERn). 
                 * reg_offset = (integer_div(N / 32) * 4
                 * value = 1 << (N mod 32) */
                LSR      R4, R0, #3               // calculate reg_offset
                BIC      R4, R4, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED100
                ADD      R4, R2, R4               // R4 = address of ICDISER
    
                AND      R2, R0, #0x1F            // N mod 32
                MOV      R5, #1                   // enable
                LSL      R2, R5, R2               // R2 = value

                /* now that we have the register address (R4) and value (R2), we need to set the
                 * correct bit in the GIC register */
                LDR      R3, [R4]                 // read current register value
                ORR      R3, R3, R2               // set the enable bit
                STR      R3, [R4]                 // store the new register value

                /* Configure Interrupt Processor Targets Register (ICDIPTRn)
                  * reg_offset = integer_div(N / 4) * 4
                  * index = N mod 4 */
                BIC      R4, R0, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED800
                ADD      R4, R2, R4               // R4 = word address of ICDIPTR
                AND      R2, R0, #0x3             // N mod 4
                ADD      R4, R2, R4               // R4 = byte address in ICDIPTR

                /* now that we have the register address (R4) and value (R2), write to (only)
                 * the appropriate byte */
                STRB     R1, [R4]
    
                POP      {R4-R5, PC}
                .end   
	


