.global main

.text

main:
        LDR R0, =array1             @ 1 - Load the address of 1st element in array
        MOV R1, #array1size         @ 2 - Load number of items in the array
        BL MaxVal                  	@ 3 - Call the function

exit:
    @ If using the RPI, uncomment the lines with the MOV and SWI instructions
    @ If using the simulator, comment the lines with the MOV and SWI instructions
@   MOV     R7, #1          @ Place code for Exit into R7
@   SWI     0               @ Make a system call to end the program
    @ If using the RPI, comment the line with B exit
    @ If using the simulator, uncomment the line with B exit
    B       exit



@@@@ MaxVal: Find the largest integer in an array (unsigned values)
@ Parameters:
@  R0 = array (base) address
@  R1 = length
@ Returns:
@  R0 = largest value


MaxVal:
        STMFD SP!, {R4, LR}         @ Save R4 and LR on the stack
        MOV R2, R1                  @ 4 - Counter = array1size
	SUB R1, #1		    @ Decrease R1
	LSL R1, R1, #2		    @ Set R1 to (size-1)*4 (max size of array)
        ADD R0, R1		    @ Set R0 to last address in the array
        LDR R3,[R0], #-4            @ Load the last element to R3
again:                   
        SUB R2, #1                  @ 7 - Decrement counter
        CMP R2, #0                  @ 8 - Compare counter to length and if counter ...
        BLE end                     @ 9 - IF <= 0 : then end function (exit loop)
        LDR R4,[R0],#-4             @10 -    Load R4 with R0 | R0 -= 4  
        CMP R4, R3                  @11 - Compare R4 with current largest value (R3)
        MOVGT R3, R4                @12 - IF R4 > R3 then store in R3 as maximum value
        B again                     @13 - Repeat (go back to step 7)
end:
        MOV R0, R3                  @14 - Return maximum value in R0
        LDMFD SP!, {R4, PC}         @ Restore R4 and LR from the stack
        MOV PC, LR                  @ Return to calling code


.data

@ Below we have defined a constant named 'arraysize' and an array of word values
@ The array is a sequence of word (32 bit in this case) values and the first item in the array
@ is given the label array1.
@ There is no need to give every array item a label. If we know the base address and the data size of 
@ the elements we can quickly calculate the memory location of any item based on its position in the 
@ array 

            .equ    array1size, 10
array1:     .word   0x0C15, 0x0101, 0x0022, 0x5B57, 0x278C, 0x009B, 0x0F06, 0x43FD, 0xFE42, 0xC4F5

            