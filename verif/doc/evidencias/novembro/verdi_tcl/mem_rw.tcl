wvResizeWindow -win $_nWave1 0 0 1800 900
wvAddSignal -win $_nWave1 {/top_tb/mem_clk_if/clk} {/top_tb/mem_if_i/mem_i_wr_en} {/top_tb/mem_if_i/mem_i_addr[9:0]} {/top_tb/mem_if_i/mem_i_data[31:0]} {/top_tb/mem_if_i/mem_o_data[31:0]} {/top_tb/dut/spi_cfg_mem_sel_aes}
wvZoom -win $_nWave1 15000 75000
