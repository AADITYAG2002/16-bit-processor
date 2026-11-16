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
                            LDA Rd, Rs / Immd   .1I. ..1. DDDD SSSS     addr             Rd <- [Rs / addr]
                            STA Rd / Immd, Rs   .1I. ..11 DDDD SSSS     addr             [Rd / addr] <- Rs
                            PUSH Rs             .1.. .1.. .... SSSS                      [SP--] <- Rs
                            POP Rd              .1.. .1.1 DDDD ....                      Rd <- [++SP]


    Arithmetic & Logic      ADD Rs / Immd       1.I. .... ...1 SSSS     data             A <- A + Rs / data
                            SUB Rs / Immd       1.I. ...1 ...1 SSSS     data             A <- A + Rs / data
                            MUL Rs / Immd       1.I. ..1. ...1 SSSS     data             A, B <- A * Rs / data
                            DIV Rs / Immd       1.I. ..11 ...1 SSSS     data             A, B <- A / Rs / data

                            AND Rs / Immd       1.I1 .... ...1 SSSS     data             A <- A & Rs / data
                            OR  Rs / Immd       1.I1 ...1 ...1 SSSS     data             A <- A | Rs / data
                            XOR Rs / Immd       1.I1 ..1. ...1 SSSS     data             A <- A ^ Rs / data
                            NOT                 1..1 ..11 ...1 ....                      A <- A
                            RRS                 1..1 .1.. ...1 ....                      A <- A >> 1
                            RRC                 1..1 .1.1 ...1 ....                      CF, A <- A >> 1
                            LLS                 1..1 .11. ...1 ....                      A <- A << 1
                            LLC                 1..1 .111 ...1 ....                      CF, A <- A << 1


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
    R0          0000       Not actual register, used for null / empty
    R1 / Acc    0001
    R2          0010
    R3          0011
    R4          0100
    R5          0101
    R6          0110
    R7          0111
    R8          1000
    R9          1001
    R10         1010
    R11         1011
    R12         1100
    R13         1101
    R14 / SP    1110
    R15 / PC    1111


    ADD     00000
    SUB     00001
    MUL     00010
    DIV     00011
    AND     10000
    OR      10001
    XOR     10010
    NOT     10011
    RRS     10100
    RRC     10101
    LLS     10110
    LLC     10111
