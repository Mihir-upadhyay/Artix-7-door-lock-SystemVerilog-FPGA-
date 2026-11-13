`timescale 1ns / 1ps
//============================================================================
// tb_simple_checker.v - testbench for the 3-bit core (same flow as before)
//============================================================================
module tb_simple_checker;

    reg clk, rst, set_pass, submit_pass;
    reg [2:0] set_in, entry_in;

    wire granted, denied, locked;
    wire [1:0] attempts;

    // Small lockout (10 cycles) so the simulation stays short
    simple_password_checker #(.PASS_WIDTH(3), .MAX_ATTEMPTS(3), .LOCKOUT_CYCLES(10)) uut (
        .clk(clk), .rst(rst),
        .set_pass(set_pass), .submit_pass(submit_pass),
        .set_in(set_in), .entry_in(entry_in),
        .granted(granted), .denied(denied), .locked(locked), .attempts(attempts)
    );

    always #10 clk = ~clk;      // 20 ns period

    // simple self-check counters
    integer n_granted = 0, n_denied = 0;
    always @(posedge clk) begin
        if (granted) n_granted = n_granted + 1;
        if (denied)  n_denied  = n_denied  + 1;
    end

    initial begin
        clk = 0; rst = 1; set_pass = 0; submit_pass = 0; set_in = 0; entry_in = 0;
        #25 rst = 0;

        // ACTION 1: set password 101 (SW2..SW0)
        set_in = 3'b101;
        set_pass = 1; #20 set_pass = 0;
        #40;

        // ACTION 2: CORRECT code on the last 3 switches
        entry_in = 3'b101;
        submit_pass = 1; #20 submit_pass = 0;
        #60;

        // ACTION 3: WRONG code three times -> lockout on the 3rd
        entry_in = 3'b000;
        submit_pass = 1; #20 submit_pass = 0; #40;   // attempt 1
        submit_pass = 1; #20 submit_pass = 0; #40;   // attempt 2
        submit_pass = 1; #20 submit_pass = 0; #40;   // attempt 3 -> locked

        // ACTION 4: correct code while locked -> must be ignored
        entry_in = 3'b101;
        submit_pass = 1; #20 submit_pass = 0;

        // ACTION 5: wait for the lockout to expire
        #155;

        // ACTION 6: correct code after unlock -> granted
        submit_pass = 1; #20 submit_pass = 0; #40;

        if (n_granted == 2 && n_denied == 3 && !locked)
            $display("ALL TESTS PASSED  (granted=%0d denied=%0d)", n_granted, n_denied);
        else
            $display("TEST FAILED       (granted=%0d denied=%0d locked=%b)", n_granted, n_denied, locked);
        $finish;
    end
endmodule
