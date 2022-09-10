// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Mult.asm

// Multiplies R0 and R1 and stores the result in R2.
// (R0, R1, R2 refer to RAM[0], RAM[1], and RAM[2], respectively.)

// Initialize all variables
@i
M=0
@sum
M=0
@n
M=0
@numtobeadded
M=0
@R0
D=M
@num1
M=D
@R1
D=M
@num2
M=D
@R2
M=0
//Check which number is bigger
@num1
D=M
@num2
D=D-M
@NUM2BIGGER
D;JLT

//IF NUM1 IS BIGGER
@num2
D=M
@n
M=D
@num1
D=M
@numtobeadded
M=D

//LOOP AND CARRY OUT MULTIPLICATION THROUGH REPEATED ADDITION
(LOOP)

//CHECK IF i<n
@i
D=M
@n
D=D-M
@END
D;JEQ    // if i<n, goto END
@numtobeadded
D=M
@sum
M=M+D
@i
M=M+1
@LOOP
0;JMP

(NUM2BIGGER)
//set numtobeadded to num2 and number of times to be added(n) to be num1
@num1
D=M
@n
M=D
@num2
D=M
@numtobeadded
M=D
@LOOP
0;JMP


(END)
@sum
D=M
@R2
M=D
@END
0;JMP
