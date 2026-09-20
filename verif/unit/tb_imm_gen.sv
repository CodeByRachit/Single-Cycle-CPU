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

    task check_imm(input string name, input logic [15:0] exp_ext, input logic [15:0] exp_lui);
        #1;
        if (ext_imm !== exp_ext || lui_out !== exp_lui) begin
            $fdisplay(fd, "FAIL | %s | Input: 0x%0x ImmSrc: %b | EXP: ext=0x%0x lui=0x%0x | ACT: ext=0x%0x lui=0x%0x", 
                      name, inst_imm, ImmSrc, exp_ext, exp_lui, ext_imm, lui_out);
            fail_count++;
        end else begin
            $fdisplay(fd, "PASS | %s | Input: 0x%0x ImmSrc: %b -> ext=0x%0x lui=0x%0x", 
                      name, inst_imm, ImmSrc, ext_imm, lui_out);
            pass_count++;
        end
    endtask

    initial begin
        fd = $fopen("results/imm_gen_report.log", "w");
        if (fd == 0) $fatal(1, "Could not open results/imm_gen_report.log");
        $fdisplay(fd, "=== IMM_GEN UNIT TEST REPORT ===");
        
        // Test I-Type (ImmSrc = 0) - Positive
        inst_imm = 12'h015; // 6-bit is 010101 (21)
        ImmSrc = 0;
        check_imm("I-Type Pos", 16'h0015, {12'h015 & 12'h03F, 10'b0}); // {6'h15, 10'b0} = 0x5400
        
        // Test I-Type (ImmSrc = 0) - Negative
        inst_imm = 12'hF25; // 6-bit is 100101 (-27) -> sext to 16'hFFe5
        ImmSrc = 0;
        check_imm("I-Type Neg", 16'hFFE5, {12'hF25 & 12'h03F, 10'b0});
        
        // Test J-Type (ImmSrc = 1) - Positive
        inst_imm = 12'h015;
        ImmSrc = 1;
        check_imm("J-Type Pos", 16'h0015, {12'h015 & 12'h03F, 10'b0});
        
        // Test J-Type (ImmSrc = 1) - Negative
        inst_imm = 12'h815; // 12-bit is negative
        ImmSrc = 1;
        check_imm("J-Type Neg", 16'hF815, {12'h815 & 12'h03F, 10'b0});

        // Test Max/Min bounds
        inst_imm = 12'hFFF;
        ImmSrc = 0;
        check_imm("I-Type -1", 16'hFFFF, {6'h3F, 10'b0});
        
        inst_imm = 12'hFFF;
        ImmSrc = 1;
        check_imm("J-Type -1", 16'hFFFF, {6'h3F, 10'b0});

        $fdisplay(fd, "\n=== SUMMARY ===");
        $fdisplay(fd, "Passed: %0d", pass_count);
        $fdisplay(fd, "Failed: %0d", fail_count);
        $fclose(fd);
        $finish;
    end
endmodule
