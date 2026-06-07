module tb_debounce;

logic clk;
logic reset;
logic noisy_in;
logic clean_out;

debounce #(.LIMIT(4)) DUT (
    .clk(clk),
    .reset(reset),
    .noisy_in(noisy_in),
    .clean_out(clean_out)
);

always #5 clk = ~clk;

initial begin
    $dumpfile("tb_debounce.vcd");
    $dumpvars(0, tb_debounce);
    
    clk = 0;
    reset = 1;
    noisy_in = 0;

    #20;
    reset = 0;

    // rebote
    #10 noisy_in = 1;
    #10 noisy_in = 0;
    #10 noisy_in = 1;
    #10 noisy_in = 0;
    #10 noisy_in = 1;

    #100;

    $finish;
end

endmodule