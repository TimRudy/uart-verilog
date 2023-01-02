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
 *   the {start} input low then high
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
    input wire [7:0] in, // parallel data to transmit
    output reg busy,     // transmit is in progress
    output reg done,     // end of transmission
    output reg out       // tx line for serial data
);

reg [2:0] state     = `RESET;
reg [7:0] in_data   = 8'b0; // shift reg for the data to transmit serially
reg [2:0] bit_index = 3'b0; // index for 8-bit data

/*
 * Disable at any time in the flow
 */
always @(posedge clk) begin
    if (!en) begin
        state <= `RESET;
    end
end

/*
 * State machine
 */
always @(posedge clk) begin
    case (state)
        `RESET: begin
            // state variables
            bit_index <= 3'b0;
            // outputs
            busy      <= 1'b0;
            done      <= 1'b0;
            out       <= 1'b1; // drive the line high for IDLE state
            // next state
            if (en) begin
                state <= `IDLE;
            end
        end

        `IDLE: begin
            if (start) begin
                in_data <= in; // register the input data
                state   <= `START_BIT;
            end
        end

        `START_BIT: begin
            bit_index <= 3'b0;
            busy      <= 1'b1;
            done      <= 1'b0;
            out       <= 1'b0; // send the space output, aka start bit (low)
            state     <= `DATA_BITS;
        end

        `DATA_BITS: begin // take 8 clock cycles for data bits to be sent
            // grab each input bit using a shift register: the hardware
            // realization is simple compared to routing the access
            // dynamically, i.e. using in_data[bit_index]
            in_data   <= { 1'b0, in_data[7:1] };
            out       <= in_data[0];
            // manage the state transition
            bit_index <= bit_index + 3'b1;
            if (&bit_index) begin
                // bit_index wraps around to zero
                state <= `STOP_BIT;
            end
        end

        `STOP_BIT: begin
            done              <= 1'b1; // signal the transmission stop
            out               <= 1'b1; // transition to mark state output (high)
            if (start) begin
                if (done == 1'b0) begin // this distinguishes 2 sub-states
                    in_data   <= in; // register new input data
                    if (TURBO_FRAMES) begin
                        state <= `START_BIT; // go direct to transmit
                    end else begin
                        state <= `STOP_BIT; // keep mark state one extra cycle
                    end
                end else begin // there was extra cycle within this state
                    done      <= 1'b0;
                    state     <= `START_BIT; // now go to transmit
                end
            end else begin
                state         <= `RESET;
            end
        end

        default: begin
            state <= `RESET;
        end
    endcase
end

endmodule
