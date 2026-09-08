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

    Atomic                  NOP                 0000 0000 0000 0000                     Do nothing for 1 Clk Cycle
                            HLT                 1111 1111 1111 1111                     Stop Execution

-----------------------------------------------------------------------------------------------------
    Data Transfer           MOV Rd, Rs / Immd   0000 0001 0DDD 0SSS     data             Rd <- Rs / data
                            LDA Rd, Rs / Immd   0000 0010 0DDD 0SSS     data             Rd <- [Rs / data]
                            STA Rd / Immd, Rs   0000 0011 0DDD 0SSS     data             [Rd / data] <- Rs

-----------------------------------------------------------------------------------------------------

    Arithmetic & Logic      ADD Rs / Immd       0000 0100 0000 0SSS     data             A <- A + Rs / data
                            SUB Rs / Immd       0000 0101 0000 0SSS     data             A <- A + Rs / data
                            MUL Rs / Immd       0000 0110 0000 0SSS     data             A, B <- A * Rs / data
                            DIV Rs / Immd       0000 0111 0000 0SSS     data             A, B <- A / Rs / data

                            AND Rd, Rs / Immd   0000 1000 0DDD 0SSS     data             Rd <- Rd & Rs / data
                            OR  Rd, Rs / Immd   0000 1001 0DDD 0SSS     data             Rd <- Rd | Rs / data
                            XOR Rd, Rs / Immd   0000 1010 0DDD 0SSS     data             Rd <- Rd ^ Rs / data
                            NOT Rd              0000 1011 0DDD 0000     data             Rd <- ~Rd
                            RRS                 0000 1100 0000 0000                      A <- A >> 1
                            RRC                 0000 1100 0000 0001                      CF, A <- A >> 1
                            LLS                 0000 1100 0000 0010                      A <- A << 1
                            LLC                 0000 1100 0000 0011                      CF, A <- A << 1

                            PUSH Rs             0000 1101 0000 0SSS                      [SP--] <- Rs
                            POP Rd              0000 1110 0DDD 0000                      Rd <- [++SP]

-----------------------------------------------------------------------------------------------------
    Jump                    JMP addr            1000 0000 0000 0000     addr             PC <- addr
                            JNZ addr            1000 0000 0001 0000     addr             PC <- addr if ZF == 0
                            JZ  addr            1000 0000 0001 0001     addr             PC <- addr if ZF != 0
                            JNC addr            1000 0000 0010 0000     addr             PC <- addr if CF == 0
                            JC  addr            1000 0000 0010 0001     addr             PC <- addr if CF != 0
                            CALL addr           1010 0000 0000 0000     addr             [SP--] <- PC
                                                                                         PC <- addr
                            RET                 1011 0000 0000 0000                      PC <- [++SP]

## Register Encoding |  ALU Encoding
-----------------------------------------------------------------------------------------------------
no_reg  000                 no_op   0000
A       001                 ADD     0001
B       010                 SUB     0010
C       011                 MUL     0011
IR      100                 DIV     0100
PC      101                 AND     1000
SP      110                 OR      1001
MDR     111                 XOR     1010
                            NOT     1011
                            RRS     1100
                            RRC     1101
                            LLS     1110
                            LLC     1111
