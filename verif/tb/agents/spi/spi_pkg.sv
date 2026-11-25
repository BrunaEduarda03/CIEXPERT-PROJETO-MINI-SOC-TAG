//-----------------------------------------------------------------------------
// spi_pkg.sv - pacote do VIP SPI
//-----------------------------------------------------------------------------
package spi_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Mapa de registradores do MiniSoC (Block Guide secao 6 / minisoc_spi.sv).
  // Fica aqui porque driver (NOP), sequences, testes e scoreboard usam.
  typedef enum bit [5:0] {
    REG_KEY0           = 6'h00,
    REG_KEY1           = 6'h01,
    REG_KEY2           = 6'h02,
    REG_KEY3           = 6'h03,
    REG_IV0            = 6'h04,
    REG_IV1            = 6'h05,
    REG_IV2            = 6'h06,
    REG_IV3            = 6'h07,
    REG_COUNTER_HI     = 6'h08,
    REG_COUNTER_LO     = 6'h09,
    REG_NUM_BLOCKS     = 6'h0A,
    REG_AES_CONTROL    = 6'h0B,
    REG_AES_STATUS     = 6'h0C,
    REG_VERSION        = 6'h0D,
    REG_SYSTEM_CONTROL = 6'h0E,
    REG_SYSTEM_STATUS  = 6'h0F,
    REG_NOP            = 6'h3F
  } minisoc_reg_e;

  localparam bit [31:0] MINISOC_VERSION = 32'h0001_0100;

  `include "spi_item.sv"
  `include "spi_cfg.sv"
  `include "spi_sequencer.sv"
  `include "spi_driver.sv"
  `include "spi_monitor.sv"
  `include "spi_agent.sv"
endpackage : spi_pkg
