vlog +acc=npr \
    ../../tb/adat_tx_channel_tb.sv \
    ../../modules/simple_dual_port_ram_single_clock.sv \
    ../../modules/i2s_msb_receiver.sv \
    +define+SIMULATION
vsim -sv_seed random adat_tx_channel_tb -L altera_mf_ver -L altera_lnsim_ver

add wave -position insertpoint  \
    sim:/adat_tx_channel_tb/clk_o \
    sim:/adat_tx_channel_tb/i2s_running_o \
    sim:/adat_tx_channel_tb/i2s_data_o \
    sim:/adat_tx_channel_tb/user_bits_o \
    sim:/adat_tx_channel_tb/u_adat_tx_channel/u_i2s_msb_receiver/ram_write_addr_o \
    sim:/adat_tx_channel_tb/u_adat_tx_channel/u_i2s_msb_receiver/ram_write_en_o \
    sim:/adat_tx_channel_tb/u_adat_tx_channel/u_i2s_msb_receiver/ram_write_data_o

add wave -divider Outputs
add wave -color yellow sim:/adat_tx_channel_tb/adat_o

run -all
