// minisoc_pll_reenable_test.sv - T-PLL-REENABLE (OPEN-01): liga o PLL, desliga
// pelo SPI e liga de novo. A spec pede o dominio AES em reset sempre que o PLL
// nao estiver travado (assertion A-02a).
// RESULTADO ATUAL: FALHA. Com o PLL desligado o sys_clk para e o pipeline de
// reset (sys_reset_pipe) nao e limpo, entao sys_rst_n fica em 1. Fora da regressao
// ate o RTL ser corrigido.
class minisoc_pll_reenable_test extends minisoc_base_test;
  `uvm_component_utils(minisoc_pll_reenable_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    minisoc_cfg_seq cfg;
    spi_write_seq   off;
    phase.raise_objection(this);
    env.rst_agt.wait_reset_done();

    cfg = minisoc_cfg_seq::type_id::create("cfg");
    cfg.start(env.spi_agt.sqr);                    // liga (/8)

    off      = spi_write_seq::type_id::create("off");
    off.addr = 'h0E;
    off.data = 'hC;                                // PLL_ENABLE = 0
    off.start(env.spi_agt.sqr);

    cfg = minisoc_cfg_seq::type_id::create("cfg");
    cfg.start(env.spi_agt.sqr);                    // liga de novo

    phase.drop_objection(this);
  endtask
endclass
