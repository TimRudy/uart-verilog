`include "BaudRateGenerator.v"
`include "Uart8Receiver.v"
`include "Uart8Transmitter.v"

/*
 * Simple 8-bit UART realization
 *
 * Able to transmit and receive 8 bits of serial data, one start bit,
 *   one stop bit
 */
module Uart8 #(
    parameter CLOCK_RATE   = 100000000, // board clock (default 100MHz)
    parameter BAUD_RATE    = 9600,
    parameter TURBO_FRAMES = 0          // see Uart8Transmitter
)(
    input wire clk, // board clock (*note: at the {CLOCK_RATE} rate)

    // rx interface
    input wire rxEn,
    input wire rx,
    output wire rxBusy,
    output wire rxDone,
    output wire rxErr,
    output wire [7:0] out,

    // tx interface
    input wire txEn,
    input wire txStart,
    input wire [7:0] in,
    output wire txBusy,
    output wire txDone,
    output wire tx
);

// this value cannot be changed in the current implementation
parameter RX_OVERSAMPLE_RATE = 16;

wire rxClk;
wire txClk;

BaudRateGenerator #(
    .CLOCK_RATE(CLOCK_RATE),
    .BAUD_RATE(BAUD_RATE),
    .RX_OVERSAMPLE_RATE(RX_OVERSAMPLE_RATE)
) generatorInst (
    .clk(clk),
    .rxClk(rxClk),
    .txClk(txClk)
);

Uart8Receiver rxInst (
    .clk(rxClk),
    .en(rxEn),
    .in(rx),
    .busy(rxBusy),
    .done(rxDone),
    .err(rxErr),
    .out(out)
);

Uart8Transmitter #(
    .TURBO_FRAMES(TURBO_FRAMES)
) txInst (
    .clk(txClk),
    .en(txEn),
    .start(txStart),
    .in(in),
    .busy(txBusy),
    .done(txDone),
    .out(tx)
);

endmodule
