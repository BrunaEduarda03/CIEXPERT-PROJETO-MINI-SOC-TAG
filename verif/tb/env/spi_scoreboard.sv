// spi_scoreboard.sv - o juiz do SPI.
// Mantem um "espelho" dos 16 registradores e confere cada leitura.
// Regras tiradas do RTL (minisoc_spi.sv). Status (0x0C, 0x0F) vem do hardware:
// o valor esperado e lido pelo probe.
class spi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(spi_scoreboard)

  uvm_analysis_imp #(spi_item, spi_scoreboard) imp;   // recebe do monitor
  virtual minisoc_probe_if probe_vif;                 // status e rst_n

  bit [31:0]   regs [16];                             // espelho: regs[addr]
  int unsigned n_compared, n_errors;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    imp = new("imp", this);
    reset_regs();
  endfunction

  // Valores de reset da spec
  function void reset_regs();
    foreach (regs[i]) regs[i] = 0;
    regs['h0A] = 1;              // NUM_BLOCKS
    regs['h0D] = 'h0001_0100;    // VERSION
    regs['h0E] = 'hC;            // SYSTEM_CONTROL: PLL_DIV_SEL = 3
  endfunction

  // Se o DUT levar reset, o espelho tambem volta ao reset
  task run_phase(uvm_phase phase);
    forever @(negedge probe_vif.rst_n) reset_regs();
  endtask

  function void write(spi_item t);
    if (t.op == SPI_WRITE) begin
      case (t.addr)
        'h00, 'h01, 'h02, 'h03, 'h04, 'h05, 'h06, 'h07, 'h08, 'h09:
                regs[t.addr] = t.data;               // KEY, IV, COUNTER: 32 bits
        'h0A:   regs[t.addr] = t.data & 'h1FF;       // NUM_BLOCKS: 9 bits
        'h0B:   regs[t.addr] = t.data & 'h1E;        // MODE + DECRYPT; START sempre le 0
        'h0E:   regs[t.addr] = t.data & 'hF;         // SYSTEM_CONTROL: 4 bits
        default: ;                                   // read-only ou nao mapeado: ignora
      endcase
    end
    else
      compare(t.addr, t.rdata, expected(t.addr));
  endfunction

  function bit [31:0] expected(bit [5:0] addr);
    if (addr == 'h0C) return {probe_vif.aes_blocks_done_spi, probe_vif.aes_error_spi,
                              probe_vif.aes_done_spi, probe_vif.aes_busy_spi};   // AES_STATUS
    if (addr == 'h0F) return probe_vif.pll_locked;                               // SYSTEM_STATUS
    if (addr < 16)    return regs[addr];
    return 0;                                                                    // nao mapeado
  endfunction

  function void compare(bit [5:0] addr, logic [31:0] got, bit [31:0] exp);
    n_compared++;
    if (got !== exp) begin
      n_errors++;
      `uvm_error("SPI_SCB", $sformatf("addr=0x%02h: lido 0x%08h, esperado 0x%08h", addr, got, exp))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SPI_SCB", $sformatf("%0d leituras comparadas, %0d erros", n_compared, n_errors), UVM_LOW)
  endfunction
endclass
