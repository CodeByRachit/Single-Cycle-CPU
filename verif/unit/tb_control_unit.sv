`timescale 1ns/1ps

module tb_control_unit;
    logic [3:0] opcode;
    logic       RegWrite;
    logic       MemRead;
    logic       MemWrite;
    logic [2:0] ALUOp;
    logic       ALUSrc;
    logic       Branch;
    logic       BranchType;
    logic       Jump;
    logic       JAL;
    logic       RET;
    logic [1:0] MemtoReg;
    logic       ImmSrc;

    control_unit dut (
        .opcode(opcode),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .ALUOp(ALUOp),
        .ALUSrc(ALUSrc),
        .Branch(Branch),
        .BranchType(BranchType),
        .Jump(Jump),
        .JAL(JAL),
        .RET(RET),
        .MemtoReg(MemtoReg),
        .ImmSrc(ImmSrc)
    );

    int fd;
    int pass_count = 0;
    int fail_count = 0;

    task check_cu(
        input string name,
        input logic exp_RegWrite, input logic exp_MemRead, input logic exp_MemWrite,
        input logic [2:0] exp_ALUOp, input logic exp_ALUSrc, input logic exp_Branch,
        input logic exp_BranchType, input logic exp_Jump, input logic exp_JAL,
        input logic exp_RET, input logic [1:0] exp_MemtoReg, input logic exp_ImmSrc
    );
        #1;
        if (RegWrite !== exp_RegWrite || MemRead !== exp_MemRead || MemWrite !== exp_MemWrite ||
            ALUOp !== exp_ALUOp || ALUSrc !== exp_ALUSrc || Branch !== exp_Branch ||
            BranchType !== exp_BranchType || Jump !== exp_Jump || JAL !== exp_JAL ||
            RET !== exp_RET || MemtoReg !== exp_MemtoReg || ImmSrc !== exp_ImmSrc) begin
            
            $fdisplay(fd, "FAIL | Opcode: %s (0x%0x)", name, opcode);
            $fdisplay(fd, "       EXP: RW=%b MR=%b MW=%b ALU=%b ALUSrc=%b Br=%b BrT=%b J=%b JAL=%b RET=%b MtR=%b ISrc=%b",
                      exp_RegWrite, exp_MemRead, exp_MemWrite, exp_ALUOp, exp_ALUSrc, exp_Branch, exp_BranchType, exp_Jump, exp_JAL, exp_RET, exp_MemtoReg, exp_ImmSrc);
            $fdisplay(fd, "       ACT: RW=%b MR=%b MW=%b ALU=%b ALUSrc=%b Br=%b BrT=%b J=%b JAL=%b RET=%b MtR=%b ISrc=%b",
                      RegWrite, MemRead, MemWrite, ALUOp, ALUSrc, Branch, BranchType, Jump, JAL, RET, MemtoReg, ImmSrc);
            fail_count++;
        end else begin
            $fdisplay(fd, "PASS | Opcode: %s (0x%0x)", name, opcode);
            pass_count++;
        end
    endtask

    initial begin
        fd = $fopen("results/cu_report.log", "w");
        if (fd == 0) $fatal(1, "Could not open results/cu_report.log");
        $fdisplay(fd, "=== CONTROL UNIT TEST REPORT ===");
        
        //           name     RW MR MW ALU ALUSrc Br BrT J JAL RET MtR ISrc
        opcode = 0;  check_cu("ADD",  1, 0, 0, 0,  0,     0, 0,  0, 0,  0,  0,  0);
        opcode = 1;  check_cu("SUB",  1, 0, 0, 1,  0,     0, 0,  0, 0,  0,  0,  0);
        opcode = 2;  check_cu("AND",  1, 0, 0, 2,  0,     0, 0,  0, 0,  0,  0,  0);
        opcode = 3;  check_cu("OR",   1, 0, 0, 3,  0,     0, 0,  0, 0,  0,  0,  0);
        opcode = 4;  check_cu("XOR",  1, 0, 0, 4,  0,     0, 0,  0, 0,  0,  0,  0);
        opcode = 5;  check_cu("ADDI", 1, 0, 0, 0,  1,     0, 0,  0, 0,  0,  0,  0);
        opcode = 6;  check_cu("LW",   1, 1, 0, 0,  1,     0, 0,  0, 0,  0,  1,  0);
        opcode = 7;  check_cu("SW",   0, 0, 1, 0,  1,     0, 0,  0, 0,  0,  0,  0);
        opcode = 8;  check_cu("LUI",  1, 0, 0, 0,  0,     0, 0,  0, 0,  0,  3,  0);
        opcode = 9;  check_cu("BEQ",  0, 0, 0, 1,  0,     1, 0,  0, 0,  0,  0,  0);
        opcode = 10; check_cu("BNE",  0, 0, 0, 1,  0,     1, 1,  0, 0,  0,  0,  0);
        opcode = 11; check_cu("JMP",  0, 0, 0, 0,  0,     0, 0,  1, 0,  0,  0,  1);
        opcode = 12; check_cu("JAL",  1, 0, 0, 0,  0,     0, 0,  1, 1,  0,  2,  1);
        opcode = 13; check_cu("RET",  0, 0, 0, 0,  0,     0, 0,  0, 0,  1,  0,  0);
        
        // Invalid opcodes should default to all zeros
        opcode = 14; check_cu("INV14",0, 0, 0, 0,  0,     0, 0,  0, 0,  0,  0,  0);
        opcode = 15; check_cu("INV15",0, 0, 0, 0,  0,     0, 0,  0, 0,  0,  0,  0);

        $fdisplay(fd, "\n=== SUMMARY ===");
        $fdisplay(fd, "Passed: %0d", pass_count);
        $fdisplay(fd, "Failed: %0d", fail_count);
        $fclose(fd);
        $finish;
    end
endmodule
