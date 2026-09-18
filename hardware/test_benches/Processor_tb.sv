`timescale 1ns / 100ps

module Processor_tb;
    parameter unsigned ADDR_WIDTH = 16;
    parameter unsigned DATA_WIDTH = 16;


    logic clk, read, write, reset_n;
    logic [ADDR_WIDTH-1:0] addr;
    wire  [DATA_WIDTH-1:0] data;

    Memory memory (
        .write(write),
        .read (read),
        .clk  (clk),
        .addr (addr),
        .data (data)
    );

    Processor u0 (
        .address  (addr),
        .data     (data),
        .read_mem (read),
        .write_mem(write),
        .clk      (clk),
        .reset_n  (reset_n)
    );



    always #1 clk = ~clk;

    initial begin
        clk     = 1;
        reset_n = 1;
        $readmemh("memory.hex", memory.mem, 0, 4);

        #5 reset_n = 0;
        #5 reset_n = 1;
        #30 $finish;
    end
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

endmodule
