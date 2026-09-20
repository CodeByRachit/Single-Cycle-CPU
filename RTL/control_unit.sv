module control_unit (
    input  logic [3:0] opcode,
    output logic       RegWrite,
    output logic       MemRead,
    output logic       MemWrite,
    output logic [2:0] ALUOp,
    output logic       ALUSrc,
    output logic       Branch,
    output logic       BranchType,
    output logic       Jump,
    output logic       JAL,
    output logic       RET,
    output logic [1:0] MemtoReg,
    output logic       ImmSrc
);
    // ALUOp encoding
    // 000: ADD
    // 001: SUB
    // 010: AND
    // 011: OR
    // 100: XOR

    // MemtoReg encoding
    // 00: ALU Result
    // 01: Data Memory
    // 10: PC + 1
    // 11: LUI output

    always_comb begin
        // Default values
        RegWrite   = 1'b0;
        MemRead    = 1'b0;
        MemWrite   = 1'b0;
        ALUOp      = 3'b000;
        ALUSrc     = 1'b0;
        Branch     = 1'b0;
        BranchType = 1'b0;
        Jump       = 1'b0;
        JAL        = 1'b0;
        RET        = 1'b0;
        MemtoReg   = 2'b00;
        ImmSrc     = 1'b0;

        case (opcode)
            4'b0000: begin // ADD
                RegWrite = 1'b1;
                ALUOp    = 3'b000;
            end
            4'b0001: begin // SUB
                RegWrite = 1'b1;
                ALUOp    = 3'b001;
            end
            4'b0010: begin // AND
                RegWrite = 1'b1;
                ALUOp    = 3'b010;
            end
            4'b0011: begin // OR
                RegWrite = 1'b1;
                ALUOp    = 3'b011;
            end
            4'b0100: begin // XOR
                RegWrite = 1'b1;
                ALUOp    = 3'b100;
            end
            4'b0101: begin // ADDI
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 3'b000;
            end
            4'b0110: begin // LW
                RegWrite = 1'b1;
                MemRead  = 1'b1;
                ALUSrc   = 1'b1;
                MemtoReg = 2'b01;
                ALUOp    = 3'b000; // ADD for address calc
            end
            4'b0111: begin // SW
                MemWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 3'b000; // ADD for address calc
            end
            4'b1000: begin // LUI
                RegWrite = 1'b1;
                MemtoReg = 2'b11;
            end
            4'b1001: begin // BEQ
                Branch     = 1'b1;
                BranchType = 1'b0;
                ALUOp      = 3'b001; // SUB for comparison
            end
            4'b1010: begin // BNE
                Branch     = 1'b1;
                BranchType = 1'b1;
                ALUOp      = 3'b001; // SUB for comparison
            end
            4'b1011: begin // JMP
                Jump   = 1'b1;
                ImmSrc = 1'b1; // 12-bit
            end
            4'b1100: begin // JAL
                RegWrite = 1'b1;
                Jump     = 1'b1;
                JAL      = 1'b1;
                MemtoReg = 2'b10;
                ImmSrc   = 1'b1; // 12-bit
            end
            4'b1101: begin // RET
                RET = 1'b1;
            end
            default: ; // Use default values
        endcase
    end
endmodule
