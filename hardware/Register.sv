`timescale 1ns / 100ps

module Register #(
    parameter unsigned DATA_WIDTH = 16
) (
    input                       write,
    input                       read,
    input                       reset_n,
    input  [             2 : 0] addr_read,
    input  [             2 : 0] addr_write,
    input  [DATA_WIDTH - 1 : 0] data_write,
    output [DATA_WIDTH - 1 : 0] data_read,
    input                       clk
);

    logic [3 * DATA_WIDTH - 1 : 0] register;

    always @(posedge clk) begin
        if (!reset_n) register <= 'b0;
        else if (write) register[DATA_WIDTH*addr_write+:DATA_WIDTH] <= data_write;
    end

    assign data_read = read ? register[DATA_WIDTH*addr_read+:DATA_WIDTH] : {DATA_WIDTH{1'hz}};

endmodule
