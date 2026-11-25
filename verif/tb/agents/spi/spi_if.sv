// spi_if.sv - fios do SPI (testbench <-> DUT). Repouso: cs_n = 1, sclk = 0.
interface spi_if;
  logic sclk = 0;
  logic cs_n = 1;    // 0 = frame em andamento
  logic mosi = 0;    // testbench -> DUT
  logic miso;        // DUT -> testbench
endinterface
