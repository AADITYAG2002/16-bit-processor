`timescale 1ns / 100ps

module Processor #(
    parameter unsigned ADDR_WIDTH = 16,
    parameter unsigned DATA_WIDTH = 16
) (
    output logic [ADDR_WIDTH - 1 : 0] address,
    inout  logic [DATA_WIDTH - 1 : 0] data,
    output bit                        read_mem,
    output bit                        write_mem,
    input  bit                        reset_n,
    input  logic                      clk
);

    ////////////////////////  Declaration & Inittialization  ///////////////////////////////
    // Registers & flags
    reg [ADDR_WIDTH - 1 : 0] PC_debug, SP_debug;
    reg [DATA_WIDTH - 1 : 0] MDR, IR, Acc;
    logic Z_flag, C_flag;

    let PC = register.register_file.reg_list.PC;
    let SP = register.register_file.reg_list.SP;
    assign PC_debug = PC;
    assign SP_debug = SP;

    // control signals
    logic Acc_Write, Acc_Read, Reg_Write, Reg_Read;
    logic [2 : 0] Reg_Read_Addr, Reg_Write_Addr;
    logic Control_Read, IR_Write, IR_Read, MDR_Read, Io_Read, Control_Write;
    wire [2 : 0] PC_Sel;
    logic ALU_In_1, ALU_In_2, ALU_Out_Write;
    logic [3 : 0] ALU_Op_Sel;

    // interconnect wires & reg
    wire [DATA_WIDTH - 1 : 0] internal_databus;
    logic [ADDR_WIDTH - 1 : 0] next_pc;
    logic [DATA_WIDTH - 1 : 0] ALU_Src_A, ALU_Src_B, ALU_out;

    // ALU
    // Alu alu (
    //     .A_reg     (ALU_Src_A),
    //     .B_reg     (ALU_Src_B),
    //     .op_select (ALU_Op_Sel),
    //     .ALU_output(ALU_out),
    //     .Z_flag    (Z_flag),
    //     .C_flag    (C_flag)
    // );

    // Register File
    Register register (
        .write     (Reg_Write),
        .read      (Reg_Read),
        .reset_n   (reset_n),
        .clk       (clk),
        .data_read (internal_databus),
        .data_write(internal_databus),
        .addr_read (Reg_Read_Addr),
        .addr_write(Reg_Write_Addr)
    );

    // Control Unit
    Control control (
        .reset_n       (reset_n),
        .clk           (clk),
        .MDR           (MDR),
        .Acc_Read      (Acc_Read),
        .Acc_Write     (Acc_Write),
        .Reg_Write     (Reg_Write),
        .Reg_Read      (Reg_Read),
        .Control_Read  (Control_Read),
        .Control_Write (Control_Write),
        .Io_Read       (Io_Read),
        .IR_Write      (IR_Write),
        .IR_Read       (IR_Read),
        .MDR_Read      (MDR_Read),
        .PC_Sel        (PC_Sel),
        .Z_flag        (Z_flag),
        .C_flag        (C_flag),
        .ALU_In_1      (ALU_In_1),
        .ALU_In_2      (ALU_In_2),
        .ALU_Op_Sel    (ALU_Op_Sel),
        .ALU_Out_Write (ALU_Out_Write),
        .Reg_Read_Addr (Reg_Read_Addr),
        .Reg_Write_Addr(Reg_Write_Addr)
    );

    ////////////////////////////////////////////////////////////////////////////////////////

    ////////////////////////  Memory Access  ////////////////////////////

    assign read_mem  = Control_Read ? 1 : 0;
    assign write_mem = Control_Write ? 1 : 0;
    always_latch begin
        if (MDR_Read) MDR = internal_databus;
        if (IR_Write) IR = internal_databus;
        if (Acc_Write && Reg_Write) Acc = internal_databus;
    end

    assign internal_databus = read_mem ? data
                                : (ALU_Out_Write ? ALU_out
                                    : (IR_Read ? IR
                                        : ((Acc_Read && Reg_Read) ? Acc
                                            : {DATA_WIDTH {1'hz}})));

    assign address = Control_Read ? (Io_Read ? IR : PC) : (Control_Write ? IR : {ADDR_WIDTH{1'hz}});
    assign data = write_mem ? internal_databus : {DATA_WIDTH{1'hz}};

    //////////////////////////////////////////////////////////////////////

    ////////////////////////  ALU  ////////////////////////////

    // always_comb begin
    //     case (ALU_In_1)
    //         1: ALU_Src_A = internal_databus;
    //         default: begin
    //             ALU_Src_A = {DATA_WIDTH{1'b0}};
    //         end
    //     endcase
    //     case (ALU_In_2)
    //         0: ALU_Src_B = internal_databus;
    //         1: ALU_Src_B = IR;
    //         default: begin
    //             ALU_Src_B = {DATA_WIDTH{1'b0}};
    //         end
    //     endcase
    // end

    ///////////////////////////////////////////////////////////

    ////////////////////////  CPU reset Program Counter ////////////////////////////

    always_comb begin
        case (PC_Sel)
            0:       next_pc = PC + {ADDR_WIDTH{1'b0}};
            1:       next_pc = PC + 1'b1;
            2:       next_pc = Z_flag ? IR : PC + 1'b1;
            3:       next_pc = (!Z_flag) ? IR : PC + 1'b1;
            4:       next_pc = (C_flag) ? IR : PC + 1'b1;
            5:       next_pc = (!C_flag) ? IR : PC + 1'b1;
            default: next_pc = PC + {ADDR_WIDTH{1'b0}};
        endcase
    end

    always_ff @(posedge clk) begin
        if (!reset_n) PC <= {ADDR_WIDTH{1'b0}};
        else PC <= next_pc;
    end

    //////////////////////////////////////////////////////////////////////

endmodule
