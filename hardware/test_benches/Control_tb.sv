`timescale 1ns / 100ps

module Control_tb;

    logic [7:0] rom = 'b0_000_0_000;

    logic [7:0] rom_1 = 8'b1;

    logic [7:0] ctrl = rom | (rom_1 << 4);

    initial begin
        $display("rom %08b, rom_1 %08b, ctrl %08b", rom, rom_1, ctrl);
    end

endmodule
