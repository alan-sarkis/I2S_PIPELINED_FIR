`timescale 1ns/1ps

module I2S2_TRANSCIEVER_tb();

reg MCLK = 0;
reg SDIN = 0;

reg [23:0] RIGHT_TX = 0;
reg [23:0] LEFT_TX = 0;

wire [23:0] RIGHT_RX;
wire [23:0] LEFT_RX;

wire RIGHT_RX_READY;
wire LEFT_RX_READY;

wire LRCK, SCLK;
wire SDOUT;


// TX IS NOT TESTED AS IT DEPENDS ON THE FIR FILTER

I2S2_TRANSCIEVER dut(
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

always #22.15 MCLK = ~MCLK; // Making 22.579 MHz Clock

always begin
    repeat(10) @(posedge MCLK);
    SDIN = $urandom();
end

always@(posedge MCLK)begin // Assigning TX to RX to bypass FIR for Testing
    if(LEFT_RX_READY)
        LEFT_TX <= LEFT_RX;
    if(RIGHT_RX_READY)
        RIGHT_TX <= RIGHT_RX;
end

initial begin
    #100000 $stop();
end

endmodule