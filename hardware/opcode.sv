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

`define A_REG 4'b0000
`define B_REG 4'b0001
`define C_REG 4'b0010
`define D_REG 4'b0001
`define E_REG 4'b0100
`define SP_REG 4'b0101
`define PC_REG 4'b0110
`define FLAGS 4'b0111
