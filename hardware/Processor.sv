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
    reg [DATA_WIDTH - 1 : 0] MDR, IR;
    reg [7 : 0] Flags;



    // control signals
    logic Halt;
    logic Reg_Write, Reg_Read;
    logic [3 : 0] Reg_Read_Addr, Reg_Write_Addr;
    logic Control_Read, IR_Write, IR_Read, MDR_Read, Io_Read, Control_Write;
    wire [2 : 0] PC_Sel;
    logic PC_Jump;
    logic ALU_Enable, ALU_in_B_Sel, ALU_Out_Write;
    logic [4 : 0] ALU_Op_Sel;

    // interconnect wires & reg
    wire [DATA_WIDTH - 1 : 0] internal_databus;
    logic [ADDR_WIDTH - 1 : 0] next_pc;
    logic [DATA_WIDTH - 1 : 0] ALU_out;
    logic [DATA_WIDTH - 1 : 0] ALU_in_B;

    // Control Unit
    Control control (
        .reset_n(reset_n),
        .clk    (clk),
        .MDR    (MDR),
        .Flags  (Flags),

        .Halt         (Halt),
        .Reg_Write    (Reg_Write),
        .Reg_Read     (Reg_Read),
        .Control_Read (Control_Read),
        .Control_Write(Control_Write),
        .Io_Read      (Io_Read),
        .IR_Write     (IR_Write),
        .IR_Read      (IR_Read),
        .MDR_Read     (MDR_Read),

        .Reg_Read_Addr (Reg_Read_Addr),
        .Reg_Write_Addr(Reg_Write_Addr),

        .PC_Sel (PC_Sel),
        .PC_Jump(PC_Jump),

        .ALU_Enable   (ALU_Enable),
        .ALU_Op_Sel   (ALU_Op_Sel),
        .ALU_in_B_Sel (ALU_in_B_Sel),
        .ALU_Out_Write(ALU_Out_Write)
    );

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

    let PC = register.register_file.reg_list.PC;
    let Acc = register.register_file.reg_list.A_reg;

    // ALU
    Alu alu (
        .clk       (clk),
        .ALU_Enable(ALU_Enable),
        .Input_A   (Acc),
        .Input_B   (ALU_in_B),
        .op_select (ALU_Op_Sel),
        .Flags     (Flags),
        .ALU_output(ALU_out)
    );

    ////////////////////////////////////////////////////////////////////////////////////////

    ////////////////////////  ALU  ////////////////////////////

    always_comb begin
        case (ALU_in_B_Sel)
            0: ALU_in_B = IR;
            1: ALU_in_B = 1'b1;
            default: begin
            end
        endcase
    end

    ///////////////////////////////////////////////////////////

    ////////////////////////  Memory Access  ////////////////////////////

    assign read_mem  = Control_Read;
    assign write_mem = Control_Write;
    always_latch begin
        if (MDR_Read) MDR = internal_databus;
        if (IR_Write) IR = internal_databus;
    end

    assign internal_databus = Control_Read ? data
                                : (ALU_Out_Write ? ALU_out
                                    : (IR_Read ? IR
                                        : {DATA_WIDTH{1'hz}}));

    assign address = Control_Read ? (Io_Read ? IR : PC) : (Control_Write ? IR : {ADDR_WIDTH{1'hz}});
    assign data = Control_Write ? internal_databus : {DATA_WIDTH{1'hz}};

    //////////////////////////////////////////////////////////////////////

    //////////////////////// Program Counter ////////////////////////////

    always_comb begin
        case (PC_Sel)
            0:       next_pc = PC + {ADDR_WIDTH{1'b0}};
            1:       next_pc = PC + 1;
            2:       next_pc = PC_Jump ? IR : PC + 1;
            default: next_pc = PC + {ADDR_WIDTH{1'b0}};
        endcase
    end

    always_ff @(posedge clk) begin
        if (!reset_n) PC <= {ADDR_WIDTH{1'b0}};
        else if (!Halt) PC <= next_pc;
    end

    //////////////////////////////////////////////////////////////////////

endmodule
