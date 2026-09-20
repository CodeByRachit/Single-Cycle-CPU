`ifndef CPU_ITEM_SV
`define CPU_ITEM_SV

typedef enum bit [3:0] {
    OP_ADD  = 4'b0000,
    OP_SUB  = 4'b0001,
    OP_AND  = 4'b0010,
    OP_OR   = 4'b0011,
    OP_XOR  = 4'b0100,
    OP_ADDI = 4'b0101,
    OP_LW   = 4'b0110,
    OP_SW   = 4'b0111,
    OP_LUI  = 4'b1000,
    OP_BEQ  = 4'b1001,
    OP_BNE  = 4'b1010,
    OP_JMP  = 4'b1011,
    OP_JAL  = 4'b1100,
    OP_RET  = 4'b1101
} opcode_t;

class cpu_item;
    rand opcode_t opcode;
    rand bit [2:0] rd;
    rand bit [2:0] rs1;
    rand bit [2:0] rs2;
    rand bit [11:0] imm;

    // Constrain opcode to valid types
    constraint c_opcode_valid {
        opcode inside {OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_ADDI, OP_LW, OP_SW, OP_LUI, OP_BEQ, OP_BNE, OP_JMP, OP_JAL, OP_RET};
    }

    // Distribution to stress branches, jumps, and memory ops
    constraint c_opcode_dist {
        opcode dist {
            [OP_ADD:OP_XOR] := 20, // R-type ALU
            OP_ADDI         := 10,
            [OP_LW:OP_SW]   := 30, // Memory (stress loads/stores)
            OP_LUI          := 5,
            [OP_BEQ:OP_JAL] := 30, // Branches and Jumps (stress control flow)
            OP_RET          := 5
        };
    }

    // Formatting constraints to keep unused fields clean
    constraint c_unused_fields {
        // R-Type uses rd, rs1, rs2 (except RET uses only rs1)
        if (opcode inside {OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR}) {
            imm == 12'b0;
        }
        if (opcode == OP_RET) {
            imm == 12'b0;
            rd == 3'b0;
            rs2 == 3'b0;
        }
        
        // I-Type uses rd, rs1, and imm[5:0]
        if (opcode inside {OP_ADDI, OP_LW, OP_SW, OP_BEQ, OP_BNE, OP_LUI}) {
            imm[11:6] == 6'b0; // Only lower 6 bits used
            if (opcode inside {OP_BEQ, OP_BNE, OP_SW}) { // These don't write to rd
                rd == 3'b0;
            }
            if (opcode == OP_LUI) { // LUI doesn't use rs1
                rs1 == 3'b0;
            }
        }
        
        // J-Type uses imm[11:0]
        if (opcode inside {OP_JMP, OP_JAL}) {
            rd == 3'b0;
            rs1 == 3'b0;
            rs2 == 3'b0;
        }
    }

    // Function to assemble the 16-bit instruction word based on format
    function bit [15:0] to_inst();
        case (opcode)
            // R-Type
            OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR: 
                return {opcode[3:0], rd[2:0], rs1[2:0], rs2[2:0], 3'b000};
            
            OP_RET:
                return {opcode[3:0], 3'b000, rs1[2:0], 6'b000000};
                
            // I-Type
            OP_ADDI, OP_LW, OP_SW, OP_BEQ, OP_BNE, OP_LUI:
                return {opcode[3:0], rd[2:0], rs1[2:0], imm[5:0]};
                
            // J-Type
            OP_JMP, OP_JAL:
                return {opcode[3:0], imm[11:0]};
                
            default: return 16'b0;
        endcase
    endfunction

    function void print(string name="cpu_item");
        $display("[%s] Opcode=%0s Rd=%0d Rs1=%0d Rs2=%0d Imm=0x%0x", name, opcode.name(), rd, rs1, rs2, imm);
    endfunction
endclass

`endif
