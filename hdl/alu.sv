module alu (
    input wire [4:0] opcode,
    input wire [63:0] rd,
    input wire [63:0] rs,
    input wire [63:0] rt,
    input wire [63:0] stack_pointer,
    input wire [11:0] L,
    input wire [63:0] memory_value,
    input wire [63:0] pc,
    output wire [63:0] memory_pointer,
    output wire memory_write, // decide if you want to write
    output wire [63:0] memory_data_to_write,
    output wire ooo_signal,
    output wire [63:0] ooo_address,
    output wire [63:0] reg_out_value,
    output wire reg_write
);
    always @(*) begin
        reg [106:0] multf_reg; // used for divison and multiplication
        reg [12:0] float_exponent_1; // extra bits just in case it's not enough
        reg [12:0] float_exponent_2; 
        reg [12:0] final_exponent;
        reg [52:0] float_value_1; // should always start with 1 -> represents the 1.32020321
        reg [52:0] float_value_2; // same as above
        reg [12:0] amount_shifted_1;
        reg [12:0] amount_shifted_2;
        multf_reg = 107'b0;
        float_exponent_1 = 13'b0;
        float_exponent_2 = 13'b0;
        final_exponent = 13'b0;
        float_value_1 = 53'b0;
        float_value_2 = 53'b0;
        amount_shifted_1 = 13'b0;
        amount_shifted_2 = 13'b0;
        case (opcode)
            5'h0: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = rs & rt;
                reg_write = 1;
            end
            5'h1: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = rs | rt;
                reg_write = 1;
            end
            5'h2: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = rs ^ rt;
                reg_write = 1;
            end
            5'h3: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = ~rs;
                reg_write = 1;
            end
            5'h4: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = rs >> rt;
                reg_write = 1;
            end
            5'h5: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = rd >> L;
                reg_write = 1;
            end
            5'h6: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = rs << rt;
                reg_write = 1;
            end
            5'h7: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = rd << L;
                reg_write = 1;
            end
            5'h8: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 1;
                ooo_address = rd;
                reg_out_value = 0;
                reg_write = 0;
            end
            5'h9: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 1;
                ooo_address = pc + rd;
                reg_out_value = 0;
                reg_write = 0;
            end
            5'ha: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 1;
                ooo_address[10:0] = L[10:0];
                ooo_address[63:11] = {53{L[11]}};
                ooo_address += pc;
                reg_out_value = 0;
                reg_write = 0;
            end
            5'hb: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 1;
                if (rs) ooo_address = rd
                else ooo_address = pc + 4
                reg_out_value = 0;
                reg_write = 0;
            end
            5'hc: begin
                memory_data_to_write = pc + 4;
                memory_pointer = stack_pointer - 8;
                memory_write = 1;
                ooo_signal = 1;
                ooo_address = rd;
                reg_out_value = 0;
                reg_write = 0;
            end
            5'hd: begin
                // TODO figure out how memory reading works
                memory_data_to_write = 0;
                memory_pointer = stack_pointer - 8;
                memory_write = 0;
                ooo_signal = 1;
                ooo_address = memory_value;
                reg_out_value = 0;
                reg_write = 0;
            end
            5'he: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 1;
                if (rs > rt) ooo_address = rd;
                else ooo_address = pc + 4;
                reg_out_value = 0;
                reg_write = 0;
            end
            5'h10: begin
                memory_data_to_write = 0;
                memory_pointer[10:0] = L[10:0];
                memory_pointer[63:11] = {53{L[11]}};
                memory_pointer += rs;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = memory_value;
                reg_write = 1;
            end
            5'h11: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = rs;
                reg_write = 1;
            end
            5'h12: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = {rd[63:12], L};
                reg_write = 1;
            end
            5'h13: begin
                memory_data_to_write = rs;
                memory_pointer[10:0] = L[10:0];
                memory_pointer[63:11] = {53{L[11]}};
                memory_pointer += rs;
                memory_write = 1;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = 0;
                reg_write = 0;
            end
            5'h14: begin
                // TODO FLOAT STUFF
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = 0;
                reg_write = 1;
            end
            5'h15: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = 0;
                reg_write = 1;
            end
            5'h16: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value[63] = rs[0] ^ rt[0];
                if (rs == 0 || rt == 0) reg_out_value = 64'b0;
                else if (rs[62:52] == 4095 || rt[62:52] == 4095) begin
                    if (rs[62:52] == 4095 && rs[51:0] != 0) reg_out_value = rs; // NaN value
                    else if (rt[62:52] == 4095 && rt[51:0] != 0) reg_out_value = rt;
                    else reg_out_value[62:52] = 4095;
                end else begin
                   // check for subnormalized numbers 
                    if (rs[62:52] == 0) begin
                        float_exponent_1 = 1; // remember that it's 1 because -1022 + 1023
                        for (i = 51; i >= 0; i--) begin
                            if (rs[i]) begin
                                amount_shifted_1 = 52 - i;
                                float_value_1 = rs[52:0] << (52 - i);
                                break;
                            end
                        end
                    end else begin
                        float_exponent_1 = rs[62:52];
                        float_value_1 = {1'b1, rs[51:0]};
                    end

                    if (rt[62:52] == 0) begin
                        float_exponent_2 = 1; // remember that it's 1 because -1022 + 1023
                        for (i = 51; i >= 0; i--) begin
                            if (rt[i]) begin
                                amount_shifted_2 = 52 - i;
                                float_value_2 = rt[52:0] << (52 - i);
                                break;
                            end
                        end
                    end else begin
                        float_exponent_2 = rt[62:52];
                        float_value_2 = {1'b1, rs[51:0]};
                    end

                    // great, now we have the 2 values, let's compute some stuff 
                    multf_reg = float_value_1 * float_value_2;
                    // first, do rounding
                    if (multf_reg[53] && multf_reg[54]) multf_reg += (1 << 53);
                    else if (multf_reg[52:49] > 4) multf_reg += (1 << 53);
                    
                    if (multf_reg[105]) begin
                        final_exponent = float_exponent_1 + float_exponent_2 + 1;
                        if (final_exponent + 51 < amount_shifted_1 + amount_shifted_2) begin
                            // we are now just 0
                            reg_out_value[62:0] = 63'b0; 
                        end else if (final_exponent > 1023 + amount_shifted_1 + amount_shifted_2) begin
                            // now we're in the safe zone
                            reg_out_value[62:52] = final_exponent - 1023 - amount_shifted_1 - amount_shifted_2;
                            reg_out_value[51:0] = multf_reg[104:53];
                            // now, check for rounding 
                            
                        end
                    end
                end
                reg_write = 1;
            end
            5'h17: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = 0;
                reg_write = 1;
            end
            5'h18: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = rs + rt;
                reg_write = 1;
            end
            5'h19: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = rd + L;
                reg_write = 1;
            end
            5'h1a: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = rs - rt;
                reg_write = 1;
            end
            5'h1b: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = rd - L;
                reg_write = 1;
            end
            5'h1c: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = rs * rt;
                reg_write = 1;
            end
            5'h1d: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                if (rt != 0 ) reg_out_value = rs / rt;
                else reg_out_value = 0; 
                reg_write = 1;
            end
            default: begin
                // TODO
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value = 0;
                reg_write = 0;
            end
           


        endcase
    end

endmodule