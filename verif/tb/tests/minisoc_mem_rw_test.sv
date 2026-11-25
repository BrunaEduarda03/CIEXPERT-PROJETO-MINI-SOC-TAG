//-----------------------------------------------------------------------------
// minisoc_mem_rw_test.sv  (T-MEM-RW parte 1)
// Escrita e leitura pela interface MEMORY DATA com MEM_SEL_AES = 0 (valor de
// reset), sem SPI. Quem julga e o mem_scoreboard; o teste so gera trafego e
// exige que o scoreboard tenha de fato comparado leituras.
//   1. Limites de endereco (0, 1, 511, 512, 1022, 1023) com cada padrao.
//   2. Blocos contiguos com cada padrao, lidos de volta (inclui a volta
//      1023 -> 0 no padrao aleatorio).
//   3. Escritas/leituras em enderecos aleatorios, intercaladas.
//-----------------------------------------------------------------------------
class minisoc_mem_rw_test extends minisoc_base_test;
  `uvm_component_utils(minisoc_mem_rw_test)

  localparam bit [9:0] BOUNDARY_ADDRS[6] = '{10'd0, 10'd1, 10'd511, 10'd512, 10'd1022, 10'd1023};

  int unsigned n_random_ops = 200;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    test_timeout = 1ms;
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this, "T-MEM-RW em execucao");

    env.rst_agt.wait_reset_done();
    repeat (5) @(posedge env_cfg.mem.vif.mem_clk);
    `uvm_info("MEM_RW", "Reset liberado; MEM_SEL_AES = 0, interface externa e dona da memoria", UVM_LOW)

    boundary_phase();
    block_phase();
    random_phase();

    repeat (5) @(posedge env_cfg.mem.vif.mem_clk);   // deixa o monitor publicar a ultima leitura
    phase.drop_objection(this, "T-MEM-RW concluido");
  endtask

  // 1. Limites
  task boundary_phase();
    mem_pattern_e p;
    `uvm_info("MEM_RW", "Fase 1: limites de endereco", UVM_LOW)
    p = p.first();
    do begin
      foreach (BOUNDARY_ADDRS[i]) begin
        write_word(BOUNDARY_ADDRS[i], mem_fill_seq::pattern_word(p, i));
        read_word(BOUNDARY_ADDRS[i]);
      end
      p = p.next();
    end while (p != p.first());
  endtask

  // 2. Blocos com padrao
  task block_phase();
    mem_fill_seq  fill;
    mem_pattern_e p;
    `uvm_info("MEM_RW", "Fase 2: blocos com padrao", UVM_LOW)
    p = p.first();
    do begin
      fill            = mem_fill_seq::type_id::create("fill");
      fill.pattern    = p;
      fill.n_words    = 32;
      fill.start_addr = (p == PAT_RANDOM) ? 10'd1008 : 10'($urandom_range(0, 1023 - 32));
      `uvm_info("MEM_RW", $sformatf("  %s: %0d palavras a partir de %0d",
                                    p.name(), fill.n_words, fill.start_addr), UVM_LOW)
      fill.start(env.mem_agt.sqr);
      for (int unsigned i = 0; i < fill.n_words; i++)
        read_word(fill.start_addr + i);
      p = p.next();
    end while (p != p.first());
  endtask

  // 3. Aleatorio: le de preferencia enderecos ja escritos
  task random_phase();
    bit [9:0] used[$];
    bit [9:0] a;
    `uvm_info("MEM_RW", $sformatf("Fase 3: %0d operacoes aleatorias", n_random_ops), UVM_LOW)
    repeat (n_random_ops) begin
      if (used.size() == 0 || $urandom_range(0, 1)) begin
        a = $urandom();
        write_word(a, $urandom());
        used.push_back(a);
      end
      else
        read_word(used[$urandom_range(0, used.size() - 1)]);
    end
  endtask

  task write_word(bit [9:0] addr, bit [31:0] data);
    mem_write_seq s = mem_write_seq::type_id::create("wr");
    s.addr = addr;
    s.data = data;
    s.start(env.mem_agt.sqr);
  endtask

  task read_word(bit [9:0] addr);
    mem_read_seq s = mem_read_seq::type_id::create("rd");
    s.addr = addr;
    s.start(env.mem_agt.sqr);
  endtask

  // Um teste que nao comparou nada nao pode passar.
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (env.mem_scb.n_compared == 0)
      `uvm_error("MEM_RW", "Nenhuma leitura foi comparada pelo mem_scoreboard")
  endfunction

endclass : minisoc_mem_rw_test
