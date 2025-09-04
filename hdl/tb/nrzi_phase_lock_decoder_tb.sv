`include "../modules/nrzi_phase_lock_decoder.sv"

`timescale 10ns / 1ns
module nrzi_phase_lock_decoder_tb(
    output reg      in_bit_o,
    output          nrzi_state_o,
    output          clk_x4_o,
    output          clk_o,
    output          clk_main_tick_no,
    output          data_o,
    output          valid_o,
    output          sync_o
);
    bit [559:0] data_tx_r;
    var bit [559:0] data_rx_r;
    var bit nrzi_state_r = '0;
    var bit clk_state_r = '0;
    var bit [15:0] write_pos_r = '0;
    const int jitter_amount = 2000;

    wire logic output_data;
    wire logic output_valid;

    nrzi_phase_lock_decoder u_nrzi_phase_lock_decoder (
        .clk_x4_i           (clk_state_r),
        .nrzi_i             (nrzi_state_r),
        .clk_o              (clk_o),
        .clk_main_tick_no   (clk_main_tick_no),
        .data_o             (data_o),
        .valid_o            (valid_o),
        .sync_o             (sync_o)
    );

    assign nrzi_state_o = nrzi_state_r;
    assign clk_x4_o = clk_state_r;

    real initial_delay;
    real next_bit_time;
    real clock_jitter;
    real actual_next_bit_time;
    bit data_in;

    initial begin
        for (int i = 0; i < 512; i++) begin
            data_tx_r[i] = $urandom() % 2;
        end

        data_tx_r[0] = '1;
        in_bit_o = '0;

        initial_delay = real'($urandom() % 10000) / 1000.0;
        #(initial_delay);

        next_bit_time = initial_delay;

        for (int i = 0; i < 560; i++) begin
            data_in = data_tx_r[i];
            in_bit_o = data_in;
            if (data_in) begin
                nrzi_state_r = !nrzi_state_r;
            end

            next_bit_time = next_bit_time + 8.0;
            clock_jitter = real'($urandom() % jitter_amount) / 1000.0;
            actual_next_bit_time = next_bit_time - clock_jitter;

            #(actual_next_bit_time - $realtime);
        end

        #20;

        $display("Input data: %b", data_tx_r);
        $display("Captured output data: %b", data_rx_r);

        data_tx_r[0] = 'b0; // the first sync transition will be missing in the output

        repeat (16) begin
            data_rx_r = data_rx_r >> 1;

            if (data_rx_r == data_tx_r) begin
                $display("Data received correctly, yay!");
            end
        end

        $stop;
    end

    initial begin
        forever begin
            clk_state_r = '1;
            #1;
            clk_state_r = '0;
            #1;

            if (!clk_main_tick_no) begin
                data_rx_r[write_pos_r] = data_o;
                write_pos_r = write_pos_r + 'd1;
            end
        end
    end
endmodule
