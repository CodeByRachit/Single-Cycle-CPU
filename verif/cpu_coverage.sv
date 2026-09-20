`ifndef CPU_COVERAGE_SV
`define CPU_COVERAGE_SV

`include "cpu_item.sv"

class cpu_coverage;
    cpu_item item;

    covergroup cg_cpu;
        option.per_instance = 1;
        
        // 1. Cover all instructions
        cp_opcode: coverpoint item.opcode {
            bins op_add  = {OP_ADD};
            bins op_sub  = {OP_SUB};
            bins op_and  = {OP_AND};
            bins op_or   = {OP_OR};
            bins op_xor  = {OP_XOR};
            bins op_addi = {OP_ADDI};
            bins op_lw   = {OP_LW};
            bins op_sw   = {OP_SW};
            bins op_lui  = {OP_LUI};
            bins op_beq  = {OP_BEQ};
            bins op_bne  = {OP_BNE};
            bins op_jmp  = {OP_JMP};
            bins op_jal  = {OP_JAL};
            bins op_ret  = {OP_RET};
        }

        // 2. Cover all destination registers
        cp_rd: coverpoint item.rd {
            bins R0 = {0}; // R0 should be hit (and RTL should ignore write)
            bins R1_to_R7[] = {[1:7]};
        }

        // 3. Cover all source registers
        cp_rs1: coverpoint item.rs1 {
            bins R0_to_R7[] = {[0:7]};
        }
        
        cp_rs2: coverpoint item.rs2 {
            bins R0_to_R7[] = {[0:7]};
        }

        // 4. Cross coverage: Ensure every instruction targets every destination register
        cr_opcode_rd: cross cp_opcode, cp_rd {
            // SW, BEQ, BNE, JMP, RET don't use RD, so ignore them
            ignore_bins no_rd = binsof(cp_opcode.op_sw) || binsof(cp_opcode.op_beq) ||
                                binsof(cp_opcode.op_bne) || binsof(cp_opcode.op_jmp) ||
                                binsof(cp_opcode.op_ret);
        }
    endgroup

    function new();
        cg_cpu = new();
    endfunction

    function void sample(cpu_item itm);
        this.item = itm;
        cg_cpu.sample();
    endfunction
endclass

`endif
