

(INFINITELOOP)
@SCREEN
D=A
@base
M=D
@8192
D=A
@n
M=D
@i
M=0
@bOw
M=-1
@KBD
D=M
@WHITENSCREEN
D;JEQ

(SCREENLOOP)
@i
D=M
@n
D=D-M
@INFINITELOOP
D;JEQ
@bOw
D=M
@base
A=M
M=D
@base
M=M+1
@i
M=M+1
@SCREENLOOP
0;JMP

(WHITENSCREEN)
@bOw
M=0
@SCREENLOOP
0;JMP




