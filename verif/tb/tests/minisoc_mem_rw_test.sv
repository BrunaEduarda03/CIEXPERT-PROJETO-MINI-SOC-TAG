//-----------------------------------------------------------------------------
// minisoc_mem_rw_test.sv  (T-MEM-RW, VPLAN secao 8) - versao basica
// Exercita o VIP MEMORY DATA com MEM_SEL_AES = 0 (default apos reset):
//   1. Escrita/leitura nos limites 0x000 e 0x3FF.
//   2. fill + readback com os padroes de ST-MEM-01 em faixas diferentes.
//   3. Mistura aleatoria de escritas e leituras.
// A checagem e feita aqui por um modelo simples (array associativo) ate o
// mem_scoreboard (CHK-04) existir; endereco nunca escrito nao e checado
// (memoria sem reset). No fim, confere que o monitor observou as mesmas
// escritas que o driver dirigiu e pelo menos as mesmas leituras (o monitor
// tambem ve como leitura cada ciclo ocioso, porque a interface nao tem valid).
// Pendente (precisa do VIP SPI): acesso com MEM_SEL_AES = 1 sem efeito (F13).
//-----------------------------------------------------------------------------
class minisoc_mem_rw_test extends minisoc_base_test;
  `uvm_component_utils(minisoc_mem_rw_test)

  bit [31:0] model[bit [9:0]];

  int unsigned n_checks;
  int unsigned n_fails;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    test_timeout = 500us;
  endfunction

  task wr(bit [9:0] addr, bit [31:0] data);
    mem_write_seq s = mem_write_seq::type_id::create("wr");
    s.addr = addr;
    s.data = data;
    s.start(env.mem_agt.sqr);
    model[addr] = data;
  endtask

  task rd(bit [9:0] addr, output logic [31:0] data);
    mem_read_seq s = mem_read_seq::type_id::create("rd");
    s.addr = addr;
    s.start(env.mem_agt.sqr);
    data = s.rdata;
  endtask

  task run_phase(uvm_phase phase);
    mem_fill_seq  fill;
    logic [31:0]  r;
    bit [9:0]     a;
    bit [9:0]     limits[2] = '{10'h000, 10'h3FF};

    phase.raise_objection(this, "T-MEM-RW em execucao");

    env.rst_agt.wait_reset_done();
    if (env_cfg.probe_vif.cfg_mem_sel_aes !== 1'b0)
      `uvm_fatal("MEM_RW", "MEM_SEL_AES != 0 apos reset: memoria nao pertence a interface externa")

    // 1. Limites
    foreach (limits[i]) begin
      wr(limits[i], $urandom());
      rd(limits[i], r);
      check_word(limits[i], r, "limite");
    end

    // 2. Padroes (ST-MEM-01) em faixas diferentes, cruzando limites de 128
    for (int p = MEM_PAT_ZERO; p <= MEM_PAT_RANDOM; p++) begin
      fill = mem_fill_seq::type_id::create($sformatf("fill_%0d", p));
      if (!fill.randomize() with { pattern == mem_pattern_e'(p); n_words inside {[16:64]}; })
        `uvm_fatal("MEM_RW", "falha ao randomizar mem_fill_seq")
      fill.start(env.mem_agt.sqr);
      foreach (fill.wdata_q[i]) model[fill.start_addr + i] = fill.wdata_q[i];
      foreach (fill.rdata_q[i]) check_word(fill.start_addr + i, fill.rdata_q[i], fill.pattern.name());
    end

    // 3. Aleatorio: 200 operacoes, endereco concentrado para haver re-leitura
    repeat (200) begin
      a = $urandom_range(0, 63) + ($urandom_range(0, 1) ? 10'h3C0 : 10'h000);
      if ($urandom_range(0, 1))
        wr(a, $urandom());
      else begin
        rd(a, r);
        if (model.exists(a)) check_word(a, r, "aleatorio");
      end
    end

    repeat (5) @(posedge env_cfg.mem.vif.mem_clk);   // monitor fecha a ultima leitura

    // 4. Monitor x driver
    n_checks++;
    if (env.mem_agt.mon.n_wr != env.mem_agt.drv.n_wr || env.mem_agt.mon.n_rd < env.mem_agt.drv.n_rd) begin
      n_fails++;
      `uvm_error("MEM_RW", $sformatf("monitor viu %0d W / %0d R, driver dirigiu %0d W / %0d R",
                                     env.mem_agt.mon.n_wr, env.mem_agt.mon.n_rd,
                                     env.mem_agt.drv.n_wr, env.mem_agt.drv.n_rd))
    end

    `uvm_info("MEM_RW", $sformatf("Checagens: %0d executadas, %0d falhas", n_checks, n_fails), UVM_LOW)
    phase.drop_objection(this, "T-MEM-RW concluido");
  endtask

  function void check_word(bit [9:0] addr, logic [31:0] got, string ctx);
    n_checks++;
    if (got !== model[addr]) begin
      n_fails++;
      `uvm_error("MEM_RW", $sformatf("[%s] addr=0x%03h lido 0x%08h, esperado 0x%08h",
                                     ctx, addr, got, model[addr]))
    end
    else
      `uvm_info("MEM_RW", $sformatf("[%s] addr=0x%03h = 0x%08h OK", ctx, addr, got), UVM_HIGH)
  endfunction

endclass : minisoc_mem_rw_test
