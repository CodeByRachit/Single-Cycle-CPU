module imm_gen (
    input  logic [11:0] inst_imm,
    input  logic        ImmSrc,
    output logic [15:0] ext_imm,
    output logic [15:0] lui_out
);

    // Sign extension
    always_comb begin
        if (ImmSrc == 1'b0) begin
            // 6-bit sign extend (I-Type)
            ext_imm = {{10{inst_imm[5]}}, inst_imm[5:0]};
        end else begin
            // 12-bit sign extend (J-Type)
            ext_imm = {{4{inst_imm[11]}}, inst_imm[11:0]};
        end
    end

    // LUI output: {Imm[5:0], 10'b0}
    assign lui_out = {inst_imm[5:0], 10'b0};

endmodule
