`timescale 1ns / 1ps

module debounce_edge_detect #(
    parameter int unsigned CLK_FREQ_HZ    = 50_000_000,
    parameter int unsigned STABLE_TIME_MS = 10
) (
    input  logic clk,
    input  logic rst_n,
    input  logic sig_in,
    output logic sig_debounced = 0,
    output logic edge_rise,
    output logic edge_fall
);

    // TODO:
    // 1. Implement a 2-stage synchronizer on the sig_in input.
    // 2. Calculate the required cycle count: CYCLES = (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000.
    // 3. Implement a counter measuring the stability interval.
    // 4. Update sig_debounced with the stable input state.
    // 5. Generate 1-clock-cycle pulses for edge_rise and edge_fall.
    
    // sig_in -> [] -> sig_del -> [] -> sig_sync
    reg sig_del = 1'b0;
    reg sig_sync = 1'b0;

    always @(posedge clk) begin
        // synchronizer may be reset
        sig_del <= sig_in & rst_n;
        sig_sync <= sig_del & rst_n;
    end
    
    // calculate wait interval
    `define CYCLES (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000
    
    // stability counter
    reg [$clog2(`CYCLES):0] stab = 0;
    
    // register storing state the input and later output signal is changing to
    reg target_state = 0;
    
    // check if interval elapsed
    wire end_stab = stab < `CYCLES;
    
    always @(posedge clk) begin

        // if input changed state and signal is stable
        if(target_state != sig_sync && stab == 0) begin
            // update target
            target_state <= sig_sync;
            // start counter
            stab <= 1;
        end

        // count up during interval
        if(|stab && end_stab) stab <= stab + 1;
        
        // reset the counter
        if(!end_stab || ~rst_n) stab <= 0;

        // after interval elapsed, update output
        if(!end_stab && target_state == sig_sync) sig_debounced <= target_state;
        
        // reset target state
        if(~rst_n) target_state <= 1'b0;
    end
    
    //assign sig_debounced = target_state;

    //assign sig_debounced = 1'b0;
    assign edge_rise      = ~end_stab & target_state;
    assign edge_fall      = ~end_stab & ~target_state;

endmodule
