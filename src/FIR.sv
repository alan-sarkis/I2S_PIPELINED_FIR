//////////////////////////////////////////////////////////////////////////////////
// Company: 4th Year Student
// Engineer: Alan Sarkis
// 
// Design Name: FIR Filter
// Module Name: FIR
// Project Name: I2S_PIPELINED_FIR
// Target Devices: ZYBO Z7-20
//
// Description: The purpose of this module is to add an FIR filter for the input
// of the I2S transciever. There is four different filters in this file which
// allow for choosing a specific filter based on the switch positions. The
// filters present in this project are lowpass, highpass, bandpass and
// bandstop. In order to achieve timing closure, I have pipelined the accumulator
// allowing me to remove the Total Negative Slack.
// 
//////////////////////////////////////////////////////////////////////////////////
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

// 4000Hz Lowpass Filter
'{16'hffa5, 16'hff66, 16'hff01, 16'hfe91, 16'hfe2e, 16'hfdf4, 16'hfe06, 16'hfe7f,
  16'hff71, 16'h00d8, 16'h0297, 16'h0478, 16'h062e, 16'h075d, 16'h07ae, 16'h06e1,
  16'h04d8, 16'h01b1, 16'hfdc1, 16'hf99b, 16'hf5fb, 16'hf3b3, 16'hf387, 16'hf610,
  16'hfb99, 16'h040c, 16'h0ee9, 16'h1b4e, 16'h280e, 16'h33d7, 16'h3d60, 16'h4394,
  16'h45ba, 16'h4394, 16'h3d60, 16'h33d7, 16'h280e, 16'h1b4e, 16'h0ee9, 16'h040c,
  16'hfb99, 16'hf610, 16'hf387, 16'hf3b3, 16'hf5fb, 16'hf99b, 16'hfdc1, 16'h01b1,
  16'h04d8, 16'h06e1, 16'h07ae, 16'h075d, 16'h062e, 16'h0478, 16'h0297, 16'h00d8,
  16'hff71, 16'hfe7f, 16'hfe06, 16'hfdf4, 16'hfe2e, 16'hfe91, 16'hff01, 16'hff66,
  16'hffa5},

// 4000Hz Highpass Filter
'{16'h0045, 16'hfea0, 16'h016b, 16'h0096, 16'hffab, 16'hff46, 16'hff61, 16'hffd6,
  16'h006c, 16'h00d5, 16'h00cd, 16'h0044, 16'hff72, 16'hfeca, 16'hfebf, 16'hff7e,
  16'h00bd, 16'h01d2, 16'h0204, 16'h00fd, 16'hff12, 16'hfd3b, 16'hfca1, 16'hfe00,
  16'h0117, 16'h048b, 16'h0657, 16'h04a9, 16'hfecc, 16'hf5b3, 16'hebc9, 16'he41f,
  16'h613e, 16'he41f, 16'hebc9, 16'hf5b3, 16'hfecc, 16'h04a9, 16'h0657, 16'h048b,
  16'h0117, 16'hfe00, 16'hfca1, 16'hfd3b, 16'hff12, 16'h00fd, 16'h0204, 16'h01d2,
  16'h00bd, 16'hff7e, 16'hfebf, 16'hfeca, 16'hff72, 16'h0044, 16'h00cd, 16'h00d5,
  16'h006c, 16'hffd6, 16'hff61, 16'hff46, 16'hffab, 16'h0096, 16'h016b, 16'hfea0,
  16'h0045},

// 2000Hz - 6000Hz Bandpass Filter
'{16'h003c, 16'h001c, 16'hffbe, 16'hfefc, 16'hfe0b, 16'hfd72, 16'hfdea, 16'h0005,
  16'h03ba, 16'h080b, 16'h0b14, 16'h0a9f, 16'h0526, 16'hfae7, 16'hee7b, 16'he471,
  16'he1e3, 16'hea49, 16'hfd78, 16'h16bc, 16'h2dbc, 16'h392a, 16'h3267, 16'h18b0,
  16'hf266, 16'hcb96, 16'hb205, 16'hb01b, 16'hc892, 16'hf4d6, 16'h26da, 16'h4de6,
  16'h5c9c, 16'h4de6, 16'h26da, 16'hf4d6, 16'hc892, 16'hb01b, 16'hb205, 16'hcb96,
  16'hf266, 16'h18b0, 16'h3267, 16'h392a, 16'h2dbc, 16'h16bc, 16'hfd78, 16'hea49,
  16'he1e3, 16'he471, 16'hee7b, 16'hfae7, 16'h0526, 16'h0a9f, 16'h0b14, 16'h080b,
  16'h03ba, 16'h0005, 16'hfdea, 16'hfd72, 16'hfe0b, 16'hfefc, 16'hffbe, 16'h001c,
  16'h003c},

// 3000Hz - 5000Hz Bandstop Filter
'{16'h0037, 16'hff37, 16'h0149, 16'hff4c, 16'hff01, 16'hffd7, 16'h0064, 16'h002a,
  16'hff63, 16'hfe98, 16'hfe4d, 16'hfeba, 16'hff8e, 16'h0015, 16'hffbc, 16'hfe9e,
  16'hfd98, 16'hfdc0, 16'hff79, 16'h01f7, 16'h03a7, 16'h0359, 16'h015f, 16'hffad,
  16'h0099, 16'h0503, 16'h0b18, 16'h0ee7, 16'h0c9c, 16'h0324, 16'hf573, 16'he95d,
  16'h648e, 16'he95d, 16'hf573, 16'h0324, 16'h0c9c, 16'h0ee7, 16'h0b18, 16'h0503,
  16'h0099, 16'hffad, 16'h015f, 16'h0359, 16'h03a7, 16'h01f7, 16'hff79, 16'hfdc0,
  16'hfd98, 16'hfe9e, 16'hffbc, 16'h0015, 16'hff8e, 16'hfeba, 16'hfe4d, 16'hfe98,
  16'hff63, 16'h002a, 16'h0064, 16'hffd7, 16'hff01, 16'hff4c, 16'h0149, 16'hff37,
  16'h0037}};


////// CHOOSE FILTER COEFFICIENTS ///////
reg signed [TAPS_WIDTH-1:0] TAPS [NUM_TAPS:0];

always@(posedge MCLK)begin
    case(SWITCH)
        4'b0001: TAPS <= COEF[3]; // 4000Hz Lowpass Filter
        4'b0010: TAPS <= COEF[2]; // 4000Hz Highpass Filter
        4'b0100: TAPS <= COEF[1]; // 2000Hz - 6000Hz Bandpass Filter
        4'b1000: TAPS <= COEF[0]; // 3000Hz - 5000Hz Bandstop Filter
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