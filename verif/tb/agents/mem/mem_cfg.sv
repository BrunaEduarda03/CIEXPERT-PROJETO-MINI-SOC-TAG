//-----------------------------------------------------------------------------
// mem_cfg.sv
// Configuracao do VIP MEMORY DATA.
//-----------------------------------------------------------------------------
class mem_cfg extends uvm_object;

  virtual mem_if vif;

  uvm_active_passive_enum is_active    = UVM_ACTIVE;  // PASSIVE = so monitor
  int unsigned            read_latency = 1;           // ciclos de mem_clk (VPLAN F12)

  `uvm_object_utils_begin(mem_cfg)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_field_int(read_latency, UVM_DEFAULT | UVM_DEC)
  `uvm_object_utils_end

  function new(string name = "mem_cfg");
    super.new(name);
  endfunction

  // Retorna 0 e uma mensagem quando a configuracao e invalida.
  function bit is_valid(output string msg);
    msg = "";
    if (read_latency == 0) begin
      msg = "read_latency=0 invalido (RAM sincrona, minimo 1)";
      return 0;
    end
    return 1;
  endfunction

endclass : mem_cfg
