`include "../Alu.sv"
`timescale 1ns / 100ps

module alu_tb;
    parameter unsigned DATA_WIDTH = 16;


    logic clk;
    logic reset_n;
    logic ALU_Enable;
    logic [DATA_WIDTH - 1 : 0] Input_A, Input_B, ALU_output;
    logic [4 : 0] op_select;
    logic [7 : 0] Flags;

    Alu alu (
        .clk       (clk),
        .reset_n   (reset_n),
        .ALU_Enable(ALU_Enable),
        .Input_A   (Input_A),
        .Input_B   (Input_B),
        .op_select (op_select),
        .ALU_output(ALU_output),
        .Flags     (Flags)
    );

    always #10 clk = ~clk;
    initial begin
        {clk, ALU_Enable, Input_A, Input_B, op_select} = 0;
        $dumpfile("alu_waveform.vcd");
        $dumpvars(0, alu_tb);

        reset_n = 1;
        #10 reset_n = 0;
        #10 reset_n = 1;
        #10 Input_A = 'h4003;
        Input_B   = 'h0;
        alu.Flags = 'h2;
        #20 op_select = 5'b10110;
        #20 ALU_Enable = 1;
        #20 ALU_Enable = 0;

        #20 $finish;
    end

endmodule
