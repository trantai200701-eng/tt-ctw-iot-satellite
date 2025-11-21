// traffic_uldl_core.v
// Uplink/Downlink Traffic Generator using two 8-bit LFSRs

module traffic_uldl_core (
    input  wire        clk,
    input  wire        rst_n,        // active-low reset
    input  wire        ena,          // core enable

    input  wire [1:0]  i_mode,       // 00: pause, 01: UL only, 10: DL only, 11: UL/DL alternate
    input  wire [3:0]  i_cfg_period, // packet interval configuration
    input  wire [1:0]  i_seed_sel,   // select different LFSR seeds

    output reg  [7:0]  o_packet_id,
    output reg         o_dir_dl,     // 0 = UL, 1 = DL
    output reg         o_packet_pulse
);

  // --------------------------------------------------------
  // 8-bit LFSR cho UL và DL
  // Polynomial: x^8 + x^6 + x^5 + x^4 + 1 (maximal-length)
  // new_bit = x^8 XOR x^6 XOR x^5 XOR x^4
  // --------------------------------------------------------
  reg [7:0] lfsr_ul;
  reg [7:0] lfsr_dl;

  // Hàm tính bước tiếp theo của LFSR
  function [7:0] lfsr_next;
    input [7:0] cur;
    reg         new_bit;
    begin
      new_bit   = cur[7] ^ cur[5] ^ cur[4] ^ cur[3];
      lfsr_next = {cur[6:0], new_bit};
    end
  endfunction

  // --------------------------------------------------------
  // Seed generator: tạo seed không bằng 0 cho UL/DL
  // --------------------------------------------------------
  wire [7:0] seed_ul = (i_seed_sel == 2'b00) ? 8'hA5 :
                       (i_seed_sel == 2'b01) ? 8'h3C :
                       (i_seed_sel == 2'b10) ? 8'h5E :
                                               8'hC7 ;

  wire [7:0] seed_dl = (i_seed_sel == 2'b00) ? 8'h5A :
                       (i_seed_sel == 2'b01) ? 8'hC3 :
                       (i_seed_sel == 2'b10) ? 8'hE5 :
                                               8'h7D ;

  // --------------------------------------------------------
  // Counter tạo khoảng cách giữa các packet
  // --------------------------------------------------------
  reg  [11:0] period_cnt;
  wire [11:0] reload_value = {i_cfg_period, 8'hFF}; // 0x0FF .. 0xFFF

  // Toggle dùng cho mode UL/DL xen kẽ
  reg last_dir_dl; // 0 = UL, 1 = DL

  // --------------------------------------------------------
  // Main sequential logic
  // --------------------------------------------------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      lfsr_ul         <= 8'h01;
      lfsr_dl         <= 8'hFE;
      period_cnt      <= 12'd0;
      last_dir_dl     <= 1'b0;
      o_packet_id     <= 8'd0;
      o_dir_dl        <= 1'b0;
      o_packet_pulse  <= 1'b0;
    end else begin
      // mặc định không phát xung packet trong mỗi chu kỳ
      o_packet_pulse <= 1'b0;

      if (!ena) begin
        // khi bị disable bởi Tiny Tapeout, giữ nguyên trạng thái
        period_cnt <= period_cnt;
      end else begin
        // Nếu LFSR = 0 (trạng thái không hợp lệ) thì nạp lại seed
        if (lfsr_ul == 8'd0)
          lfsr_ul <= seed_ul;
        if (lfsr_dl == 8'd0)
          lfsr_dl <= seed_dl;

        if (i_mode == 2'b00) begin
          // pause: giữ counter ở reload_value
          period_cnt <= reload_value;
        end else begin
          if (period_cnt == 12'd0) begin
            period_cnt <= reload_value;

            // ---------- Sinh packet mới ----------
            case (i_mode)
              2'b01: begin
                // UL only
                lfsr_ul        <= lfsr_next(lfsr_ul);
                o_packet_id    <= lfsr_next(lfsr_ul);
                o_dir_dl       <= 1'b0;
                last_dir_dl    <= 1'b0;
                o_packet_pulse <= 1'b1;
              end

              2'b10: begin
                // DL only
                lfsr_dl        <= lfsr_next(lfsr_dl);
                o_packet_id    <= lfsr_next(lfsr_dl);
                o_dir_dl       <= 1'b1;
                last_dir_dl    <= 1'b1;
                o_packet_pulse <= 1'b1;
              end

              2'b11: begin
                // Alternate UL/DL
                if (last_dir_dl == 1'b1) begin
                  // lần trước DL → lần này UL
                  lfsr_ul        <= lfsr_next(lfsr_ul);
                  o_packet_id    <= lfsr_next(lfsr_ul);
                  o_dir_dl       <= 1'b0;
                  last_dir_dl    <= 1'b0;
                end else begin
                  // lần trước UL → lần này DL
                  lfsr_dl        <= lfsr_next(lfsr_dl);
                  o_packet_id    <= lfsr_next(lfsr_dl);
                  o_dir_dl       <= 1'b1;
                  last_dir_dl    <= 1'b1;
                end
                o_packet_pulse <= 1'b1;
              end

              default: begin
                o_packet_pulse <= 1'b0;
              end
            endcase
            // ---------- Kết thúc sinh packet ----------
          end else begin
            period_cnt <= period_cnt - 12'd1;
          end
        end
      end
    end
  end

endmodule

