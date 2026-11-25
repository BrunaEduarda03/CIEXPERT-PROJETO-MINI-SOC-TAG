//-----------------------------------------------------------------------------
// top_assertions.sv
// Assertions de sistema (VPLAN secao 6.1), ligadas ao minisoc_top por bind.
// Os nomes das portas coincidem com sinais internos do minisoc_top, por isso
// o bind usa conexao implicita (.*).
// As falhas sao reportadas com `uvm_error para entrarem na contagem do teste.
//
// A-01 (reset), A-02a (reset interno sem lock), A-03 (gating),
// A-09 (velocidade do SPI), A-10 (memoria sem X/Z).
//-----------------------------------------------------------------------------
module minisoc_top_sva (
  input logic       clk,
  input logic       rst_n,
  input logic       sys_clk,
  input logic       pll_locked,
  input logic       sys_rst_n,
  input logic       spi_cfg_start,
  input logic       spi_cfg_mem_sel_aes,
  input logic       spi_cfg_pll_enable,
  input logic [1:0] spi_cfg_pll_div_sel,
  input logic       spi_sclk,
  input logic       spi_cs_n,
  input logic       mem_clk,
  input logic [31:0] mem_i_data,
  input logic       mem_i_wr_en,
  input logic [9:0] mem_i_addr
);
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // A-01: um ciclo apos rst_n = 0, PLL e configuracao estao nos defaults.
  property p_a01_reset_defaults;
    @(posedge clk)
      !rst_n |=> (!pll_locked && !spi_cfg_pll_enable && !spi_cfg_mem_sel_aes &&
                  (spi_cfg_pll_div_sel == 2'b11) && !spi_cfg_start);
  endproperty

  A01_reset_defaults: assert property (p_a01_reset_defaults)
    else `uvm_error("SVA_A01", "Apos reset, PLL/config nao estao nos valores default")

  // A-02a: o dominio AES fica em reset enquanto o PLL nao estiver locked.
  // Tambem detecta a hipotese OPEN-01 (re-enable do PLL) a partir de P2.
  A02a_sys_rst_while_unlocked: assert property (
    @(posedge clk) disable iff (!rst_n)
      !pll_locked |-> !sys_rst_n)
    else `uvm_error("SVA_A02a", "sys_rst_n = 1 com PLL_LOCKED = 0")

  // A-03: sys_clk so tem bordas de subida com o PLL locked.
  A03_no_sysclk_without_lock: assert property (
    @(posedge sys_clk) disable iff (!rst_n)
      pll_locked)
    else `uvm_error("SVA_A03", "borda de sys_clk com PLL_LOCKED = 0")

  // A-09: durante um frame, o periodo de sclk e >= 40 ns (sclk <= 25 MHz).
  // Vigia o proprio testbench: se o spi_driver ficar rapido demais, falha.
  property p_a09_sclk_max_25mhz;
    realtime t;
    @(posedge spi_sclk) disable iff (spi_cs_n)
      (1, t = $realtime) |=> ($realtime - t >= 40ns);
  endproperty
  A09_sclk_max_25mhz: assert property (p_a09_sclk_max_25mhz)
    else `uvm_error("SVA_A09", "periodo de sclk menor que 40 ns")

  // A-10: com a interface externa dona da memoria, endereco, dado e wr_en
  // nunca tem X/Z na borda em que a RAM amostra.
  A10_mem_no_x: assert property (
    @(posedge mem_clk) disable iff (!rst_n || spi_cfg_mem_sel_aes)
      !$isunknown({mem_i_wr_en, mem_i_addr, mem_i_data}))
    else `uvm_error("SVA_A10", "X/Z na interface MEMORY DATA")

  // Coberturas: confirmam que os antecedentes foram exercitados.
  C01_reset_release:  cover property (@(posedge clk) !rst_n ##1 rst_n);
  C01_reset_runtime:  cover property (@(posedge clk) rst_n ##1 !rst_n);

endmodule : minisoc_top_sva

bind minisoc_top minisoc_top_sva u_sva (.*);
