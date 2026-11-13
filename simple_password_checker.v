`timescale 1ns / 1ps
//============================================================================
// simple_password_checker.v   (core logic - same behaviour as before)
//
//  * 3-bit password (PASS_WIDTH) is SAVED from set_in   when set_pass    pulses
//  * 3-bit code     is CHECKED from entry_in            when submit_pass pulses
//  * granted / denied are 1-clock-cycle pulses
//  * 3 wrong attempts in a row  -> locked for LOCKOUT_CYCLES clock cycles,
//    all button presses are ignored while locked, then it unlocks by itself
//  * attempts = number of consecutive wrong tries so far (0..2)
//============================================================================
module simple_password_checker #(
    parameter PASS_WIDTH     = 3,
    parameter MAX_ATTEMPTS   = 3,
    parameter LOCKOUT_CYCLES = 10        // small for simulation; top level passes 5 s worth
)(
    input  wire                  clk,
    input  wire                  rst,          // async, active high
    input  wire                  set_pass,     // 1-cycle pulse: save set_in
    input  wire                  submit_pass,  // 1-cycle pulse: compare entry_in
    input  wire [PASS_WIDTH-1:0] set_in,       // "first 3 switches"
    input  wire [PASS_WIDTH-1:0] entry_in,     // "last 3 switches"

    output reg                   granted,
    output reg                   denied,
    output reg                   locked,
    output reg  [1:0]            attempts
);

    reg [PASS_WIDTH-1:0] stored_pass;
    reg [31:0]           lockout_timer;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stored_pass   <= {PASS_WIDTH{1'b0}};
            granted       <= 0;
            denied        <= 0;
            locked        <= 0;
            attempts      <= 0;
            lockout_timer <= 0;
        end else begin
            // Default: pulse outputs are low unless set below
            granted <= 0;
            denied  <= 0;

            if (locked) begin
                // Lockout countdown
                if (lockout_timer > 0) begin
                    lockout_timer <= lockout_timer - 1;
                end else begin
                    locked   <= 0;   // unlock when timer hits 0
                    attempts <= 0;   // reset attempts
                end
            end else begin
                // Normal operation
                if (set_pass) begin
                    stored_pass <= set_in;
                end
                else if (submit_pass) begin
                    if (entry_in == stored_pass) begin
                        granted  <= 1;
                        attempts <= 0;               // success clears bad attempts
                    end else begin
                        denied <= 1;
                        if (attempts == MAX_ATTEMPTS-1) begin   // 3rd wrong attempt
                            locked        <= 1;
                            lockout_timer <= LOCKOUT_CYCLES;
                        end else begin
                            attempts <= attempts + 1;
                        end
                    end
                end
            end
        end
    end
endmodule
