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

    initial begin
        fd = $fopen("results/reg_file_report.log", "w");
        $fdisplay(fd, "=== REG_FILE UNIT TEST REPORT ===");
        
        clk = 0; rst_n = 0; rs1_addr = 0; rs2_addr = 0; rd_addr = 0; write_data = 0; RegWrite = 0; JAL = 0;

        #18; rst_n = 1;
        
        #10; rd_addr = 0; write_data = 16'hFFFF; RegWrite = 1;
        #10; RegWrite = 0;
        
        #10; rs1_addr = 0;
        #1;  
        if (rs1_data !== 16'h0000) begin
            $fdisplay(fd, "FAIL | Write to R0 ignored | EXP: rs1=0x0000 | ACT: rs1=0x%0x", rs1_data);
            fail_count++;
        end else begin
            $fdisplay(fd, "PASS | Write to R0 ignored -> rs1=0x0 rs2=0x0");
            pass_count++;
        end

        #10; rd_addr = 1; write_data = 16'hAAAA; RegWrite = 1;
        #10; RegWrite = 0;

        #10; rd_addr = 2; write_data = 16'hBBBB; RegWrite = 1;
        #10; RegWrite = 0;

        #10; rs1_addr = 1; rs2_addr = 2;
        #1;
        $display("[TB DEBUG] T=%0t | rs1_addr=%0d rs2_addr=%0d | rs1_data=0x%h rs2_data=0x%h", $time, rs1_addr, rs2_addr, rs1_data, rs2_data);
        if (rs1_data !== 16'hAAAA || rs2_data !== 16'hBBBB) begin
            $fdisplay(fd, "FAIL | Normal Write/Read R1 and R2 | EXP: rs1=0xaaaa rs2=0xbbbb | ACT: rs1=0x%0x rs2=0x%0x", rs1_data, rs2_data);
            fail_count++;
        end else begin
            $fdisplay(fd, "PASS | Normal Write/Read R1 and R2 -> rs1=0x%0x rs2=0x%0x", rs1_data, rs2_data);
            pass_count++;
        end

        #10; rd_addr = 3; write_data = 16'h4321; RegWrite = 1; JAL = 1;
        #10; RegWrite = 0; JAL = 0;

        #10; rs1_addr = 3; rs2_addr = 7;
        #1;  
        $display("[TB DEBUG] T=%0t | rs1_addr=%0d rs2_addr=%0d | rs1_data=0x%h rs2_data=0x%h", $time, rs1_addr, rs2_addr, rs1_data, rs2_data);
        if (rs2_data !== 16'h4321) begin
            $fdisplay(fd, "FAIL | JAL writes to R7, ignoring rd_addr | EXP: rs1=0x0 rs2=0x4321 | ACT: rs1=0x%0x rs2=0x%0x", rs1_data, rs2_data);
            fail_count++;
        end else begin
            $fdisplay(fd, "PASS | JAL writes to R7, ignoring rd_addr -> rs1=0x%0x rs2=0x%0x", rs1_data, rs2_data);
            pass_count++;
        end

        $fdisplay(fd, "\n=== SUMMARY ===");
        $fdisplay(fd, "Passed: %0d", pass_count);
        $fdisplay(fd, "Failed: %0d", fail_count);
        $fclose(fd);
        $finish;
    end
endmodule
