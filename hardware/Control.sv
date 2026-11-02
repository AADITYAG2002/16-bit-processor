`include "opcode.sv"

`timescale 1ns / 100ps
`define ROM_ADDR_SIZE 4
`define ROM_DATA_SIZE 13
`define ROM_NUM_INST_SIZE 11
`define ROM_NOTHING `ROM_NUM_INST_SIZE - 1
`define STATE_END 255

module ROM (
    input  logic [`ROM_ADDR_SIZE - 1 : 0] rom_addr,
    output logic [`ROM_DATA_SIZE - 1 : 0] CTRL
);
    // localparam logic [`ROM_DATA_SIZE * (`ROM_NUM_INST_SIZE + 1) - 1:0] memory = {
    localparam logic [`ROM_DATA_SIZE - 1 : 0] memory[`ROM_NUM_INST_SIZE] = {
        /*
         * Reg_Read, Reg_Write,
         * Control_Read, Control_Write, Io_Read, IR_Write, IR_Read, MDR_Read, PC_Sel[2:0],
         * ALU_in_B_sel, ALU_Out_Write
         */

        // Fetch
        `ROM_DATA_SIZE'b0_0_1_0_0_0_0_1_001_0_0,  // MDR <- [PC]

        // Decode & Execute
        `ROM_DATA_SIZE'b1_1_0_0_0_0_0_0_000_0_0,  // Rd <- Rs
        `ROM_DATA_SIZE'b0_0_1_0_0_1_0_0_001_0_0,  // IR <- data
        `ROM_DATA_SIZE'b0_1_0_0_0_0_1_0_000_0_0,  // Rd <- IR
        `ROM_DATA_SIZE'b1_0_0_0_0_1_0_0_000_0_0,  // IR <- Rs
        `ROM_DATA_SIZE'b0_1_1_0_1_0_0_0_000_0_0,  // Rd <- [IR]
        `ROM_DATA_SIZE'b1_0_0_1_0_0_0_0_000_0_0,  // [IR] <- Rs
        `ROM_DATA_SIZE'b0_1_0_0_0_0_0_0_000_0_1,  // Rd <- ALU_out
        `ROM_DATA_SIZE'b0_0_0_0_0_0_0_0_010_0_0,  // Jump
        `ROM_DATA_SIZE'b0_0_0_0_0_0_0_0_000_1_0,  // ALU_in_B = 1

        // END / RESET
        `ROM_DATA_SIZE'b0_0_0_0_0_0_0_0_000_0_0  // Nothing
    };

    assign CTRL = memory[rom_addr];
    // assign CTRL     = memory[ `ROM_DATA_SIZE * rom_addr +: `ROM_DATA_SIZE ] | memory[ `ROM_DATA_SIZE * read_reg_addr +: `ROM_DATA_SIZE ] | memory[ `ROM_DATA_SIZE * write_reg_addr +: `ROM_DATA_SIZE ];
endmodule

module Control #(
    parameter unsigned DATA_WIDTH = 16
) (
    input logic                      reset_n,
    input logic                      clk,
    input logic [DATA_WIDTH - 1 : 0] MDR,
    input logic [             7 : 0] Flags,


    output logic Halt,

    output logic Reg_Read,
    output logic Reg_Write,
    output logic Control_Read,
    output logic Control_Write,
    output logic Io_Read,
    output logic IR_Write,
    output logic IR_Read,
    output logic MDR_Read,

    output logic [3 : 0] Reg_Read_Addr,
    output logic [3 : 0] Reg_Write_Addr,

    output logic [2 : 0] PC_Sel,
    output logic         PC_Jump,

    output logic         ALU_Enable,
    output logic [4 : 0] ALU_Op_Sel,
    output logic         ALU_in_B_Sel,
    output logic         ALU_Out_Write
);

    logic [`ROM_ADDR_SIZE - 1 : 0] rom_addr;
    logic [`ROM_DATA_SIZE - 1 : 0] CTRL;

    logic [3 : 0] dest_reg, src_reg;
    logic [1 : 0] mode;
    logic immd;
    logic [4 : 0] opcode;

    logic [7 : 0] state, next_state;

    ROM rom (
        .rom_addr(rom_addr),
        .CTRL    (CTRL)
    );

    assign {mode, immd, opcode, dest_reg, src_reg} = MDR;

    assign {Reg_Read, Reg_Write,
            Control_Read, Control_Write, Io_Read, IR_Write, IR_Read, MDR_Read,
            PC_Sel, ALU_in_B_Sel, ALU_Out_Write} = CTRL;

    always_comb begin
        if ((state == 1) && (mode == `DATA_MODE) && (opcode == `PUSH)) begin
            Reg_Read_Addr  = `SP_REG;
            Reg_Write_Addr = `A_REG;
        end else if ((state == 3) && (mode == `DATA_MODE) && (opcode == `PUSH)) begin
            Reg_Read_Addr  = `A_REG;
            Reg_Write_Addr = `SP_REG;
        end else if ((state == 4) && (mode == `DATA_MODE) && (opcode == `PUSH)) begin
            Reg_Read_Addr  = `SP_REG;
            Reg_Write_Addr = `A_REG;
        end else if ((state == 5) && (mode == `DATA_MODE) && (opcode == `PUSH)) begin
            Reg_Read_Addr  = src_reg;
            Reg_Write_Addr = `A_REG;
        end else if ((state == 1) && (mode == `DATA_MODE) && (opcode == `POP)) begin
            Reg_Read_Addr  = `SP_REG;
            Reg_Write_Addr = `A_REG;
        end else if ((state == 2) && (mode == `DATA_MODE) && (opcode == `POP)) begin
            Reg_Read_Addr  = `A_REG;
            Reg_Write_Addr = dest_reg;
        end else if ((state == 3) && (mode == `DATA_MODE) && (opcode == `POP)) begin
            Reg_Read_Addr  = `SP_REG;
            Reg_Write_Addr = `A_REG;
        end else if ((state == 5) && (mode == `DATA_MODE) && (opcode == `POP)) begin
            Reg_Read_Addr  = `A_REG;
            Reg_Write_Addr = `SP_REG;
        end else begin
            Reg_Read_Addr  = src_reg;
            Reg_Write_Addr = dest_reg;
        end
    end

    assign ALU_Op_Sel = ((mode == `DATA_MODE) && (opcode == `PUSH)) ?
        `SUB
        : ((mode == `DATA_MODE) && (opcode == `POP)) ?
        `ADD
        : opcode;

    assign ALU_Enable = ((mode == `DATA_MODE) && ((opcode == `PUSH) || (opcode == `POP)))
                            ? 1 : (mode == `ALU_MODE);

    always_comb begin
        logic c_flag, z_flag;
        {c_flag, z_flag} = Flags[1:0];
        if ((mode == `JUMP_MODE) && (state == 3)) begin
            case (opcode)
                `JUMP: PC_Jump = 1;
                `JUMP_NZ: PC_Jump = !z_flag;
                `JUMP_Z: PC_Jump = z_flag;
                `JUMP_NC: PC_Jump = !c_flag;
                `JUMP_C: PC_Jump = c_flag;
                default: PC_Jump = 0;
            endcase
        end else PC_Jump = 0;
    end

    always_ff @(posedge clk) begin
        if (!reset_n) state <= `STATE_END;
        else state <= next_state;
    end

    always_ff @(posedge clk) begin
        if (!reset_n) Halt <= 0;
        else if ((state == 1) && (mode == `IO_MODE) && (opcode == `HLT)) Halt <= 1;
    end

    always_comb begin
        if (!Halt) begin
            case (state)
                // Fetch
                0: begin
                    rom_addr   = 0;
                    next_state = 1;
                end

                // Decode & Execute
                1: begin
                    case (mode)
                        `IO_MODE: begin
                            case (opcode)
                                `NOP: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                                `HLT: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                                default: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                            endcase
                        end
                        `DATA_MODE: begin
                            case (opcode)
                                `MOV: begin
                                    rom_addr   = (immd == 1'b1) ? 2 : 1;
                                    next_state = (immd == 1'b1) ? 2 : `STATE_END;
                                end
                                `LDA: begin
                                    rom_addr   = (immd == 1'b1) ? 2 : 4;
                                    next_state = 2;
                                end
                                `STA: begin
                                    rom_addr   = (immd == 1'b1) ? 2 : 4;
                                    next_state = 2;
                                end
                                `PUSH: begin
                                    rom_addr   = 1;
                                    next_state = 2;
                                end
                                `POP: begin
                                    rom_addr   = 4;
                                    next_state = 2;
                                end
                                default: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                            endcase
                        end
                        `ALU_MODE: begin
                            case (opcode)
                                `ADD, `SUB, `MUL, `DIV, `AND, `OR, `XOR: begin
                                    rom_addr   = (immd == 1'b1) ? 2 : 4;
                                    next_state = 2;
                                end
                                `NOT, `RRS, `RRC, `LLS, `LLC: begin
                                    rom_addr   = 7;
                                    next_state = `STATE_END;
                                end
                                default: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                            endcase
                        end
                        `JUMP_MODE: begin
                            rom_addr   = 2;
                            next_state = 2;
                        end
                        default: begin
                        end
                    endcase
                end
                2: begin
                    case (mode)
                        `IO_MODE: begin
                        end
                        `DATA_MODE: begin
                            case (opcode)
                                `MOV: begin
                                    rom_addr   = 3;
                                    next_state = `STATE_END;
                                end
                                `LDA: begin
                                    rom_addr   = 5;
                                    next_state = `STATE_END;
                                end
                                `STA: begin
                                    rom_addr   = 6;
                                    next_state = `STATE_END;
                                end
                                `PUSH: begin
                                    rom_addr   = 9;
                                    next_state = 3;
                                end
                                `POP: begin
                                    rom_addr   = 5;
                                    next_state = 3;
                                end
                                default: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                            endcase
                        end
                        `ALU_MODE: begin
                            case (opcode)
                                `ADD, `SUB, `MUL, `DIV, `AND, `OR, `XOR: begin
                                    rom_addr   = 7;
                                    next_state = `STATE_END;
                                end
                                default: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                            endcase
                        end
                        `JUMP_MODE: begin
                            rom_addr   = 8;
                            next_state = `STATE_END;
                        end
                        default: begin
                        end
                    endcase
                end
                3: begin
                    case (mode)
                        `DATA_MODE: begin
                            case (opcode)
                                `PUSH: begin
                                    rom_addr   = 7;
                                    next_state = 4;
                                end
                                `POP: begin
                                    rom_addr   = 1;
                                    next_state = 4;
                                end
                                default: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                            endcase
                        end
                        default: begin
                        end
                    endcase
                end
                4: begin
                    case (mode)
                        `DATA_MODE: begin
                            case (opcode)
                                `PUSH: begin
                                    rom_addr   = 4;
                                    next_state = 5;
                                end
                                `POP: begin
                                    rom_addr   = 9;
                                    next_state = 5;
                                end
                                default: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                            endcase
                        end
                        default: begin
                        end
                    endcase
                end
                5: begin
                    case (mode)
                        `DATA_MODE: begin
                            case (opcode)
                                `PUSH: begin
                                    rom_addr   = 6;
                                    next_state = `STATE_END;
                                end
                                `POP: begin
                                    rom_addr   = 7;
                                    next_state = `STATE_END;
                                end
                                default: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                            endcase
                        end
                        default: begin
                        end
                    endcase
                end

                // End / Reset Cycle
                `STATE_END: begin
                    rom_addr   = `ROM_NOTHING;
                    next_state = 0;
                end

                default: begin
                end
            endcase
        end
    end

endmodule
