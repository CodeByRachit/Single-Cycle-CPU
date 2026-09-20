module reg_file (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [2:0]  rs1_addr,
    input  logic [2:0]  rs2_addr,
    input  logic [2:0]  rd_addr,
    input  logic [15:0] write_data,
    input  logic        RegWrite,
    input  logic        JAL,
    output logic [15:0] rs1_data,
    output logic [15:0] rs2_data
);

    logic [15:0] registers [7:0];
    logic [2:0]  write_addr;

    // RegDst MUX: Select R7 if JAL is active, else rd_addr
    assign write_addr = (JAL) ? 3'b111 : rd_addr;

    // Asynchronous read with R0 hardwired to 0
    assign rs1_data = (rs1_addr == 3'b000) ? 16'b0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 3'b000) ? 16'b0 : registers[rs2_addr];

    // Synchronous write with asynchronous active-low reset
    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                registers[i] <= 16'b0;
            end
        end else if (RegWrite && write_addr != 3'b000) begin
            registers[write_addr] <= write_data;
        end
    end

endmodule
