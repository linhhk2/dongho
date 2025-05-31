module time_adjust (
    input clk,
    input rst,              // Tích cực mức thấp
    input adjust_mode,      // Chế độ chỉnh thời gian
    input timezone_mode,    // Chế độ chỉnh múi giờ
    input sel,             // Chọn tham số: giờ, phút, giây, ngày, tháng, năm
    input inc,             // Tăng giá trị tham số
    input [1:0] timezone_offset, // Offset múi giờ (+/- 3 giờ)
    output reg [5:0] adj_hour, adj_min, adj_sec, // Thời gian đã chỉnh
    output reg [5:0] adj_day,   // Ngày đã chỉnh (1-31)
    output reg [3:0] adj_month, // Tháng đã chỉnh (1-12)
    output reg [13:0] adj_year, // Năm đã chỉnh (0-9999)
    output reg stop_count       // Dừng đếm khi chỉnh
);
    reg [2:0] sel_state; // 0: giờ, 1: phút, 2: giây, 3: ngày, 4: tháng, 5: năm

    // Kiểm tra năm nhuận và số ngày tối đa
    wire is_leap_year;
    assign is_leap_year = (adj_year % 4 == 0 && adj_year % 100 != 0) || (adj_year % 400 == 0);
    wire [5:0] max_day;
    assign max_day = (adj_month == 2) ? (is_leap_year ? 6'd29 : 6'd28) :
                     (adj_month == 4 || adj_month == 6 || adj_month == 9 || adj_month == 11) ? 6'd30 : 6'd31;

    // Xử lý chọn tham số
    always @(posedge clk or negedge rst) begin
        if (!rst)
            sel_state <= 3'b000;
        else if ((adjust_mode || timezone_mode) && sel)
            sel_state <= (sel_state == 3'b101) ? 3'b000 : sel_state + 1; // Xoay vòng: giờ -> phút -> giây -> ngày -> tháng -> năm
    end

    // Chỉnh thời gian, ngày, tháng, năm và múi giờ
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            adj_hour <= 6'd0;
            adj_min <= 6'd0;
            adj_sec <= 6'd0;
            adj_day <= 6'd1;
            adj_month <= 4'd1;
            adj_year <= 14'd2024;
            stop_count <= 1'b0;
        end else if (adjust_mode) begin
            stop_count <= 1'b1;
            if (inc) begin
                case (sel_state)
                    3'b000: adj_hour <= (adj_hour == 11) ? 6'd0 : adj_hour + 1; // Giờ (0-11)
                    3'b001: adj_min <= (adj_min == 59) ? 6'd0 : adj_min + 1;   // Phút (0-59)
                    3'b010: adj_sec <= (adj_sec == 59) ? 6'd0 : adj_sec + 1;   // Giây (0-59)
                    3'b011: adj_day <= (adj_day == max_day) ? 6'd1 : adj_day + 1; // Ngày (1-max_day)
                    3'b100: adj_month <= (adj_month == 12) ? 4'd1 : adj_month + 1; // Tháng (1-12)
                    3'b101: adj_year <= (adj_year == 9999) ? 14'd0 : adj_year + 1; // Năm (0-9999)
                    default: adj_hour <= adj_hour;
                endcase
            end
        end else if (timezone_mode) begin
            stop_count <= 1'b1;
            if (inc && sel_state == 3'b000) begin
                adj_hour <= (adj_hour + {1'b0, timezone_offset[0]}) > 23 ? 
                            adj_hour + {1'b0, timezone_offset[0]} - 24 : 
                            adj_hour + {1'b0, timezone_offset[0]};
            end
        end else begin
            stop_count <= 1'b0;
        end
    end
endmodule