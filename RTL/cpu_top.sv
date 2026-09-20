module cpu_top (
    input logic clk,
    input logic rst_n
);

    // -------------------------------------------------------------------------
    // Signals
    // -------------------------------------------------------------------------
    // PC & Instruction
    logic [15:0] pc, next_pc;
    logic [15:0] pc_plus_one;
    logic [15:0] instruction;
    
    // Instruction decoding
    logic [3:0]  opcode;
    logic [2:0]  rd, rs1, rs2;
    logic [11:0] imm;
    
    // Control Signals
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
    
    // Register File
    logic [15:0] write_data;
    logic [15:0] rs1_data;
    logic [15:0] rs2_data;
    
    // Immediate Generation
    logic [15:0] ext_imm;
    logic [15:0] lui_out;
    
    // ALU
    logic [15:0] alu_b;
    logic [15:0] alu_result;
    logic        zero;
    
    // Data Memory
    logic [15:0] mem_read_data;
    
    // Branching Logic
    logic [15:0] branch_target;
    logic        branch_condition;
    logic        take_branch_or_jump;

    // -------------------------------------------------------------------------
    // Instruction Slicing
    // -------------------------------------------------------------------------
    assign opcode = instruction[15:12];
    assign rd     = instruction[11:9];
    assign rs1    = instruction[8:6];
    assign rs2    = instruction[5:3];
    assign imm    = instruction[11:0];

    // -------------------------------------------------------------------------
    // PC Register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'b0;
        end else begin
            pc <= next_pc;
        end
    end

    // -------------------------------------------------------------------------
    // Instruction Memory
    // -------------------------------------------------------------------------
    instruction_memory imem (
        .pc(pc),
        .instruction(instruction)
    );

    // -------------------------------------------------------------------------
    // Control Unit
    // -------------------------------------------------------------------------
    control_unit ctrl (
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

    // -------------------------------------------------------------------------
    // Register File
    // -------------------------------------------------------------------------
    logic [2:0] actual_rs2_addr;
    // For SW (0111), BEQ (1001), BNE (1010), use Rd as the second source register.
    // Otherwise, use Rs2 from instruction[5:3].
    assign actual_rs2_addr = (opcode == 4'b0111 || opcode == 4'b1001 || opcode == 4'b1010) ? rd : rs2;

    reg_file rf (
        .clk(clk),
        .rst_n(rst_n),
        .rs1_addr(rs1),
        .rs2_addr(actual_rs2_addr),
        .rd_addr(rd),
        .write_data(write_data),
        .RegWrite(RegWrite),
        .JAL(JAL),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // -------------------------------------------------------------------------
    // Immediate Generation
    // -------------------------------------------------------------------------
    imm_gen ig (
        .inst_imm(imm),
        .ImmSrc(ImmSrc),
        .ext_imm(ext_imm),
        .lui_out(lui_out)
    );

    // -------------------------------------------------------------------------
    // ALU
    // -------------------------------------------------------------------------
    assign alu_b = ALUSrc ? ext_imm : rs2_data;

    alu core_alu (
        .A(rs1_data),
        .B(alu_b),
        .ALUOp(ALUOp),
        .Result(alu_result),
        .Zero(zero)
    );

    // -------------------------------------------------------------------------
    // Data Memory
    // -------------------------------------------------------------------------
    data_memory dmem (
        .clk(clk),
        .addr(alu_result),
        .write_data(rs2_data),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .read_data(mem_read_data)
    );

    // -------------------------------------------------------------------------
    // Write Back Logic (MemtoReg MUX)
    // -------------------------------------------------------------------------
    assign pc_plus_one = pc + 16'd1;

    always_comb begin
        case (MemtoReg)
            2'b00: write_data = alu_result;
            2'b01: write_data = mem_read_data;
            2'b10: write_data = pc_plus_one; // For JAL
            2'b11: write_data = lui_out;     // For LUI
            default: write_data = 16'b0;
        endcase
    end

    // -------------------------------------------------------------------------
    // Next PC Logic (PCSrc MUX)
    // -------------------------------------------------------------------------
    assign branch_target = pc + ext_imm;
    
    // BEQ (BranchType == 0) and BNE (BranchType == 1)
    assign branch_condition = (BranchType == 1'b0) ? zero : !zero;
    assign take_branch_or_jump = Jump | (Branch & branch_condition);

    always_comb begin
        if (RET) begin
            next_pc = rs1_data;
        end else if (take_branch_or_jump) begin
            next_pc = branch_target;
        end else begin
            next_pc = pc_plus_one;
        end
    end

endmodule
