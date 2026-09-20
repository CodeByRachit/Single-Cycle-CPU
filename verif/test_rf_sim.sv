`timescale 1ns/1ps
module test_rf_sim;
    logic clk, rst_n, RegWrite, JAL;
    logic [2:0] rs1_addr, rs2_addr, rd_addr;
    logic [15:0] write_data, rs1_data, rs2_data;

    reg_file dut(.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; rd_addr = 0; write_data = 0; RegWrite = 0; JAL = 0;
        $monitor("T=%0t clk=%b rst_n=%b RegWrite=%b rd_addr=%0d JAL=%b write_data=%0h | R1=%0h R2=%0h R7=%0h", 
                 $time, clk, rst_n, RegWrite, rd_addr, JAL, write_data, dut.registers[1], dut.registers[2], dut.registers[7]);
        
        #15 rst_n = 1;
        #10;
        
        // Write R1
        @(negedge clk);
        rd_addr = 1; write_data = 16'hAAAA; RegWrite = 1;
        @(negedge clk);
        RegWrite = 0;
        
        // Write R2
        @(negedge clk);
        rd_addr = 2; write_data = 16'hBBBB; RegWrite = 1;
        @(negedge clk);
        RegWrite = 0;
        
        // Write R7
        @(negedge clk);
        rd_addr = 0; write_data = 16'h4321; RegWrite = 1; JAL = 1;
        @(negedge clk);
        RegWrite = 0; JAL = 0;
        
        #10;
        $finish;
    end
endmodule
