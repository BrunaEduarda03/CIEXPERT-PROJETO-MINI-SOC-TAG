//-----------------------------------------------------------------------------
// minisoc_env.sv
// Ambiente de topo: agentes de clock e reset, VIP MEMORY DATA e VIP SPI, cada
// um com seu scoreboard. Monitores do PLL/AES e coverage entram em dezembro.
//-----------------------------------------------------------------------------
class minisoc_env extends uvm_env;
  `uvm_component_utils(minisoc_env)

  minisoc_env_cfg cfg;

  clk_agent ref_clk_agt;   // clk de 2 GHz
  clk_agent mem_clk_agt;   // mem_clk
  rst_agent rst_agt;       // rst_n
  mem_agent mem_agt;       // MEMORY DATA
  spi_agent spi_agt;       // SPI

  mem_scoreboard mem_scb;
  spi_scoreboard spi_scb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(minisoc_env_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("ENV_NOCFG", "minisoc_env_cfg nao encontrado")

    uvm_config_db#(clk_cfg)::set(this, "ref_clk_agt", "cfg", cfg.ref_clk);
    uvm_config_db#(clk_cfg)::set(this, "mem_clk_agt", "cfg", cfg.mem_clk);
    uvm_config_db#(rst_cfg)::set(this, "rst_agt",     "cfg", cfg.rst);
    uvm_config_db#(virtual mem_if)::set(this, "mem_agt", "vif", cfg.mem_vif);
    uvm_config_db#(virtual spi_if)::set(this, "spi_agt", "vif", cfg.spi_vif);

    ref_clk_agt = clk_agent::type_id::create("ref_clk_agt", this);
    mem_clk_agt = clk_agent::type_id::create("mem_clk_agt", this);
    rst_agt     = rst_agent::type_id::create("rst_agt",     this);
    mem_agt     = mem_agent::type_id::create("mem_agt",     this);
    spi_agt     = spi_agent::type_id::create("spi_agt",     this);

    mem_scb           = mem_scoreboard::type_id::create("mem_scb", this);
    mem_scb.probe_vif = cfg.probe_vif;

    spi_scb           = spi_scoreboard::type_id::create("spi_scb", this);
    spi_scb.probe_vif = cfg.probe_vif;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mem_agt.mon.ap.connect(mem_scb.imp);
    spi_agt.mon.ap.connect(spi_scb.imp);
  endfunction

endclass : minisoc_env
