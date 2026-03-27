module register_file (
    input wire clk,
    input wire reset,
    input wire write,
    input wire [31:0] data_write,
    input wire [4:0] d,
    input wire [4:0] s,
    input wire [4:0] t,
    output wire [63:0] rd,
    output wire [63:0] rs,
    output wire [63:0] rt,
    output wire [63:0] stack_pointer
);
    reg [63:0] registers [0:31];
    always @(*) begin
        rd = registers[d];
        rs = registers[s];
        rt = registers[t];
        stack_pointer = registers[31];
    end

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 31; i++) begin
                registers[i] <= 64'b0;
            end
            registers[31] <= MEM_SIZE;
        end else if (write) registers[d] <= data_write
    end
endmodule