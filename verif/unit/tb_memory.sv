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

        // Note: IMEM is a ROM. For unit testing, it might be uninitialized unless we backdoor write.
        // We will backdoor write to test it.
        imem.rom[0] = 16'h1234;
        imem.rom[5] = 16'hABCD;
        
        #1;
        pc = 0;
        #1 check_mem("IMEM Read Addr 0", 16'h1234, instruction);
        
        pc = 16'd5;
        #1 check_mem("IMEM Read Addr 5", 16'hABCD, instruction);

        // Test DMEM Write and Read
        @(posedge clk);
        addr = 16'h0010;
        write_data = 16'hBEEF;
        MemWrite = 1;
        MemRead = 0;
        @(posedge clk); // Write happens
        MemWrite = 0;
        MemRead = 1;
        #1; // Asynchronous read data valid
        check_mem("DMEM Read Addr 0x10 after Write", 16'hBEEF, read_data);

        // Test DMEM Read Disable
        MemRead = 0;
        #1;
        check_mem("DMEM Read Disable (Hi-Z expected)", 16'h0000, read_data); // RTL defines 0 when MemRead=0

        $fdisplay(fd, "\n=== SUMMARY ===");
        $fdisplay(fd, "Passed: %0d", pass_count);
        $fdisplay(fd, "Failed: %0d", fail_count);
        $fclose(fd);
        $finish;
    end
endmodule
