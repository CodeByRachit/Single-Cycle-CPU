/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSED */
module instruction_memory #(
    parameter MEM_DEPTH = 256,
    parameter ADDR_WIDTH = 8
) (
    input  logic [15:0] pc,
    output logic [15:0] instruction
);

    /* verilator lint_off UNDRIVEN */
    logic [15:0] rom [0:MEM_DEPTH-1];
    /* verilator lint_on UNDRIVEN */
    
    // In a real synthesis flow, you might initialize this via $readmemh or equivalent
    
    // Asynchronous read (only using ADDR_WIDTH bits of PC)
    assign instruction = rom[pc[ADDR_WIDTH-1:0]];

endmodule


module data_memory #(
    parameter MEM_DEPTH = 256,
    parameter ADDR_WIDTH = 8
) (
    input  logic        clk,
    input  logic [15:0] addr,
    input  logic [15:0] write_data,
    input  logic        MemRead,
    input  logic        MemWrite,
    output logic [15:0] read_data
);

    logic [15:0] ram [0:MEM_DEPTH-1];

    // Asynchronous read
    assign read_data = MemRead ? ram[addr[ADDR_WIDTH-1:0]] : 16'b0;

    // Synchronous write
    always_ff @(posedge clk) begin
        if (MemWrite) begin
            ram[addr[ADDR_WIDTH-1:0]] <= write_data;
        end
    end

endmodule
/* verilator lint_on UNUSED */
/* verilator lint_on DECLFILENAME */
