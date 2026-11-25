//-----------------------------------------------------------------------------
// minisoc_mem_rw_test.sv  (T-MEM-RW, VPLAN secao 8) - parte 1 (sem SPI)
// Exercita o VIP MEMORY DATA com MEM_SEL_AES = 0 (default apos reset):
//   1. Escrita/leitura nos limites 0x000 e 0x3FF.
//   2. fill + readback com os padroes de ST-MEM-01 em faixas diferentes.
//   3. Mistura aleatoria de escritas e leituras.
// Quem julga e o mem_scoreboard (CHK-04), ligado no mem_monitor. O teste so
// gera estimulo e, no fim, confere que:
//   - o scoreboard comparou leituras (um teste que nao compara nada nao prova
//     nada) e que todas as leituras dirigidas foram comparadas;
//   - o monitor viu as mesmas escritas que o driver dirigiu.
// Pendente (precisa do VIP SPI): acesso com MEM_SEL_AES = 1 sem efeito (F13).
//-----------------------------------------------------------------------------
class minisoc_mem_rw_test extends minisoc_base_test;
  `uvm_component_utils(minisoc_mem_rw_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    test_timeout = 500us;
  endfunction

  task wr(bit [9:0] addr, bit [31:0] data);
    mem_write_seq s = mem_write_seq::type_id::create("wr");
    s.addr = addr;
    s.data = data;
    s.start(env.mem_agt.sqr);
  endtask

  task rd(bit [9:0] addr);
    mem_read_seq s = mem_read_seq::type_id::create("rd");
    s.addr = addr;
    s.start(env.mem_agt.sqr);
  endtask

  task run_phase(uvm_phase phase);
    mem_fill_seq  fill;
    bit [9:0]     limits[2] = '{10'h000, 10'h3FF};
    bit [9:0]     written[$];
    int unsigned  n_rd_expected;   // leituras dirigidas a endereco ja escrito

    phase.raise_objection(this, "T-MEM-RW em execucao");

    env.rst_agt.wait_reset_done();
    if (env_cfg.probe_vif.cfg_mem_sel_aes !== 1'b0)
      `uvm_fatal("MEM_RW", "MEM_SEL_AES != 0 apos reset: memoria nao pertence a interface externa")

    // 1. Limites
    foreach (limits[i]) begin
      wr(limits[i], $urandom());
      rd(limits[i]);
      n_rd_expected++;
    end

    // 2. Padroes (ST-MEM-01) em faixas diferentes, cruzando limites de 128
    for (int p = MEM_PAT_ZERO; p <= MEM_PAT_RANDOM; p++) begin
      fill = mem_fill_seq::type_id::create($sformatf("fill_%0d", p));
      if (!fill.randomize() with { pattern == mem_pattern_e'(p); n_words inside {[16:64]}; })
        `uvm_fatal("MEM_RW", "falha ao randomizar mem_fill_seq")
      fill.start(env.mem_agt.sqr);
      n_rd_expected += fill.n_words;
    end

    // 3. Aleatorio: 200 operacoes, endereco concentrado para haver re-leitura
    repeat (200) begin
      bit [9:0] a = $urandom_range(0, 63) + ($urandom_range(0, 1) ? 10'h3C0 : 10'h000);
      if ($urandom_range(0, 1)) begin
        wr(a, $urandom());
        written.push_back(a);
      end
      else begin
        rd(a);
        if (a inside {written}) n_rd_expected++;
      end
    end

    repeat (5) @(posedge env_cfg.mem.vif.mem_clk);   // monitor fecha a ultima leitura

    // 4. O scoreboard comparou de fato?
    if (env.mem_scb.n_rd_checked == 0)
      `uvm_error("MEM_RW", "mem_scoreboard nao comparou nenhuma leitura")
    // >= porque ciclos ociosos tambem sao leituras (de endereco ja escrito).
    if (env.mem_scb.n_rd_checked < n_rd_expected)
      `uvm_error("MEM_RW", $sformatf("scoreboard comparou %0d leituras, esperado ao menos %0d",
                                     env.mem_scb.n_rd_checked, n_rd_expected))

    // 5. Monitor x driver (escritas sao exatas; leituras >= por causa do ocioso)
    if (env.mem_agt.mon.n_wr != env.mem_agt.drv.n_wr || env.mem_agt.mon.n_rd < env.mem_agt.drv.n_rd)
      `uvm_error("MEM_RW", $sformatf("monitor viu %0d W / %0d R, driver dirigiu %0d W / %0d R",
                                     env.mem_agt.mon.n_wr, env.mem_agt.mon.n_rd,
                                     env.mem_agt.drv.n_wr, env.mem_agt.drv.n_rd))

    `uvm_info("MEM_RW", $sformatf("Leituras dirigidas a endereco ja escrito: %0d; comparadas pelo scoreboard: %0d",
                                  n_rd_expected, env.mem_scb.n_rd_checked), UVM_LOW)
    phase.drop_objection(this, "T-MEM-RW concluido");
  endtask

endclass : minisoc_mem_rw_test
