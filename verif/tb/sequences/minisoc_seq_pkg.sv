//-----------------------------------------------------------------------------
// minisoc_seq_pkg.sv - pacote das sequences (mem/ agora; spi/ e virtual/ depois)
//-----------------------------------------------------------------------------
package minisoc_seq_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import mem_pkg::*;

  `include "mem/mem_write_seq.sv"
  `include "mem/mem_read_seq.sv"
  `include "mem/mem_fill_seq.sv"
endpackage : minisoc_seq_pkg
