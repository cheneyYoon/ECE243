              
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
		
		BL CONFIG_GIC // configure generic interrupt controller
		// Configure the KEY pushbutton port to generate interrupts
		LDR R0, =0xFF200050
		MOV R1, #0xF
		STR R1, [R0, #0x8]		
		
		// enable IRQ interrupts in the processor
		MOV R0, #0b01010011
		MSR CPSR, R0 
		
IDLE:
		B IDLE // main program simply idles
/********************************************************************************/
IRQ_HANDLER: 
			PUSH {R0-R7, LR}
			/* Read the ICCIAR in the CPU interface */
			LDR R4, =0xFFFEC100
			LDR R5, [R4, #0x0C] // read the interrupt ID
			
CHECK_KEYS: CMP R5, #73

UNEXPECTED: BNE UNEXPECTED // if not recognized, stop here
			BL KEY_ISR
EXIT_IRQ:
			/* Write to the End of Interrupt Register (ICCEOIR) */
			STR R5, [R4, #0x10]
			POP {R0-R7, LR}
			SUBS PC, LR, #4
			
	
	
             .global  KEY_ISR
KEY_ISR:        
			 PUSH	 {R0-R7,LR}
             LDR      R0, =0xFF200050    // pushbutton KEY port base address
             LDR      R2, [R0, #0xC]       
			 
			 CMP  R2, #0b0001
			 BEQ  KEY_0
			 CMP  R2, #0b0010
			 BEQ  KEY_1
			 CMP  R2, #0b0100
			 BEQ  KEY_2
			 CMP  R2, #0b1000
			 BEQ  KEY_3  
			  
	
KEY_0:		 
			LDR R2, =NUM1
			LDR R1, [R2]
			LDR R4, =0xFFFFFFFF
			EOR R1, R1, R4
			STR R1, [R2]

			B DONE			 
KEY_1:		 	
			LDR R2, =NUM2
			LDR R1, [R2]
			LDR R4, =0xFFFFFFFF
			EOR R1, R1, R4
			STR R1, [R2]
			B DONE
		
KEY_2:		 
			LDR R2, =NUM3
			LDR R1, [R2]
			LDR R4, =0xFFFFFFFF
			EOR R1, R1, R4
			STR R1, [R2]
			B DONE
KEY_3:		    
			LDR R2, =NUM4
			LDR R1, [R2]
			LDR R4, =0xFFFFFFFF
			EOR R1, R1, R4
			STR R1, [R2]
			B DONE
		 
DONE:	
	
			LDR 	  R5, =0xFF200020  //HEX
			//LDR 	  R5, [R5] 
			LDR R1, =NUM1
			LDR R1, [R1]
			CMP R1, #0		

			MOVEQ R0, #0b00111111   
			MOVNE R0, #0b00000000	 


			LDR R1, =NUM2
			LDR R1, [R1]
			CMP R1, #0		

			MOVEQ R2, #0b00000110   
			MOVNE R2, #0b00000000

			LSL R2, #8			
			ORR R2, R0
			
			
			LDR R1, =NUM3
			LDR R1, [R1]
			CMP R1, #0		

			MOVEQ R3, #0b01011011   
			MOVNE R3, #0b00000000

			LSL R3, #16		
			ORR R3, R2
			
			LDR R1, =NUM4
			LDR R1, [R1]
			CMP R1, #0		

			MOVEQ R4, #0b01001111   
			MOVNE R4, #0b00000000

			LSL R4, #24	
			ORR R4, R3
			
			

			STR	R4, [R5]	
	
				
    
			LDR      R0, =0xFF200050    // pushbutton KEY port base address
			LDR      R2, [R0, #0xC]        // read Edgecapture
			STR      R2, [R0, #0xC]        // clear the interrupt
			POP	 	 {R0-R7,LR}
			MOV      PC, LR                   // return
			 
			 
		
		
/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */

SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .space   2   
		
	   
NUM1:  .word 0xFFFFFFFF
NUM2:  .word 0xFFFFFFFF
NUM3:  .word 0xFFFFFFFF
NUM4:  .word 0xFFFFFFFF
	   
/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0 */
DIVIDE:     MOV    R2, #0
CONT:       CMP    R0, #10
            BLT    DIV_END
            SUB    R0, #10
            ADD    R2, #1
            B      CONT
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR
			
			

/*
 * Configure the Generic Interrupt Controller (GIC)
*/
/* Interrupt controller (GIC) CPU interface(s) */
            .equ   MPCORE_GIC_CPUIF,     0xFFFEC100   /* PERIPH_BASE + 0x100 */
            .equ   ICCICR,               0x00         /* CPU interface control register */
            .equ   ICCPMR,               0x04         /* interrupt priority mask register */
            .equ   ICCIAR,               0x0C         /* interrupt acknowledge register */
            .equ   ICCEOIR,              0x10         /* end of interrupt register */
            /* Interrupt controller (GIC) distributor interface(s) */
            .equ   MPCORE_GIC_DIST,      0xFFFED000   /* PERIPH_BASE + 0x1000 */
            .equ   ICDDCR,               0x00         /* distributor control register */
            .equ   ICDISER,              0x100        /* interrupt set-enable registers */
            .equ   ICDICER,              0x180        /* interrupt clear-enable registers */
            .equ   ICDIPTR,              0x800        /* interrupt processor targets registers */
            .equ   ICDICFR,              0xC00        /* interrupt configuration registers */

            .global   CONFIG_GIC
CONFIG_GIC:
            PUSH      {LR}
            /* To configure the FPGA KEYS interrupt (ID 73):
             *    1. set the target to cpu0 in the ICDIPTRn register
             *    2. enable the interrupt in the ICDISERn register */
            /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
            MOV       R0, #73                    // KEY port (interrupt ID = 73)
            MOV       R1, #1                    // this field is a bit-mask; bit 0 targets cpu0
            BL        CONFIG_INTERRUPT

            /* configure the GIC CPU interface */
            LDR       R0, =MPCORE_GIC_CPUIF    // base address of CPU interface
            /* Set Interrupt Priority Mask Register (ICCPMR) */
            LDR       R1, =0xFFFF             // enable interrupts of all priorities levels
            STR       R1, [R0, #ICCPMR]
            /* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
             * allows interrupts to be forwarded to the CPU(s) */
            MOV       R1, #1
            STR       R1, [R0]
    
            /* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
             * allows the distributor to forward interrupts to the CPU interface(s) */
            LDR       R0, =MPCORE_GIC_DIST
            STR       R1, [R0]    
 
            POP       {PC}

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
            LSR      R4, R0, #3                            // calculate reg_offset
            BIC      R4, R4, #3                            // R4 = reg_offset
            LDR      R2, =MPCORE_GIC_DIST+ICDISER
            ADD      R4, R2, R4                            // R4 = address of ICDISER
    
            AND      R2, R0, #0x1F                       // N mod 32
            MOV      R5, #1                                // enable
            LSL      R2, R5, R2                            // R2 = value

            /* now that we have the register address (R4) and value (R2), we need to set the
             * correct bit in the GIC register */
            LDR      R3, [R4]                                // read current register value
            ORR      R3, R3, R2                            // set the enable bit
            STR      R3, [R4]                                // store the new register value

            /* Configure Interrupt Processor Targets Register (ICDIPTRn)
             * reg_offset = integer_div(N / 4) * 4
             * index = N mod 4 */
            BIC      R4, R0, #3                            // R4 = reg_offset
            LDR      R2, =MPCORE_GIC_DIST+ICDIPTR
            ADD      R4, R2, R4                            // R4 = word address of ICDIPTR
            AND      R2, R0, #0x3                        // N mod 4
            ADD      R4, R2, R4                            // R4 = byte address in ICDIPTR

            /* now that we have the register address (R4) and value (R2), write to (only)
             * the appropriate byte */
            STRB     R1, [R4]
    
            POP      {R4-R5, PC}

            .end
	
		

