// Circular buffer for one ADAT channel (8 audio channels)
module channel_buffer (
    input               write_data_i,
    input [10:0]        read_addr_i,
    input [10:0]        write_addr_i,
    input               wr_en_i,
    input               clk_i,
    output              read_data_o
);
    simple_dual_port_ram_single_clock #(
        .DATA_WIDTH    (1),         // We access single bit at once
        .ADDR_WIDTH    (8 + 3)      // 8 samples of data
    ) u_simple_dual_port_ram_single_clock (
        .data          (write_data_i),
        .read_addr     (read_addr_i),
        .write_addr    (write_addr_i),
        .we            (wr_en_i),
        .clk           (clk_i),
        .q             (read_data_o)
    );
endmodule
