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

localparam ENABLED_BAUD_CLOCK_STEPS = 17;

reg        clk;
reg        en_1;
reg        txStart_1;
wire       txBusy_1;
wire       rxBusy_1;
wire       txDone_1;
wire       rxDone_1;
wire       rxErr_1;
reg [7:0]  txByte_1;
wire [7:0] rxByte_1;
wire       bus_wire;

Uart8 #(.CLOCK_RATE(CLOCK_FREQ)) uart1(
  .clk(clk),

  // rx interface
  .rxEn(en_1),
  .rx(bus_wire),
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
  .tx(bus_wire)
);

initial clk = 1'b0;

always #SIM_TIMESTEP_FACTOR clk = ~clk;

initial begin
  integer t;

  $dumpfile(`DUMP_FILE_NAME);
  $dumpvars(0, test);

#600
  en_1 = 1'b0;
  txStart_1 = 1'b0;
#600
  en_1 = 1'b1;

  txByte_1 = 8'b01000101;

  $display("            tx data: %8b", txByte_1);

  for (t = 0; t < ENABLED_BAUD_CLOCK_STEPS; t++) begin
    // #1000 x 100ns == 0.1ms == 1 tx clock period (approximately) at 9600 baud
#1000
    case (t)
      1: begin
        txStart_1 = 1'b1;

        $display("%7.2fms | tx start: %d", $realtime/10000, txStart_1);
        $display("%7.2fms | tx busy: %d, tx done: %d", $realtime/10000, txBusy_1, txDone_1);
        $display("%7.2fms | rx data: %8b", $realtime/10000, rxByte_1);
      end
      4: begin
        txStart_1 = 1'b0;

        $display("%7.2fms | tx start: %d", $realtime/10000, txStart_1);
      end
      13: begin
        // output is ready

        $display("%7.2fms | tx busy: %d, tx done: %d", $realtime/10000, txBusy_1, txDone_1);
        $display("%7.2fms | rx data: %8b", $realtime/10000, rxByte_1);
      end
    endcase
  end

  en_1 = 1'b0;
#2400

  $finish();
end

endmodule
