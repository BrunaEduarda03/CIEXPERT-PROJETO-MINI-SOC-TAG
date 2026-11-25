//-----------------------------------------------------------------------------
// mem_pkg.sv - pacote do VIP MEMORY DATA
//-----------------------------------------------------------------------------
package mem_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "mem_item.sv"
  `include "mem_cfg.sv"
  `include "mem_driver.sv"
  `include "mem_monitor.sv"
  `include "mem_agent.sv"
endpackage : mem_pkg
