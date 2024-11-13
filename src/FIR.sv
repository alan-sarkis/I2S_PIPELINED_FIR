module FIR(
    input MCLK,
    input [3:0] SWITCH,

    input signed [23:0] RIGHT_RX,
    input signed [23:0] LEFT_RX,

    input RIGHT_RX_READY,
    input LEFT_RX_READY,

    output reg signed [23:0] RIGHT_TX,
    output reg signed [23:0] LEFT_TX
);

localparam NUM_TAPS = 64;
localparam NUM_MODES = 4;
localparam TAPS_WIDTH = 16;
localparam DATA_WIDTH = 24;

////// FILTER COEFFICIENTS //////////
reg signed [TAPS_WIDTH-1:0] COEF [NUM_MODES-1:0][NUM_TAPS:0]  =  '{
'{16'h005f, 16'h007d, 16'h00cc, 16'h0137, 16'h01c5, 16'h027c, 16'h0361, 16'h047b,
  16'h05cf, 16'h0761, 16'h0936, 16'h0b50, 16'h0db1, 16'h1058, 16'h1344, 16'h1670,
  16'h19d7, 16'h1d71, 16'h2135, 16'h2516, 16'h2908, 16'h2cfc, 16'h30e3, 16'h34ac,
  16'h3848, 16'h3ba5, 16'h3eb4, 16'h4167, 16'h43af, 16'h4582, 16'h46d7, 16'h47a6,
  16'h47ec, 16'h47a6, 16'h46d7, 16'h4582, 16'h43af, 16'h4167, 16'h3eb4, 16'h3ba5,
  16'h3848, 16'h34ac, 16'h30e3, 16'h2cfc, 16'h2908, 16'h2516, 16'h2135, 16'h1d71,
  16'h19d7, 16'h1670, 16'h1344, 16'h1058, 16'h0db1, 16'h0b50, 16'h0936, 16'h0761,
  16'h05cf, 16'h047b, 16'h0361, 16'h027c, 16'h01c5, 16'h0137, 16'h00cc, 16'h007d,
  16'h005f},

'{16'hfec6, 16'hffdc, 16'hffe4, 16'hfff5, 16'h000d, 16'h002c, 16'h0052, 16'h007a,
  16'h00a5, 16'h00cd, 16'h00f1, 16'h010c, 16'h011b, 16'h0119, 16'h0104, 16'h00d9,
  16'h0095, 16'h0038, 16'hffc0, 16'hff30, 16'hfe8a, 16'hfdd0, 16'hfd08, 16'hfc36,
  16'hfb61, 16'hfa8f, 16'hf9c7, 16'hf911, 16'hf872, 16'hf7ef, 16'hf78e, 16'hf753,
  16'h773f, 16'hf753, 16'hf78e, 16'hf7ef, 16'hf872, 16'hf911, 16'hf9c7, 16'hfa8f,
  16'hfb61, 16'hfc36, 16'hfd08, 16'hfdd0, 16'hfe8a, 16'hff30, 16'hffc0, 16'h0038,
  16'h0095, 16'h00d9, 16'h0104, 16'h0119, 16'h011b, 16'h010c, 16'h00f1, 16'h00cd,
  16'h00a5, 16'h007a, 16'h0052, 16'h002c, 16'h000d, 16'hfff5, 16'hffe4, 16'hffdc,
  16'hfec6},
  
'{16'hffed, 16'hffc8, 16'hff7c, 16'hfefd, 16'hfe53, 16'hfda6, 16'hfd45, 16'hfd94,
  16'hfee7, 16'h0148, 16'h044d, 16'h0720, 16'h08b9, 16'h0850, 16'h05d5, 16'h022a,
  16'hfee7, 16'hfdb2, 16'hff55, 16'h030b, 16'h0670, 16'h0656, 16'h0037, 16'hf3c4,
  16'he3c1, 16'hd598, 16'hcfa2, 16'hd698, 16'heb52, 16'h09c7, 16'h29ee, 16'h4253,
  16'h4b69, 16'h4253, 16'h29ee, 16'h09c7, 16'heb52, 16'hd698, 16'hcfa2, 16'hd598,
  16'he3c1, 16'hf3c4, 16'h0037, 16'h0656, 16'h0670, 16'h030b, 16'hff55, 16'hfdb2,
  16'hfee7, 16'h022a, 16'h05d5, 16'h0850, 16'h08b9, 16'h0720, 16'h044d, 16'h0148,
  16'hfee7, 16'hfd94, 16'hfd45, 16'hfda6, 16'hfe53, 16'hfefd, 16'hff7c, 16'hffc8,
  16'hffed},

'{16'hff3b, 16'h017d, 16'hff6a, 16'hff87, 16'h0045, 16'h0095, 16'h004c, 16'hffd9,
  16'hffc1, 16'h0034, 16'h00f0, 16'h017c, 16'h0178, 16'h00e8, 16'h003f, 16'h001b,
  16'h00e3, 16'h026b, 16'h03f0, 16'h0483, 16'h03a5, 16'h01c0, 16'h001f, 16'h003d,
  16'h02cb, 16'h06fa, 16'h0a88, 16'h0ab9, 16'h05d0, 16'hfc3b, 16'hf0be, 16'he76a,
  16'h63d5, 16'he76a, 16'hf0be, 16'hfc3b, 16'h05d0, 16'h0ab9, 16'h0a88, 16'h06fa,
  16'h02cb, 16'h003d, 16'h001f, 16'h01c0, 16'h03a5, 16'h0483, 16'h03f0, 16'h026b,
  16'h00e3, 16'h001b, 16'h003f, 16'h00e8, 16'h0178, 16'h017c, 16'h00f0, 16'h0034,
  16'hffc1, 16'hffd9, 16'h004c, 16'h0095, 16'h0045, 16'hff87, 16'hff6a, 16'h017d,
  16'hff3b}};


////// CHOOSE FILTER COEFFICIENTS ///////
reg signed [TAPS_WIDTH-1:0] TAPS [NUM_TAPS:0];

always@(posedge MCLK)begin
    case(SWITCH)
        4'b0001: TAPS <= COEF[0]; // 250Hz Low-Pass
        4'b0010: TAPS <= COEF[1]; // 250Hz High-Pass
        4'b0100: TAPS <= COEF[2]; // 500Hz - 6000Hz Band-Pass
        4'b1000: TAPS <= COEF[3]; // 2000Hz - 4000Hz Band-Stop
        default: TAPS <= TAPS;
    endcase
end


////// BUFFER DATA ///////
reg signed [DATA_WIDTH-1:0] LEFT_BUFFER [NUM_TAPS:0];
reg signed [DATA_WIDTH-1:0] RIGHT_BUFFER [NUM_TAPS:0];

integer i;

always@(posedge MCLK)begin
    if(LEFT_RX_READY)begin
        LEFT_BUFFER[0] <= LEFT_RX;
        for(i = 1; i <= NUM_TAPS; i = i + 1)
            LEFT_BUFFER[i] <= LEFT_BUFFER[i - 1];
    end
    if(RIGHT_RX_READY)begin
        RIGHT_BUFFER[0] <= RIGHT_RX;
        for(i = 1; i <= NUM_TAPS; i = i + 1)
            RIGHT_BUFFER[i] <= RIGHT_BUFFER[i - 1];
    end
end

/////// MULTIPLIER /////////
reg signed [TAPS_WIDTH + DATA_WIDTH:0] LEFT_MULT [NUM_TAPS:0];
reg signed [TAPS_WIDTH + DATA_WIDTH:0] RIGHT_MULT [NUM_TAPS:0];

integer j;

always@(posedge MCLK)begin
    if(LEFT_RX_READY)begin
        for(j = 0; j <= NUM_TAPS; j = j + 1)
            LEFT_MULT[j] <= LEFT_BUFFER[j] * TAPS[j];
    end
    if(RIGHT_RX_READY)begin
        for(j = 0; j <= NUM_TAPS; j = j + 1)
            RIGHT_MULT[j] <= RIGHT_BUFFER[j] * TAPS[j];
    end
end

//////// Pipelined Accumulator /////////
reg signed [TAPS_WIDTH + DATA_WIDTH - 1:0] LEFT_ACC_1;
reg signed [TAPS_WIDTH + DATA_WIDTH - 1:0] LEFT_ACC_2;
reg signed [TAPS_WIDTH + DATA_WIDTH - 1:0] LEFT_ACC_3;
reg signed [TAPS_WIDTH + DATA_WIDTH - 1:0] LEFT_ACC_4;

reg signed [TAPS_WIDTH + DATA_WIDTH - 1:0] RIGHT_ACC_1;
reg signed [TAPS_WIDTH + DATA_WIDTH - 1:0] RIGHT_ACC_2;
reg signed [TAPS_WIDTH + DATA_WIDTH - 1:0] RIGHT_ACC_3;
reg signed [TAPS_WIDTH + DATA_WIDTH - 1:0] RIGHT_ACC_4;

always@(posedge MCLK)begin
    if(LEFT_RX_READY)begin
        LEFT_ACC_1 <=   LEFT_MULT[0] + LEFT_MULT[1] + LEFT_MULT[2] + LEFT_MULT[3] +
                        LEFT_MULT[4] + LEFT_MULT[5] + LEFT_MULT[6] + LEFT_MULT[7] +
                        LEFT_MULT[8] + LEFT_MULT[9] + LEFT_MULT[10] + LEFT_MULT[11] +
                        LEFT_MULT[12] + LEFT_MULT[13] + LEFT_MULT[14] + LEFT_MULT[15];

        LEFT_ACC_2 <=   LEFT_MULT[16] + LEFT_MULT[17] + LEFT_MULT[18] + LEFT_MULT[19] +
                        LEFT_MULT[20] + LEFT_MULT[21] + LEFT_MULT[22] + LEFT_MULT[23] +
                        LEFT_MULT[24] + LEFT_MULT[25] + LEFT_MULT[26] + LEFT_MULT[27] +
                        LEFT_MULT[28] + LEFT_MULT[29] + LEFT_MULT[30] + LEFT_MULT[31];

        LEFT_ACC_3 <=   LEFT_MULT[32] + LEFT_MULT[33] + LEFT_MULT[34] + LEFT_MULT[35] + 
                        LEFT_MULT[36] + LEFT_MULT[37] + LEFT_MULT[38] + LEFT_MULT[39] +
                        LEFT_MULT[40] + LEFT_MULT[41] + LEFT_MULT[42] + LEFT_MULT[43] +
                        LEFT_MULT[44] + LEFT_MULT[45] + LEFT_MULT[46] + LEFT_MULT[47];
        
        LEFT_ACC_4 <=   LEFT_MULT[48] + LEFT_MULT[49] + LEFT_MULT[50] + LEFT_MULT[51] +
                        LEFT_MULT[52] + LEFT_MULT[53] + LEFT_MULT[54] + LEFT_MULT[55] +
                        LEFT_MULT[56] + LEFT_MULT[57] + LEFT_MULT[58] + LEFT_MULT[59] +
                        LEFT_MULT[60] + LEFT_MULT[61] + LEFT_MULT[62] + LEFT_MULT[63] +
                        LEFT_MULT[64];
    end
    if(RIGHT_RX_READY)begin
        RIGHT_ACC_1 <=  RIGHT_MULT[0] + RIGHT_MULT[1] + RIGHT_MULT[2] + RIGHT_MULT[3] +
                        RIGHT_MULT[4] + RIGHT_MULT[5] + RIGHT_MULT[6] + RIGHT_MULT[7] +
                        RIGHT_MULT[8] + RIGHT_MULT[9] + RIGHT_MULT[10] + RIGHT_MULT[11] +
                        RIGHT_MULT[12] + RIGHT_MULT[13] + RIGHT_MULT[14] + RIGHT_MULT[15];

        RIGHT_ACC_2 <=  RIGHT_MULT[16] + RIGHT_MULT[17] + RIGHT_MULT[18] + RIGHT_MULT[19] +
                        RIGHT_MULT[20] + RIGHT_MULT[21] + RIGHT_MULT[22] + RIGHT_MULT[23] +
                        RIGHT_MULT[24] + RIGHT_MULT[25] + RIGHT_MULT[26] + RIGHT_MULT[27] +
                        RIGHT_MULT[28] + RIGHT_MULT[29] + RIGHT_MULT[30] + RIGHT_MULT[31];

        RIGHT_ACC_3 <=  RIGHT_MULT[32] + RIGHT_MULT[33] + RIGHT_MULT[34] + RIGHT_MULT[35] +
                        RIGHT_MULT[36] + RIGHT_MULT[37] + RIGHT_MULT[38] + RIGHT_MULT[39] +
                        RIGHT_MULT[40] + RIGHT_MULT[41] + RIGHT_MULT[42] + RIGHT_MULT[43] +
                        RIGHT_MULT[44] + RIGHT_MULT[45] + RIGHT_MULT[46] + RIGHT_MULT[47];
        
        RIGHT_ACC_4 <=  RIGHT_MULT[48] + RIGHT_MULT[49] + RIGHT_MULT[50] + RIGHT_MULT[51] +
                        RIGHT_MULT[52] + RIGHT_MULT[53] + RIGHT_MULT[54] + RIGHT_MULT[55] +
                        RIGHT_MULT[56] + RIGHT_MULT[57] + RIGHT_MULT[58] + RIGHT_MULT[59] +
                        RIGHT_MULT[60] + RIGHT_MULT[61] + RIGHT_MULT[62] + RIGHT_MULT[63] +
                        RIGHT_MULT[64];
    end
end

/////// Shift Register to Fit Data Output //////
wire signed [DATA_WIDTH - 1:0] LEFT_FIR;
wire signed [DATA_WIDTH - 1:0] RIGHT_FIR;

assign LEFT_FIR = (LEFT_ACC_1 + LEFT_ACC_2 + LEFT_ACC_3 + LEFT_ACC_4) >>> TAPS_WIDTH; // Shift to avoid overflow
assign RIGHT_FIR = (RIGHT_ACC_1 + RIGHT_ACC_2 + RIGHT_ACC_3 + RIGHT_ACC_4) >>> TAPS_WIDTH; // Shift to avoid overflow

//////// Sending Data to Transmiter ////////
always@(posedge MCLK)begin
    case(SWITCH)
    4'b0001:
            begin
                LEFT_TX <= LEFT_FIR;
                RIGHT_TX <= RIGHT_FIR;
            end

    4'b0010:
            begin
                LEFT_TX <= LEFT_FIR;
                RIGHT_TX <= RIGHT_FIR;
            end

    4'b0100:
            begin
                LEFT_TX <= LEFT_FIR;
                RIGHT_TX <= RIGHT_FIR;
            end

    4'b1000:
            begin
                LEFT_TX <= LEFT_FIR;
                RIGHT_TX <= RIGHT_FIR;
            end

    default:
            begin
                if(LEFT_RX_READY)
                    LEFT_TX <= LEFT_RX;
                if(RIGHT_RX_READY)
                    RIGHT_TX <= RIGHT_RX;
            end
    endcase
end

endmodule