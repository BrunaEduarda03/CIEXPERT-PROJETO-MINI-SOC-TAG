//-----------------------------------------------------------------------------
// spi_monitor.sv
// Monitor passivo do SPI: so olha os 4 pinos.
//
// Captura de frame: cs_n desce -> a cada SUBIDA de sclk guarda MOSI e MISO
// (o DUT muda MISO na descida, entao os dois estao estaveis na subida) ->
// cs_n sobe fecha o frame.
//   - frame com != 40 bits: abortado (UVM_WARNING; o DUT descarta o frame);
//   - RSV != 0: UVM_WARNING (o mestre deve mandar RSV = 0).
//
// Reconstrucao no nivel de registrador:
//   - frame de escrita (RWb=0) em endereco != 0x3F -> publica WRITE;
//   - frame de pedido (RWb=1) -> guarda o endereco; o PROXIMO frame completo
//     (normalmente o NOP) traz o dado no MISO[31:0] -> publica UM READ;
//   - frame de escrita em 0x3F e o NOP: nao e transacao, nao e publicado.
//-----------------------------------------------------------------------------
class spi_monitor extends uvm_monitor;
  `uvm_component_utils(spi_monitor)

  uvm_analysis_port #(spi_item) ap;

  spi_cfg        cfg;   // atribuido pelo spi_agent
  virtual spi_if vif;

  int unsigned n_wr;
  int unsigned n_rd;
  int unsigned n_abort;

  // Frame em captura
  int unsigned nbits;
  bit   [39:0] mosi_w;
  logic [39:0] miso_w;

  // Leitura esperando o frame que traz o dado
  bit       read_pending;
  bit [5:0] pending_addr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg == null)
      `uvm_fatal("SPI_NOCFG", "spi_cfg nao atribuido ao monitor")
    vif = cfg.vif;
    if (vif == null)
      `uvm_fatal("SPI_NOVIF", "spi_cfg.vif e nulo")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(negedge vif.cs_n);
      collect_frame();
      process_frame();
    end
  endtask

  // Junta os bits ate cs_n subir.
  task collect_frame();
    nbits  = 0;
    mosi_w = '0;
    miso_w = '0;
    fork
      forever begin
        @(posedge vif.sclk);
        mosi_w = {mosi_w[38:0], vif.mosi};
        miso_w = {miso_w[38:0], vif.miso};
        nbits++;
      end
      @(posedge vif.cs_n);
    join_any
    disable fork;
  endtask

  function void process_frame();
    bit        rwb  = mosi_w[39];
    bit [5:0]  addr = mosi_w[38:33];
    bit        rsv  = mosi_w[32];
    bit [31:0] data = mosi_w[31:0];
    spi_item   tr;

    if (nbits != 40) begin
      n_abort++;
      `uvm_warning("SPI_MON_ABORT", $sformatf("Frame abortado: %0d bits (esperado 40), descartado", nbits))
      return;
    end

    if (rsv !== 1'b0)
      `uvm_warning("SPI_MON_RSV", $sformatf("Frame com RSV=1 (addr=0x%02h)", addr))

    // Este frame traz no MISO o dado da leitura pedida no frame anterior.
    if (read_pending) begin
      tr       = spi_item::type_id::create("tr");
      tr.rwb   = 1'b1;
      tr.addr  = pending_addr;
      tr.rdata = miso_w[31:0];
      read_pending = 1'b0;
      n_rd++;
      publish(tr);
    end

    if (rwb) begin
      read_pending = 1'b1;
      pending_addr = addr;
    end
    else if (addr != REG_NOP) begin
      tr      = spi_item::type_id::create("tr");
      tr.rwb  = 1'b0;
      tr.addr = addr;
      tr.data = data;
      n_wr++;
      publish(tr);
    end
  endfunction

  function void publish(spi_item tr);
    `uvm_info(get_type_name(), {"Observado: ", tr.convert2string()}, UVM_MEDIUM)
    ap.write(tr);
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Observadas %0d escritas, %0d leituras, %0d frames abortados",
                                         n_wr, n_rd, n_abort), UVM_LOW)
    if (read_pending)
      `uvm_warning("SPI_MON", $sformatf("Leitura de 0x%02h pedida e nunca completada (faltou o frame NOP)",
                                        pending_addr))
  endfunction

endclass : spi_monitor
