`include "../ip/fifo_dual_clock.v"
`include "../modules/channel_buffer.sv"
`include "../modules/adat_tx_channel.sv"

`timescale 10ns / 1ns
module adat_tx_channel_tb (
    output              clk_o,
    output              i2s_running_o,
    output              i2s_data_o,
    output [3:0]        user_bits_o,
    output              adat_o
);
    var bit clk_state_r = '0;
    var bit i2s_running_state_r = '0;
    var bit i2s_data_state_r = '0;
    var bit [3:0] user_bits_state_r = '0;

    assign clk_o = clk_state_r;
    assign i2s_running_o = i2s_running_state_r;
    assign i2s_data_o = i2s_data_state_r;
    assign user_bits_o = user_bits_state_r;

    wire [3:0] user_bits_rev;
    assign user_bits_rev[3] = user_bits_state_r[0];
    assign user_bits_rev[2] = user_bits_state_r[1];
    assign user_bits_rev[1] = user_bits_state_r[2];
    assign user_bits_rev[0] = user_bits_state_r[3];

    adat_tx_channel u_adat_tx_channel (
        .clk_i              (clk_state_r),
        .i2s_running_i      (i2s_running_state_r),
        .i2s_data_i         (i2s_data_state_r),
        .user_bits_i        (user_bits_state_r),
        .adat_o             (adat_o)
    );

    // System clock process
    initial begin
        forever begin
            clk_state_r = '1;
            #4;
            clk_state_r = '0;
            #4;
        end
    end

    // Load data process
    int fd, status;
    var bit [2047:0] i2s_out;

    initial begin
        fd = $fopen("../../tb/adat_test_data_i2s.bin", "rb");
        status = $fread(i2s_out, fd);
        $fclose(fd);
    end

    // User bits process
    initial begin
        #50;
        #(8 * 512);

        for (int i = 1; i < 8; i++) begin
            user_bits_state_r = 4'd15 - i + 4'd1;
            #(8 * 256);
        end
    end

    // Main process
    initial begin
        i2s_running_state_r = '0;
        i2s_data_state_r = '0;

        #(8 * 128);

        i2s_data_state_r = '1;

        #(8 * 127);

        i2s_running_state_r = '1;

        for (int i = 0; i < 2048; i++) begin
            i2s_data_state_r = i2s_out[2047 - i];
            #8;
        end

        i2s_running_state_r = '0;
        i2s_data_state_r = '0;
        #(8 * 256);
        #1;

        #15000;
        $stop;
    end
endmodule
