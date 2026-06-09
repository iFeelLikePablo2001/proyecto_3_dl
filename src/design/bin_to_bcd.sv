// bin_to_bcd.sv - Conversor combinacional de binario a BCD
// Usa el algoritmo Double Dabble: ajusta cada dígito BCD con +3 cuando es >=5 y desplaza el registro.


module bin_to_bcd #(
    parameter int BIN_W    = 6,
    parameter int N_DIGITS = 2
)(
    input  logic [BIN_W-1:0]      bin_in,
    output logic [N_DIGITS*4-1:0] bcd_out
);

    localparam int TOTAL_W = N_DIGITS * 4 + BIN_W;

    logic [TOTAL_W-1:0] scratch;

    always_comb begin
        scratch = {{(N_DIGITS*4){1'b0}}, bin_in};

        for (int i = 0; i < BIN_W; i++) begin

            for (int j = 0; j < N_DIGITS; j++) begin
                if (scratch[BIN_W + j*4 +: 4] >= 4'd5)
                    scratch[BIN_W + j*4 +: 4] =
                        scratch[BIN_W + j*4 +: 4] + 4'd3;
            end

            scratch = {scratch[TOTAL_W-2:0], 1'b0};
        end

        bcd_out = scratch[TOTAL_W-1 : BIN_W];
    end

endmodule
