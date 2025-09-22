vlog +acc=npr \
    ../../tb/adat_rx_channel_tb.sv \
    ../../modules/adat_decoder.sv \
    ../../modules/i2s_msb_transmitter.sv \
    ../../modules/i2s_msb_receiver.sv \
    ../../modules/nrzi_phase_lock_decoder.sv \
    ../../modules/simple_dual_port_ram_single_clock.sv \
    ../../modules/sample_and_hold_zero.sv \
    +define+SIMULATION
vsim -sv_seed random adat_rx_channel_tb -L altera_mf_ver -L altera_lnsim_ver

add wave -position insertpoint  \
    sim:/adat_rx_channel_tb/clk_x4_o \
    sim:/adat_rx_channel_tb/adat_o \
    sim:/adat_rx_channel_tb/resync_req_o \
    sim:/adat_rx_channel_tb/reset_o \
    sim:/adat_rx_channel_tb/i2s_data_o \
    sim:/adat_rx_channel_tb/i2s_bclk_o \
    sim:/adat_rx_channel_tb/i2s_lrclk_o \
    sim:/adat_rx_channel_tb/i2s_running_o \
    sim:/adat_rx_channel_tb/adat_locked_o \
    sim:/adat_rx_channel_tb/adat_user_o \
    sim:/adat_rx_channel_tb/u_adat_rx_channel/u_adat_decoder/last_good_frame_idx_o \
    sim:/adat_rx_channel_tb/u_adat_rx_channel/u_adat_decoder/decoder_state \
    sim:/adat_rx_channel_tb/u_adat_rx_channel/u_i2s_msb_transmitter/output_state \
    sim:/adat_rx_channel_tb/u_i2s_msb_receiver/ram_write_addr_o \
    sim:/adat_rx_channel_tb/u_i2s_msb_receiver/ram_write_en_o \
    sim:/adat_rx_channel_tb/u_i2s_msb_receiver/ram_write_data_o \
    sim:/adat_rx_channel_tb/u_i2s_msb_receiver/clk_i \
    sim:/adat_rx_channel_tb/u_i2s_msb_receiver/i2s_running_i \
    sim:/adat_rx_channel_tb/u_i2s_msb_receiver/i2s_data_i \
    sim:/adat_rx_channel_tb/u_i2s_msb_receiver/i2s_bclk_i \
    sim:/adat_rx_channel_tb/u_i2s_msb_receiver/ram_write_addr_o \
    sim:/adat_rx_channel_tb/u_i2s_msb_receiver/ram_write_en_o \
    sim:/adat_rx_channel_tb/u_i2s_msb_receiver/ram_write_data_o \
    sim:/adat_rx_channel_tb/u_i2s_msb_receiver/last_good_frame_idx_o

run -all
