`define NOP 4'b0000
`define HLT 4'b1111

`define MOV_MVI 4'b0001
`define LXD 4'b0010
`define STD_STI 4'b0011

`define ADD_ADI 4'b0100
`define SUB_SDI 4'b0101
`define MUL_DIV 4'b0110
`define RRS_RRC 4'b0111
`define LLS_LLC 4'b1000
`define AND_ANI 4'b1001
`define OR_ORI 4'b1010
`define NOT 4'b1011

`define JZ_JNZ 4'b1100
`define JC_JNC 4'b1101

`define A_REG 2'b00
`define B_REG 2'b01
`define PC_REG 2'b10
`define IR_REG 2'b11
