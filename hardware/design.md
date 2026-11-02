# Custom CPU

## Outer Design
- 16-bit Address Bus
- 16-bit Data Bus
- Clock
- reset signal
- 16-bit memory mapped IO port

## Internal Design
- General Purpose Registers : A, B, C, D, E
- System Registers          : PC, SP, IR, MDR
- System Flags              : O, C, Z


### ISA 
    MMIO OOOO DDDD SSSS

    M : Mode    => 0 = I/O, 1 = Data Transfer, 2 = ALU, 3 = Jump
    I : Immediate Data
    O : Opcode
    D : Destination Register
    S : Source Register


    Category               ISA                    Opcode                               Description               

    I/O                     NOP                 .... .... .... ....                     Do nothing for 1 Clk Cycle
                            HLT                 ...1 1111 .... ....                     Stop Execution


    Data Transfer           MOV Rd, Rs / Immd   .1I. ...1 DDDD SSSS     data             Rd <- Rs / data
                            LDA Rd, Rs / Immd   .1I. ..1. DDDD SSSS     data             Rd <- [Rs / data]
                            STA Rd / Immd, Rs   .1I. ..11 DDDD SSSS     data             [Rd / data] <- Rs
                            PUSH Rs             .1.. .1.. .... SSSS                      [SP--] <- Rs
                            POP Rd              .1.. .1.1 DDDD ....                      Rd <- [++SP]


    Arithmetic & Logic      ADD Rs / Immd       1.I. .... .... SSSS     data             A <- A + Rs / data
                            SUB Rs / Immd       1.I. ...1 .... SSSS     data             A <- A + Rs / data
                            MUL Rs / Immd       1.I. ..1. .... SSSS     data             A, B <- A * Rs / data
                            DIV Rs / Immd       1.I. ..11 .... SSSS     data             A, B <- A / Rs / data

                            AND Rd, Rs / Immd   1.I1 .... .... SSSS     data             A <- A & Rs / data
                            OR  Rd, Rs / Immd   1.I1 ...1 .... SSSS     data             A <- A | Rs / data
                            XOR Rd, Rs / Immd   1.I1 ..1. .... SSSS     data             A <- A ^ Rs / data
                            NOT                 1..1 ..11 .... ....                      A <- A
                            RRS                 1..1 .1.. .... ....                      A <- A >> 1
                            RRC                 1..1 .1.1 .... ....                      CF, A <- A >> 1
                            LLS                 1..1 .11. .... ....                      A <- A << 1
                            LLC                 1..1 .111 .... ....                      CF, A <- A << 1


    Jump                    JMP addr            111. .... .... ....     addr             PC <- addr
                            JNZ addr            111. ...1 .... ....     addr             PC <- addr if ZF == 0
                            JZ  addr            111. ..1. .... ....     addr             PC <- addr if ZF != 0
                            JNC addr            111. ..11 .... ....     addr             PC <- addr if CF == 0
                            JC  addr            111. .1.. .... ....     addr             PC <- addr if CF != 0

                            CALL addr           1111 .... .... ....     addr             [SP--] <- PC
                                                                                         PC <- addr
                            RET                 11.1 ...1 .... ....                      PC <- [++SP]

## Register Encoding |  ALU Encoding
-----------------------------------------------------------------------------------------------------
    A      0000      |          
    B      0001      |          ADD     00000
    C      0010      |          SUB     00001
    D      0011      |          MUL     00010
    E      0100      |          DIV     00011
    SP     0101      |          AND     10000
    PC     0110      |          OR      10001
    Flags  0111      |          XOR     10010
                     |          NOT     10011
                     |          RRS     10100
                     |          RRC     10101
                     |          LLS     10110
                     |          LLC     10111
