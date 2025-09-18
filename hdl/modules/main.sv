module main (
    input           clk_44100_i,    // 22.5792MHz xtal out
    input           clk_48000_i,    // 24.5760MHz xtal out
    input           adat_in_1_i,    // channels 1-8 IN
    input           adat_in_2_i,    // channels 9-16 IN
    input [ 3:0]    adat_1_user_i,
    input [ 3:0]    adat_2_user_i,
    input           mcu_ready_i,
    input           fs_sel_i,       // 0 - 48 kHz, 1 - 44.1 kHz
    input           i2s_resync_req_i,
    input           loopback_i,
    input           i2s_1_data_i,
    input           i2s_2_data_i,

    output          sel_clk_o,
    output          word_clk_o,
    output          pll_locked_o,
    output          i2s_1_data_o,
    output          i2s_1_bclk_o,
    output          i2s_1_lrclk_o,
    output          i2s_2_data_o,
    output          i2s_2_bclk_o,
    output          i2s_2_lrclk_o,
    output          adat_out_1_o,   // channels 1-8 OUT
    output          adat_out_2_o,   // channels 9-16 OUT
    output          adat_loopback_1_o,
    output          adat_loopback_2_o,
    output          i2s_running_o,
    output          adat_1_locked_o,
    output          adat_2_locked_o,
    output [ 3:0]   adat_1_user_o,
    output [ 3:0]   adat_2_user_o,
    output [ 7:0]   debug_o
);
      
endmodule
