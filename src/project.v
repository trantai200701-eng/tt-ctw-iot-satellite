// ====================================
// traffic_uldl_core
// ====================================

module traffic_uldl_core (
    input  wire        i_clk,
    input  wire        i_rst_n,
    input  wire        i_ena,
    input  wire [1:0]  i_mode,
    input  wire [3:0]  i_cfg_period,
    input  wire [1:0]  i_seed_sel,
    output reg  [7:0]  o_packet_id,
    output reg         o_dir_dl,
    output reg         o_packet_pulse
);
    // ... (nguyên phần thân module như file cũ)
endmodule

// ====================================
// tt_um_ctw_iot_satellite (top TT)
// ====================================

module tt_um_ctw_iot_satellite (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    // ... (nguyên code wrapper cũ, instantiates traffic_uldl_core)
endmodule

