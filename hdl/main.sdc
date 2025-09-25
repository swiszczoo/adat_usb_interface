# ====================================================
# Top-level SDC for FPGA design (Questa / Intel T.A.)
# ====================================================

# --- Input clocks (worst-case period) ---
create_clock -name clk_44100_i -period 88.577 -waveform { 0.000 44.288 } [get_ports clk_44100_i]  ;# 11.2896 MHz
create_clock -name clk_48000_i -period 81.38 -waveform { 0.000 40.69 } [get_ports clk_48000_i]  ;# 12.288 MHz

# --- PLL-generated clocks ---
create_generated_clock -name clk_x4_44100 -source [get_ports clk_44100_i] -multiply_by 4 \
    [get_pins -compatibility_mode u_pll|altpll_component|auto_generated|pll1|clk[0]]
create_generated_clock -name clk_sys_44100 -source [get_ports clk_44100_i] \
    [get_pins -compatibility_mode u_pll|altpll_component|auto_generated|pll1|clk[1]]
create_generated_clock -name clk_word_44100 -source [get_ports clk_44100_i] -divide_by 256 \
    [get_pins -compatibility_mode u_pll|altpll_component|auto_generated|pll1|clk[2]]

create_generated_clock -add -name clk_x4_48000 -source [get_ports clk_48000_i] -multiply_by 4 \
    [get_pins -compatibility_mode u_pll|altpll_component|auto_generated|pll1|clk[0]]
create_generated_clock -add -name clk_sys_48000 -source [get_ports clk_48000_i] \
    [get_pins -compatibility_mode u_pll|altpll_component|auto_generated|pll1|clk[1]]
create_generated_clock -add -name clk_word_48000 -source [get_ports clk_48000_i] -divide_by 256 \
    [get_pins -compatibility_mode u_pll|altpll_component|auto_generated|pll1|clk[2]]

# --- False paths for clock transfers ---
set_false_path -from [get_clocks {clk_44100_i clk_48000_i}] -through [get_pins -compatibility_mode *] -to [get_clocks {clk_44100_i clk_48000_i}]
set_false_path -from [get_clocks clk_44100_i] -to [get_clocks clk_48000_i]
set_false_path -from [get_clocks clk_48000_i] -to [get_clocks clk_44100_i]
set_false_path -from [get_clocks {clk_x4_44100 clk_sys_44100 clk_x4_48000 clk_sys_48000}] \
    -through [get_pins -compatibility_mode *] -to [get_clocks {clk_x4_44100 clk_sys_44100 clk_x4_48000 clk_sys_48000}]
set_false_path -from [get_clocks clk_sys_44100] -to [get_clocks clk_sys_48000]
set_false_path -from [get_clocks clk_sys_48000] -to [get_clocks clk_sys_44100]
set_false_path -from [get_clocks clk_x4_44100] -to [get_clocks clk_sys_48000]
set_false_path -from [get_clocks clk_x4_48000] -to [get_clocks clk_sys_44100]
set_false_path -from [get_clocks clk_x4_44100] -to [get_clocks clk_x4_48000]
set_false_path -from [get_clocks clk_x4_48000] -to [get_clocks clk_x4_44100]
set_false_path -from [get_clocks clk_sys_48000] -to [get_clocks clk_x4_44100]
set_false_path -from [get_clocks clk_sys_44100] -to [get_clocks clk_x4_48000]

derive_clock_uncertainty


# --- Asynchronous inputs ---
# ADAT and user signals are asynchronous → exclude from timing analysis
set_false_path -from [get_ports {adat_in_1_i adat_in_2_i}]
set_false_path -from [get_ports {adat_1_user_i[0] adat_1_user_i[1] adat_1_user_i[2] adat_1_user_i[3] adat_2_user_i[0] adat_2_user_i[1] adat_2_user_i[2] adat_2_user_i[3] mcu_ready_i i2s_resync_req_i loopback_i}]

# --- I2S input sampling ---
# Inputs are sampled on negative edge of clk_sys → half-cycle constraints
# Setup: needs to arrive half-cycle before clock
# Hold: needs to stay valid after negative edge
set_multicycle_path -setup 0 -from [get_ports {i2s_1_data_i i2s_2_data_i}] -to [get_clocks clk_sys_*]
set_multicycle_path -hold 1 -from [get_ports {i2s_1_data_i i2s_2_data_i}] -to [get_clocks clk_sys_*]

# Optional: input delays for external timing (if measured from external sources)
set_input_delay -max 40 -clock [get_clocks clk_sys_44100] [get_ports {i2s_1_data_i i2s_2_data_i}]
set_input_delay -min 0 -clock [get_clocks clk_sys_44100] [get_ports {i2s_1_data_i i2s_2_data_i}]
set_input_delay -add_delay -max 35 -clock [get_clocks clk_sys_48000] [get_ports {i2s_1_data_i i2s_2_data_i}]
set_input_delay -add_delay -min 0 -clock [get_clocks clk_sys_48000] [get_ports {i2s_1_data_i i2s_2_data_i}]

# --- I2S output skew ---
# Limit skew between outputs (must align within 15 ns)
set_max_delay 15 -from [get_clocks clk_sys_*] -to [get_ports {i2s_1_data_o i2s_1_lrclk_o i2s_1_bclk_o i2s_2_data_o i2s_2_lrclk_o i2s_2_bclk_o}]
set_max_delay 15 -from [get_clocks clk_sys_*] -to [get_ports {adat_1_locked_o adat_2_locked_o i2s_running_o sel_clk_o}]
set_min_delay -15 -from [get_clocks clk_sys_*] -to [get_ports {i2s_1_data_o i2s_1_lrclk_o i2s_1_bclk_o i2s_2_data_o i2s_2_lrclk_o i2s_2_bclk_o}]
set_min_delay -15 -from [get_clocks clk_sys_*] -to [get_ports {adat_1_locked_o adat_2_locked_o i2s_running_o sel_clk_o}]

# --- Optional: unconstrained outputs ---
# Other outputs can remain unconstrained unless timing critical
set_false_path -to [get_ports {adat_1_user_o[0] adat_1_user_o[1] adat_1_user_o[2] adat_1_user_o[3] adat_2_user_o[0] adat_2_user_o[1] adat_2_user_o[2] adat_2_user_o[3] adat_loopback_1_o adat_loopback_2_o adat_out_1_o adat_out_2_o debug_o[0] debug_o[1] debug_o[2] debug_o[3] debug_o[4] debug_o[5] debug_o[6] debug_o[7]}]
set_false_path -to [get_ports {pll_locked_o word_clk_o}]
