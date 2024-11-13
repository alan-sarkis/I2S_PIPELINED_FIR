`timescale 1ns/1ps

module FIR_tb();

reg MCLK = 0;
reg [3:0] SWITCH = 0;

reg signed [23:0] RIGHT_RX = 0;
reg signed [23:0] LEFT_RX = 0;

reg RIGHT_RX_READY = 0;
reg LEFT_RX_READY = 0;

wire signed [23:0] RIGHT_TX;
wire signed [23:0] LEFT_TX;

always #22.14 MCLK = ~MCLK; // 22.579 MHz Clock

FIR i1(
    .MCLK(MCLK),
    .SWITCH(SWITCH),
    .RIGHT_RX(RIGHT_RX),
    .LEFT_RX(LEFT_RX),
    .RIGHT_RX_READY(RIGHT_RX_READY),
    .LEFT_RX_READY(LEFT_RX_READY),
    .RIGHT_TX(RIGHT_TX),
    .LEFT_TX(LEFT_TX)
);

////// Setting up RX_READY to Mimic it from Transciever Code //////
always begin
    #12195 // Half a period of LRCK
    RIGHT_RX_READY <= 1;
    LEFT_RX_READY <= 0;
    @(posedge MCLK);
    RIGHT_RX_READY <= 0;
    LEFT_RX_READY <= 0;
    #12195 // Half a period of LRCK
    RIGHT_RX_READY <= 0;
    LEFT_RX_READY <= 1;
    @(posedge MCLK);
    RIGHT_RX_READY <= 0;
    LEFT_RX_READY <= 0;
end

/////// Testing Each Filter //////

initial begin
    SWITCH = 4'b0000; // No Filter
    #10000000
    SWITCH = 4'b0001; // Lowpass Filter
    #10000000
    SWITCH = 4'b0010; // Highpass Filter
    #10000000
    SWITCH = 4'b0100; // Bandpass Filter
    #10000000
    SWITCH = 4'b1000; // Bandstop Filter
    #10000000
    $stop();
end


///////// DDS WAVE INPUT for Testing ///////

reg aclk = 0;

wire signed [15:0] sin500hz;
wire signed [15:0] sin5000hz;

always #5 aclk = ~aclk;

dds_compiler_500hz freq500hz(.aclk(aclk), .m_axis_data_tdata(sin500hz));
dds_compiler_5000hz freq5000hz(.aclk(aclk), .m_axis_data_tdata(sin5000hz));


always@(posedge MCLK)begin
    LEFT_RX <= sin500hz + sin5000hz;
    RIGHT_RX <= sin500hz + sin5000hz;
 end

endmodule