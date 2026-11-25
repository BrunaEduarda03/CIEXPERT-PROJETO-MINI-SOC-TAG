//-----------------------------------------------------------------------------
// mem_agent.sv
// Agente do VIP MEMORY DATA. Ativo: sequencer + driver + monitor.
// Passivo: so monitor.
//-----------------------------------------------------------------------------
typedef uvm_sequencer #(mem_item) mem_sequencer;

class mem_agent extends uvm_agent;
  `uvm_component_utils(mem_agent)

  mem_cfg       cfg;
  mem_sequencer sqr;
  mem_driver    drv;
  mem_monitor   mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(mem_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("MEM_NOCFG", {"mem_cfg nao encontrado para ", get_full_name()})
    if (cfg.vif == null)
      `uvm_fatal("MEM_NOVIF", {"mem_cfg.vif nulo em ", get_full_name()})

    mon     = mem_monitor::type_id::create("mon", this);
    mon.cfg = cfg;

    if (cfg.is_active == UVM_ACTIVE) begin
      sqr     = mem_sequencer::type_id::create("sqr", this);
      drv     = mem_driver::type_id::create("drv", this);
      drv.cfg = cfg;
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass : mem_agent
