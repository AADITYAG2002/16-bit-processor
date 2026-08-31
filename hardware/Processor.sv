module Processor #(
    parameter unsigned ADDR_WIDTH = 16,
    parameter unsigned DATA_WIDTH = 16
) (
    output logic [ADDR_WIDTH - 1:0] address,
    inout  logic [DATA_WIDTH - 1:0] data,
    output bit                      read_mem,
    output bit                      write_mem,
    input  bit                      reset_n,
    input  logic                    clk
);

    ////////////////////////  Declaration & Inittialization  ///////////////////////////////
    // Registers & flags
    logic [ADDR_WIDTH - 1 : 0] PC, SP;
    logic [DATA_WIDTH - 1 : 0] MDR, IR;
    logic Z_flag, C_flag;

    // control signals
    logic
        Reg_Write,
        Reg_Read,
        Control_Read,
        IR_Read,
        MDR_Read,
        Io_Read,
        Control_Write,
        PC_Sel,
        ALU_In_1,
        ALU_In_2,
        ALU_Out_Write;
    logic [3:0] ALU_Op_Sel;
    logic [2 : 0] Reg_Read_Addr, Reg_Write_Addr;
    logic [DATA_WIDTH - 1 : 0] Read_Addr, Write_Addr;

    // interconnect wires & reg
    logic [DATA_WIDTH - 1 : 0] internal_databus;
    logic [ADDR_WIDTH - 1 : 0] next_pc;
    logic [DATA_WIDTH - 1 : 0] ALU_Src_A, ALU_Src_B, ALU_out;

    // ALU
    Alu alu (
        .A_reg     (ALU_Src_A),
        .B_reg     (ALU_Src_B),
        .op_select (ALU_Op_Sel),
        .ALU_output(ALU_out),
        .Z_flag    (Z_flag),
        .C_flag    (C_flag)
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

    // Control Unit
    Control control (
        .reset_n       (reset_n),
        .clk           (clk),
        .instruction   (MDR),
        .Reg_Write     (Reg_Write),
        .Reg_Read      (Reg_Read),
        .Control_Read  (Control_Read),
        .Control_Write (Control_Write),
        .Io_Read       (Io_Read),
        .IR_Read       (IR_Read),
        .MDR_Read      (MDR_Read),
        .PC_Sel        (PC_Sel),
        .Z_flag        (Z_flag),
        .C_flag        (Z_flag),
        .ALU_In_1      (ALU_In_1),
        .ALU_In_2      (ALU_In_2),
        .ALU_Op_Sel    (ALU_Op_Sel),
        .ALU_Out_Write (ALU_Out_Write),
        .Reg_Read_Addr (Reg_Read_Addr),
        .Reg_Write_Addr(Reg_Write_Addr),
        .Read_Addr     (Read_Addr),
        .Write_Addr    (Write_Addr)
    );

    ////////////////////////////////////////////////////////////////////////////////////////

    ////////////////////////  Memory Access  ////////////////////////////

    // Read from memory (via pointer in register) to a register
    assign internal_databus = ALU_Out_Write ? ALU_out : read_mem ? data : {DATA_WIDTH{1'hz}};

    // Write to memory (via pointer in register) from a register
    assign data             = write_mem ? internal_databus : {DATA_WIDTH{1'hz}};

    always_comb begin
        if (Control_Read) begin
            address  = Io_Read ? Read_Addr : PC;
            read_mem = 1;
            IR       = IR_Read ? internal_databus : {DATA_WIDTH{1'b0}};
            MDR      = MDR_Read ? internal_databus : {DATA_WIDTH{1'b0}};
        end else begin
            address  = {DATA_WIDTH{1'hz}};
            read_mem = 0;
        end
        if (Control_Write) begin
            address   = Write_Addr;
            write_mem = 1;
        end else begin
            address   = {DATA_WIDTH{1'hz}};
            write_mem = 0;
        end
    end

    //////////////////////////////////////////////////////////////////////

    ////////////////////////  ALU  ////////////////////////////

    always_comb begin
        case (ALU_In_1)
            1: ALU_Src_A = internal_databus;
            default: begin
                ALU_Src_A = {DATA_WIDTH{1'b0}};
            end
        endcase
        case (ALU_In_2)
            0: ALU_Src_B = internal_databus;
            1: ALU_Src_B = IR;
            default: begin
                ALU_Src_B = {DATA_WIDTH{1'b0}};
            end
        endcase
    end

    ///////////////////////////////////////////////////////////

    ////////////////////////  CPU reset Program Counter ////////////////////////////

    always_comb begin
        case (PC_Sel)
            0: next_pc = PC + 1'b1;
            1: next_pc = IR;
            default: begin
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset_n) PC <= next_pc;
        else PC <= {ADDR_WIDTH{1'b0}};
    end

    //////////////////////////////////////////////////////////////////////


endmodule

