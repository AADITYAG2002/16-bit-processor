`include "opcode.sv"
`timescale 1ns / 100ps

module Alu #(
    parameter unsigned DATA_WIDTH = 16
) (
    input  logic                      clk,
    input                             ALU_Enable,
    input  logic [DATA_WIDTH - 1 : 0] Input_A,
    input  logic [DATA_WIDTH - 1 : 0] Input_B,
    input  logic [             4 : 0] op_select,
    output logic [DATA_WIDTH - 1 : 0] ALU_output,
    output reg   [             7 : 0] Flags
);

    logic [DATA_WIDTH : 0] result;

    always_comb begin
        case (op_select)
            `ADD: result = Input_A + Input_B;
            `SUB: result = Input_A - Input_B;
            `AND: result = Input_A & Input_B;
            `OR: result = Input_A | Input_B;
            `XOR: result = Input_A ^ Input_B;
            `NOT: result = ~Input_A;
            default: result = {(DATA_WIDTH + 1) {1'hz}};
        endcase

        if (ALU_Enable) begin
            Flags[0] = (result[DATA_WIDTH-1 : 0] == 0);
            Flags[1] = result[DATA_WIDTH];
        end

    end

    always @(posedge clk) begin
        ALU_output <= result[DATA_WIDTH-1 : 0];
    end

endmodule
