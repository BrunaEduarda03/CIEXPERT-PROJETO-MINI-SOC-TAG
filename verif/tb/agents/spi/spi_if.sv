//-----------------------------------------------------------------------------
// spi_if.sv
// Interface do VIP SPI: exatamente os 4 sinais SPI do DUT (minisoc_top).
// O sclk e gerado pelo proprio spi_driver (o TB e o mestre SPI), por isso a
// interface nao recebe clock como porta.
//
// Repouso (Mode 0): cs_n = 1, sclk = 0.
// Sem clocking block nem modport: a temporizacao fica no driver e no monitor.
//   - driver : muda MOSI com sclk baixo; o DUT amostra MOSI na SUBIDA;
//   - monitor: amostra MOSI e MISO na SUBIDA (o DUT muda MISO na DESCIDA).
//-----------------------------------------------------------------------------
interface spi_if;

  logic sclk = 1'b0;
  logic cs_n = 1'b1;
  logic mosi = 1'b0;
  logic miso;

endinterface : spi_if
