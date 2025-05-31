module extrac_bit(
    input [5:0] number,
    output reg [3:0] ten_o,
    output reg [3:0] unit_o
);
    always @(*) begin
        ten_o = number / 10;
        unit_o = number % 10;
    end
endmodule