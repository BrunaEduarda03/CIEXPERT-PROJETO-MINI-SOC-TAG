wvResizeWindow -win $_nWave1 0 0 1800 900
wvAddSignal -win $_nWave1 {/top_tb/spi_if_i/cs_n} {/top_tb/spi_if_i/sclk} {/top_tb/spi_if_i/mosi} {/top_tb/spi_if_i/miso} {/top_tb/dut/u_spi/rx_bitcnt_sclk[5:0]} {/top_tb/dut/u_spi/cmd_valid_sys} {/top_tb/dut/u_spi/read_data_sys[31:0]}
wvZoom -win $_nWave1 42850000 46250000
