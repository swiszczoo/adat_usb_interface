`include "../modules/channel_buffer.sv"
`include "../modules/i2s_msb_receiver.sv"

`timescale 10ns / 1ns
module i2s_msb_receiver_tb(
    output                      clk_x4_o,
    output                      i2s_running_o,
    output                      i2s_data_o,
    output                      i2s_bclk_o,
    output [10:0]               ram_write_addr_o,
    output                      ram_write_en_o,
    output                      ram_write_data_o,
    output [ 2:0]               last_good_frame_idx_o
);
    var bit clk_state_r = '0;
    var bit i2s_running_state_r = '0;
    var bit i2s_data_state_r = '0;
    var bit i2s_bclk_state_r = '1;

    assign clk_x4_o = clk_state_r;
    assign i2s_running_o = i2s_running_state_r;
    assign i2s_data_o = i2s_data_state_r;
    assign i2s_bclk_o = i2s_bclk_state_r;

    i2s_msb_receiver #(
        .CIRC_BUF_BITS              (3)
    ) u_i2s_msb_receiver (
        .clk_x4_i                   (clk_state_r),
        .i2s_running_i              (i2s_running_state_r),
        .i2s_data_i                 (i2s_data_state_r),
        .i2s_bclk_i                 (i2s_bclk_o),
        .ram_write_addr_o           (ram_write_addr_o),
        .ram_write_en_o             (ram_write_en_o),
        .ram_write_data_o           (ram_write_data_o),
        .last_good_frame_idx_o      (last_good_frame_idx_o)
    );

    channel_buffer u_channel_buffer (
        .write_data_i               (ram_write_data_o),
        .read_addr_i                (11'b0),
        .write_addr_i               (ram_write_addr_o),
        .wr_en_i                    (ram_write_en_o),
        .clk_i                      (clk_state_r),
        .read_data_o                ()
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
    end

    // BCLK process
    initial begin
        while (i2s_bclk_state_r != '0) #1;

        #4;

        forever begin
            i2s_bclk_state_r = '1;
            #4;
            i2s_bclk_state_r = '0;
            #4;
        end
    end

    bit valid = '1;
    initial begin
        i2s_running_state_r = '0;
        i2s_data_state_r = '0;

        #(4 * 256);

        i2s_data_state_r = '1;

        while (ram_write_addr_o != 11'hff) #1;

        #7;

        i2s_running_state_r = '1;
        i2s_bclk_state_r = '0;

        for (int i = 0; i < 2048; i++) begin
            i2s_data_state_r = i2s_out[2047 - i];
            #8;
        end

        i2s_running_state_r = '0;
        i2s_data_state_r = '0;
        #(8 * 256);
    
        // Validate received data
        for (int i = 0; i < 2048; i++) begin
            if (u_channel_buffer.u_simple_dual_port_ram_single_clock.ram[i] != i2s_out[2047 - i]) begin
                valid = '0;
            end
        end

        if (valid) begin
            $display("Everything is ok!");
        end else begin
            $display("Something is wrong!");
        end

        $stop;
    end
endmodule
