vlog +acc=npr ../../tb/i2s_msb_receiver_tb.sv ../../modules/simple_dual_port_ram_single_clock.sv +define+SIMULATION
vsim -sv_seed random i2s_msb_receiver_tb

add wave -position insertpoint  \
    sim:/i2s_msb_receiver_tb/clk_x4_o \
    sim:/i2s_msb_receiver_tb/i2s_running_o \
    sim:/i2s_msb_receiver_tb/i2s_data_o \
    sim:/i2s_msb_receiver_tb/i2s_bclk_o \
    sim:/i2s_msb_receiver_tb/ram_write_addr_o \
    sim:/i2s_msb_receiver_tb/ram_write_en_o \
    sim:/i2s_msb_receiver_tb/ram_write_data_o \
    sim:/i2s_msb_receiver_tb/last_good_frame_idx_o \
    sim:/i2s_msb_receiver_tb/u_i2s_msb_receiver/i2s_data_q

run -all