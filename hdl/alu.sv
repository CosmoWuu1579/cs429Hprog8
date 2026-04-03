module alu (
    input wire [4:0] opcode,
    input wire [63:0] rd,
    input wire [63:0] rs,
    input wire [63:0] rt,
    input wire [63:0] stack_pointer,
    input wire [11:0] L,
    input wire [63:0] memory_value,
    input wire [63:0] pc,
    output reg [63:0] memory_pointer,
    output reg memory_write, // decide if you want to write
    output reg [63:0] memory_data_to_write,
    output reg ooo_signal,
    output reg [63:0] ooo_address,
    output reg [63:0] reg_out_value,
    output reg reg_write
);
    reg [105:0] multf_reg; // used for multiplication
    reg [108:0] divf_reg;
    reg [53:0] addf_reg;
    reg [12:0] float_exponent_1; // extra bits just in case it's not enough
    reg [12:0] float_exponent_2; 
    reg [12:0] final_exponent;
    reg [52:0] float_value_1; // should always start with 1 -> represents the 1.32020321
    reg [52:0] float_value_2; // same as above
    reg [12:0] amount_shifted_1;
    reg [12:0] amount_shifted_2;
    reg [52:0] mantissa_result; 
    reg [2:0] grs_rounding;
    reg carry_1; // first carry from operation
    reg carry_2; // carry from rounding
    reg sign_1;
    reg sign_2;
    always @(*) begin
        integer i; // local variable: not in sensitivity list
        integer found;
        multf_reg = 105'b0;
        divf_reg = 109'b0;
        addf_reg = 54'b0;
        float_exponent_1 = 13'b0;
        float_exponent_2 = 13'b0;
        final_exponent = 13'b0;
        float_value_1 = 53'b0;
        float_value_2 = 53'b0;
        amount_shifted_1 = 13'b0;
        amount_shifted_2 = 13'b0;
        mantissa_result = 53'b0;
        grs_rounding = 3'b0;
        carry_1 = 1'b0;
        carry_2 = 1'b0;
        sign_1 = 1'b0;
        sign_2 = 1'b0;
        found = 0;
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
                if (rs) ooo_address = rd;
                else ooo_address = pc + 4;
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
                if ($signed(rs) > $signed(rt)) ooo_address = rd;
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
                memory_pointer += rd;
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
                reg_out_value[63] = 0;
                if (rs[62:0] == 0) reg_out_value = rt;
                else if (rt[62:0] == 0) reg_out_value = rs;
                else if (rt[62:52] == 11'h7FF || rs[62:52] == 11'h7FF) begin
                    if (rs[62:52] == 11'h7FF && rs[51:0] != 0) reg_out_value = rs; // NaN value
                    else if (rt[62:52] == 11'h7FF && rt[51:0] != 0) reg_out_value = rt;
                    else if (rt[62:52] == 11'h7FF && rs[62:52] == 11'h7FF) begin
                        if (rs[63] == rt[63]) reg_out_value = {rs[63], 11'h7FF, 52'b0}; // inf + inf = inf
                        else begin // inf + (-inf) = NaN
                            reg_out_value[62:52] = 11'h7FF;
                            reg_out_value[51:0] = 1;
                        end
                    end else if (rt[62:52] == 11'h7FF) begin
                        reg_out_value = {rt[63:52], 52'b0};
                    end else if (rs[62:52] == 11'h7FF) begin
                        reg_out_value = {rs[63:52], 52'b0};
                    end
                end else begin
                    if (rs[62:52] == 0) begin
                        float_exponent_1 = 1; // remember that it's 1 because -1022 + 1023
                        for (i = 51; i >= 0; i--) begin
                            if (rs[i] && !found) begin
                                amount_shifted_1 = 52 - i;
                                float_value_1 = rs[52:0] << (52 - i);
                                found = 1;
                            end
                        end
                    end else begin
                        float_exponent_1 = rs[62:52];
                        float_value_1 = {1'b1, rs[51:0]};
                        amount_shifted_1 = 0;
                    end

                    found = 0; // reset found before rt normalization

                    if (rt[62:52] == 0) begin
                        float_exponent_2 = 1; // remember that it's 1 because -1022 + 1023
                        for (i = 51; i >= 0; i--) begin
                            if (rt[i] && !found) begin
                                amount_shifted_2 = 52 - i;
                                float_value_2 = rt[52:0] << (52 - i);
                                found = 1;
                            end
                        end
                    end else begin
                        float_exponent_2 = rt[62:52];
                        float_value_2 = {1'b1, rt[51:0]};
                        amount_shifted_2 = 0;
                    end
                    found = 0;
                    sign_1 = rs[63];
                    sign_2 = rt[63];
                    if (float_exponent_1 + amount_shifted_2 < float_exponent_2 + amount_shifted_1) begin
                        // swap values using the leetcode method
                        // swap exponents
                        float_exponent_1 = float_exponent_1 ^ float_exponent_2;
                        float_exponent_2 = float_exponent_1 ^ float_exponent_2;
                        float_exponent_1 = float_exponent_1 ^ float_exponent_2;
                        // swap shifts
                        amount_shifted_1 = amount_shifted_1 ^ amount_shifted_2;
                        amount_shifted_2 = amount_shifted_1 ^ amount_shifted_2;
                        amount_shifted_1 = amount_shifted_1 ^ amount_shifted_2;
                        // swap values
                        float_value_1 = float_value_1 ^ float_value_2;
                        float_value_2 = float_value_1 ^ float_value_2;
                        float_value_1 = float_value_1 ^ float_value_2;
                        // swap signs
                        sign_1 = rt[63];
                        sign_2 = rs[63];
                    end

                    // now we must case work
                    if (float_exponent_1 + amount_shifted_2 == float_exponent_2 + amount_shifted_1) begin
                        if (sign_1 == sign_2) begin
                            reg_out_value[63] = sign_1;
                            addf_reg = float_value_1 + float_value_2;
                        end else begin
                            if (float_value_1 >= float_value_2) begin
                                reg_out_value[63] = sign_1;
                                addf_reg = float_value_1 - float_value_2;
                            end else begin
                                reg_out_value[63] = sign_2;
                                addf_reg = float_value_2 - float_value_1;
                            end
                        end
                        final_exponent = float_exponent_1;
                        if (addf_reg[53]) begin
                            final_exponent += 1;
                            mantissa_result[51:0] = addf_reg[52:1];
                        end else if (addf_reg[52]) begin
                            mantissa_result[51:0] = addf_reg[51:0];
                        end else begin
                            for (i = 51; i >= 0; i--) begin
                                if (addf_reg[i] && !found) begin
                                    addf_reg = addf_reg << (53-i);
                                    mantissa_result[51:0] = addf_reg[52:1];
                                    amount_shifted_1 += 52 - i;
                                    found = 1;
                                end
                            end
                            found = 0;
                            // note that it is okay if it never finds anything since mantissa result is initalized to 
                            // 0s anyway
                        end
                        // great, we our mantissa now, and our sign, and so we should just need to assign everything
                        // accroding to our exponent
                        if (final_exponent > amount_shifted_1 + 13'd2046) begin
                            // infinite
                            reg_out_value[62:52] = 11'h7FF;
                            reg_out_value[51:0] = 52'b0;
                        end else if (final_exponent > amount_shifted_1) begin
                            // we are chilling!
                            final_exponent -= amount_shifted_1;
                            reg_out_value[62:52] = final_exponent;
                            reg_out_value[51:0] = mantissa_result[51:0];
                        end else if (final_exponent + 52 > amount_shifted_1) begin
                            mantissa_result[52] = 1'b1;
                            amount_shifted_1 = amount_shifted_1 - final_exponent;
                            // the above needs no 1 + b/c you're indexing the values from [52:1], which
                            // makes a difference
                            mantissa_result = mantissa_result >> amount_shifted_1;
                            reg_out_value[62:52] = 0;
                            reg_out_value[51:0] = mantissa_result[52:1];
                        end else begin
                            reg_out_value[62:0] = 0;
                        end
                    end else begin
                        // this is the case where we must consider everything 
                        // here, we know that float_value_1 will always be larger, so let's go
                        // we break into 4 cases on what we do, but first, we shit the float_value_2
                        float_value_2 = float_value_2 >> (float_exponent_1 + amount_shifted_2 - float_exponent_2 - amount_shifted_1);
                        // sign logic uses tracked signs after swap
                        reg_out_value[63] = sign_1;
                        if (sign_1 == sign_2) begin
                            addf_reg = float_value_1 + float_value_2;
                        end else begin
                            addf_reg = float_value_1 - float_value_2;
                        end
                        final_exponent = float_exponent_1;
                        if (addf_reg[53]) begin
                            final_exponent += 1;
                            mantissa_result[51:0] = addf_reg[52:1];
                        end else if (addf_reg[52]) begin
                            mantissa_result[51:0] = addf_reg[51:0];
                        end else begin
                            for (i = 51; i >= 0; i--) begin
                                if (addf_reg[i] && !found) begin
                                    addf_reg = addf_reg << (53-i);
                                    mantissa_result[51:0] = addf_reg[52:1];
                                    amount_shifted_1 += 52 - i;
                                    found = 1;
                                end
                            end
                            found = 0;
                        end
                        // great, we our mantissa now, and our sign, and so we should just need to assign everything
                        // accroding to our exponent
                        if (final_exponent > amount_shifted_1 + 13'd2046) begin
                            // infinite
                            reg_out_value[62:52] = 11'h7FF;
                            reg_out_value[51:0] = 52'b0;
                        end else if (final_exponent > amount_shifted_1) begin
                            // we are chilling!
                            final_exponent -= amount_shifted_1;
                            reg_out_value[62:52] = final_exponent;
                            reg_out_value[51:0] = mantissa_result[51:0];
                        end else if (final_exponent + 52 > amount_shifted_1) begin
                            mantissa_result[52] = 1'b1;
                            amount_shifted_1 = amount_shifted_1 - final_exponent;
                            mantissa_result = mantissa_result >> amount_shifted_1;
                            reg_out_value[62:52] = 0;
                            reg_out_value[51:0] = mantissa_result[52:1];
                        end else begin
                            reg_out_value[62:0] = 0;
                        end
                    end
                end
                reg_write = 1;
            end
            5'h15: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value[63] = 0;
                if (rs[62:0] == 0 && rt[62:0] == 0) begin
                    if (rs[63] == 0) reg_out_value = 0;
                    else reg_out_value = rs;
                end
                else if (rs[62:0] == 0) reg_out_value = {~rt[63], rt[62:0]};
                // TODO idk if the above is correct
                else if (rt[62:0] == 0) reg_out_value = rs;
                else if (rt[62:52] == 11'h7FF || rs[62:52] == 11'h7FF) begin
                    if (rs[62:52] == 11'h7FF && rs[51:0] != 0) reg_out_value = rs; // NaN value
                    else if (rt[62:52] == 11'h7FF && rt[51:0] != 0) reg_out_value = rt;
                    else if (rt[62:52] == 11'h7FF && rs[62:52] == 11'h7FF) begin
                        if (rs[63] != rt[63]) reg_out_value = {rs[63], 11'h7FF, 52'b0}; // inf - (-inf) = inf
                        else begin // inf - inf = NaN
                            reg_out_value[62:52] = 11'h7FF;
                            reg_out_value[51:0] = 1;
                        end
                    end else if (rt[62:52] == 11'h7FF) begin
                        reg_out_value = {~rt[63], rt[62:52], 52'b0};
                    end else if (rs[62:52] == 11'h7FF) begin
                        reg_out_value = {rs[63:52], 52'b0};
                    end
                end else begin
                    if (rs[62:52] == 0) begin
                        float_exponent_1 = 1; // remember that it's 1 because -1022 + 1023
                        for (i = 51; i >= 0; i--) begin
                            if (rs[i] && !found) begin
                                amount_shifted_1 = 52 - i;
                                float_value_1 = rs[52:0] << (52 - i);
                                found = 1;
                            end
                        end
                    end else begin
                        float_exponent_1 = rs[62:52];
                        float_value_1 = {1'b1, rs[51:0]};
                        amount_shifted_1 = 0;
                    end
                    found = 0;
                    if (rt[62:52] == 0) begin
                        float_exponent_2 = 1; // remember that it's 1 because -1022 + 1023
                        for (i = 51; i >= 0; i--) begin
                            if (rt[i] && !found) begin
                                amount_shifted_2 = 52 - i;
                                float_value_2 = rt[52:0] << (52 - i);
                                found = 1;
                            end
                        end
                    end else begin
                        float_exponent_2 = rt[62:52];
                        float_value_2 = {1'b1, rt[51:0]};
                        amount_shifted_2 = 0;
                    end
                    found = 0;
                    sign_1 = rs[63];
                    sign_2 = ~rt[63]; // negate rt's sign for subtraction
                    if (float_exponent_1 + amount_shifted_2 < float_exponent_2 + amount_shifted_1) begin
                        // swap them, use the leetcode method
                        float_exponent_1 = float_exponent_1 ^ float_exponent_2;
                        float_exponent_2 = float_exponent_1 ^ float_exponent_2;
                        float_exponent_1 = float_exponent_1 ^ float_exponent_2;
                        amount_shifted_1 = amount_shifted_1 ^ amount_shifted_2;
                        amount_shifted_2 = amount_shifted_1 ^ amount_shifted_2;
                        amount_shifted_1 = amount_shifted_1 ^ amount_shifted_2;
                        float_value_1 = float_value_1 ^ float_value_2;
                        float_value_2 = float_value_1 ^ float_value_2;
                        float_value_1 = float_value_1 ^ float_value_2;
                        // swap signs
                        sign_1 = ~rt[63];
                        sign_2 = rs[63];
                    end

                    // now we must case work
                    if (float_exponent_1 + amount_shifted_2 == float_exponent_2 + amount_shifted_1) begin
                        if (sign_1 == sign_2) begin
                            reg_out_value[63] = sign_1;
                            addf_reg = float_value_1 + float_value_2;
                        end else begin
                            if (float_value_1 >= float_value_2) begin
                                reg_out_value[63] = sign_1;
                                addf_reg = float_value_1 - float_value_2;
                            end else begin
                                reg_out_value[63] = sign_2;
                                addf_reg = float_value_2 - float_value_1;
                            end
                        end                    
                        final_exponent = float_exponent_1;
                        if (addf_reg[53]) begin
                            final_exponent += 1;
                            mantissa_result[51:0] = addf_reg[52:1];
                        end else if (addf_reg[52]) begin
                            mantissa_result[51:0] = addf_reg[51:0];
                        end else begin
                            for (i = 51; i >= 0; i--) begin
                                if (addf_reg[i] && !found) begin
                                    addf_reg = addf_reg << (53-i);
                                    mantissa_result[51:0] = addf_reg[52:1];
                                    amount_shifted_1 += 52 - i;
                                    found = 1;
                                end
                            end
                            found = 0;
                            // note that it is okay if it never finds anything since mantissa result is initalized to 
                            // 0s anyway
                        end
                        // great, we our mantissa now, and our sign, and so we should just need to assign everything
                        // accroding to our exponent
                        if (final_exponent > amount_shifted_1 + 13'd2046) begin
                            // infinite
                            reg_out_value[62:52] = 11'h7FF;
                            reg_out_value[51:0] = 52'b0;
                        end else if (final_exponent > amount_shifted_1) begin
                            // we are chilling!
                            final_exponent -= amount_shifted_1;
                            reg_out_value[62:52] = final_exponent;
                            reg_out_value[51:0] = mantissa_result[51:0];
                        end else if (final_exponent + 52 > amount_shifted_1) begin
                            // case where we become a subnormal number
                            mantissa_result[52] = 1'b1;
                            amount_shifted_1 = amount_shifted_1 - final_exponent;
                            mantissa_result = mantissa_result >> amount_shifted_1;
                            reg_out_value[62:52] = 0;
                            reg_out_value[51:0] = mantissa_result[52:1];
                        end else begin
                            reg_out_value[62:0] = 0;
                        end
                    end else begin
                        // this is the case where we must consider everything
                        // here, we know that float_value_1 will always be larger, so let's go
                        // we break into 4 cases on what we do, but first, we shit the float_value_2
                        float_value_2 = float_value_2 >> (float_exponent_1 + amount_shifted_2 - float_exponent_2 - amount_shifted_1);
                        // sign logic uses tracked signs after swap
                        reg_out_value[63] = sign_1;
                        if (sign_1 == sign_2) begin
                            addf_reg = float_value_1 + float_value_2;
                        end else begin
                            addf_reg = float_value_1 - float_value_2;
                        end
                        final_exponent = float_exponent_1;
                        if (addf_reg[53]) begin
                            final_exponent += 1;
                            mantissa_result[51:0] = addf_reg[52:1];
                        end else if (addf_reg[52]) begin
                            mantissa_result[51:0] = addf_reg[51:0];
                        end else begin
                            for (i = 51; i >= 0; i--) begin
                                if (addf_reg[i] && !found) begin
                                    addf_reg = addf_reg << (53-i);
                                    mantissa_result[51:0] = addf_reg[52:1];
                                    amount_shifted_1 += 52 - i;
                                    found = 1;
                                end
                            end
                            found = 0;
                            // note that it is okay if it never finds anything since mantissa result is initalized to 
                            // 0s anyway
                        end
                        // great, we our mantissa now, and our sign, and so we should just need to assign everything
                        // accroding to our exponent
                        if (final_exponent > amount_shifted_1 + 13'd2046) begin
                            // infinite
                            reg_out_value[62:52] = 11'h7FF;
                            reg_out_value[51:0] = 52'b0;
                        end else if (final_exponent > amount_shifted_1) begin
                            // we are chilling!
                            final_exponent -= amount_shifted_1;
                            reg_out_value[62:52] = final_exponent;
                            reg_out_value[51:0] = mantissa_result[51:0];
                        end else if (final_exponent + 52 > amount_shifted_1) begin
                            mantissa_result[52] = 1'b1;
                            amount_shifted_1 = amount_shifted_1 - final_exponent;
                            mantissa_result = mantissa_result >> amount_shifted_1;
                            reg_out_value[62:52] = 0;
                            reg_out_value[51:0] = mantissa_result[52:1];
                        end else begin
                            reg_out_value[62:0] = 0;
                        end
                    end
                end
                reg_write = 1;
            end
            5'h16: begin
                memory_data_to_write = 0;
                memory_pointer = 0;
                memory_write = 0;
                ooo_signal = 0;
                ooo_address = 0;
                reg_out_value[63] = rs[63] ^ rt[63];
                if (rs[62:52] == 11'h7FF || rt[62:52] == 11'h7FF) begin
                    if (rs[62:52] == 11'h7FF && rs[51:0] != 0) reg_out_value = rs; // NaN value
                    else if (rt[62:52] == 11'h7FF && rt[51:0] != 0) reg_out_value = rt;
                    else if (rs[62:0] == 0 || rt[62:0] == 0) begin // 0 * inf = NaN
                        reg_out_value[62:52] = 11'h7FF;
                        reg_out_value[51:0] = 1;
                    end else reg_out_value[62:52] = 11'h7FF; // inf * inf = inf
                end else if (rs[62:0] == 0 || rt[62:0] == 0) reg_out_value[62:0] = 63'b0;
                else begin
                    // $display("We're in lala land");
                   // check for subnormalized numbers 
                    if (rs[62:52] == 0) begin
                        float_exponent_1 = 1; // remember that it's 1 because -1022 + 1023
                        for (i = 51; i >= 0; i--) begin
                            if (rs[i] && !found) begin
                                amount_shifted_1 = 52 - i;
                                float_value_1 = rs[52:0] << (52 - i);
                                found = 1;
                            end
                        end
                    end else begin
                        float_exponent_1 = rs[62:52];
                        float_value_1 = {1'b1, rs[51:0]};
                        amount_shifted_1 = 0;
                    end
                    found = 0;
                    if (rt[62:52] == 0) begin
                        float_exponent_2 = 1; // remember that it's 1 because -1022 + 1023
                        for (i = 51; i >= 0; i--) begin
                            if (rt[i] && !found) begin
                                amount_shifted_2 = 52 - i;
                                float_value_2 = rt[52:0] << (52 - i);
                                found = 1;
                            end
                        end
                        found = 0;
                    end else begin
                        float_exponent_2 = rt[62:52];
                        float_value_2 = {1'b1, rt[51:0]};
                        amount_shifted_2 = 0;
                    end
                    $display("My exponents are %d and %d", float_exponent_1, float_exponent_2);
                    $display("My shifts are %d and %d", amount_shifted_1, amount_shifted_2);

                    // great, now we have the 2 values, let's compute some stuff 
                    multf_reg = float_value_1 * float_value_2;
                    $display("value 1: %b", float_value_1);
                    $display("value 2: %b", float_value_2);
                    $display("My value is now %h", multf_reg);
                    if (multf_reg[105]) begin
                        carry_1 = 1;
                        mantissa_result[51:0] = multf_reg[104:53];
                        grs_rounding[2:0] = multf_reg[52:50];
                    end else begin
                        carry_1 = 0;
                        mantissa_result[51:0] = multf_reg[103:52];
                        grs_rounding[2:0] = multf_reg[51:49];
                    end

                    if ((grs_rounding > 4) || (mantissa_result[0] && grs_rounding[2])) begin
                        mantissa_result += 53'b1;
                    end

                    if (mantissa_result[52]) carry_2 = 1;
                    else carry_2 = 0;

                    final_exponent = float_exponent_1 + float_exponent_2 + carry_1 + carry_2;
                    // $display("Final exponent: %d", final_exponent);
                    // $display("Mantissa: %b", mantissa_result);
                    if (final_exponent > 13'd1023 + amount_shifted_1 + amount_shifted_2) begin
                        // we're safe!
                        // now we just need to make sure it's not too big
                        final_exponent -= (13'd1023 + amount_shifted_1 + amount_shifted_2);
                        if (final_exponent > 13'd2046) begin
                            reg_out_value[62:52] = 11'h7ff;
                            reg_out_value[51:0] = 52'b0;
                        end else begin
                            reg_out_value[62:52] = final_exponent[10:0];
                            if (carry_2) reg_out_value[51:0] ={1'b0, mantissa_result[51:1]};
                            else reg_out_value[51:0] = mantissa_result[51:0];
                        end
                        // TODO double check this condition below - idk if it's right
                    end else if (final_exponent + 52  > amount_shifted_1 + amount_shifted_2) begin
                        // subnormalized case 
                        // note the smallest value is 2^-1074
                        // so we want our actual exponent to be > -1074
                        // note that since we want a 0 in the front, we need to use the first bit
                        // of the mantissa result
                        mantissa_result[52] = 1'b1;
                        amount_shifted_1 = 1023 + amount_shifted_1 + amount_shifted_2 - final_exponent;
                        mantissa_result = mantissa_result >> amount_shifted_1;
                        // TODO if i fail cases, be sure to round here
                        reg_out_value[62:52] = 0;
                        reg_out_value[51:0] = mantissa_result[52:1];
                    end else begin
                        reg_out_value[62:0] = 0;
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
                reg_out_value[63] = rs[63] ^ rt[63];
                if (rs[62:0] == 0 || rt[62:0] == 0) begin
                    if (rs[62:0] == 0 && rt[62:0] == 0) begin // 0/0 = NaN
                        reg_out_value[62:52] = 11'h7FF;
                        reg_out_value[51:0] = 1;
                    end else if (rs[62:0] == 0) begin // 0/x = 0
                        reg_out_value[62:0] = 0;
                    end else begin // x/0 = inf
                        reg_out_value[62:52] = 11'h7FF;
                        reg_out_value[51:0] = 0;
                    end
                end else if (rs[62:52] == 11'h7FF || rt[62:52] == 11'h7FF) begin
                    if (rs[62:52] == 11'h7FF && rs[51:0] != 0) reg_out_value = rs; // NaN value
                    else if (rt[62:52] == 11'h7FF && rt[51:0] != 0) reg_out_value = rt;
                    else if (rs[62:52] == 11'h7FF && rt[62:52] == 11'h7FF) begin
                        reg_out_value[62:52] = 11'h7ff;
                        reg_out_value[51:0] = 52'h1; // NaN
                    end else if (rt[62:52] == 11'h7FF) begin
                        reg_out_value[62:0] = 0;
                    end else if (rs[62:52] == 11'h7FF) begin
                        reg_out_value[62:52] = 11'h7FF;
                        reg_out_value[51:0] = 0;
                    end
                end else begin
                   // check for subnormalized numbers 
                    if (rs[62:52] == 0) begin
                        float_exponent_1 = 1; // remember that it's 1 because -1022 + 1023
                        for (i = 51; i >= 0; i--) begin
                            if (rs[i] && !found) begin
                                amount_shifted_1 = 52 - i;
                                float_value_1 = rs[52:0] << (52 - i);
                                found = 1;
                            end
                        end
                    end else begin
                        float_exponent_1 = rs[62:52];
                        float_value_1 = {1'b1, rs[51:0]};
                        amount_shifted_1 = 0;
                    end
                    found = 0;
                    if (rt[62:52] == 0) begin
                        float_exponent_2 = 1; // remember that it's 1 because -1022 + 1023
                        for (i = 51; i >= 0; i--) begin
                            if (rt[i] && !found) begin
                                amount_shifted_2 = 52 - i;
                                float_value_2 = rt[52:0] << (52 - i);
                                found = 1;
                            end
                        end
                    end else begin
                        float_exponent_2 = rt[62:52];
                        float_value_2 = {1'b1, rt[51:0]};
                        amount_shifted_2 = 0;
                    end
                    found = 0;
                    $display("My exponents are %d and %d", float_exponent_1, float_exponent_2);
                    $display("My shifts are %d and %d", amount_shifted_1, amount_shifted_2);
                    divf_reg = {float_value_1, 56'b0};
                    $display("value 1: %b", float_value_1);
                    $display("value 2: %b", float_value_2);
                    $display("My value is now %b", divf_reg);
                    // great, now we have the 2 values, let's compute some stuff 
                    // this time, carry for carry_1 means a subtraction in our exponent
                    divf_reg = divf_reg / float_value_2;
                    $display("My value is now %b", divf_reg);
                    if (divf_reg[56]) begin
                        // no need to do any math
                        carry_1 = 0;
                        mantissa_result[51:0] = divf_reg[55:4];
                        grs_rounding[2:0] = divf_reg[3:1];
                    end else begin
                        carry_1 = 1; // this means our 1 is at the 104 position, unacceptable -> must shift to the left by 1
                        mantissa_result[51:0] = divf_reg[54:3];
                        grs_rounding[2:0] = divf_reg[2:0];
                    end

                    if ((grs_rounding > 4) || (mantissa_result[0] && grs_rounding[2])) begin
                        mantissa_result += 53'b1;
                    end

                    // same logic yay
                    if (mantissa_result[52]) carry_2 = 1;
                    else carry_2 = 0;

                    // division exponent: exp_rs - exp_rt + bias = (exp1 - shift1) - (exp2 - shift2) + 1023
                    // = 1023 + exp1 + shift2 - exp2 - shift1 (+ carry adjustments)
                    final_exponent = 13'd1023 + float_exponent_1 + carry_2 + amount_shifted_2;
                    // REMBER THAT FLOAT_EXPONENT_1 AND 2 STILL HAVE THE 1023 BIAS
                    if (final_exponent > float_exponent_2 + carry_1 + amount_shifted_1) begin
                        // normal number case
                        final_exponent -= float_exponent_2 + carry_1 + amount_shifted_1;
                        if (final_exponent > 13'd2046) begin
                            reg_out_value[62:52] = 11'h7FF;
                            reg_out_value[51:0] = 52'b0;
                        end else begin
                            reg_out_value[62:52] = final_exponent[10:0];
                            if (carry_2) reg_out_value[51:0] ={1'b0, mantissa_result[51:1]};
                            else reg_out_value[51:0] = mantissa_result[51:0];
                        end
                    end else if (final_exponent + 1075 > float_exponent_2 + carry_1 + amount_shifted_1) begin
                        // subnormalized case
                        mantissa_result[52] = 1'b1;
                        amount_shifted_1 = 2 + float_exponent_2 + carry_1 + amount_shifted_1 - final_exponent;
                        // TODO double check if 2 is correct
                        // this comes from -1022 + 1 (since we index at 52) - (final - 1023) 
                        // since we subtract by 1023 to get rid of the bias we got at the beginning
                        mantissa_result = mantissa_result >> amount_shifted_1;
                        reg_out_value[62:52] = 0;
                        reg_out_value[51:0] = mantissa_result[52:1];
                    end else begin
                        reg_out_value[62:0] = 0;
                    end     
                end     
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
                if (rt != 0 ) reg_out_value = $signed(rs) / $signed(rt);
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