@ SystemCall.s
@ Adam Watkins 
@ December 2024

@ This file contains an example of making a system call

@ In many programs printing a message to the terminal often occurs.
@ The write system call (just one of many) is used to push data from a source (buffer)  
@ to a destination. In this case we are using it to push data to the terminal.

@ The lines below that are marked * will be the same no matter when or where the
@ system call is made. It makes sense to put these lines into a function in order
@ to maintain the levels of abstraction inside our code:

@ The main calling code simply specifies the string and the number of characters 
@     from that string to print
@ The print function prepares the system call using the parameters passed
@ The system call then does the work

@ You can also see we are using a further system call (number 1) to stop
@ execution of the program.

@ The code below is numbered so you can see the order of execution

.global  main

.text 

main:                               @ 0 - This is the start of the program
    LDR R0, =name                   @ 1 - Load parameter 1 - address of the string to print
    MOV R1, #name_length            @ 2 - Load parameter 2 - length of the string
    BL print                        @ 3 - Make the system call (jump to print function)
    LDR R0, =place                  @ 10 - Load parameter 1 - address of string 'place'
    MOV R1, #place_length           @ 11 - Load parameter 2 - length of string
    BL print                        @ 12 - Now repeat the print function...
    MOV R0, #0                      @ 13 - We'll assume our program exits cleanly so put 0 in R0

exit:               @ The exit system call is used to halt execution and return
     				@ to the operating system. Whatever value is in R0 can be 
                    @ inspected using the terminal command:
                    @               echo $?
                    @ If a program closes as expected then this value is usually 0
    @ If using the RPI, uncomment the lines with the MOV and SWI instructions
    @ If using the simulator, comment the lines with the MOV and SWI instructions
	@ MOV R7, #1		@ 14 - exit syscall is #1, so load this in R7
	@ SWI 0           @ 15 - Make the system call to stop execution
    @ If using the RPI, comment the line with B exit
    @ If using the simulator, uncomment the line with B exit
    B       exit




@@@@ Print a string to the terminal 
@ Parameters:
@   R0: address of string
@   R1: length of string
@ Returns:
@   none
print:
    STMFD SP!, {R7, LR}         @ 4 - We are going to use R7, so put a copy in the stack
	MOV R7, #4		            @ * 5 - Place the System call number into R7
    MOV R2, R1                  @ Move size_t to R2
    MOV R1, R0                  @ Move char *buf to R1
 	MOV R0, #1		            @ * 6 - Place stdout in R0 (Stdout is monitor)
	SWI 0	                    @ * 7 - Make the system call using a SoftWare Interrupt (SWI)
    LDMFD SP!, {R7, LR}         @ 8 - Restore R7
	MOV PC, LR                  @ 9 - Return from the call


.data       
name:             .ascii "Hi, my name is Dorothy"
            .equ    name_length, 23
place:            .ascii "and I'm from Kansas"
            .equ   place_length, 19


