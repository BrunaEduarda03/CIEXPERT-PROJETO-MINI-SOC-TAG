// minisoc_rst_default_test.sv - T-RST-DEFAULT: depois do reset, le todos os
// registradores pelo SPI. O spi_scoreboard confere contra os valores da spec.
class minisoc_rst_default_test extends minisoc_base_test;
  `uvm_component_utils(minisoc_rst_default_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    spi_read_seq rd;
    phase.raise_objection(this);
    env.rst_agt.wait_reset_done();

    for (int a = 0; a < 16; a++) begin
      rd      = spi_read_seq::type_id::create("rd");
      rd.addr = a;
      rd.start(env.spi_agt.sqr);
      `uvm_info("RST_DEFAULT", $sformatf("reg 0x%02h = 0x%08h", a, rd.rdata), UVM_LOW)
    end

    phase.drop_objection(this);
  endtask

  function void check_phase(uvm_phase phase);
    if (env.spi_scb.n_compared != 16) `uvm_error("RST_DEFAULT", "esperava 16 leituras comparadas")
  endfunction
endclass
