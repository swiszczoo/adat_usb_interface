`include "../ip/fifo_dual_clock.v"
`include "../modules/adat_rx_channel.sv"
`include "../modules/channel_buffer.sv"
`include "jitter_generator.sv"

module adat_rx_channel_tb (
    output          clk_o,
    output          clk_x4_o,
    output          adat_o,
    output          resync_req_o,
    output          reset_o,
    output          i2s_data_o,
    output          i2s_bclk_o,
    output          i2s_lrclk_o,
    output          i2s_running_o,
    output          adat_locked_o,
    output [ 3:0]   adat_user_o
);
    var bit clk_state_r = '0;
    var bit clk_state_x4_r = '0;
    var bit adat_state_r = '0;
    var bit reset_state_r = '0;
    var bit resync_req_state_r = '0;

    adat_rx_channel u_adat_rx_channel (
        .clk_i                      (clk_state_r),
        .clk_x4_i                   (clk_state_x4_r),
        .adat_i                     (adat_state_r),
        .resync_req_i               (resync_req_state_r),
        .reset_i                    (reset_state_r),
        .i2s_data_o                 (i2s_data_o),
        .i2s_bclk_o                 (i2s_bclk_o),
        .i2s_lrclk_o                (i2s_lrclk_o),
        .i2s_running_o              (i2s_running_o),
        .adat_locked_o              (adat_locked_o),
        .adat_user_o                (adat_user_o)
    );

    assign clk_o = clk_state_r;
    assign clk_x4_o = clk_state_x4_r;
    assign adat_o = adat_state_r;
    assign resync_req_o = resync_req_state_r;
    assign reset_o = reset_state_r;

    wire [10:0] ram_write_addr_o;
    wire ram_write_data_o;
    wire ram_write_en_o;

    i2s_msb_receiver #(
        .CIRC_BUF_BITS              (3)
    ) u_i2s_msb_receiver (
        .clk_i                      (clk_state_r),
        .i2s_running_i              (i2s_running_o),
        .i2s_data_i                 (i2s_data_o),
        .i2s_bclk_i                 (i2s_bclk_o),
        .ram_write_addr_o           (ram_write_addr_o),
        .ram_write_en_o             (ram_write_en_o),
        .ram_write_data_o           (ram_write_data_o),
        .last_good_frame_idx_o      ()
    );

    channel_buffer u_buffer_dest (
        .write_data_i               (ram_write_data_o),
        .read_addr_i                (11'b0),
        .write_addr_i               (ram_write_addr_o),
        .wr_en_i                    (ram_write_en_o),
        .clk_i                      (clk_state_r),
        .read_data_o                ()
    );
    

    var bit [2047:0] adat_in;
    var bit [2047:0] i2s_out;
    const real jitter_amount = 2.0;

    // x4 clock process
    initial begin
        forever begin
            clk_state_x4_r = '1;
            #1;
            clk_state_x4_r = '0;
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
    bit ok = 1'b1;

    initial begin
        #50;

        gen.initialize();

        for (int i = 0; i < 2048; i++) begin
            adat_state_r = adat_in[2047 - i];
            gen.jitter(jitter_amount);
        end

        #4032;

        // skip first two adat frames
        i2s_out[2047:1536] = '0;

        for (int i = 0; i < 2048; i++) begin
            if (i2s_out[2047 - i] != u_buffer_dest.u_simple_dual_port_ram_single_clock.ram[i]) begin
                ok = 1'b0;
                $display("%d", i);
            end
        end

        if (ok) begin
            $display("Everything is ok!");
        end else begin
            $display("Something is wrong! Below are the compared values");
            $display("%b", i2s_out);

            for (int i = 0; i < 2048; i++) begin
                i2s_out[2047 - i] = u_buffer_dest.u_simple_dual_port_ram_single_clock.ram[i];
            end

            $display("%b", i2s_out);
        end

        $stop;
    end

    // Enable i2s at the right moment
    initial begin
        #4000;
        resync_req_state_r = '1;
    end

    assign adat_in_o = adat_state_r;
endmodule
