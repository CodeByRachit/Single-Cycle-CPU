`ifndef CPU_SCOREBOARD_SV
`define CPU_SCOREBOARD_SV

`include "cpu_reference_model.sv"

class cpu_scoreboard;
    cpu_reference_model ref_model;
    int fd;
    int pass_count = 0;
    int fail_count = 0;
    
    function new(cpu_reference_model r);
        this.ref_model = r;
        fd = $fopen("results/test_report.log", "w");
        if (fd == 0) $fatal(1, "Could not open results/test_report.log");
        $fdisplay(fd, "=========================================================================================");
        $fdisplay(fd, "                            CPU VERIFICATION REPORT                                      ");
        $fdisplay(fd, "=========================================================================================");
    endfunction
    
    function void check(bit [15:0] dut_regs[7:0], bit [15:0] dut_mem[0:255], bit [15:0] dut_pc, cpu_item item, int test_num);
        bit mismatch = 0;
        string err_msg = "";
        
        // Check PC
        if (dut_pc !== ref_model.shadow_pc) begin
            err_msg = {err_msg, $sformatf(" [PC Mismatch: DUT=0x%0x EXP=0x%0x]", dut_pc, ref_model.shadow_pc)};
            mismatch = 1;
        end
        
        // Check Registers
        for (int i = 0; i < 8; i++) begin
            if (dut_regs[i] !== ref_model.shadow_regs[i]) begin
                err_msg = {err_msg, $sformatf(" [R%0d Mismatch: DUT=0x%0x EXP=0x%0x]", i, dut_regs[i], ref_model.shadow_regs[i])};
                mismatch = 1;
            end
        end
        
        // Check Memory
        for (int i = 0; i < 256; i++) begin
            if (dut_mem[i] !== ref_model.shadow_mem[i]) begin
                err_msg = {err_msg, $sformatf(" [Mem[0x%0x] Mismatch: DUT=0x%0x EXP=0x%0x]", i, dut_mem[i], ref_model.shadow_mem[i])};
                mismatch = 1;
            end
        end
        
        if (mismatch) begin
            fail_count++;
            $fdisplay(fd, "[Test %0d] FAIL | Inst: %0s Rd=%0d Rs1=%0d Rs2=%0d Imm=0x%0x | %s", 
                      test_num, item.opcode.name(), item.rd, item.rs1, item.rs2, item.imm, err_msg);
        end else begin
            pass_count++;
            $fdisplay(fd, "[Test %0d] PASS | Inst: %0s Rd=%0d Rs1=%0d Rs2=%0d Imm=0x%0x | PC: 0x%0x", 
                      test_num, item.opcode.name(), item.rd, item.rs1, item.rs2, item.imm, dut_pc);
        end
    endfunction
    
    function void print_summary();
        $fdisplay(fd, "=========================================================================================");
        $fdisplay(fd, "                                 SUMMARY                                                 ");
        $fdisplay(fd, "=========================================================================================");
        $fdisplay(fd, "Total Tests Run: %0d", pass_count + fail_count);
        $fdisplay(fd, "Passed         : %0d", pass_count);
        $fdisplay(fd, "Failed         : %0d", fail_count);
        $fdisplay(fd, "=========================================================================================");
        $fclose(fd);
        
        $display("\n========================================");
        $display("Verification Summary:");
        $display("Total: %0d | Pass: %0d | Fail: %0d", pass_count + fail_count, pass_count, fail_count);
        $display("Detailed report saved in results/test_report.log");
        $display("========================================");
        
        if (fail_count > 0) $fatal(1, "Simulation FAILED with %0d errors", fail_count);
    endfunction
endclass

`endif
