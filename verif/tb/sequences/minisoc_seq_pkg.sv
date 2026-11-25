// minisoc_seq_pkg.sv - pacote das sequences (mem, spi e configuracao)
package minisoc_seq_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import mem_pkg::*;
  import spi_pkg::*;
  `include "mem/mem_write_seq.sv"
  `include "mem/mem_read_seq.sv"
  `include "mem/mem_fill_seq.sv"
  `include "spi/spi_write_seq.sv"
  `include "spi/spi_read_seq.sv"
  `include "minisoc_cfg_seq.sv"       // usa as sequences SPI
endpackage
