//-----------------------------------------------------------------------------
// minisoc_env.sv
// Ambiente de topo. Contem os agentes de clock, reset (P0/P1), MEMORY DATA e
// o mem_scoreboard (P3, CHK-04), ligado em mem_agt.mon.ap. spi_agent, demais
// scoreboards e coverage entram nas fases P2-P5 (VPLAN, secao 4.2).
//-----------------------------------------------------------------------------
class minisoc_env extends uvm_env;
  `uvm_component_utils(minisoc_env)

  minisoc_env_cfg cfg;

  clk_agent ref_clk_agt;   // clk de 2 GHz
  clk_agent mem_clk_agt;   // mem_clk
  rst_agent rst_agt;       // rst_n
  mem_agent mem_agt;       // MEMORY DATA

  mem_scoreboard mem_scb;  // CHK-04

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
    uvm_config_db#(mem_cfg)::set(this, "mem_agt",     "cfg", cfg.mem);

    ref_clk_agt = clk_agent::type_id::create("ref_clk_agt", this);
    mem_clk_agt = clk_agent::type_id::create("mem_clk_agt", this);
    rst_agt     = rst_agent::type_id::create("rst_agt",     this);
    mem_agt     = mem_agent::type_id::create("mem_agt",     this);

    mem_scb                   = mem_scoreboard::type_id::create("mem_scb", this);
    mem_scb.probe_vif         = cfg.probe_vif;
    mem_scb.cfg               = cfg.mem;
    mem_scb.mem_clk_period_ps = cfg.mem_clk.period_ps;
  endfunction

  // Monitor (testemunha) -> scoreboard (juiz).
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mem_agt.mon.ap.connect(mem_scb.imp);
  endfunction

endclass : minisoc_env
