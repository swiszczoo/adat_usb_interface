vlog +acc=npr ../../tb/adat_encoder_tb.sv ../../modules/simple_dual_port_ram_single_clock.sv +define+SIMULATION
vsim -sv_seed random adat_encoder_tb

add wave -position insertpoint  \
    sim:/adat_encoder_tb/clk_o \
    sim:/adat_encoder_tb/ram_data_o \
    sim:/adat_encoder_tb/last_good_frame_idx_o \
    sim:/adat_encoder_tb/user_bits_o \
    sim:/adat_encoder_tb/ram_read_addr_o \
    sim:/adat_encoder_tb/adat_o \
    sim:/adat_encoder_tb/u_adat_encoder/read_frame_r \
    sim:/adat_encoder_tb/u_adat_encoder/transmitter_state \
    sim:/adat_encoder_tb/u_adat_encoder/adat_state \
    sim:/adat_encoder_tb/u_adat_encoder/soon_next_frame \
    sim:/adat_encoder_tb/u_adat_encoder/new_frame_available \
    sim:/adat_encoder_tb/u_adat_encoder/nibble_counter_r

run -all
