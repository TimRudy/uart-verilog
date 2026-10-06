**Uart8Receiver**

| Code location                                                | Test #            |
| :------------------------------------------------------------| :-----------------|
| 79 &nbsp; if (out_hold_count == 5'b10000) begin              | 12, 25, 26, 27    |
| 106 if (en && err && !in_sample) begin                       | 30                |
| 129 if (sample_count == 4'b0) begin                          | 1, 16             |
| 130 if (&in_prior_hold_reg \|\| done && !err) begin          | 1, 16, 24         |
| 137 end else begin                                           | 17, 18, 24        |
| 144 if (sample_count == 4'b1100) begin                       | 1, 16             |
| 154 end else if (\|sample_count) begin                       | 18, 19, 26        |
| 211 if (sample_count[3]) begin                               | 20, 21, 22        |
| 212 if (!in_sample) begin                                    | 21*, 22*          |
| 216 if (sample_count == 4'b1000 && &in_prior_hold_reg) begin | 25, 26            |
| 224 end else if (&sample_count) begin                        | 23                |
| 234 if (&in_current_hold_reg) begin                          | 1, 20, 21, 27, 29 |
| 240 end else if (&sample_count) begin                        | 5**, 22           |
| 257 if (!err && !in_sample \|\| &sample_count) begin         | 27, 29            |
| 265 if (in_sample) begin                                     | 1, 9              |
| 270 end else begin [case: !in_sample]                        | 28                |
| 278 end else begin [case: !&sample_count]                    | 12, 27, 29        |
| 286 end else if (&sample_count[3:1]) begin                   | 30***             |

<br />

**Uart8Transmitter**

| Code location                            | Test #        |
| :----------------------------------------| :-------------|
| 82 &nbsp; if (start) begin               | 1, 6, 7, 8, 9 |
| 113 if (start) begin                     | 9, 12         |
| 114 if (done == 1'b0) begin              | 9, 12         |
| 116 if (TURBO_FRAMES) begin              | 12            |
| 118 end else begin [case: !TURBO_FRAMES] &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | 9, 13         |
| 121 end else begin [case: done == 1'b1]  | 9, 13         |
| 125 end else begin [case: !start]        | 1, 4          |

<br />

\* With no meeting the inner conditions lines 216 and 224  
\*\* See second transaction  
\*\*\* And meeting inner condition line 289  
