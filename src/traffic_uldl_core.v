// =====================================================
// CTW IoT Satellite Traffic UL/DL Core
//  - 8-bit LFSR cho UL và DL
//  - Tạo packet định kỳ theo cfg_period
//  - mode:
//      2'b01 : UL only   (dir_dl = 0)
//      2'b10 : DL only   (dir_dl = 1)
//      2'b11 : Alternate UL/DL
// =====================================================

module traffic_uldl_core (
    input  wire        i_clk,
    input  wire        i_rst_n,
    input  wire        i_ena,

    input  wire [1:0]  i_mode,        // 01=UL, 10=DL, 11=ALT
    input  wire [3:0]  i_cfg_period,  // khoảng cách giữa 2 packet
    input  wire [1:0]  i_seed_sel,    // chọn seed LFSR

    output reg  [7:0]  o_packet_id,
    output reg         o_dir_dl,      // 0=UL, 1=DL
    output reg         o_packet_pulse // 1 clock khi tạo packet mới
);

    // -------------------------------
    // Định nghĩa mode
    // -------------------------------
    localparam MODE_IDLE = 2'b00;
    localparam MODE_UL   = 2'b01;
    localparam MODE_DL   = 2'b10;
    localparam MODE_ALT  = 2'b11;

    // -------------------------------
    // LFSR cho UL/DL
    // -------------------------------
    reg [7:0] lfsr_ul;
    reg [7:0] lfsr_dl;

    wire feedback_ul = lfsr_ul[7] ^ lfsr_ul[5] ^ lfsr_ul[4] ^ lfsr_ul[3];
    wire feedback_dl = lfsr_dl[7] ^ lfsr_dl[5] ^ lfsr_dl[4] ^ lfsr_dl[3];

    // chọn seed tuỳ theo i_seed_sel (đơn giản 4 giá trị)
    wire [7:0] seed_ul = (i_seed_sel == 2'b00) ? 8'hA5 :
                         (i_seed_sel == 2'b01) ? 8'h3C :
                         (i_seed_sel == 2'b10) ? 8'h5A :
                                                 8'hC3;

    wire [7:0] seed_dl = (i_seed_sel == 2'b00) ? 8'h5A :
                         (i_seed_sel == 2'b01) ? 8'hC3 :
                         (i_seed_sel == 2'b10) ? 8'hA5 :
                                                 8'h3C;

    // -------------------------------
    // Bộ đếm khoảng cách giữa 2 packet
    // -------------------------------
    reg [3:0] period_cnt;
    reg       alt_sel;  // dùng cho MODE_ALT: 0=UL,1=DL

    // -------------------------------
    // Logic chính
    // -------------------------------
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            lfsr_ul       <= 8'h01;
            lfsr_dl       <= 8'hFE;
            period_cnt    <= 4'd0;
            alt_sel       <= 1'b0;
            o_packet_id   <= 8'h00;
            o_dir_dl      <= 1'b0;
            o_packet_pulse<= 1'b0;
        end else begin
            o_packet_pulse <= 1'b0; // mặc định

            if (i_ena && (i_mode != MODE_IDLE)) begin
                // tăng counter
                if (period_cnt >= i_cfg_period) begin
                    period_cnt     <= 4'd0;
                    o_packet_pulse <= 1'b1;

                    // update LFSR
                    lfsr_ul <= {lfsr_ul[6:0], feedback_ul};
                    lfsr_dl <= {lfsr_dl[6:0], feedback_dl};

                    // chọn UL/DL theo mode
                    case (i_mode)
                        MODE_UL: begin
                            o_dir_dl    <= 1'b0;
                            o_packet_id <= lfsr_ul;
                        end
                        MODE_DL: begin
                            o_dir_dl    <= 1'b1;
                            o_packet_id <= lfsr_dl;
                        end
                        MODE_ALT: begin
                            alt_sel     <= ~alt_sel;
                            o_dir_dl    <= alt_sel;
                            o_packet_id <= alt_sel ? lfsr_dl : lfsr_ul;
                        end
                        default: begin
                            o_dir_dl    <= 1'b0;
                            o_packet_id <= 8'h00;
                        end
                    endcase
                end else begin
                    period_cnt <= period_cnt + 4'd1;
                end
            end else begin
                // nếu không enable thì giữ nguyên, không tạo packet
                period_cnt     <= 4'd0;
                o_packet_pulse <= 1'b0;
            end
        end
    end

endmodule

