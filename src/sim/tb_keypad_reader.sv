module tb_keypad_reader;

logic clk;
logic reset;
logic scan_enable;
logic [3:0] rows;

logic [3:0] cols;
logic [1:0] row_detect;
logic [1:0] col_detect;
logic key_valid;

keypad_reader DUT(
    .clk(clk),
    .reset(reset),
    .scan_enable(scan_enable),
    .rows(rows),
    .cols(cols),
    .row_detect(row_detect),
    .col_detect(col_detect),
    .key_valid(key_valid)
);

always #5 clk = ~clk;

initial begin
    $dumpfile("tb_keypad_reader.vcd");
    $dumpvars(0, tb_keypad_reader);

    clk = 0;
    reset = 1;
    scan_enable = 0;
    rows = 0;

    #20;
    reset = 0;

    forever begin
        #20 scan_enable = 1;
        #10 scan_enable = 0;
    end

end

initial begin

    #80;
    rows = 4'b0010;

    #40;
    rows = 0;

    #100;

    $finish;

end

endmodule