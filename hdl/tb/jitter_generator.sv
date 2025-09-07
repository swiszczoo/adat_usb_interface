`timescale 10ns / 1ns
class jitter_generator;
    real next_bit_time;

    task automatic initialize();
        real initial_delay;
        
        initial_delay = real'($urandom() % 10000) / 1000.0;
        #(initial_delay);

        this.next_bit_time = $realtime;
    endtask

    task automatic jitter(real jitter);
        real clock_jitter;
        real actual_next_bit_time;

        this.next_bit_time = this.next_bit_time + 8.0;
        clock_jitter = real'($urandom() % int'(jitter * 1000)) / 1000.0;
        actual_next_bit_time = next_bit_time - clock_jitter;

        #(actual_next_bit_time - $realtime);
    endtask
endclass
