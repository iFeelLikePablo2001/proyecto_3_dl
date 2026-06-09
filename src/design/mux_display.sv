// mux_display.sv - Multiplexor de display para mostrar valores en dos dígitos

module mux_display (
    input logic clk,
    input logic reset,
    input logic display_enable,

    output logic [1:0] active_display
);

always_ff @(posedge clk or posedge reset) begin

    if (reset)
        active_display <= 0;

    else if (display_enable)
        active_display <= active_display + 1;

end

endmodule
