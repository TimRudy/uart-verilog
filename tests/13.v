`timescale 100ns/1ns
`default_nettype none

`include "Uart8.v"

module test;

localparam CLOCK_FREQ = 12000000; // Alhambra board
localparam SIM_STEP_FREQ = 1 / 0.0000001 / 2; // this sim timescale 100ns

// for the simulation timeline:
// ratio SIM_STEP_FREQ MHz / CLOCK_FREQ MHz gives the output waveform in proper time
// (*but note all clocks and the timeline are approximate due to rounding)
localparam SIM_TIMESTEP_FACTOR = SIM_STEP_FREQ / CLOCK_FREQ;

reg        clk;
reg        en_1;
reg        en_2;
reg        txStart_1;
reg        txStart_2;
wire       txBusy_1;
wire       txBusy_2;
wire       rxBusy_1;
wire       rxBusy_2;
wire       txDone_1;
wire       txDone_2;
wire       rxDone_1;
wire       rxDone_2;
wire       rxErr_1;
wire       rxErr_2;
reg [7:0]  txByte_1;
reg [7:0]  txByte_2;
wire [7:0] rxByte_1;
wire [7:0] rxByte_2;
wire       bus_wire_1_2;
wire       bus_wire_2_1;
integer c, r;
static reg [0:19][7:0] transmitSeq;
reg [7:0] receivedSeq1;
reg [7:0] receivedSeq2;
reg [7:0] receivedSeq3;
reg [7:0] receivedSeq4;
reg [7:0] receivedSeq5;
reg [7:0] receivedSeq6;
reg [7:0] receivedSeq7;
reg [7:0] receivedSeq8;
reg [7:0] receivedSeq9;
reg [7:0] receivedSeq10;
reg [7:0] receivedSeq11;
reg [7:0] receivedSeq12;
reg [7:0] receivedSeq13;
reg [7:0] receivedSeq14;
reg [7:0] receivedSeq15;
reg [7:0] receivedSeq16;
reg [7:0] receivedSeq17;
reg [7:0] receivedSeq18;
reg [7:0] receivedSeq19;
reg [7:0] receivedSeq20;

Uart8 #(.CLOCK_RATE(CLOCK_FREQ)) uart1(
  .clk(clk),

  // rx interface
  .rxEn(en_2),
  .rx(bus_wire_2_1),
  .rxBusy(rxBusy_1),
  .rxDone(rxDone_1),
  .rxErr(rxErr_1),
  .out(rxByte_1),

  // tx interface
  .txEn(en_1),
  .txStart(txStart_1),
  .in(txByte_1),
  .txBusy(txBusy_1),
  .txDone(txDone_1),
  .tx(bus_wire_1_2)
);

Uart8 #(.CLOCK_RATE(CLOCK_FREQ)) uart2(
  .clk(clk),

  // rx interface
  .rxEn(en_1),
  .rx(bus_wire_1_2),
  .rxBusy(rxBusy_2),
  .rxDone(rxDone_2),
  .rxErr(rxErr_2),
  .out(rxByte_2),

  // tx interface
  .txEn(en_2),
  .txStart(txStart_2),
  .in(txByte_2),
  .txBusy(txBusy_2),
  .txDone(txDone_2),
  .tx(bus_wire_2_1)
);

initial clk = 1'b0;

always #SIM_TIMESTEP_FACTOR clk = ~clk;

initial c = 1;

always @(posedge uart1.txClk) begin
  // drive the start signal low synchronously from the last tx done signal
  if (txDone_1) begin
    c <= c + 1;
    if (c == 20) begin
      txStart_1 <= 1'b0;
    end
  end
end

initial r = 0;

always @(posedge uart1.txClk) begin
  // accumulate the received byte on each rx done signal
  if (rxDone_2) begin
    r <= r + 1;
    case (r)
      0: begin
        receivedSeq1  <= rxByte_2;
      end
      1: begin
        receivedSeq2  <= rxByte_2;
      end
      2: begin
        receivedSeq3  <= rxByte_2;
      end
      3: begin
        receivedSeq4  <= rxByte_2;
      end
      4: begin
        receivedSeq5  <= rxByte_2;
      end
      5: begin
        receivedSeq6  <= rxByte_2;
      end
      6: begin
        receivedSeq7  <= rxByte_2;
      end
      7: begin
        receivedSeq8  <= rxByte_2;
      end
      8: begin
        receivedSeq9  <= rxByte_2;
      end
      9: begin
        receivedSeq10 <= rxByte_2;
      end
      10: begin
        receivedSeq11 <= rxByte_2;
      end
      11: begin
        receivedSeq12 <= rxByte_2;
      end
      12: begin
        receivedSeq13 <= rxByte_2;
      end
      13: begin
        receivedSeq14 <= rxByte_2;
      end
      14: begin
        receivedSeq15 <= rxByte_2;
      end
      15: begin
        receivedSeq16 <= rxByte_2;
      end
      16: begin
        receivedSeq17 <= rxByte_2;
      end
      17: begin
        receivedSeq18 <= rxByte_2;
      end
      18: begin
        receivedSeq19 <= rxByte_2;
      end
      19: begin
        receivedSeq20 <= rxByte_2;
      end
    endcase
  end
end

initial begin
  integer s;

  $dumpfile(`DUMP_FILE_NAME);
  $dumpvars(0, test);

  transmitSeq = {
    8'd30,
    8'd24,
    8'd19,
    8'd25,
    8'd91,
    8'd77,
    8'd01,
    8'd00,
    8'd99,
    8'd15,
    8'd100,
    8'd128,
    8'd255,
    8'd254,
    8'd00,
    8'd10,
    8'd43,
    8'd149,
    8'd7,
    8'd2
  };

#600
  en_1 = 1'b0;
  txStart_1 = 1'b0;
#600
  en_1 = 1'b1;
  txStart_1 = 1'b1;
#800
  txByte_1 = transmitSeq[0];

  $display("%7.2fms | send %d", $realtime/10000, 1);
#5000

  for (s = 1; s < 20; s++) begin
    // push the next input byte
    txByte_1 <= transmitSeq[s];

    $display("%7.2fms | send %d", $realtime/10000, s + 1);
#11500
    ;
  end

#11500
  en_1 = 1'b0;

  $display("%7.2fms | done", $realtime/10000);

#1400

  $finish();
end

endmodule
