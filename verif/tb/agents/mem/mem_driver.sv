//-----------------------------------------------------------------------------
// mem_driver.sv
// Dirige a interface MEMORY DATA a partir de mem_item.
//
//   ESCRITA: wr_en=1, addr, data por 1 ciclo de mem_clk.
//            Escritas consecutivas saem em ciclos consecutivos.
//   LEITURA: wr_en=0, addr; espera read_latency ciclos e captura o pino
//            mem_o_data no campo req.mem_o_data.
//   OCIOSO : wr_en=0 (addr/data mantidos). Pela interface isso tambem e uma
//            leitura do ultimo endereco; o monitor a publica como tal.
//
// Os campos do mem_item tem o mesmo nome dos pinos da mem_if.
// O dado lido volta no proprio req (req.mem_o_data): a sequence le o campo
// depois do finish_item(). Nao usa put_response() porque toda transacao termina em
// tempo fixo e nao ha pipelining de leituras nesta interface.
//-----------------------------------------------------------------------------
class mem_driver extends uvm_driver #(mem_item);
  `uvm_component_utils(mem_driver)

  mem_cfg        cfg;   // atribuido pelo mem_agent
  virtual mem_if vif;

  int unsigned n_wr;
  int unsigned n_rd;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg == null)
      `uvm_fatal("MEM_NOCFG", "mem_cfg nao atribuido ao driver")
    vif = cfg.vif;
    if (vif == null)
      `uvm_fatal("MEM_NOVIF", "mem_cfg.vif e nulo")
  endfunction

  task run_phase(uvm_phase phase);
    // Estado inicial direto nos sinais (antes da primeira borda).
    vif.mem_i_wr_en = 1'b0;
    vif.mem_i_addr  = '0;
    vif.mem_i_data  = '0;

    @(posedge vif.mem_clk);
    forever begin
      seq_item_port.try_next_item(req);
      if (req == null) begin
        drive_idle();
        @(posedge vif.mem_clk);
      end
      else begin
        drive_item(req);
        seq_item_port.item_done();
      end
    end
  endtask

  // Todos os drives acontecem logo apos a borda de SUBIDA de mem_clk, com
  // atribuicao NAO-bloqueante (<=): o valor so muda na regiao NBA, depois de
  // a RAM ter amostrado nesta borda, e o DUT o ve na proxima subida (mesma
  // regra de um always_ff). Com '=' haveria corrida com o DUT nesta borda.
  task drive_idle();
    vif.mem_i_wr_en <= 1'b0;
  endtask

  task drive_item(mem_item t);
    vif.mem_i_addr  <= t.mem_i_addr;
    vif.mem_i_wr_en <= t.mem_i_wr_en;
    if (t.mem_i_wr_en)
      vif.mem_i_data <= t.mem_i_data;

    @(posedge vif.mem_clk);                // borda em que a RAM escreve / amostra addr

    if (t.mem_i_wr_en)
      n_wr++;
      // wr_en so desce se nao houver proximo item (drive_idle), para
      // escritas consecutivas sairem em ciclos consecutivos.
    else begin
      // mem_o_data e atualizado (NBA) nesta subida. Na subida seguinte, lido
      // antes do NBA, ele ainda tem esse valor -> latencia de 1 ciclo.
      repeat (cfg.read_latency) @(posedge vif.mem_clk);
      t.mem_o_data = vif.mem_o_data;
      n_rd++;
    end

    `uvm_info(get_type_name(), {"Dirigido: ", t.convert2string()}, UVM_HIGH)
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Dirigidas %0d escritas e %0d leituras", n_wr, n_rd), UVM_LOW)
  endfunction

endclass : mem_driver
