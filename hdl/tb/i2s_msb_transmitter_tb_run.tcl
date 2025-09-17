vlog +acc=npr ../../tb/i2s_msb_transmitter_tb.sv ../../modules/simple_dual_port_ram_single_clock.sv +define+SIMULATION
vsim -sv_seed random i2s_msb_transmitter_tb
add wave -position insertpoint  \
    sim:/i2s_msb_transmitter_tb/clk_x4_o \
    sim:/i2s_msb_transmitter_tb/ram_data_o \
    sim:/i2s_msb_transmitter_tb/resync_req_o \
    sim:/i2s_msb_transmitter_tb/last_good_frame_idx_o \
    sim:/i2s_msb_transmitter_tb/ram_read_addr_o \
    sim:/i2s_msb_transmitter_tb/u_i2s_msb_transmitter/output_state \
    sim:/i2s_msb_transmitter_tb/u_i2s_msb_transmitter/soon_next_frame \
    sim:/i2s_msb_transmitter_tb/u_i2s_msb_transmitter/new_frame_available \
    sim:/i2s_msb_transmitter_tb/u_i2s_msb_transmitter/read_frame_r
add wave -position insertpoint -color khaki \
    sim:/i2s_msb_transmitter_tb/i2s_running_o \
    sim:/i2s_msb_transmitter_tb/i2s_bclk_o \
    sim:/i2s_msb_transmitter_tb/i2s_lrclk_o \
    sim:/i2s_msb_transmitter_tb/i2s_data_ro

run -all
