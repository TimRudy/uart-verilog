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
    output reg [7:0] out // received data
);

reg [2:0] state        = `RESET;
reg [2:0] bitIndex     = 3'b0; // index for 8-bit data
reg [1:0] inShiftReg   = 2'b0; // shift reg for input signal conditioning
reg [3:0] inHoldReg    = 4'b0; // shift reg for stop signal hold time check
reg [3:0] sampleCount  = 4'b0; // count ticks for 16x oversample
reg [3:0] validCount   = 4'b0; // count ticks before clearing output data
reg [7:0] receivedData = 8'b0; // storage for the deserialized data
wire inSample;

/*
 * Double-register the incoming data:
 *
 * This prevents metastability problems crossing into rx clock domain
 *
 * After registering, only the {inSample} wire is to be accessed - the
 *   earlier, unconditioned signal {in} must be ignored
 */
always @(posedge clk) begin
    inShiftReg <= { inShiftReg[0], in };
end

assign inSample = inShiftReg[1];

/*
 * End the validity of output data after precise time of one serial bit cycle:
 *
 * Output signals from this module might as well be consistent with input
 *   rate, which is the baud rate
 *
 * This hold is for the case when detection of a next transmit cut short
 *   the prior stop and ready transitions; i.e. IDLE state was entered direct
 *   from STOP_BIT state
 */
always @(posedge clk) begin
    if (|validCount) begin
        validCount <= validCount + 4'b1;
        if (&validCount) begin // reached 15 - timed output interval ends
            out    <= 8'b0;
        end
    end
end

always @(posedge clk) begin
    if (!en) begin
        state <= `RESET;
    end

    case (state)
        `RESET: begin
            busy         <= 1'b0;
            done         <= 1'b0;
            err          <= 1'b0;
            sampleCount  <= 4'b0;
            receivedData <= 8'b0;
            out          <= 8'b0;
            if (en) begin
                state    <= `IDLE;
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
            if (!inSample) begin
                sampleCount     <= sampleCount + 4'b1;
                if (&sampleCount[2:0]) begin // reached 7
                    busy        <= 1'b1;
                    done        <= 1'b0;
                    err         <= 1'b0;
                    sampleCount <= 4'b0; // start the full interval count over
                    state       <= `START_BIT;
                end
            end else if (|sampleCount) begin
                // bit did not remain low while waiting till 7 -
                // remain in IDLE state
                err             <= 1'b1;
            end
        end

        `START_BIT: begin
            /*
             * Wait one full baud interval to the mid-point of first bit
             */
            sampleCount      <= sampleCount + 4'b1;
            if (&sampleCount) begin // reached 15
                receivedData <= { 7'b0, inSample };
                out          <= 8'b0;
                bitIndex     <= 3'b1;
                state        <= `DATA_BITS;
            end
        end

        `DATA_BITS: begin
            /*
             * Take 8 baud intervals to receive serial data
             */
            if (&sampleCount) begin // save one bit of received data
                sampleCount            <= 4'b0;
                receivedData[bitIndex] <= inSample;
                if (&bitIndex) begin
                    bitIndex           <= 3'b0;
                    state              <= `STOP_BIT;
                end else begin
                    bitIndex           <= bitIndex + 3'b1;
                end
            end else begin
                sampleCount            <= sampleCount + 4'b1;
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
            inHoldReg <= { inHoldReg[2:0], inSample };

            sampleCount              <= sampleCount + 4'b1;
            if (sampleCount[3]) begin // reached 8 to 15
                // in the second half of the baud interval
                if (!inSample) begin
                    // accept that transmission has completed only if the stop
                    // signal held for a time of >= 4 rx clocks before it
                    // changed to a start signal
                    if (&inHoldReg) begin
                        // can accept the transmitted data and output it
                        done         <= 1'b1;
                        out          <= receivedData;
                        validCount   <= sampleCount;
                        sampleCount  <= 4'b0;
                        state        <= `IDLE;
                    end else begin
                        // bit did not go high or remain high while waiting
                        // till 8 - signal {err} for this transmit
                        err          <= 1'b1;
                        sampleCount  <= 4'b0;
                        state        <= `READY;
                    end
                end else if (&sampleCount) begin // reached 15
                    // can accept the transmitted data and output it
                    done             <= 1'b1;
                    out              <= receivedData;
                    sampleCount      <= 4'b0;
                    state            <= `READY;
                end
            end
        end

        `READY: begin
            /*
             * Wait one full bit cycle to sustain the {out} data, the
             *   {done} signal or the {err} signal
             */
            sampleCount     <= sampleCount + 4'b1;
            if (&sampleCount[3:1]) begin // reached 14 -
                // additional tick 15 comes from transitting the READY state
                // to the RESET state
                state       <= `RESET;
            end
        end

        default: begin
            state <= `RESET;
        end
    endcase
end

endmodule
