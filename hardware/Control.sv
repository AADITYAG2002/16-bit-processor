`timescale 1ns / 1ps

`include "opcode.sv"

`define ROM_ADDR_SIZE 32
`define ROM_DATA_SIZE 23
`define ROM_NUM_INST_SIZE 3

module ROM (
    input  logic [`ROM_ADDR_SIZE - 1 : 0] rom_addr,
    output logic [`ROM_DATA_SIZE - 1 : 0] CTRL
);

    parameter [`ROM_DATA_SIZE * (`ROM_NUM_INST_SIZE + 1) - 1:0] memory = {
        // {Reg_Read, Reg_Read_Addr[2:0], Reg_Write, Reg_Write_Addr[2:0], Control_Read, Control_Write, Io_Read, IR_Read, MDR_Read, PC_Sel[2:0], ALU_In_1, ALU_In_2, ALU_Op_Sel[3:0], ALU_Out_Write}
        `ROM_DATA_SIZE'b0_000_0_000_0_0_0_1_0_000_0_0_0000_0,  // MDR <- [PC]
        `ROM_DATA_SIZE'b0_000_0_000_0_0_0_0_0_000_0_0_0000_0,  // Rd <- Rs
        `ROM_DATA_SIZE'b0_000_0_000_0_0_0_0_0_000_0_0_0000_0,  // Rd <- IR

        /* Register select */
        `ROM_DATA_SIZE'b0_000_0_000_0_0_0_0_0_000_0_0_0000_0  // A
    };

    assign CTRL = memory[`ROM_DATA_SIZE*rom_addr+:`ROM_DATA_SIZE];
endmodule

module Control #(
    parameter unsigned DATA_WIDTH = 16
) (
    input logic                      reset_n,
    input logic                      clk,
    input logic [DATA_WIDTH - 1 : 0] MDR,
    input logic [DATA_WIDTH - 1 : 0] IR,
    input logic                      Z_flag,
    input logic                      C_flag,

    output logic         Reg_Read,
    output logic [2 : 0] Reg_Read_Addr,
    output logic         Reg_Write,
    output logic [2 : 0] Reg_Write_Addr,

    output logic         Control_Read,
    output logic         Control_Write,
    output logic         Io_Read,
    output logic         IR_Read,
    output logic         MDR_Read,
    output logic [2 : 0] PC_Sel,

    output logic         ALU_In_1,
    output logic         ALU_In_2,
    output logic [3 : 0] ALU_Op_Sel,
    output logic         ALU_Out_Write
);

    logic [`ROM_ADDR_SIZE - 1 : 0] rom_addr;
    logic [`ROM_DATA_SIZE - 1 : 0] CTRL;

    ROM rom (
        .rom_addr(rom_addr),
        .CTRL    (CTRL)
    );

    logic [3:0] param_2, param_1;
    logic [7 : 0] instr;

    assign {instr, param_2, param_1} = MDR;

    assign {
        Reg_Read, Reg_Read_Addr, Reg_Write, Reg_Write_Addr,
        Control_Read, Control_Write, Io_Read, IR_Read, MDR_Read, PC_Sel,
        ALU_In_1, ALU_In_2, ALU_Op_Sel, ALU_Out_Write
    } = CTRL;

    always_ff @(posedge clk) begin
        if (!reset_n) rom_addr <= 0;

        case (rom_addr)
            0: begin
                case (instr)
                    `NOP: rom_addr <= 0;
                    default: rom_addr <= 0;
                endcase
                rom_addr <= 1;
            end
            default: rom_addr <= 0;
        endcase
    end

endmodule

