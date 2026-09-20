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

    task automatic predict_and_check();
        logic exp_RegWrite = 0, exp_MemRead = 0, exp_MemWrite = 0;
        logic [2:0] exp_ALUOp = 0;
        logic exp_ALUSrc = 0, exp_Branch = 0, exp_BranchType = 0;
        logic exp_Jump = 0, exp_JAL = 0, exp_RET = 0;
        logic [1:0] exp_MemtoReg = 0;
        logic exp_ImmSrc = 0;

        case (opcode)
            4'b0000: begin exp_RegWrite=1; exp_ALUOp=0; end // ADD
            4'b0001: begin exp_RegWrite=1; exp_ALUOp=1; end // SUB
            4'b0010: begin exp_RegWrite=1; exp_ALUOp=2; end // AND
            4'b0011: begin exp_RegWrite=1; exp_ALUOp=3; end // OR
            4'b0100: begin exp_RegWrite=1; exp_ALUOp=4; end // XOR
            4'b0101: begin exp_RegWrite=1; exp_ALUOp=0; exp_ALUSrc=1; end // ADDI
            4'b0110: begin exp_RegWrite=1; exp_ALUOp=0; exp_ALUSrc=1; exp_MemRead=1; exp_MemtoReg=1; end // LW
            4'b0111: begin exp_MemWrite=1; exp_ALUOp=0; exp_ALUSrc=1; end // SW
            4'b1000: begin exp_RegWrite=1; exp_MemtoReg=3; end // LUI
            4'b1001: begin exp_Branch=1; exp_ALUOp=1; end // BEQ
            4'b1010: begin exp_Branch=1; exp_ALUOp=1; exp_BranchType=1; end // BNE
            4'b1011: begin exp_Jump=1; exp_ImmSrc=1; end // JMP
            4'b1100: begin exp_Jump=1; exp_JAL=1; exp_RegWrite=1; exp_MemtoReg=2; exp_ImmSrc=1; end // JAL
            4'b1101: begin exp_RET=1; end // RET
            default: ; // All zeros for invalid
        endcase

        #1;
        if (RegWrite !== exp_RegWrite || MemRead !== exp_MemRead || MemWrite !== exp_MemWrite ||
            ALUOp !== exp_ALUOp || ALUSrc !== exp_ALUSrc || Branch !== exp_Branch ||
            BranchType !== exp_BranchType || Jump !== exp_Jump || JAL !== exp_JAL ||
            RET !== exp_RET || MemtoReg !== exp_MemtoReg || ImmSrc !== exp_ImmSrc) begin
            
            $fdisplay(fd, "FAIL | Opcode: 0x%0x", opcode);
            $fdisplay(fd, "       EXP: RW=%b MR=%b MW=%b ALU=%b ALUSrc=%b Br=%b BrT=%b J=%b JAL=%b RET=%b MtR=%b ISrc=%b",
                      exp_RegWrite, exp_MemRead, exp_MemWrite, exp_ALUOp, exp_ALUSrc, exp_Branch, exp_BranchType, exp_Jump, exp_JAL, exp_RET, exp_MemtoReg, exp_ImmSrc);
            $fdisplay(fd, "       ACT: RW=%b MR=%b MW=%b ALU=%b ALUSrc=%b Br=%b BrT=%b J=%b JAL=%b RET=%b MtR=%b ISrc=%b",
                      RegWrite, MemRead, MemWrite, ALUOp, ALUSrc, Branch, BranchType, Jump, JAL, RET, MemtoReg, ImmSrc);
            fail_count++;
        end else begin
            $fdisplay(fd, "PASS | Opcode: 0x%0x | ACT/EXP MATCH: RW=%b MR=%b MW=%b ALU=%b ALUSrc=%b Br=%b BrT=%b J=%b JAL=%b RET=%b MtR=%b ISrc=%b",
                      opcode, RegWrite, MemRead, MemWrite, ALUOp, ALUSrc, Branch, BranchType, Jump, JAL, RET, MemtoReg, ImmSrc);
            pass_count++;
        end
    endtask

    initial begin
        fd = $fopen("results/cu_report.log", "w");
        if (fd == 0) $fatal(1, "Could not open results/cu_report.log");
        $fdisplay(fd, "=== CONTROL UNIT TEST REPORT ===");
        
        // Random Tests
        for (int i = 0; i < 10000; i++) begin
            opcode = $random % 16;
            predict_and_check();
        end

        $fdisplay(fd, "\n=== SUMMARY ===");
        $fdisplay(fd, "Passed: %0d", pass_count);
        $fdisplay(fd, "Failed: %0d", fail_count);
        $fclose(fd);
        $finish;
    end
endmodule
