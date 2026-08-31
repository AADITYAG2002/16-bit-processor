`define ROM_SIZE 16
`define ROM_ADDR_SIZE 16

module ROM (
    input  logic [`ROM_ADDR_SIZE - 1 : 0] rom_addr,
    output logic [     `ROM_SIZE - 1 : 0] CTRL
);

    logic [`ROM_SIZE:0] memory = 0;
    assign CTRL = memory[rom_addr];

endmodule

module Control #(
    parameter unsigned DATA_WIDTH = 16
) (
    input  logic                      reset_n,
    input  logic                      clk,
    input  logic [DATA_WIDTH - 1 : 0] instruction,
    output logic                      Reg_Write,
    output logic                      Reg_Read,
    output logic                      Control_Read,
    output logic                      Control_Write,
    output logic                      Io_Read,
    output logic                      IR_Read,
    output logic                      MDR_Read,
    output logic                      PC_Sel,
    input  logic                      Z_flag,
    input  logic                      C_flag,
    output logic                      ALU_In_1,
    output logic                      ALU_In_2,
    output logic [             3 : 0] ALU_Op_Sel,
    output logic                      ALU_Out_Write,
    output logic [             2 : 0] Reg_Read_Addr,
    output logic [             2 : 0] Reg_Write_Addr,
    output logic [DATA_WIDTH - 1 : 0] Read_Addr,
    output logic [DATA_WIDTH - 1 : 0] Write_Addr
);

    logic [`ROM_ADDR_SIZE - 1 : 0] rom_addr;
    logic [`ROM_SIZE - 1 : 0] CTRL;

    ROM rom (
        .rom_addr(rom_addr),
        .CTRL    (CTRL)
    );

    assign {Reg_Read_Addr, Reg_Read, Reg_Write_Addr, Reg_Write, Control_Read, Control_Write, Io_Read, IR_Read, MDR_Read, Read_Addr, Write_Addr, PC_Sel, ALU_In_1, ALU_In_2, ALU_Op_Sel} = CTRL;

endmodule

