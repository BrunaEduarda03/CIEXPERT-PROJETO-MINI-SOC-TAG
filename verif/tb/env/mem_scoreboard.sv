//-----------------------------------------------------------------------------
// mem_scoreboard.sv
// Checagem local da interface MEMORY DATA (REQ-MEM-01/02/03).
// Modelo: array associativo que imita a RAM, alimentado pelo mem_monitor.
//   WRITE com MEM_SEL_AES = 0 -> atualiza o modelo
//   WRITE com MEM_SEL_AES = 1 -> NAO atualiza (a porta externa nao e dona)
//   READ  com MEM_SEL_AES = 1 -> ignorada (mem_o_data nao e atualizado)
//   READ  de endereco ja escrito -> compara; diferenca = UVM_ERROR
//   READ  de endereco nunca escrito -> ignorada (memoria sem reset)
// MEM_SEL_AES vem do probe_vif (sinal interno do banco SPI).
//-----------------------------------------------------------------------------
class mem_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(mem_scoreboard)

  uvm_analysis_imp #(mem_item, mem_scoreboard) imp;

  virtual minisoc_probe_if probe_vif;   // atribuido pelo env

  bit [31:0] model[bit [9:0]];

  int unsigned n_writes;
  int unsigned n_writes_blocked;
  int unsigned n_compared;
  int unsigned n_errors;
  int unsigned n_reads_unknown;
  int unsigned n_reads_blocked;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    imp = new("imp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (probe_vif == null)
      `uvm_fatal("MEM_SCB_NOVIF", "probe_vif nao atribuido ao mem_scoreboard")
  endfunction

  function void write(mem_item t);
    bit sel_aes = (probe_vif.cfg_mem_sel_aes === 1'b1);

    if (t.op == MEM_WRITE) begin
      if (sel_aes) begin
        n_writes_blocked++;
        `uvm_info(get_type_name(),
                  $sformatf("WRITE addr=%0d ignorada no modelo (MEM_SEL_AES = 1)", t.addr), UVM_HIGH)
      end
      else begin
        n_writes++;
        model[t.addr] = t.data;
      end
      return;
    end

    // READ
    if (sel_aes) begin
      n_reads_blocked++;
      return;
    end
    if (!model.exists(t.addr)) begin
      n_reads_unknown++;
      `uvm_info(get_type_name(),
                $sformatf("READ addr=%0d sem valor esperado (nunca escrito)", t.addr), UVM_HIGH)
      return;
    end

    n_compared++;
    if (t.rdata !== model[t.addr]) begin
      n_errors++;
      `uvm_error("MEM_SCB_MISMATCH",
                 $sformatf("READ addr=%0d: lido 0x%08h, esperado 0x%08h",
                           t.addr, t.rdata, model[t.addr]))
    end
    else
      `uvm_info(get_type_name(),
                $sformatf("READ addr=%0d = 0x%08h OK", t.addr, t.rdata), UVM_HIGH)
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),
              $sformatf("%0d leituras comparadas, %0d erros | escritas: %0d aplicadas, %0d bloqueadas | leituras ignoradas: %0d sem referencia, %0d bloqueadas",
                        n_compared, n_errors, n_writes, n_writes_blocked,
                        n_reads_unknown, n_reads_blocked),
              UVM_LOW)
  endfunction

endclass : mem_scoreboard
