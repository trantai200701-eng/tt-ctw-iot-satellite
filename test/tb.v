`timescale 1ns/1ps

module tb_tt_ctw_iot_satellite;

  reg  clk;
  reg  rst_n;
  reg  ena;
  reg  [7:0] ui_in;
  wire [7:0] uo_out;
  wire [7:0] uio_in  = 8'h00;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // DUT
  tt_um_ctw_iot_satellite dut (
    .ui_in   (ui_in),
    .uo_out  (uo_out),
    .uio_in  (uio_in),
    .uio_out (uio_out),
    .uio_oe  (uio_oe),
    .ena     (ena),
    .clk     (clk),
    .rst_n   (rst_n)
  );

  // clock 10 ns -> 100 MHz
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_tt_ctw_iot_satellite);

    // init
    ena   = 0;
    rst_n = 0;
    ui_in = 8'h00;

    #50;
    rst_n = 1;
    ena   = 1;

    // mode = UL only, period nhỏ
    ui_in[1:0] = 2'b01;  // mode
    ui_in[5:2] = 4'h1;   // period
    ui_in[7:6] = 2'b00;  // seed_sel

    #5000;

    // mode = DL only
    ui_in[1:0] = 2'b10;
    #5000;

    // mode = alternate UL/DL, period lớn hơn
    ui_in[1:0] = 2'b11;
    ui_in[5:2] = 4'h3;

    #10000;

    $finish;
  end

endmodule

