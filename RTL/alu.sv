module alu (
    input  logic [15:0] A,
    input  logic [15:0] B,
    input  logic [2:0]  ALUOp,
    output logic [15:0] Result,
    output logic        Zero
);

    always_comb begin
        case (ALUOp)
            3'b000: Result = A + B;       // ADD
            3'b001: Result = A - B;       // SUB
            3'b010: Result = A & B;       // AND
            3'b011: Result = A | B;       // OR
            3'b100: Result = A ^ B;       // XOR
            default: Result = 16'b0;
        endcase
    end

    // Zero flag is high when A == B.
    assign Zero = (A == B);

endmodule
