module alarm (
    input clk,
    input rst,              // Tích cực mức thấp
    input [5:0] current_hour, current_min, current_sec, // Thời gian hiện tại
    input current_am_pm,    // Trạng thái AM/PM hiện tại (0: AM, 1: PM)
    input set_mode,         // Chế độ đặt báo thức
    input sel,              // Chọn giờ/phút/AM-PM
    input inc,              // Tăng giá trị
    input stop_alarm,       // Tắt báo thức
    output reg [5:0] alarm_hour, alarm_min, // Thời gian báo thức
    output reg alarm_am_pm, // Trạng thái AM/PM của báo thức (0: AM, 1: PM)
    output reg alarm        // Tín hiệu báo thức
);
    reg [1:0] sel_state; // 0: giờ, 1: phút, 2: AM/PM

    // Khối chọn giờ/phút/AM-PM
    always @(posedge clk or negedge rst) begin
        if (!rst)
            sel_state <= 2'b00;
        else if (set_mode && sel)
            sel_state <= (sel_state == 2'b10) ? 2'b00 : sel_state + 1; // Chuyển vòng từ 0->1->2->0
    end

    // Đặt thời gian báo thức
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            alarm_hour <= 6'd0;
            alarm_min <= 6'd0;
            alarm_am_pm <= 1'b0; // Mặc định AM
        end else if (set_mode && inc) begin
            case (sel_state)
                2'b00: alarm_hour <= (alarm_hour == 11) ? 6'd0 : alarm_hour + 1; // Giờ 0-11
                2'b01: alarm_min <= (alarm_min == 59) ? 6'd0 : alarm_min + 1;   // Phút 0-59
                2'b10: alarm_am_pm <= ~alarm_am_pm; // Chuyển đổi AM/PM
            endcase
        end
    end

    // Kích hoạt báo thức
    always @(posedge clk or negedge rst) begin
        if (!rst)
            alarm <= 1'b0;
        else if (current_hour == alarm_hour && current_min == alarm_min && current_sec == 0 && current_am_pm == alarm_am_pm)
            alarm <= 1'b1;
        else if (stop_alarm)
            alarm <= 1'b0;
    end
endmodule