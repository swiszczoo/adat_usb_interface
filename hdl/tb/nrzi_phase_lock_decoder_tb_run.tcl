vlog +acc=npr ../../tb/nrzi_phase_lock_decoder_tb.sv ../../modules/simple_dual_port_ram_single_clock.sv +define+SIMULATION
vsim -sv_seed random nrzi_phase_lock_decoder_tb -L altera_mf_ver -L altera_lnsim_ver
add wave -position insertpoint  \
    sim:/nrzi_phase_lock_decoder_tb/in_bit_o \
    sim:/nrzi_phase_lock_decoder_tb/nrzi_state_o \
    sim:/nrzi_phase_lock_decoder_tb/clk_o \
    sim:/nrzi_phase_lock_decoder_tb/clk_x4_o \
    sim:/nrzi_phase_lock_decoder_tb/data_o \
    sim:/nrzi_phase_lock_decoder_tb/valid_o \
    sim:/nrzi_phase_lock_decoder_tb/sync_o \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/current_read_pos_r \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/decoder_state \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/current_zeros_count_r \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/read_addr_r \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/ram_q \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/write_addr_r \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/write_data_r \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/symbol_history_shift_r \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/current_read_window_q \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/current_read_window_qr \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/u_fifo/data \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/u_fifo/rdclk \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/u_fifo/rdreq \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/u_fifo/wrclk \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/u_fifo/wrreq \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/u_fifo/q \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/u_fifo/rdempty \
    sim:/nrzi_phase_lock_decoder_tb/u_nrzi_phase_lock_decoder/u_fifo/wrfull

run -all
