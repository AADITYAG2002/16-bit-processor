`define NOP 8'b0000_0000
`define HLT 8'b1111_1111

`define MOV 8'b0000_0001
`define LDA 8'b0000_0010
`define STA 8'b0000_0011

`define ADD 8'b0000_0100
`define SUB 8'b0000_0101
`define MUL 8'b0000_0110
`define DIV 8'b0000_0111

`define AND 8'b0000_1000
`define OR 8'b0000_1001
`define XOR 8'b0000_1010
`define NOT 8'b0000_1011
`define RR 8'b0000_1100

`define PUSH 8'b0000_1101
`define POP 8'b0000_1110

`define JUMP 8'b1000_0000
`define CALL 8'b1010_0000
`define RET 8'b1011_0000

`define NO_REG 3'b000
`define A_REG 3'b001
`define B_REG 3'b010
`define C_REG 3'b001
`define IR_REG 3'b100
`define PC_REG 3'b101
`define SP_REG 3'b110
`define MDR_REG 3'b111

`define NO_OP 4'b0000
`define ADD_OP 4'b0001
`define SUB_OP 4'b0010
`define MUL_OP 4'b0011
`define DIV_OP 4'b0100
`define AND_OP 4'b1000
`define OR_OP 4'b1001
`define XOR_OP 4'b1010
`define NOT_OP 4'b1011
`define RRS_OP 4'b1100
`define RRC_OP 4'b1101
`define LLS_OP 4'b1110
`define LLC_OP 4'b1111
