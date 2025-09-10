vlog +acc=npr ../../tb/i2s_loopback_tb.sv ../../modules/simple_dual_port_ram_single_clock.sv
vsim -sv_seed random i2s_loopback_tb

add wave -position insertpoint  \
    sim:/i2s_loopback_tb/clk_x4_o \
    sim:/i2s_loopback_tb/ram_data_o \
    sim:/i2s_loopback_tb/resync_req_o \
    sim:/i2s_loopback_tb/last_good_frame_idx_o \
    sim:/i2s_loopback_tb/ram_read_addr_o \
    sim:/i2s_loopback_tb/i2s_running_o \
    sim:/i2s_loopback_tb/i2s_bclk_o \
    sim:/i2s_loopback_tb/i2s_lrclk_o \
    sim:/i2s_loopback_tb/i2s_data_ro \
    sim:/i2s_loopback_tb/ram_write_addr_o \
    sim:/i2s_loopback_tb/ram_write_en_o \
    sim:/i2s_loopback_tb/ram_write_data_o \
    sim:/i2s_loopback_tb/last_good_frame_idx_dest_o

run -all
