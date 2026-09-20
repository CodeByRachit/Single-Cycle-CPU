`ifndef CPU_REFERENCE_MODEL_SV
`define CPU_REFERENCE_MODEL_SV

`include "cpu_item.sv"

class cpu_reference_model;
    bit [15:0] shadow_regs [8];
    bit [15:0] shadow_mem [256];
    bit [15:0] shadow_pc;
    
    function new();
        for (int i = 0; i < 8; i++) shadow_regs[i] = 16'b0;
        for (int i = 0; i < 256; i++) shadow_mem[i] = 16'b0;
        shadow_pc = 16'b0;
    endfunction
    
    function void update(cpu_item item);
        bit [15:0] inst = item.to_inst();
        
        // Exact DUT decoding logic to match RTL quirks (e.g., I-Type using imm[5:3] as rs2)
        bit [3:0]  opcode = inst[15:12];
        bit [2:0]  rd     = inst[11:9];
        bit [2:0]  rs1    = inst[8:6];
        bit [2:0]  rs2    = inst[5:3];
        bit [11:0] imm    = inst[11:0];
        
        bit [15:0] rs1_data = shadow_regs[rs1];
        bit [15:0] rs2_data = shadow_regs[rs2];
        bit [15:0] rd_data  = shadow_regs[rd];
        bit [15:0] pc_plus_one = shadow_pc + 1;
        bit [15:0] next_pc = pc_plus_one;
        bit [15:0] alu_result;
        
        // Manual sign extension logic to exactly mirror RTL
        bit signed [15:0] sext_imm6  = {{10{imm[5]}}, imm[5:0]};
        bit signed [15:0] sext_imm12 = {{4{imm[11]}}, imm[11:0]};
        
        case (opcode)
            OP_ADD:  shadow_regs[rd] = rs1_data + rs2_data;
            OP_SUB:  shadow_regs[rd] = rs1_data - rs2_data;
            OP_AND:  shadow_regs[rd] = rs1_data & rs2_data;
            OP_OR:   shadow_regs[rd] = rs1_data | rs2_data;
            OP_XOR:  shadow_regs[rd] = rs1_data ^ rs2_data;
            
            OP_ADDI: shadow_regs[rd] = rs1_data + sext_imm6;
            
            OP_LW:   begin
                alu_result = rs1_data + sext_imm6;
                shadow_regs[rd] = shadow_mem[alu_result[7:0]];
            end
            
            OP_SW:   begin
                alu_result = rs1_data + sext_imm6;
                shadow_mem[alu_result[7:0]] = rd_data;
            end
            
            OP_LUI:  shadow_regs[rd] = {imm[5:0], 10'b0};
            
            OP_BEQ:  if (rs1_data == rd_data) next_pc = shadow_pc + sext_imm6;
            OP_BNE:  if (rs1_data != rd_data) next_pc = shadow_pc + sext_imm6;
            
            OP_JMP:  next_pc = shadow_pc + sext_imm12;
            
            OP_JAL:  begin
                shadow_regs[7] = pc_plus_one;
                next_pc = shadow_pc + sext_imm12;
            end
            
            OP_RET:  next_pc = rs1_data;
        endcase
        
        shadow_pc = next_pc;
        shadow_regs[0] = 16'b0; // Hardwire R0 to 0
    endfunction
endclass

`endif
