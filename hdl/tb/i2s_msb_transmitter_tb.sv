`include "../modules/channel_buffer.sv"
`include "../modules/i2s_msb_transmitter.sv"

`timescale 10ns / 1ns
module i2s_msb_transmitter_tb (
    output                          clk_x4_o,
    output                          ram_data_o,
    output                          resync_req_o,
    output [ 2:0]                   last_good_frame_idx_o,
    output [10:0]                   ram_read_addr_o,
    output                          i2s_running_o,
    output                          i2s_bclk_o,
    output                          i2s_lrclk_o,
    output reg                      i2s_data_ro
);
    var bit clk_state_r = '0;
    var bit resync_req_state_r = '0;
    var bit [2:0] last_good_frame_idx_state_r = '0;

    assign clk_x4_o = clk_state_r;
    assign resync_req_o = resync_req_state_r;
    assign last_good_frame_idx_o = last_good_frame_idx_state_r;

    channel_buffer u_channel_buffer (
        .write_data_i    (1'b0),
        .read_addr_i     (ram_read_addr_o),
        .write_addr_i    ('0),
        .wr_en_i         (1'b0),
        .clk_i           (clk_state_r),
        .read_data_o     (ram_data_o)
    );

    i2s_msb_transmitter #(
        .CIRC_BUF_BITS            (3)
    ) u_i2s_msb_transmitter (
        .clk_x4_i                 (clk_state_r),
        .ram_data_i               (ram_data_o),
        .resync_req_i             (resync_req_state_r),
        .last_good_frame_idx_i    (last_good_frame_idx_state_r),
        .ram_read_addr_o          (ram_read_addr_o),
        .i2s_running_o            (i2s_running_o),
        .i2s_bclk_o               (i2s_bclk_o),
        .i2s_lrclk_o              (i2s_lrclk_o),
        .i2s_data_ro              (i2s_data_ro)
    );

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
    var bit [2047:0] i2s_out;

    initial begin
        fd = $fopen("../../tb/adat_test_data_i2s.bin", "rb");
        status = $fread(i2s_out, fd);
        $fclose(fd);

        for (int i = 0; i < 2048; i++) begin
            u_channel_buffer.u_simple_dual_port_ram_single_clock.ram[i] = i2s_out[2047 - i];
        end
    end

    // Main process
    initial begin
        #50;

        for (int i = 0; i < 8; i++) begin
            #(8 * 256);
            last_good_frame_idx_state_r = i;
        end

        #(16 * 256);

        for (int i = 0; i < 8; i++) begin
            #(8 * 256);
            last_good_frame_idx_state_r = i;
        end

        #(16 * 256);
        $stop;
    end

    // Resync request process
    initial begin
        #10;

        resync_req_state_r = 1'b1;

        #25000;

        resync_req_state_r = 1'b0;

        #100;

        resync_req_state_r = 1'b1;
    end
endmodule
