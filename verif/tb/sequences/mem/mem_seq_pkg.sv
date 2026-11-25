//-----------------------------------------------------------------------------
// mem_seq_pkg.sv - sequences do VIP MEMORY DATA
//-----------------------------------------------------------------------------
package mem_seq_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import mem_pkg::*;

  `include "mem_base_seq.sv"
  `include "mem_write_seq.sv"
  `include "mem_read_seq.sv"
  `include "mem_fill_seq.sv"
endpackage : mem_seq_pkg
