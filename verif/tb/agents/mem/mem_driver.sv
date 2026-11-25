// mem_driver.sv - transforma mem_item em sinais.
// Muda os sinais na DESCIDA do clock; o DUT le na SUBIDA.
class mem_driver extends uvm_driver #(mem_item);
  `uvm_component_utils(mem_driver)

  virtual mem_if vif;   // entregue pelo mem_agent

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);

      @(negedge vif.mem_clk);                  // 1. coloca o pedido nos fios
      vif.mem_i_addr  = req.addr;
      vif.mem_i_data  = req.data;
      vif.mem_i_wr_en = (req.op == MEM_WRITE);
      vif.tb_valid    = 1;

      @(negedge vif.mem_clk);                  // 2. o DUT ja atendeu na subida
      req.rdata       = vif.mem_o_data;        //    (so importa no READ)
      vif.mem_i_wr_en = 0;
      vif.tb_valid    = 0;

      seq_item_port.item_done();
    end
  endtask
endclass
