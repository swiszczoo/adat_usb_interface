module adat_rx_channel (
    input           clk_x4_i,
    input           adat_i,
    input           resync_req_i,
    input           reset_i,
    output          i2s_data_o,
    output          i2s_bclk_o,
    output          i2s_lrclk_o,
    output          i2s_running_o,
    output          adat_locked_o,
    output [ 3:0]   adat_user_o
);
    wire ram_write_data;
    wire [10:0] ram_read_addr;
    wire [10:0] ram_write_addr;
    wire ram_write_en;
    wire ram_q;

    channel_buffer u_buffer (
        .write_data_i    (ram_write_data),
        .read_addr_i     (ram_read_addr),
        .write_addr_i    (ram_write_addr),
        .wr_en_i         (ram_write_en),
        .clk_i           (clk_x4_i),
        .read_data_o     (ram_q)
    );

    wire clk_main_tick;
    wire [2:0] last_good_frame_idx;
    wire has_sync;

    adat_decoder #(
        .CIRC_BUF_BITS            (3)
    ) u_adat_decoder (
        .clk_x4_i                 (clk_x4_i),
        .nrzi_i                   (adat_i),
        .reset_i                  (reset_i),
        .clk_main_tick_no         (clk_main_tick),
        .ram_write_en_o           (ram_write_en),
        .ram_write_addr_o         (ram_write_addr),
        .ram_write_data_o         (ram_write_data),
        .last_good_frame_idx_o    (last_good_frame_idx),
        .user_bits_o              (adat_user_o),
        .has_sync_o               (has_sync)
    );

    i2s_msb_transmitter #(
        .CIRC_BUF_BITS            (3)
    ) u_i2s_msb_transmitter (
        .clk_x4_i                 (clk_x4_i),
        .ram_data_i               (ram_q),
        .resync_req_i             (resync_req_i),
        .last_good_frame_idx_i    (last_good_frame_idx),
        .ram_read_addr_o          (ram_read_addr),
        .i2s_running_o            (i2s_running_o),
        .i2s_bclk_o               (i2s_bclk_o),
        .i2s_lrclk_o              (i2s_lrclk_o),
        .i2s_data_ro              (i2s_data_o)
    );

    sample_and_hold_zero #(
        .COUNTER_VAL    (6144000) // half a second
    ) u_samplenhold (
        .clk_i          (clk_x4_i),
        .signal_i       (has_sync),
        .signal_o       (adat_locked_o)
    );
endmodule
