// mem_monitor.sv - olha os fios e reconstroi as transacoes (nao fala com o driver).
// READ: o dado aparece em mem_o_data uma subida depois.
class mem_monitor extends uvm_monitor;
  `uvm_component_utils(mem_monitor)

  virtual mem_if vif;                   // entregue pelo mem_agent
  uvm_analysis_port #(mem_item) ap;     // envia cada transacao ao scoreboard

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    mem_item it;
    forever begin
      @(posedge vif.mem_clk);
      if (vif.tb_valid !== 1) continue;      // ciclo sem transacao

      it      = mem_item::type_id::create("it");
      it.addr = vif.mem_i_addr;
      it.data = vif.mem_i_data;
      it.op   = vif.mem_i_wr_en ? MEM_WRITE : MEM_READ;

      if (it.op == MEM_READ) begin
        @(posedge vif.mem_clk);              // espera o dado sair do DUT
        it.rdata = vif.mem_o_data;
      end

      `uvm_info("MEM_MON", it.convert2string(), UVM_MEDIUM)
      ap.write(it);
    end
  endtask
endclass
