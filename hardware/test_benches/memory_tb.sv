`include "../Memory.sv"
`timescale 1ns / 1ps


module memory_tb;
    parameter unsigned ADDR_WIDTH = 16;
    parameter unsigned DATA_WIDTH = 16;
    parameter unsigned DEPTH = 2 ** ADDR_WIDTH;

    logic clk;
    logic write;
    logic read;
    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] data;
    Memory u0 (
        .write(write),
        .read (read),
        .clk  (clk),
        .addr (addr),
        .data (data)
    );

    logic [DATA_WIDTH-1:0] tb_data;

    always #10 clk = ~clk;
    assign data = (write) ? tb_data : {DATA_WIDTH{1'hz}};

    initial begin
        {clk, write, read, addr, tb_data} = 0;
        $dumpfile("waveform.vcd");
        $dumpvars(0, memory_tb);


        for (shortint i = 0; i < 16; i = i + 1) begin
            repeat (1) @(posedge clk) addr = i;
            write   = 1;
            read    = 0;
            tb_data = $urandom;
        end

        for (shortint i = 0; i < 16; i = i + 1) begin
            repeat (1) @(posedge clk) addr = i;
            write = 0;
            read  = 1;
        end

        #20 $finish;
    end
endmodule
