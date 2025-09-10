vlog +acc=npr ../../tb/adat_decoder_tb.sv ../../modules/nrzi_phase_lock_decoder.sv
vsim -sv_seed random adat_decoder_tb
add wave -position insertpoint  \
    sim:/adat_decoder_tb/adat_in_o \
    sim:/adat_decoder_tb/u_adat_decoder/adat_bit \
    sim:/adat_decoder_tb/clk_main_tick_no \
    sim:/adat_decoder_tb/ram_write_en_o \
    sim:/adat_decoder_tb/ram_write_addr_o \
    sim:/adat_decoder_tb/ram_write_data_o \
    sim:/adat_decoder_tb/last_good_frame_idx_o \
    sim:/adat_decoder_tb/user_bits_o \
    sim:/adat_decoder_tb/has_sync_o \
    sim:/adat_decoder_tb/u_adat_decoder/decoder_state \
    sim:/adat_decoder_tb/u_adat_decoder/nibble_counter_r \
    sim:/adat_decoder_tb/u_adat_decoder/addr_mi_r \
    sim:/adat_decoder_tb/u_adat_decoder/addr_lo_r

run -all
