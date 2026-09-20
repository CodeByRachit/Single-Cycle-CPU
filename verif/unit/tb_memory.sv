`timescale 1ns/1ps

module tb_memory;
    logic        clk;
    logic [15:0] pc;
    logic [15:0] instruction;
    
    logic [15:0] addr;
    logic [15:0] write_data;
    logic        MemRead;
    logic        MemWrite;
    logic [15:0] read_data;

    instruction_memory imem (
        .pc(pc),
        .instruction(instruction)
    );

    data_memory dmem (
        .clk(clk),
        .addr(addr),
        .write_data(write_data),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .read_data(read_data)
    );

    int fd;
    int pass_count = 0;
    int fail_count = 0;

    // Clock generation
    always #5 clk = ~clk;

    task check_mem(input string name, input logic [15:0] exp_data, input logic [15:0] act_data);
        if (act_data !== exp_data) begin
            $fdisplay(fd, "FAIL | %s | EXP: 0x%0x | ACT: 0x%0x", name, exp_data, act_data);
            fail_count++;
        end else begin
            $fdisplay(fd, "PASS | %s -> 0x%0x", name, act_data);
            pass_count++;
        end
    endtask

    logic [15:0] shadow_rom [256];
    logic [15:0] shadow_ram [256];

    task automatic init_shadow_mem();
        for (int i=0; i<256; i++) begin
            shadow_rom[i] = $urandom;
            imem.rom[i] = shadow_rom[i];
            shadow_ram[i] = 16'hx; // ASIC RAMs are uninitialized
        end
    endtask

    task automatic do_random_op();
        bit [1:0] op_type = $urandom % 3; // 0: Read, 1: Write, 2: Idle
        addr = $urandom % 256;
        write_data = $urandom;
        pc = $urandom % 256; // Also read random ROM address
        
        MemRead = (op_type == 0);
        MemWrite = (op_type == 1);
        
        @(posedge clk);
        #1; // Allow asynchronous reads to propagate
        
        // Predict
        if (MemWrite) begin
            shadow_ram[addr[7:0]] = write_data;
        end
        
        // Check ROM
        check_mem("IMEM Read", shadow_rom[pc[7:0]], instruction);
        
        // Check RAM
        if (MemRead) begin
            check_mem("DMEM Read", shadow_ram[addr[7:0]], read_data);
        end else begin
            check_mem("DMEM Read Disabled", 16'h0000, read_data);
        end
    endtask

    initial begin
        fd = $fopen("results/memory_report.log", "w");
        if (fd == 0) $fatal(1, "Could not open results/memory_report.log");
        $fdisplay(fd, "=== MEMORY UNIT TEST REPORT ===");
        
        clk = 0;
        MemRead = 0;
        MemWrite = 0;
        addr = 0;
        write_data = 0;
        pc = 0;

        init_shadow_mem();
        
        // Let initialization settle
        @(posedge clk);
        
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
