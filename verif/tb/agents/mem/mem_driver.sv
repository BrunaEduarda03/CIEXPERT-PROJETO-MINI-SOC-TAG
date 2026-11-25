//-----------------------------------------------------------------------------
// mem_driver.sv
// Converte mem_item em sinais na mem_if. Os sinais mudam na borda de DESCIDA
// de mem_clk e o DUT amostra na SUBIDA, evitando corrida (mesmo esquema das
// tasks mem_write/mem_read do testbench do projetista).
//
// Linha do tempo de um acesso:
//   negedge  : addr/data/wr_en/tb_valid = 1
//   posedge  : DUT grava (WRITE) ou registra memory[addr] em mem_o_data (READ)
//   negedge  : READ captura mem_o_data em rdata; tb_valid = 0, wr_en = 0
//-----------------------------------------------------------------------------
class mem_driver extends uvm_driver #(mem_item);
  `uvm_component_utils(mem_driver)

  mem_cfg        cfg;   // atribuido pelo mem_agent
  virtual mem_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg == null)
      `uvm_fatal("MEM_NOCFG", "mem_cfg nao atribuido ao driver")
    vif = cfg.vif;
    if (vif == null)
      `uvm_fatal("MEM_NOVIF", "mem_cfg.vif e nulo")
  endfunction

  task run_phase(uvm_phase phase);
    drive_idle();
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  // Ocioso: leitura "fantasma" (wr_en = 0) que o monitor ignora (tb_valid = 0).
  function void drive_idle();
    vif.mem_i_wr_en = 1'b0;
    vif.tb_valid    = 1'b0;
  endfunction

  task drive_item(mem_item it);
    @(negedge vif.mem_clk);
    vif.mem_i_addr  = it.addr;
    vif.mem_i_wr_en = (it.op == MEM_WRITE);
    if (it.op == MEM_WRITE)
      vif.mem_i_data = it.data;
    vif.tb_valid    = 1'b1;

    @(negedge vif.mem_clk);           // a subida ja ocorreu
    if (it.op == MEM_READ)
      it.rdata = vif.mem_o_data;
    drive_idle();

    `uvm_info(get_type_name(), {"driven: ", it.convert2string()}, UVM_HIGH)

    repeat (cfg.idle_cycles) @(negedge vif.mem_clk);
  endtask

endclass : mem_driver
