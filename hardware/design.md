# Custom CPU

## Outer Design
- 16-bit Address Bus
- 16-bit Data Bus
- Clock
- reset signal
- 16-bit memory mapped IO port

## Internal Design
- General Purpose Registers : A, B, C
- System Registers          : PC, SP, IR, MDR
- System Flags              : CF, ZF


### ISA 

    Category               ISA                    Opcode                               Description               

    Atomic                  NOP                 .... .... .... ....                     Do nothing for 1 Clk Cycle
                            HLT                 1111 1111 1111 1111                     Stop Execution


    Data Transfer           MOV Rd, Rs / Immd   .... ...1 .DDD ISSS     data             Rd <- Rs / data
                            LDA Rd, Rs / Immd   .... ..1. .DDD ISSS     data             Rd <- [Rs / data]
                            STA Rd / Immd, Rs   .... ..11 IDDD .SSS     data             [Rd / data] <- Rs


    Arithmetic & Logic      ADD Rs / Immd       .... .1.. .... ISSS     data             A <- A + Rs / data
                            SUB Rs / Immd       .... .1.1 .... ISSS     data             A <- A + Rs / data
                            MUL Rs / Immd       .... .11. .... ISSS     data             A, B <- A * Rs / data
                            DIV Rs / Immd       .... .111 .... ISSS     data             A, B <- A / Rs / data

                            AND Rd, Rs / Immd   .... 1... .... ISSS     data             A <- A & Rs / data
                            OR  Rd, Rs / Immd   .... 1..1 .... ISSS     data             A <- A | Rs / data
                            XOR Rd, Rs / Immd   .... 1.1. .... ISSS     data             A <- A ^ Rs / data
                            NOT Rd              .... 1.11 .... .SSS     data             Rs <- ~Rs
                            RRS                 .... 11.. .... ....                      A <- A >> 1
                            RRC                 .... 11.. .... ...1                      CF, A <- A >> 1
                            LLS                 .... 11.. .... ..1.                      A <- A << 1
                            LLC                 .... 11.. .... ..11                      CF, A <- A << 1

                            PUSH Rs             .... 11.1 .... .SSS                      [SP--] <- Rs
                            POP Rd              .... 111. .DDD ....                      Rd <- [++SP]


    Jump                    JMP addr            1... .... .... ....     addr             PC <- addr
                            JNZ addr            1... .... ...1 ....     addr             PC <- addr if ZF == 0
                            JZ  addr            1... .... ...1 ...1     addr             PC <- addr if ZF != 0
                            JNC addr            1... .... ..1. ....     addr             PC <- addr if CF == 0
                            JC  addr            1... .... ..1. ...1     addr             PC <- addr if CF != 0
                            CALL addr           1.1. .... .... ....     addr             [SP--] <- PC
                                                                                         PC <- addr
                            RET                 1.11 .... .... ....                      PC <- [++SP]

## Register Encoding |  ALU Encoding
-----------------------------------------------------------------------------------------------------
    no_reg  000      |          no_op   0000
    B       001      |          ADD     0001
    C       010      |          SUB     0010
    D       011      |          MUL     0011
    E       100      |          DIV     0100
    PC      101      |          AND     1000
    SP      110      |          OR      1001
    A       111      |          XOR     1010
    IR     1000      |          NOT     1011
                     |          RRS     1100
                     |          RRC     1101
                     |          LLS     1110
                     |          LLC     1111
