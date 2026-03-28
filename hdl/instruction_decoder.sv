module instruction_decoder (
    input wire [31:0] instruction,
    output wire [4:0] opcode,
    output wire [4:0] d,
    output wire [4:0] s,
    output wire [4:0] t,
    output wire [11:0] L
);
    always @(*) begin
        opocode = instruction[31:27]
        d = instruction[26:22];
        s = instruction[21:17];
        t = instruction[16:12];
        L = instruction[11:0];
    end
    
    
endmodule