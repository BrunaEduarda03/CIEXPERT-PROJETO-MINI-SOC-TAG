//-----------------------------------------------------------------------------
// mem_scoreboard.sv  (CHK-04, VPLAN)
// Checagem local da interface MEMORY DATA. Recebe do mem_monitor todas as
// transacoes (o monitor publica todo ciclo: escrita se wr_en=1, leitura se
// wr_en=0) e compara com um modelo da RAM (array associativo).
//
//   ESCRITA com MEM_SEL_AES = 0 -> atualiza o modelo.
//   ESCRITA com MEM_SEL_AES = 1 -> NAO atualiza (a porta externa nao e dona
//                                  da RAM; ownership, F13).
//   LEITURA com MEM_SEL_AES = 0 -> endereco ja escrito: compara (!==, pega X);
//                                  nunca escrito: ignora (memoria sem reset).
//   LEITURA com MEM_SEL_AES = 1 -> ignora (mem_o_data fica parado).
//
// MEM_SEL_AES vem do probe_vif (sinal interno do DUT). Como a leitura e
// publicada read_latency ciclos depois de acontecer, se MEM_SEL_AES mudou
// nesse intervalo a transacao e ambigua: a leitura nao e checada e a escrita
// apaga o endereco do modelo (em vez de adivinhar).
//
// Limite conhecido: com MEM_SEL_AES = 1 o AES pode escrever na RAM. Enquanto
// nao houver um monitor do lado AES (dezembro), o modelo nao ve essas escritas;
// o teste deve chamar clear() depois de uma operacao AES.
//
// Falha provocada (evidencia de que a checagem funciona): com o plusarg
// +MEM_SCB_INJECT_ERR o modelo guarda o dado invertido na primeira escrita.
//-----------------------------------------------------------------------------
class mem_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(mem_scoreboard)

  uvm_analysis_imp #(mem_item, mem_scoreboard) imp;

  // Atribuidos pelo minisoc_env
  virtual minisoc_probe_if probe_vif;          // cfg_mem_sel_aes
  mem_cfg                  cfg;                // read_latency
  int unsigned             mem_clk_period_ps;

  bit [31:0] model[bit [9:0]];
  realtime   last_sel_change;
  bit        inject_err;

  int unsigned n_wr_applied;     // escritas que atualizaram o modelo
  int unsigned n_wr_blocked;     // escritas com MEM_SEL_AES = 1
  int unsigned n_wr_ambiguous;   // escritas perto de uma troca de MEM_SEL_AES
  int unsigned n_rd_checked;     // leituras comparadas
  int unsigned n_rd_errors;      // leituras divergentes
  int unsigned n_rd_unknown;     // leituras de endereco nunca escrito
  int unsigned n_rd_blocked;     // leituras com MEM_SEL_AES = 1 ou ambiguas

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp        = new("imp", this);
    inject_err = $test$plusargs("MEM_SCB_INJECT_ERR");
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    if (probe_vif == null)
      `uvm_fatal("MEM_SCB_NOVIF", "probe_vif nao atribuido ao mem_scoreboard")
    if (cfg == null)
      `uvm_fatal("MEM_SCB_NOCFG", "mem_cfg nao atribuido ao mem_scoreboard")
    if (mem_clk_period_ps == 0)
      `uvm_fatal("MEM_SCB_NOCFG", "mem_clk_period_ps nao atribuido ao mem_scoreboard")
    if (inject_err)
      `uvm_warning("MEM_SCB", "+MEM_SCB_INJECT_ERR: modelo sera corrompido na 1a escrita (falha provocada)")
  endfunction

  // Guarda o instante da ultima troca de MEM_SEL_AES.
  task run_phase(uvm_phase phase);
    forever begin
      @(probe_vif.cfg_mem_sel_aes);
      last_sel_change = $realtime;
    end
  endtask

  // 1 se MEM_SEL_AES = 0 e nao mudou nos ultimos 'cycles' ciclos de mem_clk.
  function bit user_owns(int unsigned cycles);
    return (probe_vif.cfg_mem_sel_aes === 1'b0) &&
           ($realtime - last_sel_change > cycles * mem_clk_period_ps * 1ps);
  endfunction

  function void write(mem_item t);
    if (t.mem_i_wr_en)
      check_write(t);
    else
      check_read(t);
  endfunction

  function void check_write(mem_item t);
    if (probe_vif.cfg_mem_sel_aes === 1'b1) begin
      n_wr_blocked++;
      `uvm_info(get_type_name(), {"Escrita ignorada (MEM_SEL_AES=1): ", t.convert2string()}, UVM_HIGH)
      return;
    end
    if (!user_owns(1)) begin
      n_wr_ambiguous++;
      model.delete(t.mem_i_addr);
      `uvm_info(get_type_name(), {"Escrita ambigua (MEM_SEL_AES mudou), endereco esquecido: ",
                                  t.convert2string()}, UVM_MEDIUM)
      return;
    end

    model[t.mem_i_addr] = t.mem_i_data;
    if (inject_err && n_wr_applied == 0)
      model[t.mem_i_addr] = ~t.mem_i_data;
    n_wr_applied++;
  endfunction

  function void check_read(mem_item t);
    if (!user_owns(cfg.read_latency + 1)) begin
      n_rd_blocked++;
      return;
    end
    if (!model.exists(t.mem_i_addr)) begin
      n_rd_unknown++;
      return;
    end

    n_rd_checked++;
    if (t.mem_o_data !== model[t.mem_i_addr]) begin
      n_rd_errors++;
      `uvm_error("MEM_SCB", $sformatf("Leitura divergente: mem_i_addr=0x%03h mem_o_data=0x%08h, esperado 0x%08h",
                                      t.mem_i_addr, t.mem_o_data, model[t.mem_i_addr]))
    end
    else
      `uvm_info(get_type_name(), {"Leitura OK: ", t.convert2string()}, UVM_HIGH)
  endfunction

  // Esquece o conteudo (ex.: depois de o AES ter usado a RAM).
  function void clear();
    model.delete();
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),
              $sformatf("%0d leituras comparadas, %0d erros | nao checadas: %0d endereco nunca escrito, %0d MEM_SEL_AES=1/ambiguas",
                        n_rd_checked, n_rd_errors, n_rd_unknown, n_rd_blocked), UVM_LOW)
    `uvm_info(get_type_name(),
              $sformatf("Escritas: %0d aplicadas no modelo, %0d ignoradas (MEM_SEL_AES=1), %0d ambiguas",
                        n_wr_applied, n_wr_blocked, n_wr_ambiguous), UVM_LOW)
  endfunction

endclass : mem_scoreboard
