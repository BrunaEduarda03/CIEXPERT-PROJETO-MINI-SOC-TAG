// minisoc_cfg_seq.sv - configuracao basica do DUT pelo SPI (Block Guide 9):
//   1. le VERSION
//   2. liga o PLL com o divisor escolhido
//   3. espera PLL_LOCKED = 1 (com limite de tentativas)
//   4. escolhe o dono da memoria (MEM_SEL_AES)
class minisoc_cfg_seq extends uvm_sequence #(spi_item);
  `uvm_object_utils(minisoc_cfg_seq)

  bit [1:0] div_sel     = 2'b11;   // 0 = /1 (2 GHz) ... 3 = /8 (250 MHz)
  bit       mem_sel_aes = 0;       // 0 = interface externa, 1 = AES
  int       max_tries   = 10;

  function new(string name = "minisoc_cfg_seq");
    super.new(name);
  endfunction

  task body();
    logic [31:0] status;

    ler('h0D, status);                                  // 1. VERSION (o spi_scoreboard confere)
    escrever('h0E, {div_sel, 1'b1, 1'b0});              // 2. PLL_ENABLE = 1

    for (int i = 0; i < max_tries; i++) begin           // 3. espera o lock
      ler('h0F, status);
      if (status[0]) break;
    end
    if (!status[0]) `uvm_fatal("CFG", "PLL nao travou")
    `uvm_info("CFG", $sformatf("PLL travado com divisor /%0d", 1 << div_sel), UVM_LOW)

    escrever('h0E, {div_sel, 1'b1, mem_sel_aes});       // 4. dono da memoria
  endtask

  task escrever(bit [5:0] addr, bit [31:0] data);
    spi_write_seq wr = spi_write_seq::type_id::create("wr");
    wr.addr = addr;
    wr.data = data;
    wr.start(m_sequencer, this);
  endtask

  task ler(bit [5:0] addr, output logic [31:0] rdata);
    spi_read_seq rd = spi_read_seq::type_id::create("rd");
    rd.addr = addr;
    rd.start(m_sequencer, this);
    rdata = rd.rdata;
  endtask
endclass
