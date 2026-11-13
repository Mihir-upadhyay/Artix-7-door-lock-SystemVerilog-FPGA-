`timescale 1ns / 1ps
//============================================================================
// button_conditioner.v
// Real push buttons are asynchronous and bouncy. This module
//   1) synchronises the button to clk (2 flip-flops),
//   2) debounces it (input must stay stable for DEBOUNCE_CYCLES),
//   3) gives a clean level  (level) and a ONE-clock pulse on press (pulse).
// The core expects one-cycle pulses, so every button goes through this.
//============================================================================
module button_conditioner #(
    parameter DEBOUNCE_CYCLES = 1_000_000      // 10 ms at 100 MHz
)(
    input  wire clk,
    input  wire btn_in,
    output reg  level,
    output wire pulse
);
    reg s0 = 1'b0, s1 = 1'b0;
    reg level_d = 1'b0;
    reg [19:0] cnt = 20'd0;                    // 2^20 > 1,000,000

    initial level = 1'b0;

    always @(posedge clk) begin
        s0 <= btn_in;
        s1 <= s0;
        if (s1 == level) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1'b1;
            if (cnt >= DEBOUNCE_CYCLES) begin
                level <= s1;
                cnt   <= 0;
            end
        end
        level_d <= level;
    end

    assign pulse = level & ~level_d;           // rising edge -> 1 clock pulse
endmodule
