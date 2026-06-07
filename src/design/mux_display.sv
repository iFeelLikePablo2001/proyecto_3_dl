// mux_display.sv
// Generador del índice de display activo para multiplexar una pantalla de
// cuatro dígitos. Cada vez que display_enable se activa, avanza al siguiente
// dígito.
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