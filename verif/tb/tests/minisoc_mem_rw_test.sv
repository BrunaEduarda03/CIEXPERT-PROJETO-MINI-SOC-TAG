// minisoc_mem_rw_test.sv - T-MEM-RW: escreve e le de volta a memoria.
// Nao precisa de SPI: apos o reset MEM_SEL_AES = 0 (a interface externa e a dona).
// O teste so gera trafego; quem julga e o mem_scoreboard.
class minisoc_mem_rw_test extends minisoc_base_test;
  `uvm_component_utils(minisoc_mem_rw_test)

  bit [9:0]     limites[] = '{0, 1, 511, 512, 1022, 1023};
  mem_pattern_e padroes[] = '{PAT_ZEROS, PAT_ONES, PAT_AA55, PAT_WALK1, PAT_RANDOM};

  function new(string name, uvm_component parent);
    super.new(name, parent);
    test_timeout = 1ms;
  endfunction

  task run_phase(uvm_phase phase);
    mem_fill_seq fill;
    bit [9:0]    a;
    phase.raise_objection(this);
    env.rst_agt.wait_reset_done();

    // 1. Enderecos limite, com cada padrao
    foreach (padroes[p])
      foreach (limites[i]) begin
        escrever(limites[i], mem_pattern_word(padroes[p], i));
        ler(limites[i]);
      end

    // 2. Bloco de 32 palavras por padrao, depois le de volta.
    //    O ultimo comeca em 1008: passa de 1023 para 0.
    foreach (padroes[p]) begin
      fill            = mem_fill_seq::type_id::create("fill");
      fill.pattern    = padroes[p];
      fill.n_words    = 32;
      fill.start_addr = (padroes[p] == PAT_RANDOM) ? 1008 : $urandom_range(0, 991);
      fill.start(env.mem_agt.sqr);
      for (int i = 0; i < 32; i++) ler(fill.start_addr + i);
    end

    // 3. 100 enderecos aleatorios: escreve e le
    repeat (100) begin
      a = $urandom();
      escrever(a, $urandom());
      ler(a);
    end

    repeat (5) @(posedge env_cfg.mem_vif.mem_clk);   // deixa o monitor publicar a ultima leitura
    phase.drop_objection(this);
  endtask

  task escrever(bit [9:0] addr, bit [31:0] data);
    mem_write_seq wr = mem_write_seq::type_id::create("wr");
    wr.addr = addr;
    wr.data = data;
    wr.start(env.mem_agt.sqr);
  endtask

  task ler(bit [9:0] addr);
    mem_read_seq rd = mem_read_seq::type_id::create("rd");
    rd.addr = addr;
    rd.start(env.mem_agt.sqr);
  endtask

  // Sem nenhuma comparacao o teste nao provou nada
  function void check_phase(uvm_phase phase);
    if (env.mem_scb.n_compared == 0) `uvm_error("MEM_RW", "scoreboard nao comparou nenhuma leitura")
  endfunction
endclass
