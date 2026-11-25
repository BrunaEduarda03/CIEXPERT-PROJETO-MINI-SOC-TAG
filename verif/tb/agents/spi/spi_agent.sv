//-----------------------------------------------------------------------------
// spi_agent.sv
// Agente do VIP SPI.
//   ATIVO  : sequencer + driver + monitor.
//   PASSIVO: so monitor.
// A analysis port do monitor e reexportada em 'ap'.
//-----------------------------------------------------------------------------
class spi_agent extends uvm_agent;
  `uvm_component_utils(spi_agent)

  spi_cfg       cfg;
  spi_sequencer sqr;
  spi_driver    drv;
  spi_monitor   mon;

  uvm_analysis_port #(spi_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    string msg;
    super.build_phase(phase);

    if (!uvm_config_db#(spi_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("SPI_NOCFG", {"spi_cfg nao encontrado para ", get_full_name()})
    if (!cfg.is_valid(msg))
      `uvm_fatal("SPI_BADCFG", msg)
    if (cfg.vif == null)
      `uvm_fatal("SPI_NOVIF", {"spi_cfg.vif nulo em ", get_full_name()})

    is_active = cfg.is_active;

    mon     = spi_monitor::type_id::create("mon", this);
    mon.cfg = cfg;

    if (is_active == UVM_ACTIVE) begin
      sqr     = spi_sequencer::type_id::create("sqr", this);
      drv     = spi_driver::type_id::create("drv", this);
      drv.cfg = cfg;
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass : spi_agent
