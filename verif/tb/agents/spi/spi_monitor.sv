// spi_monitor.sv - olha os fios e reconstroi as transacoes (nao fala com o driver).
// Junta o frame de pedido de leitura com o frame seguinte (onde vem o dado)
// numa unica transacao READ.
class spi_monitor extends uvm_monitor;
  `uvm_component_utils(spi_monitor)

  virtual spi_if vif;                   // entregue pelo spi_agent
  uvm_analysis_port #(spi_item) ap;     // envia cada transacao ao scoreboard

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    bit [39:0] mosi, miso;
    int        n;
    spi_item   pending;                 // pedido de leitura esperando o dado

    forever begin
      // 1. Captura um frame: um bit por subida de sclk, ate cs_n subir
      @(negedge vif.cs_n);
      n = 0;
      forever begin
        @(posedge vif.sclk or posedge vif.cs_n);
        if (vif.cs_n) break;
        mosi = {mosi[38:0], vif.mosi};
        miso = {miso[38:0], vif.miso};
        n++;
      end
      if (n != 40) begin
        `uvm_warning("SPI_MON", $sformatf("frame abortado com %0d bits: ignorado", n))
        continue;
      end

      // 2. Se havia um pedido de leitura, este frame traz o dado
      if (pending != null) begin
        pending.rdata = miso[31:0];
        publish(pending);
        pending = null;
      end

      // 3. Decodifica o frame atual
      if (mosi[38:33] == 6'h3F) continue;          // NOP: nao e transacao
      if (mosi[39] == 1) begin                     // pedido de leitura
        pending      = spi_item::type_id::create("rd");
        pending.op   = SPI_READ;
        pending.addr = mosi[38:33];
      end
      else begin                                   // escrita
        spi_item it = spi_item::type_id::create("wr");
        it.op   = SPI_WRITE;
        it.addr = mosi[38:33];
        it.data = mosi[31:0];
        publish(it);
      end
    end
  endtask

  function void publish(spi_item it);
    `uvm_info("SPI_MON", it.convert2string(), UVM_MEDIUM)
    ap.write(it);
  endfunction
endclass
