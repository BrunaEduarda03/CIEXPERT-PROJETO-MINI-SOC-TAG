//-----------------------------------------------------------------------------
// minisoc_rst_default_test.sv  (T-RST-DEFAULT, VPLAN secao 8)
// Prova o VIP SPI de ponta a ponta e os valores de reset (F01 / CHK-01):
//   1. Apos o reset inicial, le pelo SPI todos os registradores (0x00-0x0F),
//      tres nao mapeados (0x10, 0x2A, 0x3E) e o NOP (0x3F), e compara com os
//      valores de reset da spec (VERSION = 0x0001_0100 resolve o OPEN-03).
//   2. Escreve valores diferentes do reset (START=0 e PLL_ENABLE=0 para nao
//      disparar o DUT), le de volta (prova a escrita, as mascaras de bits e
//      que RO/nao mapeados ignoram escrita), aplica reset em runtime pelo
//      rst_agent e confere de novo os valores de reset.
// Enquanto o spi_scoreboard (CHK-02) nao existe, a comparacao e feita aqui.
//-----------------------------------------------------------------------------
class minisoc_rst_default_test extends minisoc_base_test;
  `uvm_component_utils(minisoc_rst_default_test)

  bit [5:0] regs[$];          // enderecos lidos em cada varredura
  bit [31:0] written[bit [5:0]];

  int unsigned n_checks;
  int unsigned n_fails;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    test_timeout = 2ms;
  endfunction

  task wr(bit [5:0] addr, bit [31:0] data);
    spi_write_seq s = spi_write_seq::type_id::create("wr");
    s.addr = addr;
    s.data = data;
    s.start(env.spi_agt.sqr);
  endtask

  task rd(bit [5:0] addr, output logic [31:0] data);
    spi_read_seq s = spi_read_seq::type_id::create("rd");
    s.addr = addr;
    s.start(env.spi_agt.sqr);
    data = s.rdata;
  endtask

  // Valor de reset de cada endereco (Block Guide secao 6 / minisoc_spi.sv).
  function bit [31:0] reset_value(bit [5:0] addr);
    case (addr)
      REG_NUM_BLOCKS    : return 32'h0000_0001;
      REG_VERSION       : return MINISOC_VERSION;
      REG_SYSTEM_CONTROL: return 32'h0000_000C;   // PLL_DIV_SEL = 11
      default           : return 32'h0000_0000;   // KEY/IV/COUNTER/STATUS/nao mapeados
    endcase
  endfunction

  // Valor lido depois de escrever 'data' (mascaras e RO), partindo do reset.
  function bit [31:0] readback_value(bit [5:0] addr, bit [31:0] data);
    case (addr)
      REG_KEY0, REG_KEY1, REG_KEY2, REG_KEY3,
      REG_IV0,  REG_IV1,  REG_IV2,  REG_IV3,
      REG_COUNTER_HI, REG_COUNTER_LO: return data;
      REG_NUM_BLOCKS    : return {23'h0, data[8:0]};
      REG_AES_CONTROL   : return {27'h0, data[4:1], 1'b0};   // START le 0
      REG_SYSTEM_CONTROL: return {28'h0, data[3:0]};
      default           : return reset_value(addr);          // RO / nao mapeado
    endcase
  endfunction

  task run_phase(uvm_phase phase);
    logic [31:0] r;

    phase.raise_objection(this, "T-RST-DEFAULT em execucao");

    for (int a = 0; a <= 15; a++) regs.push_back(a);
    regs.push_back(6'h10);
    regs.push_back(6'h2A);
    regs.push_back(6'h3E);
    regs.push_back(REG_NOP);

    // 1. Valores de reset apos o reset inicial
    env.rst_agt.wait_reset_done();
    repeat (20) @(posedge env_cfg.probe_vif.clk);
    read_all_defaults("apos reset inicial");

    // 2. Escreve valores diferentes do reset e le de volta
    foreach (regs[i]) begin
      bit [5:0]  a = regs[i];
      bit [31:0] d = $urandom();
      if (a == REG_NOP) continue;
      case (a)
        REG_NUM_BLOCKS    : d = 32'hFFFF_FF80;                // so [8:0] = 0x180 fica
        REG_AES_CONTROL   : d = 32'hFFFF_FFF6;                // MODE=101, DECRYPT=1, START=0
        REG_SYSTEM_CONTROL: d = 32'hFFFF_FFF4;                // DIV=01, PLL_ENABLE=0, MEM_SEL=0
        default           : if (d == reset_value(a)) d = ~d;  // garante valor != reset
      endcase
      wr(a, d);
      written[a] = d;
    end
    foreach (written[a]) begin
      rd(a, r);
      check_reg(a, r, readback_value(a, written[a]), "apos escrita");
    end

    // 3. Reset em runtime e valores de reset de novo
    env.rst_agt.apply_reset($urandom_range(10, 30));
    repeat (20) @(posedge env_cfg.probe_vif.clk);
    read_all_defaults("apos reset em runtime");

    `uvm_info("RST_DEFAULT", $sformatf("Checagens: %0d executadas, %0d falhas", n_checks, n_fails), UVM_LOW)
    phase.drop_objection(this, "T-RST-DEFAULT concluido");
  endtask

  task read_all_defaults(string ctx);
    logic [31:0] r;
    foreach (regs[i]) begin
      rd(regs[i], r);
      check_reg(regs[i], r, reset_value(regs[i]), ctx);
    end
  endtask

  function void check_reg(bit [5:0] addr, logic [31:0] got, bit [31:0] exp, string ctx);
    minisoc_reg_e reg_e = minisoc_reg_e'(addr);
    string        name  = (addr inside {[6'h00:6'h0F], REG_NOP}) ? reg_e.name() : "NAO_MAPEADO";
    n_checks++;
    if (got !== exp) begin
      n_fails++;
      `uvm_error("RST_DEFAULT", $sformatf("[%s] 0x%02h %s = 0x%08h, esperado 0x%08h",
                                          ctx, addr, name, got, exp))
    end
    else
      `uvm_info("RST_DEFAULT", $sformatf("[%s] 0x%02h %s = 0x%08h OK", ctx, addr, name, got),
                (addr == REG_VERSION) ? UVM_LOW : UVM_MEDIUM)
  endfunction

endclass : minisoc_rst_default_test
