module led_ten_7_seg (
    input [3:0] ten_i,
    output reg [6:0] led_7_seg
);
    always @(ten_i) begin
        case (ten_i)
            4'd0: led_7_seg = 7'b0000001; // 0
            4'd1: led_7_seg = 7'b1001111; // 1
            4'd2: led_7_seg = 7'b0010010; // 2
            4'd3: led_7_seg = 7'b0000110; // 3
            4'd4: led_7_seg = 7'b1001100; // 4
            4'd5: led_7_seg = 7'b0100100; // 5
            4'd6: led_7_seg = 7'b0100000; // 6
            4'd7: led_7_seg = 7'b0001111; // 7
            4'd8: led_7_seg = 7'b0000000; // 8
            4'd9: led_7_seg = 7'b0000100; // 9
            default: led_7_seg = 7'b1111111; // Tắt tất cả
        endcase
    end
endmodule