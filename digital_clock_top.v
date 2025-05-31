module digital_clock_top (
    input clk,                      // Xung clock (1 giây)
    input rst,                      // Reset tích cực mức thấp
    input mode,                     // Chọn chế độ: xoay vòng 0->1->2
    input sel,                      // Chọn tham số: giờ, phút, giây, ngày, tháng, năm hoặc AM/PM
    input inc,                      // Tăng giá trị tham số
    input stop_alarm,               // Tắt báo thức
    input [1:0] timezone_offset,    // Offset múi giờ (+/- 3 giờ)
    input display_mode,             // Chọn chế độ hiển thị: 0-12h, 1-24h
    output [6:0] led_unit_sec,      // LED 7 đoạn cho đơn vị giây
    output [6:0] led_ten_sec,       // LED 7 đoạn cho hàng chục giây
    output [6:0] led_unit_min,      // LED 7 đoạn cho đơn vị phút
    output [6:0] led_ten_min,       // LED 7 đoạn cho hàng chục phút
    output [6:0] led_unit_hour,     // LED 7 đoạn cho đơn vị giờ
    output [6:0] led_ten_hour,      // LED 7 đoạn cho hàng chục giờ
    output [6:0] led_am_pm,         // LED 7 đoạn cho AM/PM
    output [6:0] tens_day_o,        // LED 7 đoạn cho hàng chục ngày
    output [6:0] units_day_o,       // LED 7 đoạn cho đơn vị ngày
    output [6:0] tens_month_o,      // LED 7 đoạn cho hàng chục tháng
    output [6:0] units_month_o,     // LED 7 đoạn cho đơn vị tháng
    output [6:0] tens_year_o,       // LED 7 đoạn cho hàng chục năm
    output [6:0] units_year_o,      // LED 7 đoạn cho đơn vị năm
    output [6:0] hund_year_o,       // LED 7 đoạn cho hàng trăm năm
    output [6:0] thou_year_o,       // LED 7 đoạn cho hàng nghìn năm
    output alarm                    // Tín hiệu báo thức
);
    wire [5:0] count_sec, count_min, count_hour;
    wire [5:0] adj_hour, adj_min, adj_sec, adj_day;
    wire [3:0] adj_month;
    wire [13:0] adj_year;
    wire [5:0] alarm_hour, alarm_min;
    wire [5:0] day;
    wire [3:0] month;
    wire [13:0] year;
    wire carry_sec, carry_min, carry_hour, carry_year;
    wire [3:0] ten_sec, unit_sec, ten_min, unit_min, ten_hour, unit_hour;
    wire [3:0] ten_day, unit_day, ten_month, unit_month;
    wire [3:0] ten_year, unit_year, hund_year, thou_year;
    wire alarm_am_pm, current_am_pm;
    wire stop_count;
    reg [1:0] mode_state;

    // Xử lý mode (1-bit, xoay vòng 0->1->2)
    always @(posedge clk or negedge rst) begin
        if (!rst)
            mode_state <= 2'b00;
        else if (mode)
            mode_state <= (mode_state == 2'b10) ? 2'b00 : mode_state + 1; // Xoay vòng: bình thường -> chỉnh thời gian -> báo thức
    end

    // Counter cho giây
    counter #(.MAX_COUNT(6'd59)) counter_seconds (
        .clk(clk),
        .rst(rst),
        .enable(!stop_count),
        .count(count_sec),
        .carry(carry_sec)
    );

    // Counter cho phút
    counter #(.MAX_COUNT(6'd59)) counter_minutes (
        .clk(carry_sec),
        .rst(rst),
        .enable(!stop_count),
        .count(count_min),
        .carry(carry_min)
    );

    // Counter cho giờ (hỗ trợ cả 12h và 24h)
    counter #(.MAX_COUNT(23)) counter_hours (
        .clk(carry_min),
        .rst(rst),
        .enable(!stop_count && (display_mode == 1'b1 || mode_state == 2'b00)),
        .count(count_hour),
        .carry(carry_hour)
    );

    // Counter cho ngày, tháng, năm
    date_counter date_counter_inst (
        .clk(carry_hour),
        .rst(rst),
        .enable(mode_state == 2'b00),
        .adjust_mode(mode_state == 2'b01),
        .adj_day(adj_day),
        .adj_month(adj_month),
        .adj_year(adj_year),
        .day(day),
        .month(month),
        .year(year),
        .carry_year(carry_year)
    );

    // AM/PM toggle (chỉ hoạt động ở chế độ 12h)
    reg am_pm;
    always @(posedge carry_hour or negedge rst) begin
        if (!rst)
            am_pm <= 1'b0;
        else if (display_mode == 1'b0 && count_hour == 0)
            am_pm <= ~am_pm;
    end
    assign current_am_pm = (display_mode == 1'b0) ? am_pm : 1'b0;

    // Chỉnh thời gian
    time_adjust time_adjust_inst (
        .clk(clk),
        .rst(rst),
        .adjust_mode(mode_state == 2'b01),
        .sel(sel),
        .inc(inc),
        .timezone_offset(timezone_offset),
        .adj_hour(adj_hour),
        .adj_min(adj_min),
        .adj_sec(adj_sec),
        .adj_day(adj_day),
        .adj_month(adj_month),
        .adj_year(adj_year),
        .stop_count(stop_count)
    );

    // Báo thức
    alarm alarm_inst (
        .clk(clk),
        .rst(rst),
        .current_hour(count_hour),
        .current_min(count_min),
        .current_sec(count_sec),
        .current_am_pm(current_am_pm),
        .set_mode(mode_state == 2'b10),
        .sel(sel),
        .inc(inc),
        .stop_alarm(stop_alarm),
        .alarm_hour(alarm_hour),
        .alarm_min(alarm_min),
        .alarm_am_pm(alarm_am_pm),
        .alarm(alarm)
    );

    // Áp dụng múi giờ cho giờ hiển thị
    wire [5:0] display_hour_pre;
    assign display_hour_pre = (mode_state == 2'b01) ? adj_hour : count_hour;
    wire [5:0] display_hour;
    assign display_hour = (display_mode == 1'b0 && display_hour_pre == 0) ? 6'd12 :
                         (display_mode == 1'b0) ? display_hour_pre :
                         (timezone_offset[1] ? 
                            (display_hour_pre < timezone_offset[0] ? 24 - (timezone_offset[0] - display_hour_pre) : display_hour_pre - timezone_offset[0]) :
                            (display_hour_pre + timezone_offset[0] > 23 ? display_hour_pre + timezone_offset[0] - 24 : display_hour_pre + timezone_offset[0]));

    // Tách số cho giờ, phút, giây
    extrac_bit extrac_sec (
        .number(mode_state == 2'b10 ? 6'd0 : (mode_state == 2'b01 ? adj_sec : count_sec)),
        .ten_o(ten_sec),
        .unit_o(unit_sec)
    );

    extrac_bit extrac_min (
        .number(mode_state == 2'b01 ? adj_min : count_min),
        .ten_o(ten_min),
        .unit_o(unit_min)
    );

    extrac_bit extrac_hour (
        .number(display_hour),
        .ten_o(ten_hour),
        .unit_o(unit_hour)
    );

    // Tắt LED giây trong chế độ báo thức
    wire [3:0] ten_sec_display, unit_sec_display;
    assign ten_sec_display = (mode_state == 2'b10) ? 4'b1111 : ten_sec;
    assign unit_sec_display = (mode_state == 2'b10) ? 4'b1111 : unit_sec;

    // Tách số cho ngày
    extrac_bit extrac_day (
        .number(day),
        .ten_o(ten_day),
        .unit_o(unit_day)
    );

    // Tách số cho tháng
    wire [5:0] month_6bit;
    assign month_6bit = {2'b00, month};
    extrac_bit extrac_month (
        .number(month_6bit),
        .ten_o(ten_month),
        .unit_o(unit_month)
    );

    // Tách số cho năm
    assign thou_year = year / 1000;
    assign hund_year = (year % 1000) / 100;
    assign ten_year = (year % 100) / 10;
    assign unit_year = year % 10;

    // Hiển thị trên LED 7 đoạn
    led_unit_7_seg led_sec_unit (.unit_i(unit_sec_display), .led_7_seg(led_unit_sec));
    led_ten_7_seg led_sec_ten (.ten_i(ten_sec_display), .led_7_seg(led_ten_sec));
    led_unit_7_seg led_min_unit (.unit_i(unit_min), .led_7_seg(led_unit_min));
    led_ten_7_seg led_min_ten (.ten_i(ten_min), .led_7_seg(led_ten_min));
    led_unit_7_seg led_hour_unit (.unit_i(unit_hour), .led_7_seg(led_unit_hour));
    led_ten_7_seg led_hour_ten (.ten_i(ten_hour), .led_7_seg(led_ten_hour));

    // Hiển thị AM/PM (tắt ở chế độ 24h)
    am_pm_display am_pm_display_inst (
        .am_pm(current_am_pm),
        .display_mode(display_mode),
        .led_am_pm(led_am_pm)
    );

    // Hiển thị ngày, tháng, năm
    led_ten_7_seg led_day_ten (.ten_i(ten_day), .led_7_seg(tens_day_o));
    led_unit_7_seg led_day_unit (.unit_i(unit_day), .led_7_seg(units_day_o));
    led_ten_7_seg led_month_ten (.ten_i(ten_month), .led_7_seg(tens_month_o));
    led_unit_7_seg led_month_unit (.unit_i(unit_month), .led_7_seg(units_month_o));
    led_ten_7_seg led_year_ten (.ten_i(ten_year), .led_7_seg(tens_year_o));
    led_unit_7_seg led_year_unit (.unit_i(unit_year), .led_7_seg(units_year_o));
    led_ten_7_seg led_year_hund (.ten_i(hund_year), .led_7_seg(hund_year_o));
    led_ten_7_seg led_year_thou (.ten_i(thou_year), .led_7_seg(thou_year_o));
endmodule