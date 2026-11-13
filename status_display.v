`timescale 1ns / 1ps
//============================================================================
// status_display.v
// Drives the 8-digit seven-segment display and the red / green LEDs.
//
//   idle            :  - - - - - - - -
//   password saved  :  SEt           (2 s)
//   correct         :    tr UE       (2 s)  "TRUE"   + GREEN LED
//   wrong           :  FALSE      n  (2 s)  "FALSE" + attempts left n + RED LED
//   locked          :  LOC      ss   countdown in seconds + RED LED
//
// Segments and digit-enables on the Nexys A7 are ACTIVE LOW.
// seg = {g,f,e,d,c,b,a}  (seg[0] -> CA ... seg[6] -> CG)
//============================================================================
module status_display #(
    parameter CLK_FREQ        = 100_000_000,
    parameter LOCKOUT_SECONDS = 5,
    parameter HOLD_CYCLES     = 200_000_000,   // how long TRUE/FALSE/SEt stay (2 s)
    parameter MAX_ATTEMPTS    = 3
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       granted,       // 1-cycle pulse from core
    input  wire       denied,        // 1-cycle pulse from core
    input  wire       set_event,     // 1-cycle pulse: new password saved
    input  wire       locked,
    input  wire [1:0] attempts,

    output reg  [6:0] seg,
    output wire       dp,
    output reg  [7:0] an,
    output wire       led_green,
    output wire       led_red
);
    // ---- segment patterns (active low, {g,f,e,d,c,b,a}) --------------------
    localparam [6:0] S_0 = 7'h40, S_1 = 7'h79, S_2 = 7'h24, S_3 = 7'h30,
                     S_4 = 7'h19, S_5 = 7'h12, S_6 = 7'h02, S_7 = 7'h78,
                     S_8 = 7'h00, S_9 = 7'h10;
    localparam [6:0] S_A = 7'h08, S_C = 7'h46, S_E = 7'h06, S_F = 7'h0E,
                     S_L = 7'h47, S_O = 7'h40, S_S = 7'h12, S_T = 7'h07, // t
                     S_R = 7'h2F, S_U = 7'h41,
                     S_DASH = 7'h3F, S_BLANK = 7'h7F;

    function [6:0] digit_pattern(input [3:0] d);
        case (d)
            4'd0: digit_pattern = S_0;  4'd1: digit_pattern = S_1;
            4'd2: digit_pattern = S_2;  4'd3: digit_pattern = S_3;
            4'd4: digit_pattern = S_4;  4'd5: digit_pattern = S_5;
            4'd6: digit_pattern = S_6;  4'd7: digit_pattern = S_7;
            4'd8: digit_pattern = S_8;  4'd9: digit_pattern = S_9;
            default: digit_pattern = S_BLANK;
        endcase
    endfunction

    // ---- message latch: keeps TRUE / FALSE / SEt visible for HOLD_CYCLES --
    localparam [1:0] MSG_NONE = 2'd0, MSG_TRUE = 2'd1, MSG_FALSE = 2'd2, MSG_SET = 2'd3;
    reg [1:0]  msg      = MSG_NONE;
    reg [31:0] hold_cnt = 32'd0;

    always @(posedge clk) begin
        if (rst) begin
            msg      <= MSG_NONE;
            hold_cnt <= 0;
        end else if (granted) begin
            msg <= MSG_TRUE;  hold_cnt <= 0;
        end else if (denied) begin
            msg <= MSG_FALSE; hold_cnt <= 0;
        end else if (set_event) begin
            msg <= MSG_SET;   hold_cnt <= 0;
        end else if (msg != MSG_NONE) begin
            if (hold_cnt >= HOLD_CYCLES) begin
                msg <= MSG_NONE; hold_cnt <= 0;
            end else begin
                hold_cnt <= hold_cnt + 1;
            end
        end
    end

    // ---- lockout countdown in whole seconds (display only) ----------------
    reg        locked_d = 1'b0;
    reg [31:0] sec_cnt  = 32'd0;
    reg [3:0]  lock_secs = 4'd0;

    always @(posedge clk) begin
        locked_d <= locked;
        if (rst) begin
            sec_cnt <= 0; lock_secs <= 0;
        end else if (locked && !locked_d) begin
            lock_secs <= LOCKOUT_SECONDS; sec_cnt <= 0;
        end else if (locked) begin
            if (sec_cnt == CLK_FREQ-1) begin
                sec_cnt <= 0;
                if (lock_secs != 0) lock_secs <= lock_secs - 1'b1;
            end else begin
                sec_cnt <= sec_cnt + 1'b1;
            end
        end
    end

    // ---- attempts left (shown after a wrong password) ----------------------
    localparam [3:0] MAXA = MAX_ATTEMPTS;
    wire [3:0] left = locked ? 4'd0 : (MAXA - {2'b00, attempts});
    wire [3:0] tens = (lock_secs >= 4'd10) ? 4'd1 : 4'd0;
    wire [3:0] ones = (lock_secs >= 4'd10) ? (lock_secs - 4'd10) : lock_secs;

    // ---- choose the 8 characters (ch7 = leftmost digit, ch0 = rightmost) --
    reg [6:0] ch0, ch1, ch2, ch3, ch4, ch5, ch6, ch7;
    always @(*) begin
        {ch7,ch6,ch5,ch4,ch3,ch2,ch1,ch0} = {8{S_DASH}};          // idle  "--------"
        if (msg == MSG_TRUE) begin                                // "  tr UE "
            ch7 = S_BLANK; ch6 = S_BLANK; ch5 = S_T; ch4 = S_R;
            ch3 = S_U;     ch2 = S_E;     ch1 = S_BLANK; ch0 = S_BLANK;
        end else if (msg == MSG_FALSE) begin                      // "FALSE  n"
            ch7 = S_F; ch6 = S_A; ch5 = S_L; ch4 = S_S;
            ch3 = S_E; ch2 = S_BLANK; ch1 = S_BLANK; ch0 = digit_pattern(left);
        end else if (msg == MSG_SET) begin                        // "SEt     "
            ch7 = S_S; ch6 = S_E; ch5 = S_T; ch4 = S_BLANK;
            ch3 = S_BLANK; ch2 = S_BLANK; ch1 = S_BLANK; ch0 = S_BLANK;
        end else if (locked) begin                                // "LOC   ss"
            ch7 = S_L; ch6 = S_O; ch5 = S_C; ch4 = S_BLANK; ch3 = S_BLANK;
            ch2 = S_BLANK;
            ch1 = (tens == 0) ? S_BLANK : digit_pattern(tens);
            ch0 = digit_pattern(ones);
        end
    end

    // ---- time-multiplex the 8 digits (~190 Hz refresh per digit) ----------
    reg [18:0] refresh = 19'd0;
    always @(posedge clk) refresh <= refresh + 1'b1;
    wire [2:0] sel = refresh[18:16];

    always @(*) begin
        an  = ~(8'b0000_0001 << sel);          // active low, one digit at a time
        case (sel)
            3'd0: seg = ch0;  3'd1: seg = ch1;  3'd2: seg = ch2;  3'd3: seg = ch3;
            3'd4: seg = ch4;  3'd5: seg = ch5;  3'd6: seg = ch6;  default: seg = ch7;
        endcase
    end
    assign dp = 1'b1;                          // decimal points off

    // ---- LEDs ------------------------------------------------------------
    assign led_green = (msg == MSG_TRUE);
    assign led_red   = (msg == MSG_FALSE) || locked;
endmodule
