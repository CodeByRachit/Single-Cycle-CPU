`timescale 1ns/1ps

module tb_alu;
    logic [15:0] A;
    logic [15:0] B;
    logic [2:0]  ALUOp;
    logic [15:0] Result;
    logic        Zero;

    alu dut (
        .A(A),
        .B(B),
        .ALUOp(ALUOp),
        .Result(Result),
        .Zero(Zero)
    );

    int fd;
    int pass_count = 0;
    int fail_count = 0;

    task check_alu(input string op_name, input logic [15:0] exp_res, input logic exp_zero);
        #1;
        if (Result !== exp_res || Zero !== exp_zero) begin
            $fdisplay(fd, "FAIL | Op: %s A: 0x%0x B: 0x%0x | EXP: Res=0x%0x Z=%b | ACT: Res=0x%0x Z=%b", 
                      op_name, A, B, exp_res, exp_zero, Result, Zero);
            fail_count++;
        end else begin
            $fdisplay(fd, "PASS | Op: %s A: 0x%0x B: 0x%0x -> Res=0x%0x Z=%b", 
                      op_name, A, B, Result, Zero);
            pass_count++;
        end
    endtask

    initial begin
        fd = $fopen("results/alu_report.log", "w");
        if (fd == 0) $fatal(1, "Could not open results/alu_report.log");
        $fdisplay(fd, "=== ALU UNIT TEST REPORT ===");
        
        // Random Tests
        for (int i = 0; i < 1000; i++) begin
            A = $random;
            B = $random;
            ALUOp = $random % 5;
            
            case (ALUOp)
                3'b000: check_alu("ADD", A + B, A == B);
                3'b001: check_alu("SUB", A - B, A == B);
                3'b010: check_alu("AND", A & B, A == B);
                3'b011: check_alu("OR",  A | B, A == B);
                3'b100: check_alu("XOR", A ^ B, A == B);
            endcase
        end

        // Edge case: A == B
        A = 16'h5555;
        B = 16'h5555;
        ALUOp = 3'b001; // SUB
        check_alu("SUB(EQ)", 16'h0, 1'b1);

        $fdisplay(fd, "\n=== SUMMARY ===");
        $fdisplay(fd, "Passed: %0d", pass_count);
        $fdisplay(fd, "Failed: %0d", fail_count);
        $fclose(fd);
        $finish;
    end
endmodule
