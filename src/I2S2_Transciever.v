//////////////////////////////////////////////////////////////////////////////////
// Company: 4th Year Student
// Engineer: Alan Sarkis
// 
// Design Name: I2S2 TRANSCIEVER
// Module Name: I2S2_TRANSCIEVER
// Project Name: I2S_PIPELINED_FIR
// Target Devices: ZYBO Z7-20, PMOD I2S2
//
// Description: The purpose of this module is to communicate from the PMOD I2S2
// peripheral with the Zybo Board. The transciever operates as a slave meaning
// that the clock signals are fully supplied by the FPGA. All the values used
// for the clock divider and clock wizard are referenced from the reference
// manuals given in the readme of this project.
//
// Specs: 
// - 41000 Hz Sampling Frequency
// - 24 Bits of Data per Sample
// - Righ-Justified
// - PMOD I2S2 operating as Slave
// 
//////////////////////////////////////////////////////////////////////////////////

module I2S2_TRANSCIEVER(
    input MCLK, // 22.579MHz
    output SCLK, // 8 Periods of MCLK
    output LRCK,  // 512 Periods of MCLK Right-Justified

    input SDIN,
    output reg SDOUT,

    output reg signed [23:0] RIGHT_RX = 0, // Data for Right Channel
    output reg signed [23:0] LEFT_RX = 0, // Data for Left Channel

    input signed [23:0] RIGHT_TX,
    input signed [23:0] LEFT_TX,

    output RIGHT_RX_READY,
    output LEFT_RX_READY
);

localparam DATA_WIDTH = 24;
localparam FIRST_PERIOD = 8'b0000011; // Start sampling after 1 period of SCLK
localparam SAMPLE_DONE  = 8'd200; // End of sample frame: (8 Periods of MCLK) * (25 Periods of SCLK) = 200
localparam SCLK_POSEDGE = 3'b011; // Positive Edge of SCLK is when COUNT[2:0] = 3'b011 (It is not 3'b100 as we have a delay)
localparam SCLK_NEGEDGE = 3'b111; // Negative Edge of SCLK is when COUNT[2:0] = 3'b111 (It is not 3'b000 as we have a delay)

////// Setting up SCLK and LRCK ///////
reg [8:0] COUNT = 9'd0;

always@(posedge MCLK)
    COUNT <= COUNT + 1;
    
assign LRCK = COUNT[8];
assign SCLK = COUNT[2];

////// Setting up RX //////
always@(posedge MCLK)begin
    if(COUNT[2:0] == SCLK_POSEDGE && COUNT[7:0] > FIRST_PERIOD && COUNT[7:0] <= SAMPLE_DONE)begin
        if(LRCK)begin
            RIGHT_RX <= {RIGHT_RX[DATA_WIDTH-2:0], SDIN};
            LEFT_RX  <= 0;
        end
        else begin
            LEFT_RX <= {LEFT_RX[DATA_WIDTH-2:0], SDIN};
            RIGHT_RX <= 0;
        end
    end
end

assign RIGHT_RX_READY = (COUNT[7:0] == SAMPLE_DONE && LRCK); // TRANSMIT RIGHT DATA FLAG
assign LEFT_RX_READY  = (COUNT[7:0] == SAMPLE_DONE && ~LRCK); // TRANSMIT LEFT DATA FLAG


/////// Setting up TX For Playback////////
reg [4:0] DATA_COUNT = 0; // Count to read data from MSB to LSB

always@(posedge MCLK)begin
    if(DATA_COUNT == DATA_WIDTH || COUNT[7:0] > SAMPLE_DONE) // When sampling is done or data count reaches 24 bits, we reset the counter
        DATA_COUNT <= 0;
    else if(COUNT[2:0] == SCLK_NEGEDGE && COUNT[7:0] > FIRST_PERIOD && COUNT[7:0] <= SAMPLE_DONE)begin 
        DATA_COUNT <= DATA_COUNT + 1; // Count increases each negative edge to read next bit
        if(LRCK)
            SDOUT <= RIGHT_TX[(DATA_WIDTH-1)-DATA_COUNT];
        else
            SDOUT <= LEFT_TX[(DATA_WIDTH-1)-DATA_COUNT];
    end
end

endmodule
