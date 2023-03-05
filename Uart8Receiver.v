`include "UartStates.vh"

/*
 * 8-bit UART Receiver
 *
 * Able to receive 8 bits of serial data, one start bit, one stop bit
 *
 * When receive is detected and in progress over {in}, {busy} is driven high
 *
 * When receive is complete, {done} is driven high for one serial bit cycle
 *   (aka baud interval: equal to 16 {clk} ticks)
 *
 * Output data should be taken away within one baud interval or it will be lost
 *
 * System clock must be divided down to oversampling rate times baud rate
 *   to provide the {clk} input
 *
 * (*Note this module's logic is hard-coded based on 16x oversampling rate)
 */
module Uart8Receiver (
    input wire clk,      // rx data sampling rate
    input wire en,
    input wire in,       // rx line
    output reg busy,     // transaction is in progress
    output reg done,     // end of transaction
    output reg err,      // error while receiving data
    output reg [7:0] out // the received data assembled in parallel form
);

reg [2:0] state          = `RESET;
reg [1:0] in_reg         = 2'b0; // shift reg for input signal conditioning
reg [4:0] in_hold_reg    = 5'b0; // shift reg for signal hold time checks
reg [3:0] sample_count   = 4'b0; // count ticks for 16x oversample
reg [4:0] out_hold_count = 5'b0; // count ticks before clearing output data
reg [2:0] bit_index      = 3'b0; // index for 8-bit data
reg [7:0] received_data  = 8'b0; // shift reg for the deserialized data
wire in_sample;
wire [3:0] in_prior_hold_reg;
wire [3:0] in_current_hold_reg;

/*
 * Double-register the incoming data:
 *
 * This prevents metastability problems crossing into rx clock domain
 *
 * After registering, only the in_sample wire is to be accessed - the
 *   earlier, unconditioned signal {in} must be ignored
 */
always @(posedge clk) begin
    in_reg <= { in_reg[0], in };
end

assign in_sample = in_reg[1];

/*
 * Track the incoming data for 4 rx {clk} ticks + 1, to be able to enforce a
 *   minimum hold time of 4 {clk} ticks for any rx signal
 */
always @(posedge clk) begin
    in_hold_reg <= { in_hold_reg[3:1], in_sample, in_reg[0] };
end

assign in_prior_hold_reg   = in_hold_reg[4:1];
assign in_current_hold_reg = in_hold_reg[3:0];

/*
 * End the validity of output data after precise time of one serial bit cycle:
 *
 * Output signals from this module might as well be consistent with input
 *   rate, which is the baud rate
 *
 * This hold is for the case when detection of a next transmit cut the
 *   prior stop and ready transitions short; i.e. IDLE state has been entered
 *   direct from STOP_BIT state or READY state
 */
always @(posedge clk) begin
    if (|out_hold_count) begin
        out_hold_count     <= out_hold_count + 5'b1;
        if (out_hold_count == 5'b10000) begin // reached 16 -
            // timed output interval ends
            out_hold_count <= 5'b0;
            done           <= 1'b0;
            out            <= 8'b0;
        end
    end
end

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
            sample_count   <= 4'b0;
            out_hold_count <= 5'b0;
            received_data  <= 8'b0;
            // outputs
            busy           <= 1'b0;
            done           <= 1'b0;
            if (en && err && !in_sample) begin // in error condition already -
                // leave the output uninterrupted
                err        <= 1'b1;
            end else begin
                err        <= 1'b0;
            end
            out            <= 8'b0; // output parallel data only during {done}
            // next state
            if (en) begin
                state      <= `IDLE;
            end
        end

        `IDLE: begin
            /*
             * Accept low-going input as the trigger to start:
             *
             * Count from the first low sample, and sample again at the
             *   mid-point of a full baud interval to accept the low signal
             *
             * Then start the count for the proceeding full baud intervals
             */
            if (!in_sample) begin
                if (sample_count == 4'b0) begin
                    if (&in_prior_hold_reg || done && !err) begin
                        // meets the preceding min high hold time -
                        // note that {done} && !{err} encodes the fact that
                        // the min hold time was met earlier in STOP_BIT state
                        // or READY state
                        sample_count  <= 4'b1;
                        err           <= 1'b0;
                    end else begin
                        // this was a false start -
                        // remain in IDLE state with sample_count zero
                        err           <= 1'b1;
                    end
                end else begin
                    sample_count      <= sample_count + 4'b1;
                    if (sample_count == 4'b1100) begin // reached 12
                        // start signal meets an additional hold time
                        // of >= 4 rx ticks after its own mid-point -
                        // start new full interval count but from the mid-point
                        sample_count  <= 4'b0100;
                        busy          <= 1'b1;
                        err           <= 1'b0;
                        state         <= `START_BIT;
                    end
                end
            end else if (|sample_count) begin
                // bit did not remain low while waiting till 8 then 12 -
                // remain in IDLE state
                sample_count          <= 4'b0;
                received_data         <= 8'b0;
                err                   <= 1'b1;
            end
        end

        `START_BIT: begin
            /*
             * Wait one full baud interval to the mid-point of first bit
             */
            sample_count      <= sample_count + 4'b1;
            if (&sample_count) begin // reached 15
                // sample_count wraps around to zero
                bit_index     <= 3'b1;
                received_data <= { in_sample, 7'b0 };
                out           <= 8'b0;
                state         <= `DATA_BITS;
            end
        end

        `DATA_BITS: begin
            /*
             * Take 8 baud intervals to receive serial data
             */
            sample_count      <= sample_count + 4'b1;
            if (&sample_count) begin // reached 15 - save one more bit of data
                // store the bit using a shift register: the hardware
                // realization is simple compared to routing the bit
                // dynamically, i.e. using received_data[bit_index]
                received_data <= { in_sample, received_data[7:1] };
                // manage the state transition
                bit_index     <= bit_index + 3'b1;
                if (&bit_index) begin
                    // bit_index wraps around to zero
                    // sample_count wraps around to zero
                    state     <= `STOP_BIT;
                end
            end
        end

        `STOP_BIT: begin
            /*
             * Accept the received data if input goes high:
             *
             * If stop signal condition(s) met, drive the {done} signal high
             *   for one bit cycle
             *
             * Otherwise drive the {err} signal high for one bit cycle
             *
             * Since this baud clock may not track the transmitter baud clock
             *   precisely in reality, accept the transition to handling the
             *   next start bit any time after the stop bit mid-point
             */
            sample_count               <= sample_count + 4'b1;
            if (sample_count[3]) begin // reached 8 to 15
                if (!in_sample) begin
                    // accept that transmit has completed only if the stop
                    // signal held for a time of >= 4 rx ticks before it
                    // changed to a start signal
                    if (sample_count == 4'b1000 &&
                            &in_prior_hold_reg) begin // meets the hold time
                        // can accept the transmitted data and output it
                        sample_count   <= 4'b0;
                        out_hold_count <= 5'b1;
                        done           <= 1'b1;
                        out            <= received_data;
                        state          <= `IDLE;
                    end else if (&sample_count) begin // reached 15
                        // bit did not go high or remain high -
                        // signal {err}, continuing until condition resolved
                        sample_count   <= 4'b0;
                        received_data  <= 8'b0;
                        busy           <= 1'b0;
                        err            <= 1'b1;
                        state          <= `IDLE;
                    end
                end else begin
                    if (&in_current_hold_reg) begin // meets min high hold time
                        // can accept the transmitted data and output it
                        sample_count   <= 4'b0;
                        done           <= 1'b1;
                        out            <= received_data;
                        state          <= `READY;
                    end else if (&sample_count) begin // reached 15
                        // did not meet min high hold time -
                        // signal {err} for this transmit
                        sample_count   <= 4'b0;
                        err            <= 1'b1;
                        state          <= `READY;
                    end
                end
            end
        end

        `READY: begin
            /*
             * Wait one full bit cycle to sustain the {out} data, the
             *   {done} signal or the {err} signal
             */
            sample_count              <= sample_count + 4'b1;
            if (!err && !in_sample || &sample_count) begin
                // check if this is the change to a start signal -
                // note that in this state, in_sample has met the min high
                // hold time any time it drops to low
                // (also in these cases, namely !{err} or tick 15 special case,
                //  signaling of {done} is in progress)
                if (&sample_count) begin // reached 15, last tick, and no error
                    // (signaling of {done} is now complete)
                    if (in_sample) begin
                        // not transitioning to start bit -
                        // sample_count wraps around to zero
                        received_data <= 8'b0;
                        busy          <= 1'b0;
                    end else begin
                        // transitioning to start bit -
                        // sustain the {busy} signal high
                        sample_count  <= 4'b1;
                    end
                    done              <= 1'b0;
                    out               <= 8'b0;
                    state             <= `IDLE;
                end else begin
                    // in_sample drops from high to low
                    // (signaling of {done} continues)
                    sample_count      <= 4'b1;
                    // continue the counting
                    out_hold_count    <= sample_count + 5'b00010;
                    state             <= `IDLE;
                end
            end else if (&sample_count[3:1]) begin // reached 14 -
                // additional tick 15 comes from transiting the READY state
                // to get to the RESET state
                if (err || !in_sample) begin
                    state             <= `RESET;
                end
                // otherwise, signaling of {done} is in progress (i.e. !{err}) -
                // in this case, on tick 15, will be checking if in_sample
                // dropped from high to low on the entry to IDLE state
            end
        end

        default: begin
            state <= `RESET;
        end
    endcase
end

endmodule
