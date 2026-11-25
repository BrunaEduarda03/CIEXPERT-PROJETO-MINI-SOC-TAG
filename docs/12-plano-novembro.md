# 12 — Plano de execução do checkpoint de novembro (prazo 30/11/2026)

> **Status: AGUARDANDO APROVAÇÃO** (seção 9). Execução prevista: **hoje, numa
> sessão só**, etapa por etapa. Nada abaixo foi implementado ainda.

**Em uma frase:** em outubro o testbench aprendeu a *ligar* o DUT (clock e
reset). Agora ele precisa aprender a *conversar* com o DUT — pela **MEMORY
DATA** (dados) e pelo **SPI** (configuração) — e a *conferir sozinho* se as
respostas estão certas.

Fontes: Plano de Projeto (seção 5), Block Guide MiniSoC AES (seções 3, 5, 6, 7, 9),
Plano Dia 3, VPLAN v1, RTL (`minisoc_memory.sv`, `minisoc_spi.sv`) e o testbench
do projetista em `frontend/tb/minisoc_top_tb.sv` (tasks `mem_write`, `mem_read`,
`spi_transfer`, `spi_read` — ótima referência de protocolo).

---

## 1. O que o marco pede

| Entregar | Demonstrar na apresentação |
|---|---|
| VIP MEMORY DATA e VIP SPI (clk/rst já feitos) | transações de memória e SPI acontecendo |
| configuração básica do DUT | monitores reconstruindo essas transações |
| VPLAN atualizado (v2) | checagens automáticas (scoreboard / assertion) |
| primeiros testes de interface | **por que** a arquitetura é assim |

Avaliação: entrega técnica 50% · saber explicar 25% · evidências 15% · apresentação 10%.

---

## 2. Onde você está

| Já existe ✅ | Falta ❌ |
|---|---|
| `agents/clk/`, `agents/rst/` (if, cfg, driver, agent, pkg) | `agents/mem/`, `agents/spi/` |
| `env/` com env, env_cfg, env_pkg (só clk + rst) | scoreboards |
| `tests/` com base_test e smoke_test | `sequences/` está vazio |
| `top_tb.sv`, `top_assertions.sv`, `minisoc_probe_if.sv` | MEMORY e SPI no `top_tb` estão **parados** (sinais fixos) |
| Makefile (`TEST`, `SEED`, `WAVES`) | alvo de regressão |
| Evidências de outubro | VPLAN v2 |

---

## 3. Como o testbench vai ficar

```
                         minisoc_base_test
                                │
                           minisoc_env
   ┌──────────┬──────────┬──────┴──────────┬───────────────────┐
ref_clk_agt mem_clk_agt rst_agt       mem_agt (NOVO)       spi_agt (NOVO)
 (driver)    (driver)   (driver)   sqr → driver            sqr → driver
                                         monitor ──┐            monitor ──┐
                                                   ▼                      ▼
                         probe_if ──► mem_scoreboard (NOVO)   spi_scoreboard (NOVO)
                      (MEM_SEL_AES)
```

- **driver** = transforma uma transação ("escreva 0xCAFE no endereço 5") em sinais no fio.
- **monitor** = faz o caminho inverso: olha os fios e reconstrói a transação.
- **scoreboard** = compara o que o monitor viu com o que *deveria* acontecer.
  É aqui que mora a "checagem automática".

---

## 3. O que precisa existir no dia 30/11 (escopo mínimo)

Ordem de prioridade — se faltar tempo, corte de baixo para cima.

### 3.1 VIP SPI — **obrigatório**

Arquivos (estrutura do Plano Dia 3, seção 5):

```
verif/tb/agents/spi/
  spi_if.sv  spi_item.sv  spi_cfg.sv  spi_driver.sv
  spi_monitor.sv  spi_sequencer.sv  spi_agent.sv  spi_pkg.sv
verif/tb/sequences/spi/
  spi_write_seq.sv  spi_read_seq.sv  spi_reg_seqs.sv
```

O que cada peça precisa fazer (regras do Block Guide seção 5):

| Peça | Conteúdo |
|---|---|
| `spi_if` | `sclk`, `cs_n`, `mosi`, `miso`. |
| `spi_item` | `op` (WRITE/READ), `addr[5:0]`, `wdata[31:0]`, `rdata[31:0]`; constraint `addr` em 0x00–0x0F/0x3F (e um modo "não mapeado" para 0x10–0x3E). |
| `spi_cfg` | `sclk_period_ns` (default 50 ns = 20 MHz; **mínimo 40 ns = 25 MHz**), gap entre frames, `is_active`. |
| `spi_driver` | Gera o próprio `sclk`. Mode 0: `sclk` em 0 no repouso, MOSI muda com `sclk` baixo, DUT amostra na **subida**. Frame de 40 bits MSB-first: `{RWb, ADDR[5:0], RSV=0, DATA[31:0]}`. **WRITE** = 1 frame. **READ** = 2 frames: request (`RWb=1`, addr) + frame NOP (addr `0x3F`), capturando MISO bits [31:0] do 2º frame. Devolve `rdata` com `put_response()` (decisão do Dia 3: "resposta separada via `get_response()`"). |
| `spi_monitor` | Passivo. Amostra MOSI e MISO na subida de `sclk`; fecha o frame na subida de `cs_n`. Frame com ≠ 40 bits → reporta como abortado. Junta request + NOP em **uma** transação READ com o dado lido. Publica no `analysis_port`. |
| `spi_agent` | Ativo: sequencer + driver + monitor. Passivo: só monitor. |
| Sequences | `spi_write_seq(addr, data)`, `spi_read_seq(addr) → data`, `spi_reg_rw_seq` (escreve e lê de volta). |

> Atenção ao CDC (spec 5.3): o frame é capturado em `sclk` e transportado para
> o `clk` por toggle sync. Deixe um gap entre frames (≥ 1 período de `sclk`
> já é muito mais que os ciclos de 2 GHz necessários).

### 3.2 Checagem local do SPI — **obrigatório** (o checkpoint pede "checagens locais")

`verif/tb/env/spi_scoreboard.sv` (CHK-02 do VPLAN) — modelo simples de
registradores, sem RAL (decisão do Dia 3):

- defaults pós-reset: KEY/IV/COUNTER = 0, `NUM_BLOCKS = 1`, `AES_CONTROL = 0`,
  `SYSTEM_CONTROL`: `MEM_SEL_AES = 0`, `PLL_ENABLE = 0`, `PLL_DIV_SEL = 11`;
- R/W (0x00–0x0B, 0x0E) devolvem o último valor escrito (com máscara de bits válidos);
- RO (0x0C `AES_STATUS`, 0x0D `VERSION` = `0x0001_0100`, 0x0F `SYSTEM_STATUS`) ignoram escrita;
- `START` lê sempre 0; não mapeados (0x10–0x3E) leem 0;
- para `AES_STATUS`/`SYSTEM_STATUS` em novembro basta comparar com o `probe_vif`
  (ou deixar como "não checado" e registrar no VPLAN).

Divergência → `UVM_ERROR`. Leitura do `VERSION` resolve o **OPEN-03**.

### 3.3 VIP MEMORY DATA — **obrigatório**

```
verif/tb/agents/mem/
  mem_if.sv  mem_item.sv  mem_cfg.sv  mem_driver.sv
  mem_monitor.sv  mem_sequencer.sv  mem_agent.sv  mem_pkg.sv
verif/tb/sequences/mem/
  mem_write_seq.sv  mem_read_seq.sv  mem_fill_seq.sv
```

| Peça | Conteúdo |
|---|---|
| `mem_if` | Recebe `mem_clk` como porta (como o `rst_if` recebe `clk`); sinais `mem_i_data[31:0]`, `mem_i_wr_en`, `mem_i_addr[9:0]`, `mem_o_data[31:0]`; sem clocking block nem modport (decisao de 24/11): driver e monitor na subida de `mem_clk`; driver usa atribuicao nao-bloqueante (`<=`) para nao correr com o DUT. O `mem_clk` continua vindo do `mem_clk_agt` que você já tem. |
| `mem_item` | `op` (R/W), `addr[9:0]`, `wdata`, `rdata`. |
| `mem_driver` | Escrita: `wr_en=1` + addr + data por 1 ciclo. Leitura: `wr_en=0` + addr, espera a latência de **1 ciclo** (VPLAN F12) e captura `mem_o_data`. Ociosa: `wr_en=0`. |
| `mem_monitor` | Publica escritas e leituras com o dado de retorno. |
| Sequences | escrita/leitura unitária; `fill` de N palavras; padrões 0, `0xFFFFFFFF`, `0xAAAA5555`, walking-1, aleatório (ST-MEM-01). |

> **Decisão de arquitetura que você vai ter que justificar:** a interface não
> tem sinal de *valid* — com `wr_en = 0` todo ciclo é uma leitura. O monitor
> precisa saber o que é "transação". Opções:
> (a) sinal `tb_valid` só no `mem_if` (não vai ao DUT), dirigido pelo driver — simples e sem ruído;
> (b) monitor publica toda escrita e só leituras com endereço novo — 100% passivo, mais frágil.
> (c) monitor publica **todo ciclo** como transação (escrita se `wr_en = 1`, leitura se `wr_en = 0`) — é o que a RAM faz.
>
> **Decidido em 24/11: (c).** A `mem_if` tem só os sinais do DUT; o monitor é 100% passivo
> (funciona com o agent em modo passivo) e o scoreboard recebe todas as leituras reais.
> Custo: mais transações (leituras vão para o log só em `UVM_HIGH`). Registrar no VPLAN
> o motivo (interface sem handshake, spec 3/7.3).

### 3.4 Checagem local da memória — **obrigatório**

`verif/tb/env/mem_scoreboard.sv` (CHK-04): array associativo como modelo da RAM.
- Escrita com `MEM_SEL_AES = 0` → atualiza o modelo.
- Escrita com `MEM_SEL_AES = 1` → **não** atualiza (ownership, F13). Leia `MEM_SEL_AES` do `probe_vif.cfg_mem_sel_aes`.
- Leitura de endereço conhecido → compara; desconhecido → não checa (memória sem reset).

### 3.5 Configuração básica do DUT — **obrigatório**

Uma sequence (ou task no `base_test`) `minisoc_cfg_seq` que, via SPI:
1. lê `VERSION`;
2. escreve `PLL_DIV_SEL` e `PLL_ENABLE = 1` em `SYSTEM_CONTROL`;
3. faz polling de `SYSTEM_STATUS.PLL_LOCKED` com **timeout** (CHK-08);
4. escreve/limpa `MEM_SEL_AES`.

Isso mostra a "configuração básica" e já prepara o fluxo de dezembro
(passos 1–10 do modelo de programação, Block Guide seção 9).

### 3.6 Integração no ambiente

- `top_tb.sv`: trocar os `logic` fixos de SPI e MEMORY por `spi_if` e `mem_if`; publicar `spi_vif`/`mem_vif` no `config_db`.
- `minisoc_env_cfg`: adicionar `spi_cfg` e `mem_cfg`.
- `minisoc_env`: criar `spi_agt`, `mem_agt`, `spi_scb`, `mem_scb` e conectar `monitor.ap → scoreboard` no `connect_phase`.
- `Makefile`: incluir os novos pacotes/`+incdir+`.

### 3.7 Testes de interface — **obrigatório** (pelo menos os 4 primeiros)

Nomes e IDs já definidos no VPLAN v1, seção 8:

| Teste | O que faz | Checker | Prioridade |
|---|---|---|---|
| 3.1 | 🆕 `env/mem_scoreboard.sv` | Um array associativo que imita a RAM. Escrita com `MEM_SEL_AES = 0` → atualiza; com `MEM_SEL_AES = 1` → **não** atualiza. Leitura de endereço já escrito → compara e dá `UVM_ERROR` se divergir; nunca escrito → ignora. `MEM_SEL_AES` vem do `probe_if`. `report_phase`: "N leituras comparadas, M erros". | É a "checagem local" que o marco pede. Sem ela o teste só *mostra* valores; com ela, o teste *julga*. Já nasce pronto para o ownership (Etapa 7). |
| 3.2 | ✏️ `env/minisoc_env.sv` | Cria `mem_scb`, liga `mem_agt.mon.ap → mem_scb`, entrega o `probe_vif`. | É o fio de dados entre a testemunha (monitor) e o juiz (scoreboard). |

✅ **Pronto quando:** T-MEM-RW passa com o scoreboard ativo e 0 erros.

---

### PARTE 2 — SPI

Regras do protocolo (Block Guide 5; RTL `minisoc_spi.sv`):
- frame de **40 bits**, MSB primeiro: `{RWb, ADDR[5:0], RSV=0, DATA[31:0]}`;
- **Mode 0:** `sclk` parado em 0; MOSI muda com `sclk` baixo; o DUT lê na **subida**;
- **escrita** = 1 frame (`RWb = 0`);
- **leitura** = 2 frames: pedido (`RWb = 1`, endereço) + frame NOP
  (`RWb = 0`, endereço `0x3F`). O dado sai no MISO durante o NOP, bits [31:0];
- `sclk` ≤ 25 MHz → padrão 20 MHz (meio período de 25 ns); intervalo entre frames
  para a sincronização interna (CDC).

#### Etapa 4 — VIP SPI

| # | Arquivo | O que contém | Por quê |
|---|---|---|---|
| 4.1 | 🆕 `agents/spi/spi_if.sv` | `sclk`, `cs_n`, `mosi`, `miso`; repouso `cs_n = 1`, `sclk = 0`. | Conector físico, como o `mem_if`. |
| 4.2 | 🆕 `agents/spi/spi_item.sv` | `op` (WRITE/READ), `addr[5:0]`, `data[31:0]`, `rdata[31:0]`; `convert2string()`. | A "palavra" do SPI: "ler o registrador X". |
| 4.3 | 🆕 `agents/spi/spi_cfg.sv` | `vif`, `is_active`, `sclk_half_ns` (25), `gap_ns`; `is_valid()` recusa `sclk` > 25 MHz. | Parâmetros fora do código e proteção contra violar a spec. |
| 4.4 | 🆕 `agents/spi/spi_driver.sv` | Task `transfer(tx40, rx40)` (como a `spi_transfer` do projetista). WRITE chama 1 vez; READ chama 2 vezes e guarda `rx[31:0]` em `rdata`. Devolve com `put_response()`. | É quem "fala SPI" e **esconde o frame NOP** do teste. `put_response` foi decisão do Plano Dia 3. |
| 4.5 | 🆕 `agents/spi/spi_monitor.sv` | Na subida de `sclk` guarda MOSI e MISO; na subida de `cs_n` fecha o frame. Frame ≠ 40 bits → aviso "abortado". Junta pedido + NOP numa só transação READ. Publica no `analysis_port`. | Testemunha independente. Juntar os 2 frames mantém a abstração do lado de quem observa. |
| 4.6 | 🆕 `agents/spi/spi_agent.sv` | Sequencer + driver + monitor. | Igual ao `mem_agent`. |
| 4.7 | 🆕 `agents/spi/spi_pkg.sv` | Pacote com 4.2–4.6. | — |
| 4.8 | ✏️ `top_tb.sv`, `env/*`, `tests/minisoc_base_test.sv`, `Makefile` | Mesmo roteiro da 1.8–1.10, agora para `spi_if` / `spi_agt`. | — |

✅ **Pronto quando:** `make compile` passa e os testes anteriores continuam PASS.

#### Etapa 5 — Sequences SPI + teste de reset

| # | Arquivo | O que contém | Por quê |
|---|---|---|---|
| 5.1 | 🆕 `sequences/spi/spi_write_seq.sv` | `addr`, `data` → 1 WRITE. | Bloco básico. |
| 5.2 | 🆕 `sequences/spi/spi_read_seq.sv` | `addr` → 1 READ, devolve `rdata`. | Bloco básico. |
| 5.3 | ✏️ `sequences/minisoc_seq_pkg.sv` | Inclui as sequences SPI. | — |
| 5.4 | 🆕 `tests/minisoc_rst_default_test.sv` | **T-RST-DEFAULT:** após o reset, lê todos os registradores pelo SPI. | Prova que o SPI funciona de ponta a ponta e que o DUT sai do reset com os valores da spec. |

✅ **Pronto quando:** o log mostra `VERSION = 0x0001_0100` lido pelo SPI.

#### Etapa 6 — Checagem local do SPI

| # | Arquivo | O que contém | Por quê |
|---|---|---|---|
| 6.1 | 🆕 `env/spi_scoreboard.sv` | Um "espelho" dos 16 registradores. WRITE → atualiza (respeitando máscaras e read-only); READ → compara e dá `UVM_ERROR` se divergir. `report_phase` com o total. | Checagem local do SPI. |
| 6.2 | ✏️ `env/minisoc_env.sv` | Cria `spi_scb` e liga `spi_agt.mon.ap → spi_scb`. | — |
| 6.3 | 🆕 `tests/minisoc_spi_reg_test.sv` | **T-SPI-REG:** escreve e lê de volta todos os endereços com valores fixos (0, `0xFFFFFFFF`, walking-1) e aleatórios. | Exercita todas as regras do espelho. |

Regras do espelho (lidas no RTL):

| Endereço | Registro | Reset | Leitura |
|---|---|---|---|
| 0x00–0x09 | KEY, IV, COUNTER | 0 | 32 bits, o que foi escrito |
| 0x0A | NUM_BLOCKS | 1 | só bits [8:0] |
| 0x0B | AES_CONTROL | 0 | bits [4:1] (MODE, DECRYPT); **START sempre lê 0** |
| 0x0C | AES_STATUS | 0 | read-only |
| 0x0D | VERSION | `0x0001_0100` | read-only, constante |
| 0x0E | SYSTEM_CONTROL | `0b1100` | bits [3:0]: `PLL_DIV_SEL`, `PLL_ENABLE`, `MEM_SEL_AES` |
| 0x0F | SYSTEM_STATUS | 0 | read-only (`PLL_LOCKED`) |
| 0x10–0x3E | não mapeados | — | lê 0, escrita ignorada |

> **Cuidado no T-SPI-REG:** escrever `START = 1` ou `PLL_ENABLE = 1` dispara
> comportamento no DUT. O teste escreve `AES_CONTROL` sempre com `START = 0` e,
> em `SYSTEM_CONTROL`, mantém `PLL_ENABLE = 0` (o PLL é testado na Etapa 7).

✅ **Pronto quando:** T-RST-DEFAULT e T-SPI-REG passam com 0 erros.

---

### PARTE 3 — Integração e configuração do DUT

#### Etapa 7 — Configuração básica + ownership

| # | Arquivo | O que contém | Por quê |
|---|---|---|---|
| 7.1 | 🆕 `sequences/minisoc_cfg_seq.sv` | Via SPI: lê `VERSION` → escreve `PLL_DIV_SEL` + `PLL_ENABLE = 1` → lê `SYSTEM_STATUS` em loop até `PLL_LOCKED = 1` (com **limite de tentativas** → `UVM_FATAL`) → ajusta `MEM_SEL_AES`. | É o item "configuração básica do DUT": passos 1–10 do modelo de programação (Block Guide 9). Em dezembro só se acrescenta "START → esperar DONE". |
| 7.2 | 🆕 `tests/minisoc_pll_bringup_test.sv` | **T-PLL-BRINGUP (básico):** roda 7.1 nos 4 divisores (/1, /2, /4, /8), desligando o PLL entre eles. | Mostra o DUT sendo configurado de verdade. O limite evita simulação travada se o PLL nunca travar. |
| 7.3 | ✏️ `tests/minisoc_mem_rw_test.sv` | **T-MEM-RW (parte 2, ownership):** via SPI põe `MEM_SEL_AES = 1`, tenta escrever pela memória, volta para 0 e confere que **o valor antigo continuou lá**. | Junta os dois VIPs num teste só (REQ-MEM-03: um dono por vez). É o caminho de dezembro: SPI configura, memória carrega/lê. |

✅ **Pronto quando:** `PLL_LOCKED = 1` nos 4 divisores e T-MEM-RW passa com ownership.

#### Etapa 8 — Assertions e regressão

| # | Arquivo | O que contém | Por quê |
|---|---|---|---|
| 8.1 | ✏️ `top_assertions.sv` | **A-09:** com `cs_n = 0`, período de `sclk` ≥ 40 ns. **A-10:** com `MEM_SEL_AES = 0`, endereço/dado/`wr_en` sem X/Z na subida de `mem_clk`. | Checagem com pouco código. A-09 vigia o *próprio* testbench. |
| 8.2 | ✏️ `Makefile` | `make regress`: roda todos os testes com 3 seeds e imprime tabela PASS/FAIL. | Evidência fácil; a regressão só é exigida em dezembro, então é ponto a favor. |
| 8.3 | 🆕 `tests/minisoc_spi_abort_test.sv` *(opcional)* | **T-SPI-ABORT:** frames interrompidos no meio + frames válidos; nenhum registrador pode mudar. | Robustez, se sobrar tempo. |

### Fica para dezembro (registrar no VPLAN v2)

Monitor/checker completo do PLL (período do `sys_clk`, janela de lock), virtual
sequencer, covergroups e tudo do AES (monitor, refmod, scoreboard).

---

## 6. Resumo

**~24 arquivos novos · 8 alterados** (`top_tb`, `env_cfg`, `env`, `env_pkg`,
`base_test`, `test_pkg`, `Makefile`, `top_assertions`).

| Teste | Etapa | Verifica | Checker |
|---|---|---|---|
| `minisoc_smoke_test` | — | clock + reset (já existe) | SVA A-01 |
| `minisoc_mem_rw_test` | 2–3, 7 | memória + ownership | mem_scoreboard |
| `minisoc_rst_default_test` | 5 | valores de reset via SPI | spi_scoreboard |
| `minisoc_spi_reg_test` | 6 | todos os registradores | spi_scoreboard |
| `minisoc_pll_bringup_test` | 7 | PLL trava nos 4 divisores | limite + leitura |
| `minisoc_spi_abort_test` | 8 (opcional) | frame interrompido | spi_scoreboard |

**Prioridade se o tempo acabar:** Etapas 1–3 (memória) → 4–6 (SPI) → 7 → 8.
Memória + SPI com scoreboard é o núcleo; o resto é bônus.

---

## 7. Decisões de arquitetura (o que a banca vai perguntar)

| Decisão | Por quê |
|---|---|
| Memória antes do SPI | Protocolo mais simples e independente (`MEM_SEL_AES = 0` no reset); serve de modelo para o SPI. |
| MEM e SPI têm sequencer; clk/rst não | MEM/SPI têm transações com conteúdo e ordem; clock e reset são só parâmetros. |
| `tb_valid` no `mem_if` | A interface não tem *valid*; sem ele o monitor veria "leituras fantasmas" todo ciclo. |
| Leitura SPI é 1 item, mas são 2 frames | Abstração: o teste pensa em registrador; driver e monitor cuidam do protocolo. |
| clk/rst como *agents* (o Dia 3 dizia "só driver") | Padrão uniforme, reuso (2 `clk_agent`) e fácil tornar passivo. |
| Scoreboard próprio, sem RAL | 16 registros, prazo curto, controle total das regras. RAL é evolução futura. |
| `MEM_SEL_AES` lido do `probe_if` | Sinal interno; o scoreboard precisa saber quem é o dono no instante do acesso. |
| `UVM_ERROR` × `UVM_FATAL` | Dado errado = ERROR (continua achando mais). Ambiente quebrado / timeout = FATAL. |

---

## 8. Depois do código: VPLAN v2, evidências, apresentação

**VPLAN v2** (`verif/doc/CI-Expert_Fase2_Verification_Plan_v2.docx`): versão
V2.0; VCS `X-2025.06-SP2` e `UVM-1.2`; diagrama novo; decisões da seção 7;
F01, F08, F09, F12, F13 (e F05) → `IMPLEMENTADO` com o log; OPEN-03 fechado
com o `VERSION` lido; lista do que foi para dezembro.

**Evidências** (`verif/doc/evidencias/novembro/`): logs com `TEST PASSED`;
saída do `make regress`; print do Verdi de uma escrita/leitura na memória e de
um WRITE e um READ SPI; trecho do scoreboard ("N comparadas, 0 erros"); **uma
falha provocada de propósito** (prova de que o scoreboard não está "dormindo").

**Slides (6–8):** outubro → novembro · arquitetura · VIP MEMORY · VIP SPI ·
checagens · configuração do DUT + ownership · testes + regressão + VPLAN ·
plano de dezembro.

---

## 9. Aprovação

Marque cada item. Os marcados "Ajustar" eu reescrevo antes de começar.

| # | Decisão | Aprovo | Ajustar |
|---|---|---|---|
| 1 | Tudo hoje, numa sessão, na ordem das Etapas 1 → 8 | [ ] | [ ] |
| 2 | Memória (Etapas 1–3) antes do SPI (4–6); integração por último (7) | [ ] | [ ] |
| 3 | `tb_valid` no `mem_if` para o monitor da memória | [ ] | [ ] |
| 4 | Scoreboard próprio de registradores, sem RAL | [ ] | [ ] |
| 5 | Sequences em `sequences/` com pacote próprio `minisoc_seq_pkg` | [ ] | [ ] |
| 6 | Checker completo do PLL vai para dezembro (registrado no VPLAN v2) | [ ] | [ ] |
| 7 | **Modo de execução:** ao fim de cada etapa eu rodo `make compile run`, te mostro o resultado e deixo tudo *staged* para você revisar — sem commit/push meu | [ ] | [ ] |

**Decisão final:** [ ] Aprovo a execução do plano  [ ] Não aprovo / ajustar antes
