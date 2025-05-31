module date_counter (
    input clk,              // Xung clock (1 giây)
    input rst,              // Reset tích cực mức thấp
    input enable,           // Tín hiệu cho phép đếm
    input adjust_mode,      // Chế độ chỉnh thời gian
    input [5:0] adj_day,    // Ngày đã chỉnh
    input [3:0] adj_month,  // Tháng đã chỉnh
    input [13:0] adj_year,  // Năm đã chỉnh
    output reg [5:0] day,   // Ngày (1-31)
    output reg [3:0] month, // Tháng (1-12)
    output reg [13:0] year, // Năm (0-9999)
    output reg carry_year   // Tín hiệu carry khi năm tăng
);
    // Kiểm tra năm nhuận
    wire is_leap_year;
    assign is_leap_year = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

    // Xác định số ngày tối đa của tháng
    wire [5:0] max_day;
    assign max_day = (month == 2) ? (is_leap_year ? 6'd29 : 6'd28) :
                     (month == 4 || month == 6 || month == 9 || month == 11) ? 6'd30 : 6'd31;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin //rst=0
            day <= 6'd1;
            month <= 4'd1;
            year <= 14'd2024;
            carry_year <= 1'b0;
        end else if (adjust_mode) begin
            // Gán giá trị từ điều chỉnh
            day <= adj_day;
            month <= adj_month;
            year <= adj_year;
            carry_year <= 1'b0;
        end else if (enable) begin
            // Logic đếm bình thường
            if (day == max_day) begin
                day <= 6'd1;
                if (month == 12) begin
                    month <= 4'd1;
                    if (year == 9999) begin
                        year <= 14'd0;
                        carry_year <= 1'b1;
                    end else begin
                        year <= year + 1;
                        carry_year <= 1'b0;
                    end
                end else begin
                    month <= month + 1;
                    carry_year <= 1'b0;
                end
            end else begin
                day <= day + 1;
                carry_year <= 1'b0;
            end
        end
    end
endmodule