// spi_pkg.sv - pacote do VIP SPI (ordem: cada arquivo usa os anteriores)
package spi_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "spi_item.sv"
  `include "spi_driver.sv"
  `include "spi_monitor.sv"
  `include "spi_agent.sv"
endpackage
