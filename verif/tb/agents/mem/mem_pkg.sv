// mem_pkg.sv - pacote do VIP de memoria (ordem: cada arquivo usa os anteriores)
package mem_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "mem_item.sv"
  `include "mem_driver.sv"
  `include "mem_monitor.sv"
  `include "mem_agent.sv"
endpackage
