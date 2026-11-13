`timescale 1ns / 1ps
//============================================================================
// top_nexys_a7.v  -  Top level for Digilent Nexys A7-100T (xc7a100tcsg324-1)
//
//   SET password   : SW0, SW1, SW2     (first 3 switches)   + press BTNL
//   ENTER password : SW13, SW14, SW15  (last 3 switches)    + press BTNC
//        SW0 <-> SW13,  SW1 <-> SW14,  SW2 <-> SW15  (bit 0, 1, 2)
//   Reset          : CPU RESET button (red, active low)
//   Display        : TRUE / FALSE + attempts left / LOC + countdown
//   LEDs           : RGB LD16 green = TRUE,  RGB LD17 red = FALSE or locked
//============================================================================
module top_nexys_a7 #(
    parameter CLK_FREQ        = 100_000_000,   // Nexys A7 oscillator = 100 MHz
    parameter LOCKOUT_SECONDS = 5,
    parameter HOLD_SECONDS    = 2
)(
    input  wire       clk,          // E3
    input  wire       cpu_resetn,   // C12, active low
    input  wire [2:0] set_sw,       // SW0..SW2
    input  wire [2:0] entry_sw,     // SW13..SW15
    input  wire       btn_submit,   // BTNC
    input  wire       btn_set,      // BTNL

    output wire [6:0] seg,
    output wire       dp,
    output wire [7:0] an,
    output wire       led_green,    // LED16_G
    output wire       led_red       // LED17_R
);
    // ---- power-on reset + reset button ------------------------------------
    reg [3:0] por_cnt = 4'd0;
    always @(posedge clk) if (por_cnt != 4'hF) por_cnt <= por_cnt + 1'b1;
    wire por = (por_cnt != 4'hF);

    wire rst_level, rst_unused;
    button_conditioner #(.DEBOUNCE_CYCLES(CLK_FREQ/100)) db_rst
        (.clk(clk), .btn_in(~cpu_resetn), .level(rst_level), .pulse(rst_unused));

    reg rst_r = 1'b1;
    always @(posedge clk) rst_r <= por | rst_level;

    // ---- buttons -> clean one-cycle pulses ----------------------------------
    wire submit_pulse, set_pulse, lvl_a, lvl_b;
    button_conditioner #(.DEBOUNCE_CYCLES(CLK_FREQ/100)) db_submit
        (.clk(clk), .btn_in(btn_submit), .level(lvl_a), .pulse(submit_pulse));
    button_conditioner #(.DEBOUNCE_CYCLES(CLK_FREQ/100)) db_set
        (.clk(clk), .btn_in(btn_set),    .level(lvl_b), .pulse(set_pulse));

    // ---- synchronise the switches ---------------------------------------
    reg [2:0] set_s0 = 0, set_s1 = 0, ent_s0 = 0, ent_s1 = 0;
    always @(posedge clk) begin
        set_s0 <= set_sw;    set_s1 <= set_s0;
        ent_s0 <= entry_sw;  ent_s1 <= ent_s0;
    end

    // ---- core -------------------------------------------------------------
    wire       granted, denied, locked;
    wire [1:0] attempts;

    simple_password_checker #(
        .PASS_WIDTH(3), .MAX_ATTEMPTS(3),
        .LOCKOUT_CYCLES(CLK_FREQ * LOCKOUT_SECONDS)
    ) core (
        .clk(clk), .rst(rst_r),
        .set_pass(set_pulse), .submit_pass(submit_pulse),
        .set_in(set_s1), .entry_in(ent_s1),
        .granted(granted), .denied(denied), .locked(locked), .attempts(attempts)
    );

    // ---- display + LEDs ---------------------------------------------------
    status_display #(
        .CLK_FREQ(CLK_FREQ), .LOCKOUT_SECONDS(LOCKOUT_SECONDS),
        .HOLD_CYCLES(CLK_FREQ * HOLD_SECONDS), .MAX_ATTEMPTS(3)
    ) disp (
        .clk(clk), .rst(rst_r),
        .granted(granted), .denied(denied),
        .set_event(set_pulse & ~locked),       // no "SEt" while locked
        .locked(locked), .attempts(attempts),
        .seg(seg), .dp(dp), .an(an),
        .led_green(led_green), .led_red(led_red)
    );
endmodule
