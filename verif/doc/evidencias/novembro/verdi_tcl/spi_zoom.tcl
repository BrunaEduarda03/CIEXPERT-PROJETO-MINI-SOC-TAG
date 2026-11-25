wvResizeWindow -win $_nWave1 0 0 1800 900
wvAddSignal -win $_nWave1 {/top_tb/spi_if_i/cs_n} {/top_tb/spi_if_i/sclk} {/top_tb/spi_if_i/mosi} {/top_tb/spi_if_i/miso} {/top_tb/dut/u_spi/rx_bitcnt_sclk[5:0]} {/top_tb/dut/u_spi/rx_shift_sclk[39:0]}
wvZoom -win $_nWave1 42860000 43260000
