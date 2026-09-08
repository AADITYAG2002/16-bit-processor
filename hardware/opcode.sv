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
