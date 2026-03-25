@ Binary.s
@ Adam Watkins, Richard Verhoeven
@ December 2021

@ Wire the Gertboard as follows: 						
@   On J2				On J3 			
@		GP0 -> 			B12 			
@		GP1 ->			B11 			
@		GP4 ->			B10 			
@		GP7 ->			B9 				
@		GP17-GP24 ->	B8-B3 			
@		GP25 -> 		B1				
@   Put output jumpers on B1-B12 (Output side of U3,U4,U5)	

.global main

.equ SYS_EXIT, 0x01
.equ SYS_READ, 0x03
.equ SYS_WRITE, 0x04
.equ SYS_GETTIME, 0x4E
.equ STDOUT, 0x01
.equ STDIN, 0x00

.equ		GPCLR0, 0x28			@ Value to set a GPIO pin to OFF
.equ		GPSET0, 0x1C			@ Value to set a GPIO pin to ON
.equ        DISP_MASK,  0x09C6009C  @ Mask of all 10 LED pins combined
                                    @ TASK: Create a constant for the mask
                                    
.text
.include "Init_pins.s"
.include "Hardware2.s"
.include "Wait.s"

main:
		BL	    map_io          	@ open /dev/mem and map hardware
    	BL	    init_pins

		LDR   R0, =prompt       @ TASK: Load prompt string address
		MOV   R1, #prompt_len   @ TASK: Load prompt length
        BL    print             @ Print the prompt

        LDR   R0, =input        @ TASK: Load input buffer address
        MOV   R1, #1		@ TASK: Load input buffer length
        BL    read		@ Read 1 chars to input buffer (including newline)

		LDR   R0, =input        @ TASK: Load input buffer address
		LDRB  R0, [R0]         @ Load the first byte of input (the character) into R0
		CMP   R0, #'1'		    @ TASK: Compare input to '1'
		BLEQ   count_up          @ If '1' then count up
		BLNE   count_down        @ else count down
exit:
		BL	    unmap_io        	@ unmap and close hardware addresses
		MOV	    R7, #SYS_EXIT
		SWI	    0

@ Functions
count_up:
		STMFD	SP!, {R8, R9, LR}		 @ save R4 and LR
    	MOV	    R8, #0           @ puts 0 in the counter register
		MOV     R9, #1		     @ puts 1 in the increment register
		BAL	    count_somehow     @ call function to count to 1023 (0x3FF)
count_down:
		STMFD	SP!, {R8, R9, LR}		 @ save R4 and LR
		MOV	    R8, #1023        @ puts 1023 in the counter register
		MOV     R9, #-1	     @ puts -1 in the increment register
count_somehow:
		MOV     R0, R8           @ move counter value to R0
		BL	    disp_num         @ display the number in binary on the LEDs
		ADD	    R8, R9           @ increase counter
		MOV     R0, #100       @ wait for 100 ms
		BL	    wait             @ wait for a short period
		CMP	    R8, #1024      @ compare to 1024
		BEQ	    count_end     @ if not 1024, repeat loop
		CMP	    R8, #-1         @ if counting down, check if -1
		BEQ	    count_end     @ if not -1, repeat loop

		BAL	    count_somehow     @ repeat loop

count_end:
		LDMFD	SP!, {R8, R9, LR}		 @ restore R4 and LR
		MOV     PC, LR                   @ return


@@@@ read: read a string from keyboard and store in variable
@ Parameters:
@   R0: address of where to store string
@   R1: number of characters to store
@ Returns:
@   none
read:
        STMFD SP!, {R7, LR}     	        @ Push used registers and LR to stack
        MOV R2, R1                        	@ TASK: Move number of characters to read(R1) to R2
        MOV R1, R0                	        @ TASK: Move address of input string(R0) to R1
        MOV R7, #SYS_READ                      	@ TASK: Put the Syscall number in R?
        MOV R0, #STDIN                        	@ TASK: Put the keyboard STDIN in R?
        SWI 0					@ TASK: Uncomment this line to make the syscall
        LDMFD SP!, {R7, LR}     	        @ Restore used registers (update SP with !)
        MOV  PC, LR

@@@@ print: Print a string to the terminal
@ Parameters:
@   R0: address of string
@   R1: length of string
@ Returns:
@   none
print:                      
        STMFD   SP!, {R7,LR}    	@ Push used registers and LR on the stack;
        MOV R2, R1                	@ TASK: Move number of characters to print(R1) to R2
        MOV R1, R0              	@ TASK: Move address of output string(R0) to R1
        MOV R7, #SYS_WRITE              @ TASK: Put the Syscall number in R? - R7 - SYS_WRITE
        MOV R0, #STDOUT  		@ TASK: Put the monitor STDOUT in R? - R0 - #1
        SWI 0                 	@ TASK: Uncomment this line to make the syscall
        LDMFD   SP!, {R7,LR}    	@ Restore used registers (update SP with !)
        MOV     PC, LR          	@ Return


@@@@ disp_num : Function to display a number in binary on LEDS
@ Parameters:
@	R0: number < 1024.
@ Returns:
@ 	None
disp_num:
		STMFD	SP!, {R1-R4,LR}
		MOV	    R1, #1024
		SUB	    R1, #1		        @ R1 = 1023 = 0x3FF
		AND	    R0, R1		        @ restrict R1 to 10 bits.
		MOV	    R1, #0		        @ R1 collects bit pattern (set to 0)
		LDR	    R2, =disp_bits      @ R2: Address of bit mask array
		MOV	    R3, #0		        @ R3: offset within array
disp_num_loop:
		ANDS	R4, R0, #1          @ if last bit is set ..
		LDRNE	R4, [R2, R3]	    @ ... load pattern for that bit
		ORRNE	R1, R1, R4	        @ ... and update pattern
		ADD	    R3, #4		        @ increase offset in array
		MOVS	R0, R0, LSR #1	    @ shift, and update flags
		BNE	    disp_num_loop	    @ if not zero, continue.
		@ R1 contains pattern for setting the bits.
		LDR	    R2, =gpiobase
		LDR	    R2, [R2]
		CMP	    R1, #0
		STRNE	R1, [R2, #GPSET0]
		@ Adjust pattern for clear
		LDR	    R3, =DISP_MASK      @ load all bits value
		SUBS	R1, R3, R1		    @ substract bits for set
		STRNE	R1, [R2, #GPCLR0]	@ if not zero, clear bits
		LDMFD	SP!, {R1-R4,LR}
		MOV     PC, LR

@@@@@ set_pin_function : function to set pin n to output in GPSELm
@ Parameters: 
@   R0: pin number
@   R1: code of function (see chapter 6 BCM2837 manual for codes)
@ Returns:
@   R0:  -1 on error
set_pin_function:
				@ successively subtract 10 from R1 until <10
				@ store offset of of GPSELm in R5
		STMFD	SP!, {R2-R7, LR}	@ Save registers
		BL	    check_pin			@ Check if pin number OK
		CMP	    R0, #0				@ If returned value is 
		BLT	    exit_set_func		@   <0 (error) then exit function
				@ Find GPSELm from pin number
		CMP	    R0,#9				@ GPSEL0?
		MOV	    R5,#0
		BHI	    gpsel1
		BAL	    clr_GPSELm			@ Offset of GPSEL0 (= GPIO base address) in R5 = 0
gpsel1:	
        SUB	    R0, #10
		CMP	    R0, #9				@ GPSEL1?
		BHI	    gpsel2
		MOV	    R5,#4
		BAL	    clr_GPSELm			@ Offset of GPSEL1 in R5
gpsel2:	
        SUB	    R0, #10
		MOV	    R5,#8				@ Offset of GPSEL2 in R5
clr_GPSELm:	
        MOV	    R3, R0				@ Save R0
		MOV	    R6, #0b111			@ Load R6 with bit pattern for BIC to clear 3 bits
		MOV	    R2, #3
		MUL	    R7, R3, R2
		MOV	    R6, R6, LSL R7		@ Shift R6 R3*3 times left
clear:	LDR	    R3, =gpiobase
		LDR	    R2, [R3]			@ Load base memory address of gpio
		LDR	    R4, [R2,R5]			@ Load current contents of GPSELm
		BIC	    R4, R4, R6			@ Clear the 3 bits corresponding to the pin
		MOV	    R1, R1, LSL R7		@ Shift R1 (function) R7 times left
		ORR	    R4, R1				@ Set the function bits in R4 ( R4 is a copy of the
		                            @ Current GPSELm register with the 3 bits corresponding
								    @ To pin R1 set o 0)
		LDR	    R3, =gpiobase
		LDR	    R3, [R3]			@ Load memory base address of gpio
		STR	    R4, [R3,R5]			@ Copy R4 to GPSELm
exit_set_func:	
        LDMFD	SP!,{R2-R7, LR}	    @ Restore R2-R7 and LR
		MOV     PC, LR					@ R0 still holds GPIO base address if no error occurred..


@@@@ set_pin_value:	function to set the pin
@ Paramters:
@   R0: 	pin number
@   R1: 	offset of GPSET0/GPCLR0
@ Returns:
@   R0:		returns: -1 if error
set_pin_value:				
		STMFD	SP!, {R3, LR}
		MOV	    R3, R0				@ save R0
		BL	    check_pin			@ check if pin number is correct
		CMP	    R0, #0				@ if value returned from check_pin
		BLT	    ret_set				@     <1 then return (error)
		MOV	    R3, #1				@ will be shifted until pin position R1
		MOV	    R3, R3, LSL R0		@ shift by R0 bits left
		LDR	    R2, =gpiobase		@ gpio base address in memory
		LDR	    R2, [R2]
		STR	    R3, [R2,R1]			@ set or clear pin; R0+R2 address of GPSET/CLR0
								    @ notice that register is Write only
ret_set:
        LDMFD	SP!,{R3, LR}
		MOV     PC, LR              @ return - R0 still holds base address if no error occurred


@@@@ check_pin :	check if pin number is legal
@ Parameters:
@   R0: pin number
@ Return
@   R0: -1 if illegal
check_pin:
		CMP	    R0, #1				@ GPIO 0 and 1 not available
		BLS	    error				@ GPIO2 is connected to GP0, GPIO3 to GP1
		CMP	    R0, #5				@ GPIO5 not available
		BEQ	    error
		CMP	    R0, #6				@ GPIO6 not available
		BEQ	    error
		CMP	    R0, #16				@ GPIO 12, 13, 16 not available - R1 >16?
		BHI	    next_check			@ GPIO 14 and 15 set for UART so leave alone
		CMP	    R0, #11				@ GPIO# <12?
		BLS	    next_check
		BAL	    error
next_check:	
        CMP	    R0, #21				@ GPIO19, 20 and 21 not available
		BHI	    check_next
		CMP	    R0, #18
		BLS	    check_next
		BAL	    error
check_next:
        CMP	    R0, #27				@ GPIO27 is connected to GP21
		BEQ	    ret
		CMP	    R0, #25				@ no pins over 25
		BHI	    error
		MOV     PC, LR
error:	MOV	    R0, #-1				@ signal error to caller
ret:	MOV     PC, LR



.data
@@@@ Constants
prompt:           .asciz  "Press 1 to count up else count down:\n"            @ TASK: Modify the prompt to include the range of values
.equ              prompt_len, . - prompt   @ Assembler calculates exact length

@ Mapping of bits to GPIO pins
@ Note: the numbers on the Gertboard don't match the GPIO numbers.
@       See page 10 of the Gertboard documentation.
.align 4
disp_bits:
    .word   0x4         @ bits[0]: GP0  -> GPIO2
    .word   0x8         @ bits[1]: GP1  -> GPIO3
    .word   0x10        @ bits[2]: GP4  -> GPIO4
    .word   0x80        @ bits[3]: GP7  -> GPIO7
    .word   0x20000     @ bits[4]: GP17 -> GPIO17
    .word   0x40000     @ bits[5]: GP18 -> GPIO18
    .word   0x8000000   @ bits[6]: GP21 -> GPIO27
    .word   0x400000    @ bits[7]: GP22 -> GPIO22
    .word   0x800000    @ bits[8]: GP23 -> GPIO23
    .word   0x1000000   @ bits[9]: GP24 -> GPIO24

@@@@ Variables
.align
input:            .space 3              @ TASK: Create user guess variable here (input buffer)  @ 2 characters + newline 

dev_mem: .asciz "/dev/mem"
                   		
.align 4
file_desc:      .word 0x0           @ File descriptor for /dev/mem
clockbase:      .word 0x0           @ TASK: Add variable to store start of mapped hardware address
gpiobase:	.word	0x0			    @ address to which gpio is mapped

