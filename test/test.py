import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def test_project(dut):
    """Smoke test cho CTW IoT Satellite Traffic Generator"""

    dut._log.info("Start test_project")

    # Khởi tạo clock 50 MHz (period 20 ns)
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # Init input
    dut.ena.value = 0
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Giữ reset một lúc
    await Timer(100, units="ns")

    # Bỏ reset, enable core
    dut.rst_n.value = 1
    dut.ena.value = 1

    # Cấu hình: mode = 01 (UL only), period nhỏ cho dễ thấy
    # ui_in[1:0] = mode, ui_in[5:2] = cfg_period, ui_in[7:6] = seed_sel
    mode = 0b01
    cfg_period = 0b0010  # period = 2
    seed_sel = 0b00
    dut.ui_in.value = (seed_sel << 6) | (cfg_period << 2) | mode

    # Chờ vài chu kỳ để core ổn định
    for _ in range(20):
        await RisingEdge(dut.clk)

    first_id = int(dut.uo_out.value)
    dut._log.info(f"First packet_id = 0x{first_id:02X}")

    # Chờ thêm vài packet nữa
    for _ in range(200):
        await RisingEdge(dut.clk)

    second_id = int(dut.uo_out.value)
    dut._log.info(f"Second packet_id = 0x{second_id:02X}")

    # Điều kiện pass rất nhẹ: chỉ cần packet_id có thay đổi là được
    assert first_id != second_id, "packet_id không thay đổi, core có vẻ không chạy"

