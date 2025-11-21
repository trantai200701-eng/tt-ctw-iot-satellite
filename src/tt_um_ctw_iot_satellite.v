// tt_um_ctw_iot_satellite.v
// Tiny Tapeout top-level wrapper cho traffic_uldl_core

module tt_um_ctw_iot_satellite (
    input  wire [7:0] ui_in,   // input từ người dùng
    output wire [7:0] uo_out,  // output tới người dùng
    input  wire [7:0] uio_in,  // bidirectional IO (không dùng)
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,     // enable khi tile được chọn
    input  wire       clk,     // global clock
    input  wire       rst_n    // global reset (active-low)
);

  // Map:
  // ui_in[1:0]  -> i_mode
  // ui_in[5:2]  -> i_cfg_period
  // ui_in[7:6]  -> i_seed_sel

  wire [1:0] mode       = ui_in[1:0];
  wire [3:0] cfg_period = ui_in[5:2];
  wire [1:0] seed_sel   = ui_in[7:6];

  wire [7:0] packet_id;
  wire       dir_dl;
  wire       packet_pulse;

  // Core instance
  traffic_uldl_core core (
      .clk            (clk),
      .rst_n          (rst_n),
      .ena            (ena),

      .i_mode         (mode),
      .i_cfg_period   (cfg_period),
      .i_seed_sel     (seed_sel),

      .o_packet_id    (packet_id),
      .o_dir_dl       (dir_dl),
      .o_packet_pulse (packet_pulse)
  );

  //----------------------------------------------------------
  // Xuất tín hiệu ra pins Tiny Tapeout
  //----------------------------------------------------------

  // uo_out: hiển thị luôn packet_id 8 bit
  assign uo_out = packet_id;

  // uio_out[0] = dir_dl (0 = UL, 1 = DL)
  // uio_out[1] = packet_pulse
  // các bit còn lại = 0
  assign uio_out[0] = dir_dl;
  assign uio_out[1] = packet_pulse;
  assign uio_out[7:2] = 6'b0;

  // uio_oe: cho phép drive uio_out[1:0], còn lại hi-Z (input)
  assign uio_oe[0] = 1'b1;
  assign uio_oe[1] = 1'b1;
  assign uio_oe[7:2] = 6'b0;

endmodule

