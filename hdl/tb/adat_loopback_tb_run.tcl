vlog +acc=npr \
    ../../tb/adat_loopback_tb.sv \
    ../../modules/simple_dual_port_ram_single_clock.sv \
    +define+SIMULATION
vsim -sv_seed random adat_loopback_tb -L altera_mf_ver -L altera_lnsim_ver

add wave -position insertpoint  \
    sim:/adat_loopback_tb/clk_o \
    sim:/adat_loopback_tb/clk_x4_o \
    sim:/adat_loopback_tb/resync_req_o \
    sim:/adat_loopback_tb/i2s_data_o \
    sim:/adat_loopback_tb/i2s_bclk_o \
    sim:/adat_loopback_tb/i2s_lrclk_o \
    sim:/adat_loopback_tb/i2s_running_o \
    sim:/adat_loopback_tb/adat_locked_o \
    sim:/adat_loopback_tb/adat_user_o \
    sim:/adat_loopback_tb/user_bits_state_r \
    sim:/adat_loopback_tb/user_bits_state_q \
    sim:/adat_loopback_tb/raw_adat_o \
    sim:/adat_loopback_tb/raw_adat_valid_o

add wave -divider ADAT

add wave -color yellow \
    sim:/adat_loopback_tb/adat_in_o \
    sim:/adat_loopback_tb/adat_out_o

run -all
