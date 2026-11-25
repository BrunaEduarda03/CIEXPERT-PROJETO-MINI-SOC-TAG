// minisoc_spi_reg_test.sv - T-SPI-REG: escreve e le de volta todos os registradores.
// Inclui read-only e enderecos nao mapeados (escrita deve ser ignorada).
// Cuidado: START (0x0B bit 0) e PLL_ENABLE (0x0E bit 1) ficam sempre em 0,
// porque disparam o AES e o PLL.
class minisoc_spi_reg_test extends minisoc_base_test;
  `uvm_component_utils(minisoc_spi_reg_test)

  bit [5:0]  enderecos[] = '{'h00, 'h01, 'h02, 'h03, 'h04, 'h05, 'h06, 'h07, 'h08, 'h09,
                             'h0A, 'h0B, 'h0C, 'h0D, 'h0E, 'h0F, 'h10, 'h20, 'h3E};
  bit [31:0] valores[]   = '{'h0000_0000, 'hFFFF_FFFF, 'hA5A5_A5A5, 'h0000_0001, 'h8000_0000};

  function new(string name, uvm_component parent);
    super.new(name, parent);
    test_timeout = 5ms;
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    env.rst_agt.wait_reset_done();

    foreach (enderecos[a]) begin
      foreach (valores[v]) escrever_e_ler(enderecos[a], valores[v]);
      escrever_e_ler(enderecos[a], $urandom());
    end

    phase.drop_objection(this);
  endtask

  task escrever_e_ler(bit [5:0] addr, bit [31:0] data);
    spi_write_seq wr = spi_write_seq::type_id::create("wr");
    spi_read_seq  rd = spi_read_seq::type_id::create("rd");
    if (addr == 'h0B) data[0] = 0;   // START = 0
    if (addr == 'h0E) data[1] = 0;   // PLL_ENABLE = 0
    wr.addr = addr;
    wr.data = data;
    wr.start(env.spi_agt.sqr);
    rd.addr = addr;
    rd.start(env.spi_agt.sqr);
  endtask

  function void check_phase(uvm_phase phase);
    if (env.spi_scb.n_compared == 0) `uvm_error("SPI_REG", "scoreboard nao comparou nenhuma leitura")
  endfunction
endclass
