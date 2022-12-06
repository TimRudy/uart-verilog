`include "UartStates.vh"

/*
 * 8-bit UART Transmitter
 *
 * Able to transmit 8 bits of serial data, one start bit, one stop bit
 *
 * When transmit is in progress over {out}, {busy} is driven high
 *
 * When transmit is complete, {done} is driven high for one tx clock cycle
 *
 * Capable of back-to-back transmits for full bandwidth utilization,
 *   by only changing the {in} data
 *   (*change before {done} rising edge)
 *
 * Finer control over when to start the next frame is provided by cycling
 *   the {start} input low then driving it high
 *
 * System clock must be divided down to the baud rate, which is the
 *   {clk} input
 *
 * {TURBO_FRAMES}: performance mode versus forgiving mode:
 *
 * 0: forgiving mode:
 *    drive the mark state, aka stop bit, output high for two
 *    tx clock cycles instead of one - this way, the boundaries between
 *    data frames are distinguished in the transmitted data stream,
 *    for more robust sync between tx/rx
 *    (*sync can be re-established more quickly if it's lost)
 *    (*this mode will only have an effect in the max, back-to-back,
 *     frame transmission use case)
 *    (*this mode has no positive effect in an environment of
 *     reliably matched tx/rx baud clocks)
 *
 * 1: performance mode:
 *    drive the mark state output high for one cycle when at max rate
 *    (*this is the normal UART protocol: 80% effective data rate
 *     for 8 bits in a frame, no parity)
 */
module Uart8Transmitter #(
    parameter TURBO_FRAMES = 0
)(
    input wire clk,      // baud rate
    input wire en,
    input wire start,    // start transmission
    input wire [7:0] in, // data to transmit
    output reg busy,     // transmit is in progress
    output reg done,     // end of transmission
    output reg out       // tx line
);

reg [2:0] state    = `RESET;
reg [7:0] inData   = 8'b0; // storage for the data to transmit serially
reg [2:0] bitIndex = 3'b0; // index for 8-bit data

always @(posedge clk) begin
    if (!en) begin
        state <= `RESET;
    end

    case (state)
        `RESET: begin
            busy      <= 1'b0;
            done      <= 1'b0;
            out       <= 1'b1; // line is high for IDLE state
            if (en) begin
                state <= `IDLE;
            end
        end

        `IDLE: begin
            if (start) begin
                inData <= in; // register the input data
                state  <= `START_BIT;
            end
        end

        `START_BIT: begin
            busy     <= 1'b1;
            done     <= 1'b0;
            out      <= 1'b0; // send the space output, aka start bit (low)
            bitIndex <= 3'b0;
            state    <= `DATA_BITS;
        end

        `DATA_BITS: begin // take 8 clock cycles for data bits to be sent
            out          <= inData[bitIndex];
            if (&bitIndex) begin
                bitIndex <= 3'b0;
                state    <= `STOP_BIT;
            end else begin
                bitIndex <= bitIndex + 1'b1;
            end
        end

        `STOP_BIT: begin
            done       <= 1'b1; // signal transmission stop (one clock cycle)
            out        <= 1'b1; // transition to the mark state output (high)
            if (TURBO_FRAMES && start) begin
                inData <= in; // register the input data
                state  <= `START_BIT; // go straight to transmit
            end else begin
                state  <= `RESET; // keep mark state (high) for one extra cycle
            end
        end

        default: begin
            state <= `RESET;
        end
    endcase
end

endmodule