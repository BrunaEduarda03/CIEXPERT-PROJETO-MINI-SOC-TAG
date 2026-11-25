// mem_scoreboard.sv - o juiz da memoria.
// Guarda o que foi escrito em "model" e confere cada leitura.
// Com MEM_SEL_AES = 1 o AES e o dono da RAM: a interface externa e ignorada.
class mem_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(mem_scoreboard)

  uvm_analysis_imp #(mem_item, mem_scoreboard) imp;   // recebe do monitor
  virtual minisoc_probe_if probe_vif;                 // para ler MEM_SEL_AES

  bit [31:0]   model [bit [9:0]];                     // model[addr] = dado esperado
  int unsigned n_compared, n_errors;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    imp = new("imp", this);
  endfunction

  // Chamada automaticamente a cada ap.write() do monitor
  function void write(mem_item t);
    if (probe_vif.cfg_mem_sel_aes === 1) return;      // AES e o dono: ignora

    if (t.op == MEM_WRITE)
      model[t.addr] = t.data;
    else if (model.exists(t.addr)) begin              // so compara o que ja foi escrito
      n_compared++;
      if (t.rdata !== model[t.addr]) begin
        n_errors++;
        `uvm_error("MEM_SCB", $sformatf("addr=%0d: lido 0x%08h, esperado 0x%08h",
                                        t.addr, t.rdata, model[t.addr]))
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("MEM_SCB", $sformatf("%0d leituras comparadas, %0d erros", n_compared, n_errors), UVM_LOW)
  endfunction
endclass
