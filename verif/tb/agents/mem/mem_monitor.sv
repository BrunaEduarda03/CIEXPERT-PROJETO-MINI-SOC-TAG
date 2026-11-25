//-----------------------------------------------------------------------------
// mem_monitor.sv
// Reconstroi as transacoes MEMORY DATA olhando apenas os fios. E a testemunha
// independente do driver: o scoreboard so confia no que o monitor publica.
//
// Em cada subida de mem_clk (antes do DUT atualizar seus registradores):
//   1. Se ha uma leitura pendente do ciclo anterior, mem_o_data ja contem o
//      dado dela: completa rdata e publica.
//   2. Se tb_valid = 1, ha uma transacao neste ciclo: WRITE e publicada na
//      hora; READ fica pendente ate a proxima subida (latencia de 1 ciclo).
// A ordem (1 antes de 2) garante que o scoreboard recebe as transacoes na
// mesma ordem em que aconteceram no DUT.
//-----------------------------------------------------------------------------
class mem_monitor extends uvm_monitor;
  `uvm_component_utils(mem_monitor)

  mem_cfg        cfg;   // atribuido pelo mem_agent
  virtual mem_if vif;

  uvm_analysis_port #(mem_item) ap;

  int unsigned n_writes;
  int unsigned n_reads;

  function new(string name, uvm_component parent);
    super.new(name, parent);
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
    mem_item pending;
    mem_item it;

    forever begin
      @(posedge vif.mem_clk);

      if (pending != null) begin
        pending.rdata = vif.mem_o_data;
        publish(pending);
        pending = null;
      end

      if (vif.tb_valid === 1'b1) begin
        it      = mem_item::type_id::create("mon_item");
        it.addr = vif.mem_i_addr;
        if (vif.mem_i_wr_en === 1'b1) begin
          it.op   = MEM_WRITE;
          it.data = vif.mem_i_data;
          publish(it);
        end
        else begin
          it.op   = MEM_READ;
          pending = it;
        end
      end
    end
  endtask

  function void publish(mem_item it);
    if (it.op == MEM_WRITE) n_writes++; else n_reads++;
    `uvm_info(get_type_name(), it.convert2string(), UVM_MEDIUM)
    ap.write(it);
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),
              $sformatf("Transacoes observadas: %0d escritas, %0d leituras", n_writes, n_reads),
              UVM_LOW)
  endfunction

endclass : mem_monitor
