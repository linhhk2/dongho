module am_pm_display (
    input am_pm,
    input display_mode, // 0: 12h, 1: 24h
    output reg [6:0] led_am_pm
);
    always @(*) begin
        if (display_mode == 1'b1)
            led_am_pm = 7'b1111111; // Tắt LED ở chế độ 24h
        else if (am_pm)
            led_am_pm = 7'b0001100; // PM
        else
            led_am_pm = 7'b0001000; // AM
    end
endmodule