`timescale 1ns/1ps

module tb_reg_file;
    logic        clk;
    logic        rst_n;
    logic [2:0]  rs1_addr;
    logic [2:0]  rs2_addr;
    logic [2:0]  rd_addr;
    logic [15:0] write_data;
    logic        RegWrite;
    logic        JAL;
    logic [15:0] rs1_data;
    logic [15:0] rs2_data;

    reg_file dut (
        .clk(clk),
        .rst_n(rst_n),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .write_data(write_data),
        .RegWrite(RegWrite),
        .JAL(JAL),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    int fd;
    int pass_count = 0;
    int fail_count = 0;

    always #5 clk = ~clk;

    logic [15:0] shadow_regs [8];

    task init_shadow_regs();
        for (int i=0; i<8; i++) begin
            shadow_regs[i] = 16'b0;
        end
    endtask

    task automatic do_random_op();
        bit [2:0] write_target;
        
        rs1_addr = $random % 8;
        rs2_addr = $random % 8;
        rd_addr = $random % 8;
        write_data = $random;
        RegWrite = $random % 2;
        JAL = $random % 2;
        
        @(posedge clk);
        #1; // Allow asynchronous reads to propagate
        
        // Predict
        if (RegWrite) begin
            write_target = JAL ? 3'b111 : rd_addr;
            if (write_target != 3'b000) begin
                shadow_regs[write_target] = write_data;
            end
        end
        
        // Check
        if (rs1_data !== shadow_regs[rs1_addr]) begin
            $fdisplay(fd, "FAIL | Read RS1 | addr=%0d | EXP: 0x%0x | ACT: 0x%0x", rs1_addr, shadow_regs[rs1_addr], rs1_data);
            fail_count++;
        end else begin
            $fdisplay(fd, "PASS | Read RS1 | addr=%0d -> data=0x%0x", rs1_addr, rs1_data);
            pass_count++;
        end
        
        if (rs2_data !== shadow_regs[rs2_addr]) begin
            $fdisplay(fd, "FAIL | Read RS2 | addr=%0d | EXP: 0x%0x | ACT: 0x%0x", rs2_addr, shadow_regs[rs2_addr], rs2_data);
            fail_count++;
        end else begin
            $fdisplay(fd, "PASS | Read RS2 | addr=%0d -> data=0x%0x", rs2_addr, rs2_data);
            pass_count++;
        end
    endtask

    initial begin
        fd = $fopen("results/reg_file_report.log", "w");
        $fdisplay(fd, "=== REG_FILE UNIT TEST REPORT ===");
        
        clk = 0; rst_n = 0; rs1_addr = 0; rs2_addr = 0; rd_addr = 0; write_data = 0; RegWrite = 0; JAL = 0;
        init_shadow_regs();

        #18; rst_n = 1;
        
        // Random Tests
        for (int i = 0; i < 10000; i++) begin
            do_random_op();
        end

        $fdisplay(fd, "\n=== SUMMARY ===");
        $fdisplay(fd, "Passed: %0d", pass_count);
        $fdisplay(fd, "Failed: %0d", fail_count);
        $fclose(fd);
        $finish;
    end
endmodule
