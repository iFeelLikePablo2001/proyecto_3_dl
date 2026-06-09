// division_unit.sv - Unidad de división entera pipelinizada

module division_unit #(
    parameter int NA = 6,
    parameter int NB = 4
)(
    input  logic          clk,
    input  logic          rst_n,
    input  logic          valid,
    input  logic [NA-1:0] A,
    input  logic [NB-1:0] B,
    output logic [NA-1:0] Q,
    output logic [NB-1:0] R,
    output logic          done
);

    logic [NB-1:0] r_p [1:NA];
    logic [NA-1:0] q_p [1:NA];
    logic [NA-1:0] a_p [0:NA];
    logic [NB-1:0] b_p [0:NA];
    logic          v_p [0:NA];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_p[0] <= '0;
            b_p[0] <= '0;
            v_p[0] <= 1'b0;
        end else begin
            v_p[0] <= valid;
            if (valid) begin
                a_p[0] <= A;
                b_p[0] <= B;
            end
        end
    end

    genvar k;
    generate
        for (k = 0; k < NA; k++) begin : gen_fila

            logic [NB-1:0] r_prev;
            logic [NA-1:0] q_prev;

            if (k == 0) begin : g_entrada_primera
                assign r_prev = {NB{1'b0}};
                assign q_prev = {NA{1'b0}};
            end else begin : g_entrada_resto
                assign r_prev = r_p[k];
                assign q_prev = q_p[k];
            end

            logic [NB:0]   r_ext;
            logic [NB+1:0] sub;
            logic          q_bit;

            assign r_ext = {r_prev, a_p[k][NA-1]};

            assign sub   = {1'b0, r_ext}
                         + {1'b0, {1'b1, ~b_p[k]}}
                         + {{(NB+1){1'b0}}, 1'b1};
            assign q_bit = sub[NB+1];

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    r_p[k+1] <= '0;
                    q_p[k+1] <= '0;
                    a_p[k+1] <= '0;
                    b_p[k+1] <= '0;
                    v_p[k+1] <= 1'b0;
                end else begin
                    r_p[k+1] <= q_bit ? sub[NB-1:0] : r_ext[NB-1:0];

                    q_p[k+1] <= {q_prev[NA-2:0], q_bit};

                    a_p[k+1] <= {a_p[k][NA-2:0], 1'b0};

                    b_p[k+1] <= b_p[k];
                    v_p[k+1] <= v_p[k];
                end
            end

        end
    endgenerate

    assign Q    = q_p[NA];
    assign R    = r_p[NA];
    assign done = v_p[NA];

endmodule
