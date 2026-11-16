`include "opcode.sv"
`timescale 1ns / 100ps

typedef struct packed {
    // logic [16 - 1 : 0] R15_PC;
    logic [16 - 1 : 0] R14_SP;
    logic [16 - 1 : 0] R13;
    logic [16 - 1 : 0] R12;
    logic [16 - 1 : 0] R11;
    logic [16 - 1 : 0] R10;
    logic [16 - 1 : 0] R9;
    logic [16 - 1 : 0] R8;
    logic [16 - 1 : 0] R7;
    logic [16 - 1 : 0] R6;
    logic [16 - 1 : 0] R5;
    logic [16 - 1 : 0] R4;
    logic [16 - 1 : 0] R3;
    logic [16 - 1 : 0] R2;
    logic [16 - 1 : 0] R1;
} register_def_t;

typedef union packed {
    register_def_t    reg_list;
    logic   [ 14 * 16 - 1 : 0 ] reg_array;
} register_file_t;

module Register #(
    parameter unsigned DATA_WIDTH = 16
) (
    input                             clk,
    input  logic                      write,
    input  logic                      read,
    input  logic                      reset_n,
    input  logic [             3 : 0] addr_read,
    input  logic [             3 : 0] addr_write,
    input  logic [DATA_WIDTH - 1 : 0] data_write,
    output logic [DATA_WIDTH - 1 : 0] data_read,
    output logic [  DATA_WIDTH - 1:0] R1_Acc
);

    register_file_t register_file;

    always @(posedge clk) begin
        if (!reset_n) register_file <= 'b0;
        else if (write)
            if (addr_write != `R0_REG)
                register_file[DATA_WIDTH*(addr_write-1)+:DATA_WIDTH] <= data_write;
    end

    assign data_read = read
                        ? ((addr_read != `R0_REG)
                            ? register_file[DATA_WIDTH * ( addr_read - 1 ) +: DATA_WIDTH]
                                : {DATA_WIDTH{1'b0}})
                                    : {DATA_WIDTH {1'hz}};

    assign R1_Acc = register_file.reg_list.R1;

endmodule
