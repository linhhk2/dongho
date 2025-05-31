module counter #(
    parameter MAX_COUNT = 6'd59
)(
    input clk,
    input rst, // Tích cực mức thấp
    input enable,
    output reg [15:0] count, // Tăng bit để hỗ trợ năm
    output reg carry
);
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            count <= 16'd0;
            carry <= 1'b0;
        end else if (enable) begin
            if (count == MAX_COUNT) begin
                count <= 16'd0;
                carry <= 1'b1;
            end else begin
                count <= count + 1;
                carry <= 1'b0;
            end
        end
    end
endmodule