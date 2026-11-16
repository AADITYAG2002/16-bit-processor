`define IO_MODE 2'b00
`define DATA_MODE 2'b01
`define ALU_MODE 2'b10
`define JUMP_MODE 2'b11

`define NOP 5'b00000
`define HLT 5'b11111

`define MOV 5'b00001
`define LDA 5'b00010
`define STA 5'b00011
`define PUSH 5'b00100
`define POP 5'b00101

`define ADD 5'b00000
`define SUB 5'b00001
`define MUL 5'b00010
`define DIV 5'b00011

`define AND 5'b10000
`define OR 5'b10001
`define XOR 5'b10010
`define NOT 5'b10011
`define RRS 5'b10100
`define RRC 5'b10101
`define LLS 5'b10110
`define LLC 5'b10111


`define JUMP 5'b00000
`define JUMP_NZ 5'b00001
`define JUMP_Z 5'b00010
`define JUMP_NC 5'b00011
`define JUMP_C 5'b00100

`define CALL 5'b10000
`define RET 5'b10001

`define R0_REG 4'b0000
`define R1_REG 4'b0001
`define R2_REG 4'b0010
`define R3_REG 4'b0011
`define R4_REG 4'b0100
`define R5_REG 4'b0101
`define R6_REG 4'b0110
`define R7_REG 4'b0111
`define R8_REG 4'b1000
`define R9_REG 4'b1001
`define R10_REG 4'b1010
`define R11_REG 4'b1011
`define R12_REG 4'b1100
`define R13_REG 4'b1101
`define R14_SP_REG 4'b1110
`define R15_PC_REG 4'b1111
