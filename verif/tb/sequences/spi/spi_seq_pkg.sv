//-----------------------------------------------------------------------------
// spi_seq_pkg.sv - sequences do VIP SPI
//-----------------------------------------------------------------------------
package spi_seq_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import spi_pkg::*;

  `include "spi_base_seq.sv"
  `include "spi_write_seq.sv"
  `include "spi_read_seq.sv"
endpackage : spi_seq_pkg
