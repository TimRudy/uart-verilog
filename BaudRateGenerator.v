/*
 * Baud rate generator to divide {CLOCK_RATE} (internal system clock) into
 *   {BAUD_RATE} tx/rx pair, with rx oversample by default 16x
 */
module BaudRateGenerator #(
    parameter CLOCK_RATE         = 100000000, // board clock (default 100MHz)
    parameter BAUD_RATE          = 9600,
    parameter RX_OVERSAMPLE_RATE = 16
)(
    input wire clk,   // board clock (*note: at the {CLOCK_RATE} rate)
    output reg rxClk, // baud rate for rx
    output reg txClk  // baud rate for tx
);

localparam RX_ACC_MAX   = CLOCK_RATE / (2 * BAUD_RATE * RX_OVERSAMPLE_RATE);
localparam TX_ACC_MAX   = CLOCK_RATE / (2 * BAUD_RATE);
localparam RX_ACC_WIDTH = $clog2(RX_ACC_MAX);
localparam TX_ACC_WIDTH = $clog2(TX_ACC_MAX);

reg [RX_ACC_WIDTH-1:0] rx_counter = 0;
reg [TX_ACC_WIDTH-1:0] tx_counter = 0;

initial begin
    rxClk = 1'b0;
    txClk = 1'b0;
end

always @(posedge clk) begin
    // rx clock
    if (rx_counter == RX_ACC_MAX[RX_ACC_WIDTH-1:0]) begin
        rx_counter <= 0;
        rxClk      <= ~rxClk;
    end else begin
        rx_counter <= rx_counter + 1'b1;
    end

    // tx clock
    if (tx_counter == TX_ACC_MAX[TX_ACC_WIDTH-1:0]) begin
        tx_counter <= 0;
        txClk      <= ~txClk;
    end else begin
        tx_counter <= tx_counter + 1'b1;
    end
end

endmodule
