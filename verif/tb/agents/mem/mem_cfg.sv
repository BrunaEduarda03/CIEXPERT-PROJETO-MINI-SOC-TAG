//-----------------------------------------------------------------------------
// mem_cfg.sv
// Configuracao do VIP MEMORY DATA.
//-----------------------------------------------------------------------------
class mem_cfg extends uvm_object;

  virtual mem_if vif;

  uvm_active_passive_enum is_active   = UVM_ACTIVE;  // PASSIVE = so monitor
  int unsigned            idle_cycles = 0;           // ciclos ociosos extras entre acessos

  `uvm_object_utils_begin(mem_cfg)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_field_int(idle_cycles, UVM_DEFAULT | UVM_DEC)
  `uvm_object_utils_end

  function new(string name = "mem_cfg");
    super.new(name);
  endfunction

endclass : mem_cfg
