// states of state machine
`define RESET     3'b000
`define IDLE      3'b001
`define START_BIT 3'b010
`define DATA_BITS 3'b011
`define STOP_BIT  3'b100
`define READY     3'b101 // receiver only
