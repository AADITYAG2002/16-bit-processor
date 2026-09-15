`timescale 1ns / 100ps

module Memory #(
    parameter unsigned ADDR_WIDTH = 16,
    parameter unsigned DATA_WIDTH = 16,
    parameter unsigned DEPTH = 2 ** ADDR_WIDTH
) (
    input bit                    write,
    input bit                    read,
    input logic                  clk,
    input logic [ADDR_WIDTH-1:0] addr,
    inout logic [DATA_WIDTH-1:0] data
);

    logic [DATA_WIDTH-1:0] tmp_data;
    logic [DATA_WIDTH-1:0] mem[5];

    // always @(posedge clk) begin
    //     if (write) mem[addr] <= data;
    //     if (read) tmp_data <= mem[addr];
    // end

    always_comb begin
        if (write) mem[addr] = data;
        if (read) tmp_data = mem[addr];
    end

    assign data = (!write && read) ? tmp_data : {DATA_WIDTH{1'hz}};

endmodule
