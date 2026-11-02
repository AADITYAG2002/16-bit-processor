`timescale 1ns / 100ps

module bsram #(
    parameter unsigned ADDR_WIDTH = 16,
    parameter unsigned DATA_WIDTH = 16,
    // parameter unsigned DEPTH = 16383
    parameter unsigned DEPTH = 10
) (
    input  bit                    wre,
    input  logic                  clk,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out
);

    logic [DATA_WIDTH-1:0] read_addr;
    logic [DATA_WIDTH-1:0] mem[DEPTH];

    always @(posedge clk) begin
        if (wre) mem[addr] <= data_in;
        read_addr <= addr;
    end

    assign data_out = mem[read_addr];

endmodule

module Memory #(
    parameter unsigned ADDR_WIDTH = 16,
    parameter unsigned DATA_WIDTH = 16
) (
    input logic                      clk,
    input bit                        write,
    input bit                        read,
    input logic [ADDR_WIDTH - 1 : 0] addr,
    inout logic [DATA_WIDTH - 1 : 0] data
);

    logic [DATA_WIDTH-1:0] data_out;

    bsram bsram (
        .clk     (clk),
        .addr    (addr),
        .wre     (write),
        .data_in (data),
        .data_out(data_out)
    );

    assign data = read ? data_out : {DATA_WIDTH{1'hz}};

endmodule
