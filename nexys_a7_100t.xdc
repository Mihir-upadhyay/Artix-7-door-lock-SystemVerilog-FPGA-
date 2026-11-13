## =============================================================================
## Constraints for the password lock - Digilent Nexys A7-100T
## FPGA part : XC7A100T-1CSG324C   (Vivado part string: xc7a100tcsg324-1)
## Top module: top_nexys_a7
## Port names below match top_nexys_a7.v exactly.
## =============================================================================

## ---- Clock (100 MHz) --------------------------------------------------------
set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## ---- CPU RESET button (red, active low) -------------------------------------
set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports cpu_resetn]

## ---- SET-password switches: SW0, SW1, SW2 (first 3 switches) -----------------
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports {set_sw[0]}]   ;# SW0
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS33 } [get_ports {set_sw[1]}]   ;# SW1
set_property -dict { PACKAGE_PIN M13 IOSTANDARD LVCMOS33 } [get_ports {set_sw[2]}]   ;# SW2

## ---- ENTER-password switches: SW13, SW14, SW15 (last 3 switches) ----------------
set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports {entry_sw[0]}] ;# SW13
set_property -dict { PACKAGE_PIN U11 IOSTANDARD LVCMOS33 } [get_ports {entry_sw[1]}] ;# SW14
set_property -dict { PACKAGE_PIN V10 IOSTANDARD LVCMOS33 } [get_ports {entry_sw[2]}] ;# SW15

## ---- Push buttons -----------------------------------------------------------
set_property -dict { PACKAGE_PIN N17 IOSTANDARD LVCMOS33 } [get_ports btn_submit]    ;# BTNC = check
set_property -dict { PACKAGE_PIN P17 IOSTANDARD LVCMOS33 } [get_ports btn_set]       ;# BTNL = save password

## ---- Seven-segment display (cathodes, active low) -----------------------------
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports {seg[0]}]     ;# CA
set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports {seg[1]}]     ;# CB
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports {seg[2]}]     ;# CC
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports {seg[3]}]     ;# CD
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports {seg[4]}]     ;# CE
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports {seg[5]}]     ;# CF
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports {seg[6]}]     ;# CG
set_property -dict { PACKAGE_PIN H15 IOSTANDARD LVCMOS33 } [get_ports dp]           ;# DP

## ---- Seven-segment digit enables (anodes, active low) -------------------------
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {an[0]}]      ;# rightmost digit
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {an[1]}]
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports {an[2]}]
set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS33 } [get_ports {an[3]}]
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports {an[4]}]
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports {an[5]}]
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports {an[6]}]
set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports {an[7]}]      ;# leftmost digit

## ---- RGB LEDs: green channel of LD16, red channel of LD17 ---------------------
set_property -dict { PACKAGE_PIN M16 IOSTANDARD LVCMOS33 } [get_ports led_green]    ;# LED16_G
set_property -dict { PACKAGE_PIN N16 IOSTANDARD LVCMOS33 } [get_ports led_red]      ;# LED17_R

## ---- Configuration -------------------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
