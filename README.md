<img src="images/uart01_chip.svg" title="UART01-V Chip in Verilog" align="right" width="6.3%">
<br />
<br />

# uart-verilog

8 bit UART with tests, documentation, timing diagrams

&ensp;&ensp;For simulation and Electronic Design Automation

#### Parameters

Selected rates, e.g.:
```
CLOCK_RATE = 12000000
```
```
BAUD_RATE = 115200
```
Mode 8-N-1 or 8-N-2 (8 bits data, no parity, 1 or 2 stop bits). The default 2 stop bits:
```
TURBO_FRAMES = 0
```
&ensp;&ensp;trades off maximum bandwidth against more reliable communication

![Multiple module design of the UART](images/Uart3ChipScreenShot.png "Hierarchy of the design showing the Verilog modules: Transmitter, Receiver, Baud clock generator")

#### Test benches

Functional.

&ensp;&ensp;Direct to [the tests](tests/)

Some text.

#### Running the tests on your machine

The test benches can be run using the open source simulator Icarus Verilog: [Installation][link-iverilogi], [Getting Started][link-iverilogs].

With it installed, you can run a command like the following that specifies the required input files and one output file (.vvp):

    > iverilog -g2012 -I.. -osimout.vvp -D"DUMP_FILE_NAME=\"1.vcd\"" 1.v

&ensp;&ensp;(This is run in the "tests" directory, and ".." thus references the device .v files or .vh files at root level.)

It then requires a second step: Run the Icarus Verilog simulator/runtime to store all signal and timing data to a .vcd file (viewable signal trace):

    > vvp simout.vvp

I combine these:

    > iverilog -g2012 -I.. -osimout.vvp -D"DUMP_FILE_NAME=\"1.vcd\"" 1.v && timeout 1 >NUL && vvp simout.vvp

GTKWave viewer is used to view the trace (waveforms): [Installation][link-gtkwavei], [Getting Started][link-gtkwaves].

With GTKWave installed, just click on the .vcd file. However, to persist the view (the duration window, amount of zoom and the particular signals) that you want to see for that test bench, save it as a .gtkw file. The .gtkw file persists and is a consistent view, whereas .vcd, the data, can be regenerated at will. Thus runs can be compared. (If you haven't changed the HDL code, the runs will come out identical.)

<img src="tests/images/13.png" title="Simulation waveform" width="50%">

#### Topics: Device and circuit simulation

#### Related open source technology for device and circuit simulation:

- [HDLs][link-web-hdls] · Hardware Description Languages
- [EDA][link-web-eda] · Electronic Design Automation
- [FPGAs][link-web-fpgas] · Field-Programmable Gate Arrays

#### Related open source technology

[IceChips][link-icechips] devices from 7400 TTL family

[Icestudio][link-icestudio] and Apio built on top of IceStorm, Yosys, nextpnr

[Yosys][link-yosys] synthesis by Claire Wolf

[Icarus Verilog][link-iverilog] simulator by Stephen Williams

[GTKWave][link-gtkwavei] for viewing waveforms

## <!-- -->

© 2022-2023 Tim Rudy

[link-icechips]: https://github.com/TimRudy/ice-chips-verilog
[link-icestudio]: https://icestudio.io
[link-web-hdls]: https://www.google.com/search?q=Hardware+Description+Languages
[link-web-eda]: https://www.google.com/search?q=Electronic+Design+Automation
[link-web-fpgas]: https://www.google.com/search?q=Field-Programmable+Gate+Arrays
[link-yosys]: https://github.com/YosysHQ/yosys
[link-iverilog]: http://iverilog.icarus.com
[link-iverilogi]: https://steveicarus.github.io/iverilog/usage/installation.html
[link-iverilogs]: https://steveicarus.github.io/iverilog/usage/getting_started.html
[link-gtkwavei]: http://gtkwave.sourceforge.net
[link-gtkwaves]: https://gtkwave.sourceforge.net/gtkwave.pdf
