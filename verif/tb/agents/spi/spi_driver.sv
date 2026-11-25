//-----------------------------------------------------------------------------
// spi_driver.sv
// Mestre SPI Mode 0 (CPOL=0, CPHA=0), MSB primeiro. Gera o proprio sclk.
//
//   transfer(tx, rx): 1 frame de 40 bits. cs_n desce; para cada bit, MOSI
//                     muda com sclk baixo, meio periodo depois sclk sobe (o
//                     DUT amostra MOSI) e o driver amostra MISO; meio periodo
//                     depois sclk desce (o DUT muda MISO). No fim cs_n sobe e
//                     o driver espera gap_ns (CDC sclk -> clk do DUT).
//   ESCRITA: 1 frame {0, addr, 0, data}.
//   LEITURA: 2 frames: pedido {1, addr, 0, 0} + NOP {0, 0x3F, 0, 0}; o dado
//            volta no MISO durante o NOP, bits [31:0].
//
// O dado lido volta para a sequence com put_response (item_done(rsp)), so em
// leitura (decisao do Plano Dia 3: resposta separada do pedido). A sequence
// de leitura faz get_response().
//-----------------------------------------------------------------------------
class spi_driver extends uvm_driver #(spi_item);
  `uvm_component_utils(spi_driver)

  spi_cfg        cfg;   // atribuido pelo spi_agent
  virtual spi_if vif;

  int unsigned n_wr;
  int unsigned n_rd;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg == null)
      `uvm_fatal("SPI_NOCFG", "spi_cfg nao atribuido ao driver")
    vif = cfg.vif;
    if (vif == null)
      `uvm_fatal("SPI_NOVIF", "spi_cfg.vif e nulo")
  endfunction

  task run_phase(uvm_phase phase);
    spi_item rsp;

    vif.sclk = 1'b0;
    vif.cs_n = 1'b1;
    vif.mosi = 1'b0;

    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);

      if (req.rwb) begin
        $cast(rsp, req.clone());
        rsp.set_id_info(req);
        seq_item_port.item_done(rsp);
      end
      else
        seq_item_port.item_done();
    end
  endtask

  task drive_item(spi_item t);
    logic [39:0] rx;

    if (!t.rwb) begin
      transfer({1'b0, t.addr, 1'b0, t.data}, rx);
      n_wr++;
    end
    else begin
      transfer({1'b1, t.addr, 1'b0, 32'h0}, rx);   // pedido
      transfer({1'b0, REG_NOP, 1'b0, 32'h0}, rx);  // NOP: o dado sai no MISO
      t.rdata = rx[31:0];
      n_rd++;
    end

    `uvm_info(get_type_name(), {"Dirigido: ", t.convert2string()}, UVM_HIGH)
  endtask

  // Um frame de 40 bits. Mesma sequencia da spi_transfer do TB do projetista.
  task transfer(input bit [39:0] tx, output logic [39:0] rx);
    realtime half = cfg.sclk_period_ns * 1ns / 2.0;

    rx       = 'x;
    vif.cs_n = 1'b0;
    for (int i = 39; i >= 0; i--) begin
      vif.mosi = tx[i];          // sclk esta baixo
      #(half);
      vif.sclk = 1'b1;           // DUT amostra MOSI nesta subida
      rx[i]    = vif.miso;       // MISO so muda na descida: estavel aqui
      #(half);
      vif.sclk = 1'b0;
    end
    vif.cs_n = 1'b1;
    vif.mosi = 1'b0;
    #(cfg.gap_ns * 1ns);
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Dirigidas %0d escritas e %0d leituras", n_wr, n_rd), UVM_LOW)
  endfunction

endclass : spi_driver
