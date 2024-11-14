//////////////////////////////////////////////////////////////////////////////////
// Company: 4th Year Student
// Engineer: Alan Sarkis
// 
// Design Name: top
// Module Name: top
// Project Name: I2S_PIPELINED_FIR
// Target Devices: ZYBO Z7-20, PMOD I2S2
//
// Description: This module combines both submodules:
// - I2S2_Transciever.v
// - FIR.sv
// 
//////////////////////////////////////////////////////////////////////////////////

module top(
    input SYS_CLK,
    input SDIN,
    input [3:0] SWITCH,
    output rx_MCLK, rx_LRCK, rx_SCLK,
    output tx_MCLK, tx_LRCK, tx_SCLK,
    output SDOUT
);

wire MCLK, LRCK, SCLK;

assign rx_MCLK = MCLK;
assign tx_MCLK = MCLK;

assign rx_LRCK = LRCK;
assign tx_LRCK = LRCK;

assign rx_SCLK = SCLK;
assign tx_SCLK = SCLK;

wire signed [23:0] RIGHT_RX, LEFT_RX;
wire signed [23:0] RIGHT_TX, LEFT_TX;

wire RIGHT_RX_READY, LEFT_RX_READY;


clk_wiz_0 i1(
    .SYS_CLK(SYS_CLK),
    .MCLK(MCLK)
);

I2S2_TRANSCIEVER ii1(
    .MCLK(MCLK),
    .SCLK(SCLK),
    .LRCK(LRCK),
    .SDIN(SDIN),
    .SDOUT(SDOUT),
    .RIGHT_RX(RIGHT_RX),
    .LEFT_RX(LEFT_RX),
    .RIGHT_TX(RIGHT_TX),
    .LEFT_TX(LEFT_TX),
    .RIGHT_RX_READY(RIGHT_RX_READY),
    .LEFT_RX_READY(LEFT_RX_READY)
);

FIR iii1(
    .MCLK(MCLK),
    .SWITCH(SWITCH),
    .RIGHT_RX(RIGHT_RX),
    .LEFT_RX(LEFT_RX),
    .RIGHT_RX_READY(RIGHT_RX_READY),
    .LEFT_RX_READY(LEFT_RX_READY),
    .RIGHT_TX(RIGHT_TX),
    .LEFT_TX(LEFT_TX)
);

endmodule