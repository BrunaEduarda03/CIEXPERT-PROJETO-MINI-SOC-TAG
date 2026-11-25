// mem_agent.sv - junta sequencer + driver + monitor.
//   sequencer -> driver -> mem_if -> DUT -> mem_if -> monitor -> ap
typedef uvm_sequencer #(mem_item) mem_sequencer;

class mem_agent extends uvm_agent;
  `uvm_component_utils(mem_agent)

  mem_sequencer sqr;
  mem_driver    drv;
  mem_monitor   mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    virtual mem_if vif;
    if (!uvm_config_db#(virtual mem_if)::get(this, "", "vif", vif))
      `uvm_fatal("MEM_AGT", "mem_if nao encontrada no config_db")
    sqr = mem_sequencer::type_id::create("sqr", this);
    drv = mem_driver::type_id::create("drv", this);
    mon = mem_monitor::type_id::create("mon", this);
    drv.vif = vif;
    mon.vif = vif;
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
