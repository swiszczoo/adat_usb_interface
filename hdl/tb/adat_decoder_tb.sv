`include "../modules/adat_decoder.sv"
`include "../modules/channel_buffer.sv"
`include "jitter_generator.sv"

`timescale 10ns / 1ns
module adat_decoder_tb (
    output reg      adat_in_o,
    output          clk_main_tick_no,
    output          ram_write_en_o,
    output [10:0]   ram_write_addr_o,
    output          ram_write_data_o,
    output [2:0]    last_good_frame_idx_o,
    output [3:0]    user_bits_o,
    output          has_sync_o
);
    var bit clk_state_r = '0;
    var bit adat_state_r = '0;
    var bit reset_state_r = '0;

    adat_decoder #(
        .CIRC_BUF_BITS              (3)
    ) u_adat_decoder (
        .clk_x4_i                   (clk_state_r),
        .nrzi_i                     (adat_state_r),
        .reset_i                    (reset_state_r),
        .clk_main_tick_no           (clk_main_tick_no),
        .ram_write_en_o             (ram_write_en_o),
        .ram_write_addr_o           (ram_write_addr_o),
        .ram_write_data_o           (ram_write_data_o),
        .last_good_frame_idx_o      (last_good_frame_idx_o),
        .user_bits_o                (user_bits_o),
        .has_sync_o                 (has_sync_o)
    );

    channel_buffer u_channel_buffer (
        .write_data_i               (ram_write_data_o),
        .read_addr_i                (),
        .write_addr_i               (ram_write_addr_o),
        .wr_en_i                    (ram_write_en_o),
        .clk_i                      (clk_state_r),
        .read_data_o                ()
    );

    var bit [2047:0] adat_in;
    var bit [2047:0] i2s_out;
    const real jitter_amount = 2.0;

    // Clock process
    initial begin
        forever begin
            clk_state_r = '1;
            #1;
            clk_state_r = '0;
            #1;
        end
    end

    // Load data process
    int fd, status;
    initial begin
        fd = $fopen("../../tb/adat_test_data_adat_nrzi.bin", "rb");
        status = $fread(adat_in, fd);
        $fclose(fd);

        fd = $fopen("../../tb/adat_test_data_i2s.bin", "rb");
        status = $fread(i2s_out, fd);
        $fclose(fd);
    end

    // Test process
    jitter_generator gen = new();

    initial begin
        gen.initialize();

        for (int i = 0; i < 2048; i++) begin
            adat_state_r = adat_in[2047 - i];

            if (i > 150) begin
                gen.jitter(jitter_amount);
            end else begin
                gen.jitter(real'(150 - i) / 20.0 + 1.0);
            end
        end

        $stop;
    end

    assign adat_in_o = adat_state_r;
endmodule
