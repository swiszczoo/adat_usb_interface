module nrzi_phase_lock_decoder (
    input           clk_x4_i,
    input           nrzi_i,
    
    output          clk_o,
    output          clk_main_tick_no,
    output          data_o,
    output          valid_o,
    output          sync_o              // starts outputting 1 after 8 consecutive zeroes
                                        // can be used for ADAT frame synchronization
);
    typedef enum bit[1:0] {
        // initial state, reset all registers
        StIdle,

        // we are looking for a clean transition pattern and adjust our detection window position
        StSearchForTransition,

        // we are currently synced to the signal and output decoded bits
        StSynced,

        // a decoding error occured, will be resetting rn
        StError
    } decoder_state_e;

    // Clock divider submodule (div/4)
    var bit [1:0] clk_div_r = 'b00;
    wire clk_main_tick_next = clk_div_r[1] | clk_div_r[0];
    var bit clk_main_tick_r;

    always_ff @(posedge clk_x4_i) begin
        clk_div_r <= clk_div_r + 'b01;
        clk_main_tick_r <= clk_main_tick_next;
    end

    assign clk_o = !clk_div_r[1];
    assign clk_main_tick_no = clk_main_tick_r;

    // Decoder
    decoder_state_e decoder_state = StIdle;
    decoder_state_e decoder_state_next;

    var bit prev_symbol_r = 'b0;
    var bit [10:0] symbol_history_shift_r = 'b0;

    var bit [3:0] symbol_history_temp_shift_r = 'b0000;
    logic [3:0] symbol_history_temp_shift_next;

    var bit [4:0] current_zeros_count_r = 'b00000;
    logic [4:0] current_zeros_count_next;

    var bit [2:0] current_read_pos_r = 'b000;
    logic [2:0] current_read_pos_next;

    wire too_many_zeros_error = current_zeros_count_r[4];
    logic [3:0] current_read_window_q;

    reg data_r;
    logic data_next;

    always_comb begin
        unique case (current_read_pos_r)
            'b000: current_read_window_q = symbol_history_shift_r[ 3:0];
            'b001: current_read_window_q = symbol_history_shift_r[ 4:1];
            'b010: current_read_window_q = symbol_history_shift_r[ 5:2];
            'b011: current_read_window_q = symbol_history_shift_r[ 6:3];
            'b100: current_read_window_q = symbol_history_shift_r[ 7:4];
            'b101: current_read_window_q = symbol_history_shift_r[ 8:5];
            'b110: current_read_window_q = symbol_history_shift_r[ 9:6];
            'b111: current_read_window_q = symbol_history_shift_r[10:7];
        endcase
    end

    always_comb begin
        symbol_history_temp_shift_next[3:1] = symbol_history_temp_shift_r[2:0];
        symbol_history_temp_shift_next[0] = nrzi_i;
    end

    always_comb begin
        unique case (decoder_state)
            StIdle: begin
                decoder_state_next = StSearchForTransition;
                current_zeros_count_next = 'b00000;
                current_read_pos_next = 'd4;
                data_next = 'b0;
            end // StIdle
            StSearchForTransition: begin
                current_zeros_count_next = 'b00000;
                data_next = 'b0;
                unique case (current_read_window_q)
                    'b0000: begin
                        if (prev_symbol_r == 'b1) begin
                            decoder_state_next = StSynced;
                            // we move to the left because there is more wiggle room there
                            current_read_pos_next = 'd2; 
                        end else begin
                            decoder_state_next = StSearchForTransition;
                            current_read_pos_next = current_read_pos_r;
                        end
                    end
                    'b1111: begin
                        if (prev_symbol_r == 'b0) begin
                            decoder_state_next = StSynced;
                            // we move to the left because there is more wiggle room there
                            current_read_pos_next = 'd2;
                        end else begin
                            decoder_state_next = StSearchForTransition;
                            current_read_pos_next = current_read_pos_r;
                        end
                    end
                    'b0001: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 'd3;
                    end
                    'b0011: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 'd4;
                    end
                    'b0111: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 'd5;
                    end
                    'b1110: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 'd3;
                    end
                    'b1100: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 'd4;
                    end
                    'b1000: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 'd5;
                    end
                    default: begin
                        decoder_state_next = StSearchForTransition;
                        current_read_pos_next = current_read_pos_r;
                    end
                endcase
            end // StSearchForTransition
            StSynced: begin
                if (too_many_zeros_error) begin
                    decoder_state_next = StError;
                    current_zeros_count_next = 'b0;
                    current_read_pos_next = 'd4;
                    data_next = 'b0;
                end else begin
                    decoder_state_next = StSynced;
                    current_zeros_count_next = 'b00000;
                    current_read_pos_next = current_read_pos_r;

                    unique case (current_read_window_q)
                        'b0000: begin
                            data_next = 'b0;
                            current_zeros_count_next = current_zeros_count_r + 'd1;
                        end
                        'b1111: begin
                            data_next = 'b0;
                            current_zeros_count_next = current_zeros_count_r + 'd1;
                        end
                        'b0011: data_next = 'b1;
                        'b1100: data_next = 'b1;
                        'b0001: begin
                            if (current_read_pos_r == 'd0) begin
                                data_next = 'b0;
                                decoder_state_next = StError;
                            end else begin
                                data_next = 'b1;
                                current_read_pos_next = current_read_pos_next - 'd1;
                            end
                        end
                        'b1110: begin
                            if (current_read_pos_r == 'd0) begin
                                data_next = 'b0;
                                decoder_state_next = StError;
                            end else begin
                                data_next = 'b1;
                                current_read_pos_next = current_read_pos_next - 'd1;
                            end
                        end
                        'b0111: begin
                            if (current_read_pos_r == 'd7) begin
                                data_next = 'b0;
                                decoder_state_next = StError;
                            end else begin
                                data_next = 'b1;
                                current_read_pos_next = current_read_pos_next + 'd1;
                            end
                        end
                        'b1000: begin
                            if (current_read_pos_r == 'd7) begin
                                data_next = 'b0;
                                decoder_state_next = StError;
                            end else begin
                                data_next = 'b1;
                                current_read_pos_next = current_read_pos_next + 'd1;
                            end
                        end
                        'b1010: begin
                            data_next = 'b0;
                            decoder_state_next = StError;
                        end
                        'b0101: begin
                            data_next = 'b0;
                            decoder_state_next = StError;
                        end
                        'b0010: begin
                            data_next = 'b0;
                            current_zeros_count_next = current_zeros_count_r + 'd1;
                        end
                        'b1101: begin
                            data_next = 'b0;
                            current_zeros_count_next = current_zeros_count_r + 'd1;
                        end
                        'b0100: begin
                            data_next = 'b0;
                            current_zeros_count_next = current_zeros_count_r + 'd1;
                        end
                        'b1011: begin
                            data_next = 'b0;
                            current_zeros_count_next = current_zeros_count_r + 'd1;
                        end
                        default: begin
                            data_next = 'b0;
                            decoder_state_next = StError;
                        end
                    endcase
                end
            end // StSynced
            default: begin
                decoder_state_next = StIdle;
                current_zeros_count_next = 'b00000;
                current_read_pos_next = 'd4;
                data_next = 'b0;
            end
        endcase
    end

    always_ff @(posedge clk_x4_i) begin
        symbol_history_temp_shift_r <= symbol_history_temp_shift_next;

        if (!clk_main_tick_no) begin
            decoder_state <= decoder_state_next;

            prev_symbol_r <= current_read_window_q[0];
            symbol_history_shift_r[10:4] <= symbol_history_shift_r[6:0];
            symbol_history_shift_r[3:0] <= symbol_history_temp_shift_next;
            current_zeros_count_r <= current_zeros_count_next;
            current_read_pos_r <= current_read_pos_next;
            data_r <= data_next;
        end
    end

    assign data_o = data_r;
    assign valid_o = decoder_state == StSynced;
    assign sync_o = current_zeros_count_r[3];
endmodule
