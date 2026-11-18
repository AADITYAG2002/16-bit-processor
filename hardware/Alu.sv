`include "opcode.sv"
`timescale 1ns / 100ps

module Alu #(
    parameter unsigned DATA_WIDTH = 16
) (
    input  logic                      clk,
    input  logic                      reset_n,
    input  logic                      ALU_Enable,
    input  logic [DATA_WIDTH - 1 : 0] Input_A,
    input  logic [DATA_WIDTH - 1 : 0] Input_B,
    input  logic [             4 : 0] op_select,
    output logic [DATA_WIDTH - 1 : 0] ALU_output,
    output reg   [             7 : 0] Flags
);

    logic [DATA_WIDTH - 1:0] result;
    logic C_flag;

    always_comb begin
        C_flag = Flags[1];
        case (op_select)
            `ADD: {C_flag, result} = Input_A + Input_B;
            `SUB: {C_flag, result} = Input_A - Input_B;
            `AND: result = Input_A & Input_B;
            `OR: result = Input_A | Input_B;
            `XOR: result = Input_A ^ Input_B;
            `NOT: result = ~Input_A;
            `RRS: begin
                result[DATA_WIDTH-2 : 0] = Input_A[DATA_WIDTH-1 : 1];
                C_flag = Input_A[0];
                result[DATA_WIDTH - 1] = C_flag;
            end
            `RRC: begin
                result[DATA_WIDTH-2 : 0] = Input_A[DATA_WIDTH-1 : 1];
                result[DATA_WIDTH - 1] = C_flag;
                C_flag = Input_A[0];
            end
            `LLS: begin
                result[DATA_WIDTH-1 : 1] = Input_A[DATA_WIDTH-2 : 0];
                C_flag = Input_A[DATA_WIDTH - 1];
                result[0] = C_flag;
            end
            `LLC: begin
                result[DATA_WIDTH-1 : 1] = Input_A[DATA_WIDTH-2 : 0];
                result[0] = C_flag;
                C_flag = Input_A[DATA_WIDTH - 1];
            end
            default: {C_flag, result} = {(DATA_WIDTH + 1) {1'hz}};
        endcase
    end

    always_latch begin
        if (!reset_n) Flags = 0;
        if (ALU_Enable) begin
            Flags[0] = (result[DATA_WIDTH-1 : 0] == 0);
            Flags[1] = C_flag;
        end
    end

    always @(negedge clk) begin
        ALU_output <= result[DATA_WIDTH-1 : 0];
    end

endmodule
