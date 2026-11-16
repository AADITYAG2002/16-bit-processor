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
    reg [DATA_WIDTH - 1 : 0] MAR, MDR, CIR, IR, PC, R1_Acc;
    reg [7 : 0] Flags;



    // control signals
    logic Halt;
    logic Reg_Write, Reg_Read;
    logic [3 : 0] Reg_Read_Addr, Reg_Write_Addr;
    logic
        Control_Read,
        Control_Write,
        IR_Write,
        IR_Read,
        MDR_Read,
        MDR_Write,
        MAR_Write,
        Io_Read_Write,
        CIR_Write;
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
        .CIR    (CIR),
        .Flags  (Flags),

        .Halt(Halt),

        .Reg_Write     (Reg_Write),
        .Reg_Read      (Reg_Read),
        .Reg_Read_Addr (Reg_Read_Addr),
        .Reg_Write_Addr(Reg_Write_Addr),

        .Read_Mem     (read_mem),
        .Write_Mem    (write_mem),
        .Control_Read (Control_Read),
        .Control_Write(Control_Write),
        .Io_Read_Write(Io_Read_Write),
        .IR_Write     (IR_Write),
        .IR_Read      (IR_Read),
        .CIR_Write    (CIR_Write),
        .MDR_Read     (MDR_Read),
        .MDR_Write    (MDR_Write),
        .MAR_Write    (MAR_Write),

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
        .addr_write(Reg_Write_Addr),
        .R1_Acc    (R1_Acc)
    );

    // ALU
    Alu alu (
        .clk       (clk),
        .ALU_Enable(ALU_Enable),
        .Input_A   (R1_Acc),
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
            1: ALU_in_B = 1;
            default: begin
            end
        endcase
    end

    ///////////////////////////////////////////////////////////

    ////////////////////////  Memory Access  ////////////////////////////

    always_latch begin
        if (!reset_n) begin
            MAR = {DATA_WIDTH{1'b0}};
            IR  = {DATA_WIDTH{1'b0}};
            CIR = {DATA_WIDTH{1'b0}};
            MDR = {DATA_WIDTH{1'b0}};
        end
        if (MAR_Write) MAR = Io_Read_Write ? IR : PC;
        if (IR_Write) IR = internal_databus;
        if (CIR_Write) CIR = MDR;
        if (Control_Read) MDR = data;
        else if (MDR_Write) MDR = internal_databus;
    end

    always_ff @(posedge clk) begin
        address <= MAR;
    end
    assign data = Control_Write ? MDR : {DATA_WIDTH{1'hz}};

    assign internal_databus = MDR_Read ? MDR
                                : (ALU_Out_Write ? ALU_out
                                    : (IR_Read ? IR
                                        : {DATA_WIDTH{1'hz}}));

    //////////////////////////////////////////////////////////////////////

    //////////////////////// Program Counter ////////////////////////////

    always_comb begin
        case (PC_Sel)
            0:       next_pc = PC + {ADDR_WIDTH{1'b0}};
            1:       next_pc = PC + 1;
            2:       next_pc = PC_Jump ? IR : PC;
            default: next_pc = PC + {ADDR_WIDTH{1'b0}};
        endcase
    end

    always_ff @(posedge clk) begin
        if (!reset_n) PC <= {ADDR_WIDTH{1'b0}};
        else if (!Halt) PC <= next_pc;
    end

    //////////////////////////////////////////////////////////////////////

endmodule
