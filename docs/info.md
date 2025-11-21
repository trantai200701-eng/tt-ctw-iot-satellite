<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

# CTW IoT Satellite Traffic Generator

## Overview

Dự án này hiện thực một **bộ sinh traffic uplink/downlink** kiểu vệ tinh/IoT, sử dụng hai **LFSR 8-bit** độc lập để tạo ra các mã `packet_id` giả ngẫu nhiên.

Mỗi gói (packet) tương ứng với một giá trị 8-bit, kèm theo:

- Thông tin **hướng truyền**: uplink (`UL`) hay downlink (`DL`)
- Xung **`packet_pulse`** một chu kỳ clock tại thời điểm gói mới được sinh ra

Thiết kế được hiện thực trên Tiny Tapeout SKY130, chiếm **1×1 tile** và chạy trên một clock domain duy nhất.

---

## Block diagram (logical)

```text
                +------------------------------+
                |  traffic_uldl_core          |
                |                              |
   clk -------->+                              |
   rst_n ------>+                              |
   ena -------->+                              |
                |   +----------------------+   |
   i_mode[1:0] ->   |  Packet Scheduler    |   |
   i_cfg_period ----> (interval counter)   |   |
   i_seed_sel[1:0]   +----------+---------+   |
                |              / \            |
                |             /   \           |
                |    +-------+     +-------+  |
                |    |  UL LFSR 8b |       |  |
                |    +-------------+       |  |
                |                          |  |
                |    +-----------------+   |  |
                |    |  DL LFSR 8b     |   |  |
                |    +-----------------+   |  |
                |                              |
                |  o_packet_id[7:0] -----------+----> packet_id[7:0]
                |  o_dir_dl ------------------------> dir_dl (0=UL,1=DL)
                |  o_packet_pulse ------------------> packet_pulse
                +------------------------------+

Modes of operation

Tín hiệu điều khiển chính là i_mode[1:0] (map từ ui_in[1:0]):

2'b00 – Pause
Không sinh packet mới, counter giữ nguyên.

2'b01 – UL only
Chỉ sử dụng LFSR uplink, tất cả packet là UL (dir_dl=0).

2'b10 – DL only
Chỉ sử dụng LFSR downlink, tất cả packet là DL (dir_dl=1).

2'b11 – Alternate UL/DL
Lần lượt UL → DL → UL → DL… theo mỗi packet.

Tần suất packet được điều chỉnh bởi i_cfg_period[3:0]:

Nội bộ tạo reload_value từ i_cfg_period và dùng làm khoảng thời gian giữa 2 packet liên tiếp.

Giá trị càng lớn, packet càng thưa.

i_seed_sel[1:0] cho phép chọn seed khác nhau cho 2 LFSR, thay đổi chuỗi pseudo-random.

Pin description
Inputs (ui_in)
| Pin     | Tên nội bộ      | Mô tả                                               |
| ------- | --------------- | --------------------------------------------------- |
| `ui[0]` | `mode[0]`       | Bit LSB của `i_mode` – chọn chế độ traffic          |
| `ui[1]` | `mode[1]`       | Bit MSB của `i_mode`                                |
| `ui[2]` | `cfg_period[0]` | Bit 0 của `i_cfg_period` – cấu hình khoảng cách gói |
| `ui[3]` | `cfg_period[1]` | Bit 1 của `i_cfg_period`                            |
| `ui[4]` | `cfg_period[2]` | Bit 2 của `i_cfg_period`                            |
| `ui[5]` | `cfg_period[3]` | Bit 3 của `i_cfg_period`                            |
| `ui[6]` | `seed_sel[0]`   | Chọn seed LFSR (bit 0)                              |
| `ui[7]` | `seed_sel[1]`   | Chọn seed LFSR (bit 1)                              |


Outputs (uo_out)
| Pin       | Tên nội bộ       | Mô tả                                |
| --------- | ---------------- | ------------------------------------ |
| `uo[7:0]` | `packet_id[7:0]` | Giá trị ID 8-bit của packet mới nhất |


Bidirectional (uio)
| Pin               | Tên nội bộ     | Hướng | Mô tả                                 |
| ----------------- | -------------- | ----- | ------------------------------------- |
| `uio[0]`          | `dir_dl`       | out   | `0` = UL, `1` = DL                    |
| `uio[1]`          | `packet_pulse` | out   | Xung 1 chu kỳ clock khi có packet mới |
| `uio[2]`–`uio[7]` | –              | in    | Không sử dụng                         |


How to use (simulation / lab)

Reset & enable

rst_n = 0 vài chu kỳ clock, sau đó rst_n = 1.

ena = 1 để core chạy (mặc định Tiny Tapeout chỉ enable khi project được chọn).

Cấu hình mode

UL only: ui_in[1:0] = 2'b01.

DL only: ui_in[1:0] = 2'b10.

Alternate: ui_in[1:0] = 2'b11.

Pause: ui_in[1:0] = 2'b00.

Cấu hình khoảng cách packet

Gán ui_in[5:2] (từ 0000 tới 1111) để chỉnh tần suất sinh packet.

Trên FPGA/logic analyzer có thể chọn giá trị nhỏ để thấy packet nhảy liên tục.

Chọn seed LFSR

Thay đổi ui_in[7:6] để đổi chuỗi pseudo-random cho UL/DL.

Quan sát

uo[7:0] → giá trị packet_id.

uio[0] → UL/DL flag (0/1).

uio[1] → xung packet_pulse, dùng làm trigger trên logic analyzer.



Verification

Trong thư mục test/ có testbench Verilog đơn giản:

Reset, enable core.

Lần lượt chạy qua các mode:

UL only → DL only → Alternate UL/DL.

Ghi waveform vào wave.vcd để kiểm tra packet_id, dir_dl, packet_pulse.

iverilog -g2012 -o sim \
  src/traffic_uldl_core.v \
  src/tt_um_ctw_iot_satellite.v \
  test/tb_tt_ctw_iot_satellite.v

vvp sim
gtkwave wave.vcd &

Notes

Thiết kế hoàn toàn synchronous, không dùng #delay hay tasks không synthesizable.

Tất cả logic chạy trên 1 clock domain (clk Tiny Tapeout).

Có thể dùng core này như traffic/telemetry source để test các block xử lý số khác (filter, encoder, protocol stack, v.v.) trong các tapeout tương lai.


