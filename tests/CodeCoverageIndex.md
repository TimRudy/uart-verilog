**Uart8Receiver**

| Code location                                                | Test #            |
| :------------------------------------------------------------| :-----------------|
| 79 &nbsp; if (out_hold_count == 5'b10000) begin              | 12, 25, 26, 27    |
| 110 if (en && err && !in_sample) begin                       | 30                |
| 133 if (sample_count == 4'b0) begin                          | 1, 16             |
| 134 if (&in_prior_hold_reg \|\| done && !err) begin          | 1, 16, 24         |
| 141 end else begin                                           | 17, 18, 24        |
| 148 if (sample_count == 4'b1100) begin                       | 1, 16             |
| 158 end else if (\|sample_count) begin                       | 18, 19, 26        |
| 215 if (sample_count[3]) begin                               | 20, 21, 22        |
| 216 if (!in_sample) begin                                    | 21*, 22*          |
| 220 if (sample_count == 4'b1000 && &in_prior_hold_reg) begin | 25, 26            |
| 228 end else if (&sample_count) begin                        | 23                |
| 238 if (&in_current_hold_reg) begin                          | 1, 20, 21, 27, 29 |
| 244 end else if (&sample_count) begin                        | 5**, 22           |
| 261 if (!err && !in_sample \|\| &sample_count) begin         | 27, 29            |
| 269 if (in_sample) begin                                     | 1, 9              |
| 274 end else begin [case: !in_sample]                        | 28                |
| 282 end else begin [case: !&sample_count]                    | 12, 27, 29        |
| 290 end else if (&sample_count[3:1]) begin                   | 30***             |

<br />

**Uart8Transmitter**

| Code location                            | Test #        |
| :----------------------------------------| :-------------|
| 84 &nbsp; if (start) begin               | 1, 6, 7, 8, 9 |
| 115 if (start) begin                     | 9, 12         |
| 116 if (done == 1'b0) begin              | 9, 12         |
| 118 if (TURBO_FRAMES) begin              | 12            |
| 120 end else begin [case: !TURBO_FRAMES] &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | 9, 13         |
| 123 end else begin [case: done == 1'b1]  | 9, 13         |
| 127 end else begin [case: !start]        | 1, 4          |

<br />

\* With no meeting the inner conditions lines 220 and 228  
\*\* See second transaction  
\*\*\* And meeting inner condition line 293  
