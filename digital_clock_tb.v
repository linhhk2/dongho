module digital_clock_tb;
    // Tín hiệu đầu vào
    reg clk, rst, sel, inc, stop_alarm, display_mode, mode;
    reg [1:0] timezone_offset;
    // Tín hiệu đầu ra
    wire [6:0] led_unit_sec, led_ten_sec, led_unit_min, led_ten_min;
    wire [6:0] led_unit_hour, led_ten_hour, led_am_pm;
    wire [6:0] tens_day_o, units_day_o, tens_month_o, units_month_o;
    wire [6:0] tens_year_o, units_year_o, hund_year_o, thou_year_o;
    wire alarm;

    // Biến điều khiển trường hợp kiểm tra
    reg if_normal = 0;      // Kiểm tra chế độ bình thường (12h)
    reg if_24h = 0;         // Kiểm tra chế độ 24h
    reg if_adjust_time = 0; // Kiểm tra chỉnh giờ/phút/giây
    reg if_adjust_date = 0; // Kiểm tra chỉnh ngày/tháng/năm
    reg if_timezone = 0;    // Kiểm tra chỉnh múi giờ
    reg if_alarm = 0;       // Kiểm tra báo thức
    reg if_leap_year = 0;   // Kiểm tra năm nhuận

    // Khởi tạo instance của module digital_clock_top
    digital_clock_top uut (
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .sel(sel),
        .inc(inc),
        .stop_alarm(stop_alarm),
        .timezone_offset(timezone_offset),
        .display_mode(display_mode),
        .led_unit_sec(led_unit_sec),
        .led_ten_sec(led_ten_sec),
        .led_unit_min(led_unit_min),
        .led_ten_min(led_ten_min),
        .led_unit_hour(led_unit_hour),
        .led_ten_hour(led_ten_hour),
        .led_am_pm(led_am_pm),
        .tens_day_o(tens_day_o),
        .units_day_o(units_day_o),
        .tens_month_o(tens_month_o),
        .units_month_o(units_month_o),
        .tens_year_o(tens_year_o),
        .units_year_o(units_year_o),
        .hund_year_o(hund_year_o),
        .thou_year_o(thou_year_o),
        .alarm(alarm)
    );

    // Tạo xung clock (chu kỳ 10ns giả lập 1 giây)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Hàm hỗ trợ để thực hiện thao tác chọn và tăng
    task adjust_param;
        input [31:0] num_increments;
        integer i;
        begin
            sel = 1; #20; sel = 0; #20; // Chọn tham số
            for (i = 0; i < num_increments; i = i + 1) begin
                inc = 1; #20; inc = 0; #20; // Tăng giá trị
            end
            #60; // Chờ thêm để giá trị được cập nhật
        end
    endtask

    // Kịch bản kiểm tra
    initial begin
        $dumpfile("digital_clock_tb.vcd");
        $dumpvars(0, digital_clock_tb, uut.mode_state, uut.stop_count, uut.carry_hour, 
                  uut.date_counter_inst.day, uut.date_counter_inst.month, uut.date_counter_inst.year,
                  uut.time_adjust_inst.sel_state, sel, uut.carry_min, uut.count_hour, 
                  uut.time_adjust_inst.adj_hour, uut.time_adjust_inst.adj_min, uut.time_adjust_inst.adj_sec,
                  uut.time_adjust_inst.adj_day, uut.time_adjust_inst.adj_month, uut.time_adjust_inst.adj_year);

        // Khởi tạo tín hiệu
        rst = 0; mode = 0; sel = 0; inc = 0; stop_alarm = 0; timezone_offset = 2'b00; display_mode = 0;
        #20 rst = 1;

        // 1. Kiểm tra chế độ bình thường (12h)
        if (if_normal) begin
            $display("Time=%0t: Testing normal mode (12h)", $time);
            display_mode = 1'b0; // Chế độ 12h
            #100; // Chạy 100 giây
            $display("Time=%0t: Hour=%b:%b, Min=%b:%b, Sec=%b:%b, AM/PM=%b, Day=%0d, Month=%0d, Year=%0d", 
                     $time, led_ten_hour, led_unit_hour, led_ten_min, led_unit_min, led_ten_sec, led_unit_sec, 
                     led_am_pm, uut.date_counter_inst.day, uut.date_counter_inst.month, uut.date_counter_inst.year);
        end

        // 2. Kiểm tra chế độ 24h
        if (if_24h) begin
            $display("Time=%0t: Testing 24h mode", $time);
            display_mode = 1'b1; // Chuyển sang 24h
            #100; // Chạy 100 giây
            $display("Time=%0t: Hour=%b:%b, Min=%b:%b, Sec=%b:%b, AM/PM=%b, Day=%0d, Month=%0d, Year=%0d", 
                     $time, led_ten_hour, led_unit_hour, led_ten_min, led_unit_min, led_ten_sec, led_unit_sec, 
                     led_am_pm, uut.date_counter_inst.day, uut.date_counter_inst.month, uut.date_counter_inst.year);
        end

        // 3. Kiểm tra chỉnh múi giờ (+2 giờ)
        if (if_timezone) begin
            $display("Time=%0t: Testing timezone adjustment (+2 hours)", $time);
            mode = 1; #20; mode = 0; // Chuyển sang chế độ chỉnh múi giờ (mode_state = 1)
            timezone_offset = 2'b10; // +2 giờ
            #20;
            adjust_param(1); // Tăng giờ +2
            $display("Time=%0t: After timezone adjust, Hour=%b:%b", 
                     $time, led_ten_hour, led_unit_hour);
            mode = 1; #20; mode = 0; // Chuyển về chế độ bình thường
        end

        // 4. Kiểm tra chỉnh giờ/phút/giây (12:12:12)
        if (if_adjust_time) begin
            $display("Time=%0t: Testing time adjustment to 12:12:12", $time);
            mode = 1; #20; mode = 0; // Chuyển sang chế độ chỉnh thời gian (mode_state = 2)
            #20;
            // Đặt giờ = 12
            adjust_param(12); // Chọn giờ, tăng 12 lần
            $display("Time=%0t: After hour adjust, Hour=%b:%b", 
                     $time, led_ten_hour, led_unit_hour);
            // Đặt phút = 12
            adjust_param(12); // Chọn phút, tăng 12 lần
            $display("Time=%0t: After minute adjust, Min=%b:%b", 
                     $time, led_ten_min, led_unit_min);
            // Đặt giây = 12
            adjust_param(12); // Chọn giây, tăng 12 lần
            $display("Time=%0t: After second adjust, Sec=%b:%b, stop_count=%b", 
                     $time, led_ten_sec, led_unit_sec, uut.stop_count);
            mode = 1; #20; mode = 0; // Chuyển về chế độ bình thường
            #100; // Chạy 100 giây
            $display("Time=%0t: After 100s, Hour=%b:%b, Min=%b:%b, Sec=%b:%b, Day=%0d, Month=%0d, Year=%0d", 
                     $time, led_ten_hour, led_unit_hour, led_ten_min, led_unit_min, led_ten_sec, led_unit_sec,
                     uut.date_counter_inst.day, uut.date_counter_inst.month, uut.date_counter_inst.year);
        end

        // 5. Kiểm tra chỉnh ngày/tháng/năm (2/2/2025)
        if (if_adjust_date) begin
            $display("Time=%0t: Testing date adjustment to 2/2/2025", $time);
            mode = 1; #20; mode = 0; // Chuyển sang chế độ chỉnh thời gian (mode_state = 2)
            #20;
            // Chuyển đến trạng thái ngày (sel_state = 3)
            adjust_param(0); // Giờ (sel_state = 0)
            $display("Time=%0t: sel_state=%0d, adj_day=%0d, day=%0d", 
                     $time, uut.time_adjust_inst.sel_state, uut.time_adjust_inst.adj_day, uut.date_counter_inst.day);
            adjust_param(0); // Phút (sel_state = 1)
            $display("Time=%0t: sel_state=%0d, adj_day=%0d, day=%0d", 
                     $time, uut.time_adjust_inst.sel_state, uut.time_adjust_inst.adj_day, uut.date_counter_inst.day);
            adjust_param(0); // Giây (sel_state = 2)
            $display("Time=%0t: sel_state=%0d, adj_day=%0d, day=%0d", 
                     $time, uut.time_adjust_inst.sel_state, uut.time_adjust_inst.adj_day, uut.date_counter_inst.day);
            // Đặt ngày = 2
            adjust_param(1); // Chọn ngày (sel_state = 3), tăng 1 lần (từ 1 lên 2)
            $display("Time=%0t: After day adjust, sel_state=%0d, adj_day=%0d, day=%0d", 
                     $time, uut.time_adjust_inst.sel_state, uut.time_adjust_inst.adj_day, uut.date_counter_inst.day);
            // Đặt tháng = 2
            adjust_param(1); // Chọn tháng (sel_state = 4), tăng 1 lần (từ 1 lên 2)
            $display("Time=%0t: After month adjust, sel_state=%0d, adj_month=%0d, month=%0d", 
                     $time, uut.time_adjust_inst.sel_state, uut.time_adjust_inst.adj_month, uut.date_counter_inst.month);
            // Đặt năm = 2025
            adjust_param(1); // Chọn năm (sel_state = 5), tăng 1 lần (từ 2024 lên 2025)
            $display("Time=%0t: After year adjust, sel_state=%0d, adj_year=%0d, year=%0d, stop_count=%b", 
                     $time, uut.time_adjust_inst.sel_state, uut.time_adjust_inst.adj_year, uut.date_counter_inst.year, uut.stop_count);
            mode = 1; #20; mode = 0; // Chuyển về chế độ bình thường
            #100; // Chạy 100 giây
            $display("Time=%0t: After 100s, Hour=%b:%b, Min=%b:%b, Sec=%b:%b, Day=%0d, Month=%0d, Year=%0d", 
                     $time, led_ten_hour, led_unit_hour, led_ten_min, led_unit_min, led_ten_sec, led_unit_sec,
                     uut.date_counter_inst.day, uut.date_counter_inst.month, uut.date_counter_inst.year);
        end

        // 6. Kiểm tra báo thức
        if (if_alarm) begin
            $display("Time=%0t: Testing alarm (set to 01:01 AM)", $time);
            mode = 1; #20; mode = 0; // Chuyển sang chế độ báo thức (mode_state = 3)
            #20;
            adjust_param(1); // Chọn giờ, đặt giờ báo thức = 1
            adjust_param(1); // Chọn phút, đặt phút báo thức = 1
            adjust_param(1); // Chọn AM/PM, đặt AM
            $display("Time=%0t: Alarm set to 01:01 AM, Hour=%b:%b, Min=%b:%b, AM/PM=%b", 
                     $time, led_ten_hour, led_unit_hour, led_ten_min, led_unit_min, led_am_pm);
            mode = 1; #20; mode = 0; // Chuyển về chế độ bình thường
            #3600; // Chạy đến 01:01 AM (3600 giây)
            $display("Time=%0t: Alarm check, Alarm=%b", $time, alarm);
            stop_alarm = 1; #20; stop_alarm = 0; // Tắt báo thức
            $display("Time=%0t: Stop alarm check, Alarm=%b", $time, alarm);
        end

        // 7. Kiểm tra năm nhuận (29/2/2024)
        if (if_leap_year) begin
            $display("Time=%0t: Testing leap year (2024)", $time);
            mode = 1; #20; mode = 0; // Chế độ chỉnh thời gian (mode_state = 2)
            #20;
            adjust_param(1); // Giờ = 0
            adjust_param(1); // Phút = 0
            adjust_param(1); // Giây = 0
            adjust_param(1); // Ngày = 1
            adjust_param(1); // Tháng = 1
            adjust_param(1); // Năm = 2024
            mode = 1; #20; mode = 0; // Thoát chế độ chỉnh
            #2678400; // Từ 1/1/2024 đến 1/2/2024 (31 ngày = 31 * 86400 giây)
            $display("Time=%0t: Before 27/2/2024, Day=%0d, Month=%0d, Year=%0d", 
                     $time, uut.date_counter_inst.day, uut.date_counter_inst.month, uut.date_counter_inst.year);
            #2246400; // 26 ngày đến 27/2/2024
            $display("Time=%0t: Day 27/2/2024, Day=%0d, Month=%0d, Year=%0d", 
                     $time, uut.date_counter_inst.day, uut.date_counter_inst.month, uut.date_counter_inst.year);
            #86400; // Đến 28/2/2024
            $display("Time=%0t: Day 28/2/2024, Day=%0d, Month=%0d, Year=%0d", 
                     $time, uut.date_counter_inst.day, uut.date_counter_inst.month, uut.date_counter_inst.year);
            #86400; // Đến 29/2/2024
            $display("Time=%0t: Day 29/2/2024, Day=%0d, Month=%0d, Year=%0d", 
                     $time, uut.date_counter_inst.day, uut.date_counter_inst.month, uut.date_counter_inst.year);
            #86400; // Đến 1/3/2024
            $display("Time=%0t: Day 1/3/2024, Day=%0d, Month=%0d, Year=%0d", 
                     $time, uut.date_counter_inst.day, uut.date_counter_inst.month, uut.date_counter_inst.year);
        end

        // Kết thúc
        #10000;
        $finish;
    end

    // In trạng thái thời gian
    initial begin
        $monitor($time, " Hour: %b:%b, Min: %b:%b, Sec: %b:%b, AM/PM: %b, Day: %0d, Month: %0d, Year: %0d, Alarm: %b, mode: %b, mode_state: %0d, sel: %b, sel_state: %0d, stop_count: %b",
                 led_ten_hour, led_unit_hour, led_ten_min, led_unit_min,
                 led_ten_sec, led_unit_sec, led_am_pm,
                 uut.date_counter_inst.day, uut.date_counter_inst.month, uut.date_counter_inst.year, 
                 alarm, mode, uut.mode_state, sel, uut.time_adjust_inst.sel_state, uut.stop_count);
    end

    // Tùy chọn bật/tắt các trường hợp kiểm tra
    initial begin
        // Bật trường hợp chỉnh ngày/tháng/năm
        if_normal = 0;
        if_24h = 0;
        if_adjust_time = 0;
        if_adjust_date = 1; // Kiểm tra chỉnh 2/2/2025
        if_timezone = 0;
        if_alarm = 0;
        if_leap_year = 0;
    end
endmodule
