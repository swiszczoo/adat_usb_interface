vlog +acc=npr ../../tb/nrzi_phase_lock_decoder_tb.sv
vsim -sv_seed random nrzi_phase_lock_decoder_tb
add wave -position insertpoint  \
    sim:/nrzi_phase_lock_decoder_tb/in_bit_o \
    sim:/nrzi_phase_lock_decoder_tb/nrzi_state_o \
    sim:/nrzi_phase_lock_decoder_tb/clk_x4_o \
    sim:/nrzi_phase_lock_decoder_tb/clk_o \
    sim:/nrzi_phase_lock_decoder_tb/clk_main_tick_no \
    sim:/nrzi_phase_lock_decoder_tb/data_o \
    sim:/nrzi_phase_lock_decoder_tb/valid_o \
    sim:/nrzi_phase_lock_decoder_tb/sync_o \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/current_read_pos_r \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/decoder_state \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/current_zeros_count_r

run -all
