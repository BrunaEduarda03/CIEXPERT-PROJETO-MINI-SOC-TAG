//-----------------------------------------------------------------------------
// mem_monitor.sv
// Monitor passivo da MEMORY DATA. A cada borda de mem_clk:
//   - wr_en=1 -> publica a ESCRITA imediatamente;
//   - wr_en=0 -> guarda a LEITURA e publica read_latency ciclos depois, com o
//                dado de mem_o_data daquela borda.
// A interface nao tem sinal de valido, entao todo ciclo e uma transacao (e o
// que a RAM faz). Leituras saem no log em UVM_HIGH para nao polui-lo; o
// scoreboard recebe todas.
// Com MEM_SEL_AES = 1 a RAM nao usa mem_clk e mem_o_data fica parado: as
// leituras continuam sendo publicadas e cabe ao scoreboard ignora-las.
// Amostra na borda de SUBIDA, antes do NBA: ve as entradas dirigidas na subida
// anterior (mesmo valor que o DUT amostra) e
// mem_o_data ainda com o valor anterior ao NBA da RAM nessa borda.
// Funciona igual com o agente ativo ou passivo (so depende dos pinos).
//-----------------------------------------------------------------------------
class mem_monitor extends uvm_monitor;
  `uvm_component_utils(mem_monitor)

  uvm_analysis_port #(mem_item) ap;

  mem_cfg        cfg;   // atribuido pelo mem_agent
  virtual mem_if vif;

  int unsigned n_wr;
  int unsigned n_rd;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg == null)
      `uvm_fatal("MEM_NOCFG", "mem_cfg nao atribuido ao monitor")
    vif = cfg.vif;
    if (vif == null)
      `uvm_fatal("MEM_NOVIF", "mem_cfg.vif e nulo")
  endfunction

  task run_phase(uvm_phase phase);
    mem_item     pend_tr [$];   // leituras aguardando o dado
    int unsigned pend_cnt[$];   // ciclos restantes de cada uma
    mem_item     tr;

    forever begin
      @(posedge vif.mem_clk);

      // 1. Leituras pendentes: o dado amostrado nesta borda e o da leitura
      //    emitida read_latency bordas atras.
      foreach (pend_cnt[i]) pend_cnt[i]--;
      while (pend_cnt.size() > 0 && pend_cnt[0] == 0) begin
        tr            = pend_tr.pop_front();
        void'(pend_cnt.pop_front());
        tr.mem_o_data = vif.mem_o_data;
        n_rd++;
        publish(tr);
      end

      // 2. Transacao desta borda (todo ciclo e uma escrita ou uma leitura)
      if ($isunknown({vif.mem_i_wr_en, vif.mem_i_addr}))
        `uvm_error("MEM_MON_X", $sformatf("wr_en/addr com X/Z (wr_en=%b addr=%h)",
                                          vif.mem_i_wr_en, vif.mem_i_addr))

      tr            = mem_item::type_id::create("tr");
      tr.mem_i_addr = vif.mem_i_addr;

      if (vif.mem_i_wr_en === 1'b1) begin
        tr.mem_i_wr_en = 1'b1;
        tr.mem_i_data  = vif.mem_i_data;
        n_wr++;
        publish(tr);
      end
      else begin
        tr.mem_i_wr_en = 1'b0;
        pend_tr.push_back(tr);
        pend_cnt.push_back(cfg.read_latency);
      end
    end
  endtask

  function void publish(mem_item tr);
    `uvm_info(get_type_name(), {"Observado: ", tr.convert2string()},
              tr.mem_i_wr_en ? UVM_MEDIUM : UVM_HIGH)
    ap.write(tr);
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Observadas %0d escritas e %0d leituras", n_wr, n_rd), UVM_LOW)
  endfunction

endclass : mem_monitor
