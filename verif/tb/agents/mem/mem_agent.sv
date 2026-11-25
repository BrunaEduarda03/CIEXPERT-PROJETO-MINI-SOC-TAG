//-----------------------------------------------------------------------------
// mem_agent.sv
// Agente do VIP MEMORY DATA.
//   ATIVO  : sequencer + driver + monitor.
//   PASSIVO: so monitor.
// A analysis port do monitor e reexportada em 'ap' para o env ligar no
// scoreboard sem conhecer a estrutura interna do agente.
//-----------------------------------------------------------------------------
class mem_agent extends uvm_agent;
  `uvm_component_utils(mem_agent)

  mem_cfg       cfg;
  mem_sequencer sqr;
  mem_driver    drv;
  mem_monitor   mon;

  uvm_analysis_port #(mem_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    string msg;
    super.build_phase(phase);

    if (!uvm_config_db#(mem_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("MEM_NOCFG", {"mem_cfg nao encontrado para ", get_full_name()})
    if (!cfg.is_valid(msg))
      `uvm_fatal("MEM_BADCFG", msg)
    if (cfg.vif == null)
      `uvm_fatal("MEM_NOVIF", {"mem_cfg.vif nulo em ", get_full_name()})

    is_active = cfg.is_active;

    mon     = mem_monitor::type_id::create("mon", this);
    mon.cfg = cfg;

    if (is_active == UVM_ACTIVE) begin
      sqr     = mem_sequencer::type_id::create("sqr", this);
      drv     = mem_driver::type_id::create("drv", this);
      drv.cfg = cfg;
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass : mem_agent
