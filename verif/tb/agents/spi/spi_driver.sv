// spi_driver.sv - transforma spi_item em frames SPI (Mode 0, MSB primeiro).
// Frame de 40 bits: {RWb, ADDR[5:0], 0, DATA[31:0]}.
//   WRITE = 1 frame.  READ = 2 frames: pedido + NOP (o dado volta no MISO do NOP).
class spi_driver extends uvm_driver #(spi_item);
  `uvm_component_utils(spi_driver)

  virtual spi_if vif;          // entregue pelo spi_agent
  time half = 25ns;            // meio periodo de sclk: 20 MHz (spec: <= 25 MHz)
  time gap  = 20ns;            // pausa entre frames para o DUT sincronizar (CDC)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    bit [39:0] rx;
    forever begin
      seq_item_port.get_next_item(req);
      if (req.op == SPI_WRITE)
        transfer({1'b0, req.addr, 1'b0, req.data}, rx);
      else begin
        transfer({1'b1, req.addr, 1'b0, 32'h0}, rx);   // 1. pede a leitura
        transfer({1'b0, 6'h3F,    1'b0, 32'h0}, rx);   // 2. NOP: o DUT devolve o dado
        req.rdata = rx[31:0];
      end
      seq_item_port.item_done();
    end
  endtask

  // Envia 40 bits em tx e recebe 40 bits em rx.
  // MOSI muda com sclk baixo; DUT e testbench leem na subida.
  task transfer(bit [39:0] tx, output bit [39:0] rx);
    vif.cs_n = 0;
    for (int i = 39; i >= 0; i--) begin
      vif.mosi = tx[i];
      #half vif.sclk = 1;
      rx[i] = vif.miso;
      #half vif.sclk = 0;
    end
    vif.cs_n = 1;
    vif.mosi = 0;
    #gap;
  endtask
endclass
