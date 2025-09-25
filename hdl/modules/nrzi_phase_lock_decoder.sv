// This version uses circular buffer in BRAM and can decode shittier clocks
module nrzi_phase_lock_decoder (
    input           clk_i,
    input           clk_x4_i,
    
    // This will be sampled in clk_x4_i domain
    input           nrzi_i, 

    // This pins are in clk_i clock domain
    output          data_o,
    output          valid_o,
    output          sync_o              // starts outputting 1 after 8 consecutive zeroes
                                        // can be used for ADAT frame synchronization
);
    typedef enum bit[1:0] {
        // initial state, reset all registers
        StIdle,

        // we are currently waiting for enough data to be acquired
        StInitialAcquireData,

        // we are looking for a clean transition pattern and adjust our detection window position
        StSearchForTransition,

        // we are currently synced to the signal and output decoded bits
        StSynced
    } decoder_state_e;

    // Clock divider submodule (div/4)
    var bit [1:0] clk_div_r = 'b00;
    wire clk_main_tick_next = clk_div_r[1] | clk_div_r[0];
    var bit clk_main_tick_nr;

    always_ff @(posedge clk_x4_i) begin
        clk_div_r <= clk_div_r + 2'b01;
        clk_main_tick_nr <= clk_main_tick_next;
    end

    wire clk_main_tick = clk_main_tick_nr;

    // Decoder
    decoder_state_e decoder_state = StIdle;
    decoder_state_e decoder_state_next;

    var bit [4:0] current_zeros_count_r = 'b00000;
    logic [4:0] current_zeros_count_next;

    var bit [4:0] current_read_pos_r = 5'd16;
    logic [4:0] current_read_pos_next;
    
    var bit [5:0] read_addr_r = 6'b0;
    var bit [5:0] read_addr_actual;
    var bit [5:0] read_addr_next;

    var bit [5:0] write_addr_r = 'b000;
    var bit [5:0] write_addr_next;

    var bit write_data_r = 'b000;
    var bit write_data_next;

    reg data_r;
    logic data_next;

    wire too_many_zeros_error = current_zeros_count_r[4];

    wire ram_q;
    var ram_q2;

    simple_dual_port_ram_single_clock #(
        .DATA_WIDTH     (1),
        .ADDR_WIDTH     (6)
    ) u_single_port_ram (
        .data           (write_data_r),
        .read_addr      (read_addr_actual),
        .write_addr     (write_addr_r),
        .we             (1'b1),
        .clk            (clk_x4_i),
        .q              (ram_q)
    );

    // FIFO
    wire [2:0] fifo_q;
    wire fifo_wrfull, fifo_rdempty;
    logic fifo_wrreq_next;
    wire [2:0] fifo_wrdata_next;
    wire fifo_rdreq_next = !fifo_rdempty;

    fifo_dual_clock u_fifo (
        .data           (fifo_wrdata_next),
        .rdclk          (clk_i),
        .rdreq          (fifo_rdreq_next),
        .wrclk          (clk_x4_i),
        .wrreq          (fifo_wrreq_next),
        .q              (fifo_q),
        .rdempty        (fifo_rdempty),
        .wrfull         (fifo_wrfull)
    );

    always_comb begin
        if (!clk_main_tick) begin
            read_addr_actual <= read_addr_next;
        end else begin
            read_addr_actual <= read_addr_r + 6'b1;
        end
    end

    var bit [3:0] symbol_history_shift_r = 4'b0;
    var bit nrzi_q = '0;
    var bit nrzi_q2 = '0;
    always_ff @(posedge clk_x4_i) begin
        symbol_history_shift_r[3:1] <= symbol_history_shift_r[2:0];
        symbol_history_shift_r[0] <= ram_q;

        read_addr_r <= read_addr_actual;
        write_addr_r <= write_addr_next;
        write_data_r <= write_data_next;
        ram_q2 <= ram_q;

        // to deal with potential metastability
        nrzi_q <= nrzi_i;
        nrzi_q2 <= nrzi_q;

        fifo_wrreq_next = !clk_main_tick && !fifo_wrfull;
    end

    var bit [2:0] current_read_window_qr;
    wire logic [3:0] current_read_window_q;
    var bit prev_symbol_r;

    assign current_read_window_q[3:2] = current_read_window_qr[1:0];
    assign current_read_window_q[1] = ram_q2;
    assign current_read_window_q[0] = ram_q;

    always_comb begin
        write_addr_next = write_addr_r + 6'b1;
        write_data_next = nrzi_q2;

        unique case (decoder_state)
            StIdle: begin
                decoder_state_next = StInitialAcquireData;
                current_zeros_count_next = 'b00000;
                current_read_pos_next = 5'd16;
                read_addr_next = 6'h00;
                write_addr_next = 6'h3f;
                data_next = 'b0;
            end // StIdle
            StInitialAcquireData: begin
                decoder_state_next = (write_addr_r[4:2] == 3'b101) ? StSearchForTransition : StInitialAcquireData;
                current_zeros_count_next = 'b00000;
                current_read_pos_next = 5'd16;
                read_addr_next = 6'h00;
                data_next ='b0;
            end // StInitialAcquireData
            StSearchForTransition: begin
                current_zeros_count_next = 'b00000;
                data_next = 'b0;
                read_addr_next = read_addr_r + 6'b1;

                unique case (current_read_window_q)
                    'b0000: begin
                        if (prev_symbol_r == 'b1) begin
                            decoder_state_next = StSynced;
                            // we move to the left because there is more wiggle room there
                            current_read_pos_next = 5'd14; 
                            read_addr_next = read_addr_r + 6'd3;
                        end else begin
                            decoder_state_next = StSearchForTransition;
                            current_read_pos_next = current_read_pos_r;
                        end
                    end
                    'b1111: begin
                        if (prev_symbol_r == 'b0) begin
                            decoder_state_next = StSynced;
                            // we move to the left because there is more wiggle room there
                            current_read_pos_next = 5'd14; 
                            read_addr_next = read_addr_r + 6'd3;
                        end else begin
                            decoder_state_next = StSearchForTransition;
                            current_read_pos_next = current_read_pos_r;
                        end
                    end
                    'b0001: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 5'd15;
                        read_addr_next = read_addr_r + 6'd2;
                    end
                    'b0011: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 5'd16;
                        read_addr_next = read_addr_r + 6'd1;
                    end
                    'b0111: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 5'd17;
                        read_addr_next = read_addr_r;
                    end
                    'b1110: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 5'd15;
                        read_addr_next = read_addr_r + 6'd2;
                    end
                    'b1100: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 5'd16;
                        read_addr_next = read_addr_r + 6'd1;
                    end
                    'b1000: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 5'd17;
                        read_addr_next = read_addr_r;
                    end
                    default: begin
                        decoder_state_next = StSearchForTransition;
                        current_read_pos_next = current_read_pos_r;
                    end
                endcase
            end // StSearchForTransition
            StSynced: begin
                if (too_many_zeros_error) begin
                    decoder_state_next = StIdle;
                    current_zeros_count_next = 'b0;
                    current_read_pos_next = 5'd16;
                    read_addr_next = 6'h00;
                    write_addr_next = 6'h3f;
                    data_next = 'b0;
                end else begin
                    decoder_state_next = StSynced;
                    current_zeros_count_next = 'b00000;
                    current_read_pos_next = current_read_pos_r;
                    read_addr_next = read_addr_r + 6'b1;

                    unique case (current_read_window_q)
                        'b0000: begin
                            data_next = 'b0;
                            current_zeros_count_next = current_zeros_count_r + 5'd1;
                        end
                        'b1111: begin
                            data_next = 'b0;
                            current_zeros_count_next = current_zeros_count_r + 5'd1;
                        end
                        'b0011: data_next = 'b1;
                        'b1100: data_next = 'b1;
                        'b0001: begin
                            if (current_read_pos_r == 5'd0) begin
                                data_next = 'b0;
                                decoder_state_next = StIdle;
                            end else begin
                                data_next = 'b1;
                                current_read_pos_next = current_read_pos_next - 5'd1;
                                read_addr_next = read_addr_r + 6'd2;
                            end
                        end
                        'b1110: begin
                            if (current_read_pos_r == 5'd0) begin
                                data_next = 'b0;
                                decoder_state_next = StIdle;
                            end else begin
                                data_next = 'b1;
                                current_read_pos_next = current_read_pos_next - 5'd1;
                                read_addr_next = read_addr_r + 6'd2;
                            end
                        end
                        'b0111: begin
                            if (current_read_pos_r == 5'd31) begin
                                data_next = 'b0;
                                decoder_state_next = StIdle;
                            end else begin
                                data_next = 'b1;
                                current_read_pos_next = current_read_pos_next + 5'd1;
                                read_addr_next = read_addr_r;
                            end
                        end
                        'b1000: begin
                            if (current_read_pos_r == 5'd31) begin
                                data_next = 'b0;
                                decoder_state_next = StIdle;
                            end else begin
                                data_next = 'b1;
                                current_read_pos_next = current_read_pos_next + 5'd1;
                                read_addr_next = read_addr_r;
                            end
                        end
                        'b1010: begin
                            data_next = 'b0;
                            decoder_state_next = StIdle;
                        end
                        'b0101: begin
                            data_next = 'b0;
                            decoder_state_next = StIdle;
                        end
                        'b0010: begin
                            data_next = 'b0;
                            current_zeros_count_next = current_zeros_count_r + 5'd1;
                        end
                        'b1101: begin
                            data_next = 'b0;
                            current_zeros_count_next = current_zeros_count_r + 5'd1;
                        end
                        'b0100: begin
                            data_next = 'b0;
                            current_zeros_count_next = current_zeros_count_r + 5'd1;
                        end
                        'b1011: begin
                            data_next = 'b0;
                            current_zeros_count_next = current_zeros_count_r + 5'd1;
                        end
                        default: begin
                            data_next = 'b0;
                            decoder_state_next = StIdle;
                        end
                    endcase
                end
            end // StSynced
            default: begin
                decoder_state_next = StInitialAcquireData;
                current_zeros_count_next = 'b00000;
                current_read_pos_next = 5'd16;
                read_addr_next = 6'h00;
                write_addr_next = 6'h3f;
                data_next = 'b0;
            end // default
        endcase
    end

    always_ff @(posedge clk_x4_i) begin
        if (!clk_main_tick) begin
            decoder_state <= decoder_state_next;

            current_zeros_count_r <= current_zeros_count_next;
            current_read_pos_r <= current_read_pos_next;
            data_r <= data_next;
        end

        if (clk_div_r == 2'b11) begin
            current_read_window_qr[2:1] <= symbol_history_shift_r[1:0];
            current_read_window_qr[0] <= ram_q;
            prev_symbol_r <= symbol_history_shift_r[1];
        end
    end

    assign fifo_wrdata_next = { data_r, decoder_state == StSynced, current_zeros_count_r[3] };

    // Retrieve data on clk_i domain
    var bit [2:0] fifo_delay_r = 3'b0;
    logic [2:0] fifo_delay_next;
    wire fifo_valid = fifo_delay_r >= 3'd4 && !fifo_rdempty;

    var bit data_out_r = '0;
    var bit valid_out_r = '0;
    var bit sync_out_r = '0;

    always_comb begin
        fifo_delay_next = (!fifo_valid) ? fifo_delay_r + 3'b1 : fifo_delay_r;
    end

    always_ff @(posedge clk_i) begin
        fifo_delay_r <= fifo_delay_next;

        data_out_r <= fifo_valid ? fifo_q[2] : '0;
        valid_out_r <= fifo_valid ? fifo_q[1] : '0;
        sync_out_r <= fifo_valid ? fifo_q[0] : '0;
    end

    assign data_o = data_out_r;
    assign valid_o = valid_out_r;
    assign sync_o = sync_out_r;
endmodule
