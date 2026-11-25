// spi_agent.sv - junta sequencer + driver + monitor (igual ao mem_agent).
typedef uvm_sequencer #(spi_item) spi_sequencer;

class spi_agent extends uvm_agent;
  `uvm_component_utils(spi_agent)

  spi_sequencer sqr;
  spi_driver    drv;
  spi_monitor   mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    virtual spi_if vif;
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif))
      `uvm_fatal("SPI_AGT", "spi_if nao encontrada no config_db")
    sqr = spi_sequencer::type_id::create("sqr", this);
    drv = spi_driver::type_id::create("drv", this);
    mon = spi_monitor::type_id::create("mon", this);
    drv.vif = vif;
    mon.vif = vif;
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
