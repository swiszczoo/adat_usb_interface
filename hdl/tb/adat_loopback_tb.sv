`include "../modules/adat_decoder.sv"
`include "../modules/adat_encoder.sv"
`include "../modules/adat_rx_channel.sv"
`include "../modules/adat_tx_channel.sv"
`include "../modules/i2s_msb_receiver.sv"
`include "../modules/i2s_msb_transmitter.sv"
`include "../modules/nrzi_encoder.sv"
`include "jitter_generator.sv"

`timescale 10ns / 1ns
module adat_loopback_tb (
    output                      clk_o,
    output                      clk_x4_o,
    output                      adat_in_o,
    output                      resync_req_o,
    output                      i2s_data_o,
    output                      i2s_bclk_o,
    output                      i2s_lrclk_o,
    output                      i2s_running_o,
    output                      adat_locked_o,
    output [3:0]                adat_user_o,
    output                      raw_adat_o,
    output                      raw_adat_valid_o,
    output                      adat_out_o
);
    var bit clk_state_r = '0;
    var bit clk_x4_state_r = '0;
    var bit adat_in_state_r = '0;
    var bit resync_req_state_r = '0;
    var bit [3:0] user_bits_state_r = '0;
    var bit [3:0] user_bits_state_q = '0;

    assign clk_o = clk_state_r;
    assign clk_x4_o = clk_x4_state_r;
    assign adat_in_o = adat_in_state_r;
    assign resync_req_o = resync_req_state_r;

    adat_rx_channel u_rx (
        .clk_i                  (clk_state_r),
        .clk_x4_i               (clk_x4_state_r),
        .adat_i                 (adat_in_state_r),
        .resync_req_i           (resync_req_state_r),
        .reset_i                (1'b0),
        .i2s_data_o             (i2s_data_o),
        .i2s_bclk_o             (i2s_bclk_o),
        .i2s_lrclk_o            (i2s_lrclk_o),
        .i2s_running_o          (i2s_running_o),
        .adat_locked_o          (adat_locked_o),
        .adat_user_o            (adat_user_o),
        .raw_adat_o             (raw_adat_o),
        .raw_adat_valid_o       (raw_adat_valid_o)
    );

    adat_tx_channel u_tx (
        .clk_i                  (clk_state_r),
        .i2s_running_i          (i2s_running_o),
        .i2s_data_i             (i2s_data_o),
        .adat_user_i            (user_bits_state_r),
        .adat_o                 (adat_out_o)
    );

    // x4 clock process
    initial begin
        forever begin
            clk_x4_state_r = '1;
            #1;
            clk_x4_state_r = '0;
            #1;
        end
    end
    
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
    var bit [2047:0] adat_in;

    initial begin
        fd = $fopen("../../tb/adat_test_data_adat_nrzi.bin", "rb");
        status = $fread(adat_in, fd);
        $fclose(fd);
    end

    // User bits process
    initial begin
        #50;
        forever begin
            user_bits_state_q = user_bits_state_r;
            user_bits_state_r = adat_user_o;
            #(8 * 256);
        end
    end

    // Data storage process
    var bit [2047:0] adat_out;
    var bit [10:0] adat_write_idx = 11'd2047;

    initial begin
        #(8 * 512);
        #8;

        for (int i = 0; i < 2048; i++) begin
            #4;
            adat_out[adat_write_idx] = adat_out_o;
            adat_write_idx = adat_write_idx - 1'd1;
            #4;
        end
    end

    // Main process
    jitter_generator gen = new();
    const real jitter_amount = 2.0;
    var bit ok = '0;

    initial begin
        resync_req_state_r = '1;

        gen.initialize();

        for (int i = 0; i < 2048; i++) begin
            adat_in_state_r = adat_in[2047 - i];
            gen.jitter(jitter_amount);
        end

        // Send one more ADAT frame
        for (int i = 0; i < 256; i++) begin
            adat_in_state_r = adat_in[2047 - i];
            gen.jitter(jitter_amount);
        end

        #(8 * 256);
        #8;

        // Check
        adat_in[2047:1536] = '0;
        adat_out[2047:1536] = '0;
        if (adat_in == adat_out) begin
            ok = '1;
        end else begin
            adat_in[2047:1536] = '1;
            adat_in = ~adat_in;

            if (adat_in == adat_out) begin
                ok = '1;
            end
        end

        if (ok) begin
            $display("Data transmitted correctly, yay!");
        end else begin
            $display("Something is wrong...");
            $display("Input data: %b", adat_in);
            $display("Captured output data: %b", adat_out);
        end

        #20000;

        $stop;
    end
endmodule
