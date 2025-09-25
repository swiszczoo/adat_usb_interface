module adat_tx_channel (
    input               clk_i,
    input               i2s_running_i,
    input               i2s_data_i,
    input [3:0]         adat_user_i,

    output              adat_o
);
    wire ram_write_data;
    wire [10:0] ram_read_addr;
    wire [10:0] ram_write_addr;
    wire ram_write_en;
    wire ram_q;

    channel_buffer u_buffer (
        .write_data_i               (ram_write_data),
        .read_addr_i                (ram_read_addr),
        .write_addr_i               (ram_write_addr),
        .wr_en_i                    (ram_write_en),
        .clk_i                      (clk_i),
        .read_data_o                (ram_q)
    );

    wire [2:0] last_good_frame_idx;

    i2s_msb_receiver #(
        .CIRC_BUF_BITS              (3)
    ) u_i2s_msb_receiver (
        .clk_i                      (clk_i),
        .i2s_running_i              (i2s_running_i),
        .i2s_data_i                 (i2s_data_i),
        .ram_write_addr_o           (ram_write_addr),
        .ram_write_en_o             (ram_write_en),
        .ram_write_data_o           (ram_write_data),
        .last_good_frame_idx_o      (last_good_frame_idx)
    );

    adat_encoder #(
        .CIRC_BUF_BITS              (3)
    ) u_adat_encoder (
        .clk_i                      (clk_i),
        .ram_data_i                 (ram_q),
        .last_good_frame_idx_i      (last_good_frame_idx),
        .user_bits_i                (adat_user_i),
        .ram_read_addr_o            (ram_read_addr),
        .adat_o                     (adat_o)
    );
endmodule
