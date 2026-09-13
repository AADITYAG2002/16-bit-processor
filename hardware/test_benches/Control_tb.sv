`timescale 1ns / 100ps

module Control_tb;

    parameter unsigned ADDR_WIDTH = 16;
    parameter unsigned DATA_WIDTH = 16;

    logic clk, reset_n, Z_flag, C_flag;
    logic [DATA_WIDTH - 1 : 0] MDR;

    Control u0 (
        .reset_n(reset_n),
        .clk    (clk),
        .MDR    (MDR),
        .Z_flag (Z_flag),
        .C_flag (C_flag)
    );

    always #1 clk = ~clk;

    initial begin
        clk     = 0;
        Z_flag  = 0;
        C_flag  = 0;
        reset_n = 0;
        MDR     = 'hFFFF;
        #0.5 reset_n = 1;

        #2.5 MDR = 'h0000;
        #2 MDR = 'h0124;
        // #2 MDR = 'hCAFE;
        #4 MDR = 'hFFFF;
        #2 MDR = 'h0000;

        #10 $finish;
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

endmodule
