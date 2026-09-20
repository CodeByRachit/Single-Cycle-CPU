`timescale 1ns/1ps

module tb_imm_gen;
    logic [11:0] inst_imm;
    logic        ImmSrc;
    logic [15:0] ext_imm;
    logic [15:0] lui_out;

    imm_gen dut (
        .inst_imm(inst_imm),
        .ImmSrc(ImmSrc),
        .ext_imm(ext_imm),
        .lui_out(lui_out)
    );

    int fd;
    int pass_count = 0;
    int fail_count = 0;

    task automatic predict_and_check();
        logic signed [15:0] exp_ext;
        logic [15:0] exp_lui;

        if (ImmSrc == 0) begin
            exp_ext = {{10{inst_imm[5]}}, inst_imm[5:0]};
        end else begin
            exp_ext = {{4{inst_imm[11]}}, inst_imm[11:0]};
        end
        
        exp_lui = {inst_imm[5:0], 10'b0};

        #1;
        if (ext_imm !== exp_ext || lui_out !== exp_lui) begin
            $fdisplay(fd, "FAIL | Input: 0x%0x ImmSrc: %b | EXP: ext=0x%0x lui=0x%0x | ACT: ext=0x%0x lui=0x%0x", 
                      inst_imm, ImmSrc, exp_ext, exp_lui, ext_imm, lui_out);
            fail_count++;
        end else begin
            $fdisplay(fd, "PASS | Input: 0x%0x ImmSrc: %b -> ext=0x%0x lui=0x%0x", 
                      inst_imm, ImmSrc, ext_imm, lui_out);
            pass_count++;
        end
    endtask

    initial begin
        fd = $fopen("results/imm_gen_report.log", "w");
        if (fd == 0) $fatal(1, "Could not open results/imm_gen_report.log");
        $fdisplay(fd, "=== IMM_GEN UNIT TEST REPORT ===");
        
        // Random Tests
        for (int i = 0; i < 10000; i++) begin
            inst_imm = $random;
            ImmSrc = $random % 2;
            predict_and_check();
        end

        $fdisplay(fd, "\n=== SUMMARY ===");
        $fdisplay(fd, "Passed: %0d", pass_count);
        $fdisplay(fd, "Failed: %0d", fail_count);
        $fclose(fd);
        $finish;
    end
endmodule
