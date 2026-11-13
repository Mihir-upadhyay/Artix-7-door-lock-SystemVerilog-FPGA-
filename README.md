# Password Lock - Digilent Nexys A7-100T (Verilog)

**Board:** Nexys A7-100T  |  **Vivado part:** `xc7a100tcsg324-1` (XC7A100T-1CSG324C)
**Top module:** `top_nexys_a7`  |  **Clock:** 100 MHz (pin E3)

## Files
| File | Purpose |
|---|---|
| `simple_password_checker.v` | Core logic (3-bit password, 3 attempts, lockout) - same logic as before |
| `button_conditioner.v` | Synchronise + debounce + one-pulse for each button |
| `status_display.v` | 8-digit seven-segment text + red/green LED control |
| `top_nexys_a7.v` | Top level - connects everything to the board |
| `tb_simple_checker.v` | Self-checking testbench for the core (simulation only) |
| `nexys_a7_100t.xdc` | Pin constraints for this board |

## How to use the board
| Action | Switches / button |
|---|---|
| Set password | Put the 3-bit code on **SW0, SW1, SW2**, press **BTNL** |
| Enter password | Put your guess on **SW13, SW14, SW15**, press **BTNC** |
| Reset | **CPU RESET** (red button) - also resets the stored password to 000 |

Bit matching: SW0 <-> SW13, SW1 <-> SW14, SW2 <-> SW15.
Example: set SW2-SW1-SW0 = 1-0-1, then put SW15-SW14-SW13 = 1-0-1 and press BTNC -> TRUE.

## What you will see
| Situation | 7-segment | LED |
|---|---|---|
| Idle | `--------` | off |
| Password saved | `SEt` (2 s) | off |
| Correct | `TRUE` (2 s) | **green** (LD16) |
| Wrong | `FALSE      n` = attempts left (2 s) | **red** (LD17) |
| 3rd wrong -> locked | `FALSE 0` (2 s), then `LOC  ss` countdown (5 s total) | red stays on |

While locked, both buttons are ignored. After the countdown it unlocks and attempts reset.

## Vivado steps
1. New RTL project -> add the 4 design files (`simple_password_checker.v`, `button_conditioner.v`, `status_display.v`, `top_nexys_a7.v`) as **Design Sources**.
2. Add `nexys_a7_100t.xdc` as a **Constraint**; add `tb_simple_checker.v` as a **Simulation Source**.
3. Part: **xc7a100tcsg324-1** (or select board "Nexys A7-100T").
4. Set `top_nexys_a7` as top. Simulate `tb_simple_checker` -> console prints `ALL TESTS PASSED`.
5. Run Synthesis -> Implementation -> Generate Bitstream -> Open Hardware Manager -> Program Device.

## Notes
* Reset clears the stored password to **000** - set your password first after every reset/power-up.
* The RGB LEDs are very bright; that is normal.
* For a faster demo change `LOCKOUT_SECONDS` / `HOLD_SECONDS` in `top_nexys_a7.v`.
* Pin numbers follow Digilent's Nexys A7-100T master XDC; if Vivado reports a pin error, compare with the labels printed on the board.
* The core was not simulated in this chat (no simulator available) - please run the testbench in Vivado first.
