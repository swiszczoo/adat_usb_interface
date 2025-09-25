module top (
    input           clk_44100_i,    // 11.2896MHz xtal out
    input           clk_48000_i,    // 12.2880MHz xtal out
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
    wire clk_x4;
    wire clk_sys;
    wire clk_word;
    wire pll_locked;

    pll u_pll (
        .areset         (1'b0),
        .clkswitch      (fs_sel_i),
        .inclk0         (clk_48000_i),
        .inclk1         (clk_44100_i),
        .activeclock    (),
        .c0             (clk_x4),
        .c1             (clk_sys),
        .c2             (clk_word),
        .locked         (pll_locked)
    );

    wire pll_locked_snh;
    sample_and_hold_zero #(
        .COUNTER_VAL    (6144000) // half a second
    ) u_sample_and_hold_zero (
        .clk_i          (clk_sys),
        .signal_i       (pll_locked),
        .signal_o       (pll_locked_snh)
    );

    wire [3:0] adat_1_user_sync;
    wire [3:0] adat_2_user_sync;

    synchronizer_2stage #(
        .PORT_WIDTH    (4)
    ) u_adat_1_user_sync (
        .data_i        (adat_1_user_i),
        .clk_i         (clk_sys),
        .data_o        (adat_1_user_sync)
    );

    synchronizer_2stage #(
        .PORT_WIDTH    (4)
    ) u_adat_2_user_sync (
        .data_i        (adat_2_user_i),
        .clk_i         (clk_sys),
        .data_o        (adat_2_user_sync)
    );

    wire mcu_ready_sync;
    synchronizer_2stage u_mcu_ready_sync (
        .data_i        (mcu_ready_i),
        .clk_i         (clk_sys),
        .data_o        (mcu_ready_sync)
    );

    wire i2s_resync_req_sync;
    synchronizer_2stage u_i2s_resync_req_sync (
        .data_i        (i2s_resync_req_i),
        .clk_i         (clk_sys),
        .data_o        (i2s_resync_req_sync)
    );

    wire loopback_sync;
    synchronizer_2stage u_loopback_sync (
        .data_i        (loopback_i),
        .clk_i         (clk_sys),
        .data_o        (loopback_sync)
    );

    assign sel_clk_o = pll_locked_o && clk_sys;
    assign word_clk_o = clk_word;
    assign pll_locked_o = pll_locked_snh;

    wire adat_reset = !pll_locked_snh || !mcu_ready_sync;

    wire i2s_1_running;
    wire i2s_1_raw_adat;
    wire i2s_1_raw_adat_valid;
    adat_rx_channel u_rx_ch_1_8 (
        .clk_i               (clk_sys),
        .clk_x4_i            (clk_x4),
        .adat_i              (adat_in_1_i),
        .resync_req_i        (i2s_resync_req_sync),
        .reset_i             (adat_reset),
        .i2s_data_o          (i2s_1_data_o),
        .i2s_bclk_o          (i2s_1_bclk_o),
        .i2s_lrclk_o         (i2s_1_lrclk_o),
        .i2s_running_o       (i2s_1_running),
        .adat_locked_o       (adat_1_locked_o),
        .adat_user_o         (adat_1_user_o),
        .raw_adat_o          (i2s_1_raw_adat),
        .raw_adat_valid_o    (i2s_1_raw_adat_valid)
    );

    wire i2s_2_running;
    wire i2s_2_raw_adat;
    wire i2s_2_raw_adat_valid;
    adat_rx_channel u_rx_ch_9_16 (
        .clk_i               (clk_sys),
        .clk_x4_i            (clk_x4),
        .adat_i              (adat_in_2_i),
        .resync_req_i        (i2s_resync_req_sync),
        .reset_i             (adat_reset),
        .i2s_data_o          (i2s_2_data_o),
        .i2s_bclk_o          (i2s_2_bclk_o),
        .i2s_lrclk_o         (i2s_2_lrclk_o),
        .i2s_running_o       (i2s_2_running),
        .adat_locked_o       (adat_2_locked_o),
        .adat_user_o         (adat_2_user_o),
        .raw_adat_o          (i2s_2_raw_adat),
        .raw_adat_valid_o    (i2s_2_raw_adat_valid)
    );

    assign i2s_running_o = i2s_1_running && i2s_2_running;

    wire adat_1_out;
    adat_tx_channel u_tx_ch_1_8 (
        .clk_i            (clk_sys),
        .i2s_running_i    (i2s_1_running),
        .i2s_data_i       (i2s_1_data_i),
        .adat_user_i      (adat_1_user_sync),
        .adat_o           (adat_1_out)
    );

    wire adat_2_out;
    adat_tx_channel u_tx_ch_9_16 (
        .clk_i            (clk_sys),
        .i2s_running_i    (i2s_2_running),
        .i2s_data_i       (i2s_2_data_i),
        .adat_user_i      (adat_2_user_sync),
        .adat_o           (adat_2_out)
    );

    wire adat_1_loopback;
    nrzi_encoder u_ch_1_8_loopback_encoder (
        .clk_i              (clk_sys),
        .data_i             (i2s_1_raw_adat),
        .output_en_i        (i2s_1_raw_adat_valid),
        .data_o             (adat_1_loopback)
    );

    wire adat_2_loopback;
    nrzi_encoder u_ch_9_16_loopback_encoder (
        .clk_i              (clk_sys),
        .data_i             (i2s_2_raw_adat),
        .output_en_i        (i2s_2_raw_adat_valid),
        .data_o             (adat_2_loopback)
    );

    assign adat_out_1_o = (loopback_sync) ? adat_1_loopback : adat_1_out;
    assign adat_out_2_o = (loopback_sync) ? adat_2_loopback : adat_2_out;
    assign adat_loopback_1_o = adat_1_loopback;
    assign adat_loopback_2_o = adat_2_loopback;

    assign debug_o = '0;
endmodule
