//-----------------------------------------------------------------------------
// minisoc_test_pkg.sv - pacote dos testes
//-----------------------------------------------------------------------------
package minisoc_test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import clk_pkg::*;
  import rst_pkg::*;
  import mem_pkg::*;
  import spi_pkg::*;
  import minisoc_env_pkg::*;
  import minisoc_seq_pkg::*;

  `include "minisoc_base_test.sv"
  `include "minisoc_smoke_test.sv"
  `include "minisoc_mem_rw_test.sv"
  `include "minisoc_rst_default_test.sv"
  `include "minisoc_spi_reg_test.sv"
  `include "minisoc_pll_bringup_test.sv"
  `include "minisoc_pll_reenable_test.sv"
  `include "minisoc_mem_owner_test.sv"
endpackage : minisoc_test_pkg
