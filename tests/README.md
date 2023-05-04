# Tests

**For reference**

[`CodeCoverageIndex.md`](CodeCoverageIndex.md "CodeCoverageIndex file")

- Lists all the non-trivial `if-else` branches in the code; each branch references a test that covers it

- The tests below provide the reverse index to the code coverage: Highlighted code lines are linked from each test

**Other notes**

- Red marker in each test points to where the essential action is

- The tests without .png screenshots you can easily view with GTKWave on your own copy of the repo

## Group 1 - TX module to RX module transmission

Group 1 tests use two different UART chips, with one's transmitter talking to the other's receiver. A UART chip has the two fully independent submodules so transmission can go either direction between two systems.

Test results would be identical, however, if a loopback configuration were used: testing on one chip only, connecting its tx pin to its rx pin. The equivalence is demonstrated by test variant [#1a](1a.v "Test bench 1a.v"): It's the same as test #1 but with the one-chip configuration. The delta of the test bench setup can be seen here: [1.v &larr;&rarr; 1a.v](https://github.com/TimRudy/uart-verilog/compare/main..TimRudy:diff-test-1a "Compare: Test bench setup using one-chip configuration").

Group 1 traces show the communication as an integrated whole:

- Relative timing of the bits sent, synched, received

- How the Uart8Transmitter (top half) and Uart8Receiver (bottom half) each indicates when it's busy, done, or the transmission is in error: `txBusy`, `txDone`, `rxBusy`, `rxDone`, `rxErr` signals are for external control purposes

- Result at a glance: When successful, the `out` value at bottom matches the `in` value at top left

<br />

### #1 One successful transmission frame

[![Test case 1][img-1-cr]][img-1]

[1.v](1.v "Test bench 1.v")

**Code Coverage Refs**

`Uart8Transmitter:` [`84`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L84), [`127`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L127)  
`Uart8Receiver:` [`133, 134`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L132-L134), [`148`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L148), [`238`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L237-L238), [`269`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L261-L269)  

**Observations**

- `txStart` must be asserted over the time period when data byte "`45`" is accepted for transmit

- `txEn` and `rxEn` must hold for the transmit and receive durations otherwise the transmission halts in the middle

- `rxDone` is the output that can be monitored for the purpose of grabbing the `out` data "`45`", because `out` is only available for a limited time

- `in_data` is the byte of data to transmit; `received_data` is the byte being reassembled on the other side

    <details>
    <summary>But what's the reason "in_data" changes during the progression?</summary>
    <br />

    First, note signal `in` is shown at the top of tests [#4](#4-two-successful-frames-second-is-shortened-due-to-external-reset) and following - not shown in this test. `in` is a wire by which the data, `45`, is presented to the transmitter. `in_data`, however, is a register accepting that data.

    The bits are shifted through the register (`Uart8Transmitter` ref above, line [`102`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L99-L102)). When the lowest-order bit of the `5` is taken away and shifted out, what's left is `2`; the higher-order bits that form the `4` shift to follow, so what's left in that position is `2`.

    The `45` -> `22` -> `...` is just an implementation detail, but worth mentioning because the design choice does not help with understandability and transparency. Not many people will ever look at that value in `in_data`, but you are looking at it. So the reason it is shifted 8 times is that each bit is only needed once by the next stage in processing, the bits are needed in order, and that's it: They can be thrown away as the progression happens. The shift register mechanism is very practical, very no-frills for the purpose required (comment at line [`102`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L99-L102)).

    `received_data` shows it has the same implementation. Given that the lowest bit comes first in the transmission sequence to the receiver, the shift implementation dictates: the bit shows up in the highest bit position, following which it progressively moves into place!

    </details>
    <br />

### #2 &ndash; #3

<details>
<summary>Tolerance for mismatch in transmit, receive clocks</summary>

### #2 Leading RX clock, correct data is read out

[2.v](2.v "Test bench 2.v")

**Observations**

- Tests #2 and #3 tweak the parameter `RX_OVERSAMPLE_RATE` to distort the relation between `txClk` and `rxClk`

- By design, the frequency ratio is `1:16`, but in reality the transmitting and receiving UARTs' clocks are independent, so unsynchronized. A degree of synchronization occurs through the UART protocol, though: Every 8 bits the receiver waits and listens for the idle-to-start transition. See the idle waiting interval in other tests, for example [#4, #5](#4-two-successful-frames-second-is-shortened-due-to-external-reset)

- The idle interval between each 8-bit packet gives a "reset" for sampling drift (from the precise middle of each bit) that may build up on the receiver side by the time of the eighth bit and the stop bit being sampled

<br />

### #3 Lagging RX clock, incorrect data is read out

[3.v](3.v "Test bench 3.v")

**Observations**

- `RX_OVERSAMPLE_RATE` is outside the range where the sampling of 8 bits by the receiver actually aligns with the 8 bits, so this demonstrates how communication will go wrong when two systems don't have the same UART protocol configured, or don't have the same nominal clock rate

</details>
<br />

### #4 &ndash; #8

<details>
<summary>Two transmission frames: Enabling, disabling and the use of "txStart" signal</summary>

### #4 Two successful frames, second is shortened due to external reset

[![Test case 4][img-4-cr]][img-4]

[4.v](4.v "Test bench 4.v")

**Code Coverage Refs**

`Uart8Transmitter:` [`127`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L127)

**Observations**

- Demonstrates the indefinitely long idle time for the transmitter (while enabled): After `txBusy` and `txDone`, transmitter state is `001`

- `IDLE` state `001` is ended by the `txStart` signal being clocked in

- Receiver is very much the same, except it relies on the transmitter to wake it from `IDLE` state `001`

- Note transmitter `out` and receiver `in`/`in_sample`: The `1` value of these is known as a "mark" and it signals waiting, in a state between transmits (terminology here will be "stop bit"); the drop to `0` is the signal to start receiving; because it is not the data yet, but a fixed length pause before the data, this `0` is known as a "space" (terminology here: "start bit")

- Second transmission frame is shortened, but it's not enough to affect the result since it's during the output. Note when `rxEn` drops to `0`: It makes the `rxDone` pulse shorter than `rxDone` in the first frame, it makes the state `101` shorter, and makes the availability of the "`7F`" data shorter

### #5 Correct data is read out for first frame, incorrect for second due to mismatch

[5.v](5.v "Test bench 5.v")

**Code Coverage Refs**

`Uart8Receiver:` [`244 (*second frame)`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L244)

### #6 Interrupted transmit followed by complete transmit

[6.v](6.v "Test bench 6.v")

**Code Coverage Refs**

`Uart8Transmitter:` [`84`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L84)

### #7 Interrupted transmit followed by complete transmit ("txStart" overlaps)

[7.v](7.v "Test bench 7.v")

**Code Coverage Refs**

`Uart8Transmitter:` [`84`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L84)

### #8 Interrupted transmit followed by failed transmit ("txStart" too short)

[![Test case 8][img-8-cr]][img-8]

[8.v](8.v "Test bench 8.v")

</details>
<br />

### #9 Continuous mode: Two successful transmission frames

[![Test case 9][img-9-cr]][img-9]

[9.v](9.v "Test bench 9.v")

**Code Coverage Refs**

`Uart8Transmitter:` [`84`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L84), [`115, 116`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L115-L116), [`120`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L120), [`123`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L123)  
`Uart8Receiver:` [`238`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L237-L238), [`269`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L261-L269)  

**Observations**

- For this mode, `txStart` does not go low; so for each frame the `in` data just needs to be set up in time to be captured in `in_data` and transmitted

- Limit time for set-up of `in`: Before the high-going clock at the high-going `txDone`

- This trace shows a third transmit starting, because `txStart` goes low too late at the end of second transmit

- Since this trace is longer, it reveals there is a lot of clock mismatch

    <details>
    <summary>How much clock mismatch is there?</summary>
    <br />

    By the end of 8 bits, timing appears about 3.5 RX clock periods off compared to the TX clock (for the baud rate chosen for this testing, anyway).

    The mismatch comes from round-off error: It's the fault of `BaudRateGenerator`'s simplistic code; so it's implementation, not testing-related. (As such, it is a factor of the chosen baud rate.)

    </details>
    <br />

### #10 Continuous mode, input data is set up just in time for transmit

[10.v](10.v "Test bench 10.v")

**Observations**

- The second transmit data `in` is set up just before the data capture; #9 shows earlier in the same clock cycle

<br />

### #11 Continuous mode, input data is not set up in time

[11.v](11.v "Test bench 11.v")

**Observations**

- Unlike in #9 and #10, the second `in` data signal lags the transmitter's high-going done signal; thus at the moment of the high-going `txDone`, you can see the previous `in` value is re-captured in `in_data`

- Shows a third transmit starting, because `txStart` goes low too late at the end of second transmit

- This test bench uses a feedback method of control to shut off `txStart`; so it's suggestive of ideas for external control of the UART; but these tests do not go into how you can use outputs for external control, and how to decide the timing of inputs

- The test benches in general though rely on tuned timings to present the inputs according to the intent of the test - in other words, empirical or ad hoc timings. Examples to illustrate:

  - Interval `#11500` used in test [#13](#13-turbo_frames--0): Because each cycle is about 11.5ms, this gives prep or set-up times mid-way through each transmit for pushing each next byte (this is the `in` transitions relative to the `txDone` pulses)
  - Compare `#10750` used in test [#14](#13-turbo_frames--0), because its cycles are shorter

<br />

### #12 Continuous mode: 8-N-1 (TURBO_FRAMES = 1)

[![Test case 12][img-12-cr]][img-12]

[12.v](12.v "Test bench 12.v")

**Code Coverage Refs**

`Uart8Transmitter:` [`115, 116`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L115-L116), [`118`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L118)  
`Uart8Receiver:` [`79`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L79), [`282`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L282)  

**Observations**

- Here the UART is instantiated with parameter `TURBO_FRAMES = 1`, and it means the transmitter sends a "stop bit" of the duration of 1 bit rather than duration 2 bits

- Documentation for the `8-N-1`, `8-N-2` modes: In `Uart8Transmitter` [`header`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L22-L38 "Header comments about 8-N-1, 8-N-2")

- This mode `8-N-1` provides the maximum bandwidth: Effective data rate of 80% over the serial line, because 10 bits are transmitted for each 8-bit packet

- But I gave the Verilog code a default of `8-N-2`, `TURBO_FRAMES = 0`, because it fits the project's purpose, namely: simulation & testing, either for the UART's own sake or to support other projects in development; and: education, visualization. So by default, the UART might as well be more bullet-proof in use; if you are getting specific about your use case, then you'll set the parameters

- The Verilog that implements the `TURBO_FRAMES` feature (see `Uart8Transmitter` refs above), deserves a note for the reader

    <details>
    <summary>Not 100% transparent Verilog implementation</summary>
    <br />

    The [code](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L112-L130 "Transmitter code for `STOP_BIT` state: `TURBO_FRAMES`") for `STOP_BIT` state waits in that state for either 1 tick or 2 - but how, and why, is it using that `done` variable?

    You need to know the meaning of "`<=`", in context, in procedural block code.

    Specifically, `done <= 1'b1;` appears to do something, but remember, its change to the value is not applied till the end of the time slice; consequently, the code after it `if (done == 1'b0)` is referring to the value at the current time *before* `done` is changed at all; so it is not a mistake!

    The code `done <= 1'b0;` in the same block is simply contradicting (overriding) the prior `done <= 1'b1;` which is (was) pending. ...So you see that that makes perfect sense as well!

    Those are hints to reveal how the `if-else` code works to introduce a single-clock-tick delay (that is, an extra one). The logic could present itself more clearly, if there was a separate new variable, or another state, but for convenience and economy it uses variable `done` that is boolean and is already at hand.

    </details>
    <br />

### #13 &ndash; #15

<details>
<summary>Twenty transmission frames continuous mode: 8-N-1, 8-N-2</summary>

### #13 TURBO_FRAMES = 0

[![Test case 13][img-13-cr]][img-13]

[13.v](13.v "Test bench 13.v")

**Code Coverage Refs**

`Uart8Transmitter:` [`120`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L120), [`123`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Transmitter.v#L123)

<br />

### #14 TURBO_FRAMES = 1

[![Test case 14][img-14-cr]][img-14]

[14.v](14.v "Test bench 14.v")

**Observations**

- The differences between #13 and #14 are seen in:

  - `out` of the transmitter: The narrowing of the high (stop) signal which is the pulse directly below each `txDone` pulse
  - `rxBusy` of the receiver: The disappearance of the one-tx-clock-period `IDLE` state
  - Completion, at the red marker, about 1.5ms earlier

<br />

### #15 TURBO_FRAMES = 1, two transmissions are lost due to clock mismatch

[![Test case 15][img-15-cr]][img-15]

[15.v](15.v "Test bench 15.v")

**Observations**

- Input byte "`99`" misses its deadline; however, it is still present at the input for next data capture, so it is transmitted

- The bytes after it are all accounted for, synchronously, until byte "`7`" misses its deadline

- This shows the virtue of limiting the length of bursts of data sent with this simple protocol; if each burst in this test (*note it is an extreme example), were 8 bytes (frames), followed by driving the `txStart` signal low then going on to the next burst, then there would have been no data errors

- There is no `rxErr` signal for this scenario because there is no breach of the protocol

</details>
<br />
<br />

## Group 2 - RX module

Group 2 tests are for the receiver RX part of the UART.

The TX module is fairly deterministic, and it's been tested by all the transmits of the Group 1 scenarios.

The RX module has a tougher job, because it receives an arbitrary signal pattern as input and must make sense of it. It must lock on and accept good serial data (forming a frame), or otherwise must reject a data stream if the data doesn't start cleanly from a baseline signal, or if it doesn't end in the accepted way, to certify that it's well-formed.

These test signals don't have to come from a well-behaved or realistic TX module. You could consider them from a potentially "malicious" transmitter.

To note: If the protocol requirements are not met, and the output isn't the 8-bit byte expected, then the output can include an error signal or can just be garbled data.

So, these tests are fine-grained in order to nail down the behaviour of the RX device by exploring the range of signal waveforms possible (mainly the variety of timings; and the signal held low when it should revert to high or vice versa; in addition, high-low or low-high glitches). Variants of tests are necessary to do this. I named files with an "a" suffix, like #18a.v, when they were used to explore changed waveforms - over a range related to that test - to keep them separate from the canonical test.

<br />

### #16 Transmit start is recognized because rx signal was high for minimum 4 ticks

[![Test case 16][img-16-cr]][img-16]

[16.v](16.v "Test bench 16.v")

**Code Coverage Refs**

`Uart8Receiver:` [`134`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L132-L134)

**Observations**

- Look at `in_sample` rather than `rx`. `rx` is the external signal to the Device Under Test; `in_sample` follows it; all the subsequent, or coincident, signal changes of interest are tied to the latter

- `clk` in these traces is `rxClk` (16x higher frequency than the `txClk` of this communication)

<br />

### #17 Transmit start is not recognized because rx signal was not high for 4 ticks

[![Test case 17][img-17-cr]][img-17]

[17.v](17.v "Test bench 17.v")

**Code Coverage Refs**

`Uart8Receiver:` [`141`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L141)

**Observations**

- Here is an example of the `err` signal turning on (`err` is `rxErr`)

- The device is in state `001` the whole time; after `err` clears, it's ready to go on and start receiving data

- Look at the `Uart8Receiver` code ref to see where and why `err` is signaled; at around the same place in the code, you'll see the condition under which it's cleared

  <details>
  <summary>Some Verilog hints to understand the code</summary>
  <br />

  - The "`&`" operator of `&in_prior_hold_reg` collects the bits, and the expression is true if all the bits are `1`; secondly, `in_prior_hold_reg` is a vector of size `4`, and is a shift register; this provides a connection to time passing: `4` ticks of the clock for it to fill up (say with `1`s)

  - Ticks of the clock are implicitly being examined, and waited for, by this section of code: `4` ticks, `8` ticks, `12` ticks; `16` ticks is the nominal duration of an incoming bit being sampled; if you understand line [`152`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L152): `sample_count <= 4'b0100;` and how `sample_count` is being used cycling from `0` to `F`, then you've understood a lot of the code and the protocol, and how a Finite State Machine is useful

  - When `in_sample` drops to `0`, that's the trigger for recovering from the error: `in_prior_hold_reg` is losing its `1` bits and goes away from the `F` or `&in_prior_hold_reg` condition; `sample_count`, if it continues to increase, will allow moving from the `IDLE` state to `START_BIT` state

  </details>
  <br />

### #18 Transmit start fails because rx signal goes high too early

[![Test case 18][img-18-cr]][img-18]

[18.v](18.v "Test bench 18.v")

**Code Coverage Refs**

`Uart8Receiver:` [`134`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L134), [`158`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L158)

**Observations**

- Compared to #17, it's a different condition, a different code branch that turns on the `err` signal

- Note below and in some other tests a "variant" test bench is included:

  - This was used to plug in different wait-time numbers, basically a range of timings for this specific signal and transition that's being tested; the process can find and go beyond the threshold where the response changes

  - The variation can be down to individual clock ticks, because exactitude is needed if there's any doubt or there could be "off-by-one" errors

  - (I also made variations to test benches to switch input values, `1` to `0` etc.; for example, when a `0` lines up as first bit after the "start" bit or a `1` lines up as last bit before the "stop" bit, these are edge cases needing to be tested)

**Variant #18a**

- Focuses on the high in `IDLE` state after a false start bit (start signal has gone high too early)

- `18a.v` line [`63`](https://github.com/TimRudy/uart-verilog/blob/a805332/tests/18a.v#L63 "Test bench changes at line 63"): Try `#230` for short, `#250` meets the minimum, `#300` long

<br />

### #19 Transmit start fails because rx signal goes low-high-low

[19.v](19.v "Test bench 19.v")

**Code Coverage Refs**

`Uart8Receiver:` [`158`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L158)

**Observations**

- Start is recognized at the time a high signal eventually holds for a full `4` ticks; then `err` is cleared

- As in #17 and #18, the test ends in `IDLE` state, looking to proceed after the low signal holds for `12` ticks

<br />

### #20 Transmit stop is recognized after rx signal goes high-low-high then is stable

[![Test case 20][img-20-cr]][img-20]

[20.v](20.v "Test bench 20.v")

**Code Coverage Refs**

`Uart8Receiver:` [`215`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L215), [`238`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L237-L238)

**Observations**

- The reader can explore the implication of splitting `in_current_hold_reg` from `in_prior_hold_reg`; these are views into the register that stores the most recent `in` signal values/changes; the look-back allows for **signal hold time checks**

**Variant #20a**

<br />

### #21 Transmit stop is recognized after rx signal goes high-low-high past tick 8

[![Test case 21][img-21-cr]][img-21]

[21.v](21.v "Test bench 21.v")

**Code Coverage Refs**

`Uart8Receiver:` [`215, 216`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L215-L216), [`238`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L237-L238)

**Variant #21a**

<br />

### #22 Transmit fails because rx signal goes high too late, after tick 8

[![Test case 22][img-22-cr]][img-22]

[22.v](22.v "Test bench 22.v")

**Code Coverage Refs**

`Uart8Receiver:` [`215, 216`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L215-L216), [`244`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L244)

**Variant #22a**

<br />

### #23 Transmit fails because rx signal does not go high; error state begins

[23.v](23.v "Test bench 23.v")

**Code Coverage Refs**

`Uart8Receiver:` [`228`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L228)

<br />

### #24 Error state holds as long as rx signal has never gone high

[24.v](24.v "Test bench 24.v")

**Code Coverage Refs**

`Uart8Receiver:` [`134`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L132-L134), [`141`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L141)

**Observations**

- This test covers an edge case of the `err` tests #17, #18 and #19

<br />

### #25 &ndash; #30

<details>
<summary>Transition between two frames: Overlap of done and error signals</summary>

### #25 Next transmit frame starts after rx signal was high for minimum 8 ticks

[![Test case 25][img-25-cr]][img-25]

[25.v](25.v "Test bench 25.v")

**Code Coverage Refs**

`Uart8Receiver:` [`79`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L79), [`220`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L215-L221)

**Observations**

- Shows `done` sustained for `16`-tick cycle which overlaps with the next frame start

- Passes the condition at line [`134`](https://github.com/TimRudy/uart-verilog/blob/a805332/Uart8Receiver.v#L134), immediately on entry to `IDLE` state

<br />

### #26 Successful transmit done signal overlaps with next transmit start error

[![Test case 26][img-26-cr]][img-26]

[26.v](26.v "Test bench 26.v")

<br />

### #27 Next transmit frame start overlaps with previous frame done signal

[27.v](27.v "Test bench 27.v")

**Variant #27a**

### #28 Next transmit frame start overlaps with previous frame done signal 2

[28.v](28.v "Test bench 28.v")

### #29 Successful transmit done signal overlaps with next transmit start error 2

[29.v](29.v "Test bench 29.v")

**Variant #29a**

### #30 Transmit fails, error state is continuous with next transmit start error

[30.v](30.v "Test bench 30.v")

**Observations**

- Shows err sustained high, no glitch low-high

</details>

[img-1]: images/1.png "Test case 1"
[img-1-cr]: images/1-cr.png
[img-4]: images/4.png "Test case 4"
[img-4-cr]: images/4-cr.png
[img-8]: images/8.png "Test case 8"
[img-8-cr]: images/8-cr.png
[img-9]: images/9.png "Test case 9"
[img-9-cr]: images/9-cr.png
[img-12]: images/12.png "Test case 12"
[img-12-cr]: images/15-cr.png
[img-13]: images/13.png "Test case 13"
[img-13-cr]: images/13-cr.png
[img-14]: images/14-timesync.png "Test case 14"
[img-14-cr]: images/14-cr.png
[img-15]: images/15.png "Test case 15"
[img-15-cr]: images/15-cr.png
[img-16]: images/16.png "Test case 16"
[img-16-cr]: images/16-cr.png
[img-17]: images/17.png "Test case 17"
[img-17-cr]: images/17-cr.png
[img-18]: images/18.png "Test case 18"
[img-18-cr]: images/18-cr.png
[img-20]: images/20.png "Test case 20"
[img-20-cr]: images/20-cr.png
[img-21]: images/21.png "Test case 21"
[img-21-cr]: images/21-cr.png
[img-22]: images/22.png "Test case 22"
[img-22-cr]: images/22-cr.png
[img-25]: images/25.png "Test case 25"
[img-25-cr]: images/25-cr.png
[img-26]: images/26.png "Test case 26"
[img-26-cr]: images/26-cr.png
