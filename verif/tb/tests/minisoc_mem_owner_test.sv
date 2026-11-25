// minisoc_mem_owner_test.sv - T-MEM-OWNER (REQ-MEM-03, um dono por vez):
//   1. memoria externa grava um valor
//   2. SPI configura o DUT com MEM_SEL_AES = 1 (o AES vira o dono)
//   3. memoria externa tenta gravar outro valor -> deve ser ignorado
//   4. SPI devolve a memoria (MEM_SEL_AES = 0) e le de volta
// O mem_scoreboard ignora acessos com MEM_SEL_AES = 1, entao ele espera o valor antigo.
class minisoc_mem_owner_test extends minisoc_base_test;
  `uvm_component_utils(minisoc_mem_owner_test)

  bit [9:0] enderecos[] = '{0, 100, 1023};

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    minisoc_cfg_seq cfg;
    spi_write_seq   devolve;
    phase.raise_objection(this);
    env.rst_agt.wait_reset_done();

    foreach (enderecos[i]) mem_escrever(enderecos[i], 'h1111_0000 + i);      // 1.

    cfg             = minisoc_cfg_seq::type_id::create("cfg");               // 2.
    cfg.mem_sel_aes = 1;
    cfg.start(env.spi_agt.sqr);

    foreach (enderecos[i]) mem_escrever(enderecos[i], 'hDEAD_0000 + i);      // 3.

    devolve      = spi_write_seq::type_id::create("devolve");                // 4.
    devolve.addr = 'h0E;
    devolve.data = 'hE;               // PLL_DIV_SEL = 3, PLL_ENABLE = 1, MEM_SEL_AES = 0
    devolve.start(env.spi_agt.sqr);
    foreach (enderecos[i]) mem_ler(enderecos[i]);

    repeat (5) @(posedge env_cfg.mem_vif.mem_clk);
    phase.drop_objection(this);
  endtask

  task mem_escrever(bit [9:0] addr, bit [31:0] data);
    mem_write_seq wr = mem_write_seq::type_id::create("wr");
    wr.addr = addr;
    wr.data = data;
    wr.start(env.mem_agt.sqr);
  endtask

  task mem_ler(bit [9:0] addr);
    mem_read_seq rd = mem_read_seq::type_id::create("rd");
    rd.addr = addr;
    rd.start(env.mem_agt.sqr);
  endtask

  function void check_phase(uvm_phase phase);
    if (env.mem_scb.n_compared != 3) `uvm_error("MEM_OWNER", "esperava 3 leituras comparadas")
  endfunction
endclass
