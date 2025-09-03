module nrzi_phase_lock_decoder (
    input           clk_x4_i,
    input           nrzi_i,
    
    output          clk_o,
    output          data_o,
    output          valid_o
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
    reg [1:0] clk_div_r = 2'b00;

    always_ff @(posedge clk_x4_i) begin
        clk_div_r <= clk_div_r + 2'b01;
    end

    assign clk_o = !clk_div_r[1];

    // Decoder
    decoder_state_e decoder_state = StIdle;
    logic decoder_state_next;

    bit prev_symbol_r = 1'b0;
    bit [10:0] symbol_history_shift_r = 11'b0;

    bit [3:0] symbol_history_temp_shift_r = 4'b0000;
    logic [3:0] symbol_history_temp_shift_next;

    reg [4:0] current_zeros_count_r = 5'b00000;
    logic [4:0] current_zeros_count_next;

    reg [2:0] current_read_pos_r = 3'b000;
    logic [2:0] current_read_pos_next;

    wire too_many_zeros_error = current_zeros_count_r[4];
    logic [3:0] current_read_window_q;

    reg data_r;
    logic data_next;

    always_comb begin
        unique case (current_read_pos_r)
            3'b000: current_read_window_q = symbol_history_shift_r[ 3:0];
            3'b001: current_read_window_q = symbol_history_shift_r[ 4:1];
            3'b010: current_read_window_q = symbol_history_shift_r[ 5:2];
            3'b011: current_read_window_q = symbol_history_shift_r[ 6:3];
            3'b100: current_read_window_q = symbol_history_shift_r[ 7:4];
            3'b101: current_read_window_q = symbol_history_shift_r[ 8:5];
            3'b110: current_read_window_q = symbol_history_shift_r[ 9:6];
            3'b111: current_read_window_q = symbol_history_shift_r[10:7];
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
                current_zeros_count_next = 5'b00000;
                current_read_pos_next = 3'd4;
                data_next = 1'b0;
            end // StIdle
            StSearchForTransition: begin
                current_zeros_count_next = 5'b00000;
                data_next = 1'b0;
                unique case (current_read_window_q)
                    4'b0000: begin
                        if (prev_symbol_r == 1'b1) begin
                            decoder_state_next = StSynced;
                            // we move to the left because there is more wiggle room there
                            current_read_pos_next = 3'd2; 
                        end else begin
                            decoder_state_next = StSearchForTransition;
                            current_read_pos_next = current_read_pos_r;
                        end
                    end
                    4'b1111: begin
                        if (prev_symbol_r == 1'b0) begin
                            decoder_state_next = StSynced;
                            // we move to the left because there is more wiggle room there
                            current_read_pos_next = 3'd2;
                        end else begin
                            decoder_state_next = StSearchForTransition;
                            current_read_pos_next = current_read_pos_r;
                        end
                    end
                    4'b0001: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 3'd3;
                    end
                    4'b0011: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 3'd4;
                    end
                    4'b0111: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 3'd5;
                    end
                    4'b1110: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 3'd3;
                    end
                    4'b1100: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 3'd4;
                    end
                    4'b1000: begin
                        decoder_state_next = StSynced;
                        current_read_pos_next = 3'd5;
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
                    current_zeros_count_next = 5'b00000;
                    current_read_pos_next = 3'd4;
                    data_next = 1'b0;
                end else begin
                    decoder_state_next = StSynced;
                    current_zeros_count_next = 5'b00000;
                    current_read_pos_next = current_read_pos_r;

                    unique case (current_read_window_q)
                        4'b0000: begin
                            data_next = 1'b0;
                            current_zeros_count_next = current_zeros_count_r + 5'b1;
                        end
                        4'b1111: begin
                            data_next = 1'b0;
                            current_zeros_count_next = current_zeros_count_r + 5'b1;
                        end
                        4'b0011: data_next = 1'b1;
                        4'b1100: data_next = 1'b1;
                        4'b0001: begin
                            if (current_read_pos_r == 3'd0) begin
                                data_next = 1'b0;
                                decoder_state_next = StError;
                            end else begin
                                data_next = 1'b1;
                                current_read_pos_next = current_read_pos_next - 3'd1;
                            end
                        end
                        4'b1110: begin
                            if (current_read_pos_r == 3'd0) begin
                                data_next = 1'b0;
                                decoder_state_next = StError;
                            end else begin
                                data_next = 1'b1;
                                current_read_pos_next = current_read_pos_next - 3'd1;
                            end
                        end
                        4'b0111: begin
                            if (current_read_pos_r == 3'd7) begin
                                data_next = 1'b0;
                                decoder_state_next = StError;
                            end else begin
                                data_next = 1'b1;
                                current_read_pos_next = current_read_pos_next + 3'd1;
                            end
                        end
                        4'b1000: begin
                            if (current_read_pos_r == 3'd7) begin
                                data_next = 1'b0;
                                decoder_state_next = StError;
                            end else begin
                                data_next = 1'b1;
                                current_read_pos_next = current_read_pos_next + 3'd1;
                            end
                        end
                        4'b1010: begin
                            data_next = 1'b0;
                            decoder_state_next = StError;
                        end
                        4'b0101: begin
                            data_next = 1'b0;
                            decoder_state_next = StError;
                        end
                        4'b0010: begin
                            data_next = 1'b0;
                            current_zeros_count_next = current_zeros_count_r + 5'b1;
                        end
                        4'b1101: begin
                            data_next = 1'b0;
                            current_zeros_count_next = current_zeros_count_r + 5'b1;
                        end
                        4'b0100: begin
                            data_next = 1'b0;
                            current_zeros_count_next = current_zeros_count_r + 5'b1;
                        end
                        4'b1011: begin
                            data_next = 1'b0;
                            current_zeros_count_next = current_zeros_count_r + 5'b1;
                        end
                        default: begin
                            data_next = 1'b0;
                            decoder_state_next = StError;
                        end
                    endcase
                end
            end // StSynced
            default: begin
                decoder_state_next = StIdle;
                current_zeros_count_next = 5'b00000;
                current_read_pos_next = 3'd4;
                data_next = 1'b0;
            end
        endcase
    end

    always_ff @(posedge clk_x4_i) begin
        symbol_history_temp_shift_r <= symbol_history_temp_shift_next;

        if (clk_div_r == 2'b00) begin
            decoder_state <= decoder_state_next;

            prev_symbol_r <= current_read_window_q[0];
            symbol_history_shift_r[10:4] <= symbol_history_shift_r[6:0];
            symbol_history_shift_r[3:0] <= symbol_history_temp_shift_next;
            current_zeros_count_r <= current_zeros_count_next;
            current_read_pos_r <= current_read_pos_next;
        end
    end

    assign data_o = data_r;
    assign valid_o = decoder_state == StSynced;
endmodule
