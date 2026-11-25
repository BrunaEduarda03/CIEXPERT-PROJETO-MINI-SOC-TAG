// minisoc_pll_bringup_test.sv - T-PLL-BRINGUP: configura o DUT pelo SPI nos 4
// divisores do PLL e mede o sys_clk gerado. Entre um divisor e outro aplica
// reset (desligar o PLL pelo SPI expoe o bug OPEN-01: ver minisoc_pll_reenable_test).
class minisoc_pll_bringup_test extends minisoc_base_test;
  `uvm_component_utils(minisoc_pll_bringup_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    minisoc_cfg_seq cfg;
    phase.raise_objection(this);
    env.rst_agt.wait_reset_done();

    for (int div = 0; div < 4; div++) begin
      cfg         = minisoc_cfg_seq::type_id::create("cfg");
      cfg.div_sel = div;
      cfg.start(env.spi_agt.sqr);
      medir_sys_clk(500 << div);                   // 500 ps x 1, 2, 4, 8
      env.rst_agt.apply_reset(10);                 // volta ao estado inicial
    end

    phase.drop_objection(this);
  endtask

  // Mede a distancia entre duas subidas de sys_clk
  task medir_sys_clk(int esperado_ps);
    realtime t0;
    int      medido_ps;
    @(posedge env_cfg.probe_vif.sys_clk);
    t0 = $realtime;
    @(posedge env_cfg.probe_vif.sys_clk);
    medido_ps = ($realtime - t0) / 1ps;
    if (medido_ps != esperado_ps)
      `uvm_error("PLL", $sformatf("sys_clk: %0d ps, esperado %0d ps", medido_ps, esperado_ps))
    else
      `uvm_info("PLL", $sformatf("sys_clk: %0d ps OK", medido_ps), UVM_LOW)
  endtask
endclass
