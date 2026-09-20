`timescale 1ns/1ps

`include "cpu_item.sv"
`include "cpu_reference_model.sv"
`include "cpu_scoreboard.sv"

module tb_top;
    // Signals
    logic clk;
    logic rst_n;
    
    // Instantiate DUT
    cpu_top dut (
        .clk(clk),
        .rst_n(rst_n)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Testbench Objects
    cpu_item item;
    cpu_reference_model ref_model;
    cpu_scoreboard scoreboard;

    // Reset generation and main test
    initial begin
        // Waveform dumping (VCS format)
        $vcdplusfile("dump.vpd");
        $vcdpluson();
        
        item = new();
        ref_model = new();
        scoreboard = new(ref_model);

        rst_n = 0;
        #20;
        rst_n = 1;
        
        run_test();
        
        $display("Simulation completed successfully with 1000000 tests!");
        scoreboard.print_summary();
        $finish;
    end
    
    task run_test();
        // Boot Sequence: Initialize DUT Memory to 0 using SW instructions natively
        // This avoids ALL multiple driver (ICPD) errors by using the DUT's own datapath!
        for (int i = 0; i < 256; i++) begin
            // 1. SW R0, 0(R1) -> Write R0 (which is 0) to memory address in R1
            item.opcode = OP_SW;
            item.rs1 = 1;
            item.rs2 = 0;
            item.rd  = 0;
            item.imm = 12'b0;
            dut.imem.rom[dut.pc[7:0]] = item.to_inst();
            ref_model.update(item);
            @(posedge clk); #1;
            scoreboard.check(dut.rf.registers, dut.dmem.ram, dut.pc, item, 0);
            
            // 2. ADDI R1, R1, 1 -> Increment address pointer in R1
            item.opcode = OP_ADDI;
            item.rd  = 1;
            item.rs1 = 1;
            item.rs2 = 0;
            item.imm = 12'd1;
            dut.imem.rom[dut.pc[7:0]] = item.to_inst();
            ref_model.update(item);
            @(posedge clk); #1;
            scoreboard.check(dut.rf.registers, dut.dmem.ram, dut.pc, item, 0);
        end
        $display("Boot Sequence Complete: Memory initialized to 0");
        
        for (int i = 1; i <= 1000000; i++) begin
            if (!item.randomize()) begin
                $fatal(1, "Randomization failed!");
            end
            
            // Backdoor write instruction to DUT Instruction Memory at current PC
            dut.imem.rom[dut.pc[7:0]] = item.to_inst();
            
            // Update Reference Model with the same instruction
            ref_model.update(item);
            
            // Wait for a clock cycle to allow DUT to process
            @(posedge clk);
            #1; // Delay to let non-blocking assignments resolve
            
            // Verify DUT against Reference Model
            scoreboard.check(dut.rf.registers, dut.dmem.ram, dut.pc, item, i);
            
            if (i % 100000 == 0) begin
                $display("Completed %0d / 1000000 instructions", i);
            end
        end
    endtask
endmodule
