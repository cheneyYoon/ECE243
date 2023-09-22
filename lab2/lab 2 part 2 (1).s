.global _start


_start:        MOV R4, #TEST_NUM
            MOV R5, #0

MAIN_LOOP:  LDR R1, [R4], #4
            CMP R1, #0
            BEQ END 
            BL ONES
            CMP R5, R0
            MOVLT R5, R0

            B MAIN_LOOP

END:         B END

TEST_NUM:
            .word 0xDEADBEEF
            .word 0x103fe00f
            .word 0x0

ONES:        MOV R0, #0

LOOP:        CMP R1, #0 // loop until the data contains no more 1’s
            BEQ END_ONES
            LSR R2, R1, #1 // perform SHIFT, followed by AND
            AND R1, R1, R2
            ADD R0, #1
            B LOOP

END_ONES:    MOV PC, LR