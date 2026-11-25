//-----------------------------------------------------------------------------
// spi_cfg.sv
// Configuracao do VIP SPI.
//-----------------------------------------------------------------------------
class spi_cfg extends uvm_object;

  virtual spi_if vif;

  uvm_active_passive_enum is_active      = UVM_ACTIVE;  // PASSIVE = so monitor
  int unsigned            sclk_period_ns = 40;          // 25 MHz = limite da spec (REQ-SPI-01);
                                                        // variacao: +SPI_SCLK_PERIOD_NS=50 (20 MHz)
  int unsigned            gap_ns         = 50;          // cs_n alto entre frames (CDC)

  `uvm_object_utils_begin(spi_cfg)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_field_int(sclk_period_ns, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(gap_ns,         UVM_DEFAULT | UVM_DEC)
  `uvm_object_utils_end

  function new(string name = "spi_cfg");
    super.new(name);
  endfunction

  function real sclk_mhz();
    return 1000.0 / real'(sclk_period_ns);
  endfunction

  // Retorna 0 e uma mensagem quando a configuracao e invalida.
  function bit is_valid(output string msg);
    msg = "";
    if (sclk_period_ns < 40) begin
      msg = $sformatf("sclk_period_ns=%0d invalido: sclk > 25 MHz viola a spec (minimo 40 ns)",
                      sclk_period_ns);
      return 0;
    end
    if (gap_ns == 0) begin
      msg = "gap_ns=0 invalido: o DUT precisa de tempo entre frames para o CDC";
      return 0;
    end
    return 1;
  endfunction

endclass : spi_cfg
