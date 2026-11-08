# Guia de Manutenção Mensal e Otimização do Windows 11 Host

> **Ambiente:** Windows 11 (24H2 build 26100+) &bull; 13th Gen Intel Core i5-13420H &bull; NVIDIA GeForce RTX 3050 Laptop GPU (6GB) &bull; 16 GB RAM &bull; NVMe SSD 512GB
> **Periodicidade Recomendada:** 1 vez por mês (rotina preventiva de primeiro fim de semana)
> **Script Automatizado:** [`windows/scripts/Invoke-WorkstationMaintenance.ps1`](../windows/scripts/Invoke-WorkstationMaintenance.ps1) &bull; Alias no PowerShell: `sysclean`

---

## 1. Visão Geral e Filosofia de Engenharia

Notebooks modernos voltados simultaneamente para **mobilidade acadêmica/profissional**, **jogos** e **desenvolvimento de software (WSL 2 e Docker)** sofrem degradação contínua de desempenho e armazenamento por três razões principais:

1. **Expansão Unilateral de Discos Virtuais:** O WSL 2 e o Docker Desktop utilizam discos dinâmicos `.vhdx` (`ext4.vhdx` e `docker_data.vhdx`). Quando containers são removidos ou arquivos deletados dentro do Linux, o Windows **não reduz o tamanho do arquivo no SSD automaticamente**, acumulando facilmente de 30 a 60 GB de espaço "fantasma".
2. **Fragmentação de Shaders Gráficos:** Cada atualização de driver NVIDIA ou patch de jogo gera novos pipelines compilados de DirectX/GL nos diretórios `DXCache` e `D3DSCache`. Caches antigos ou corrompidos geram *micro-stutters* (engasgos de frametime) durante partidas.
3. **Caches Ocultos de Toolchains Dev:** Gerenciadores como `npm`, `pip`, `cargo` e `VS Code` acumulam gigabytes de wheels, tarballs e pacotes que já foram instalados e não precisam persistir indefinidamente no SSD.

> [!IMPORTANT]
> **Segurança e Estabilidade Operacional:**
> Esta rotina **não utiliza scripts destrutivos de "debloat"** que quebrem o Windows Update, desativem o Windows Defender ou corrompam componentes essenciais do sistema operacional. Toda a manutenção baseia-se em APIs oficiais da Microsoft, rotinas de gerenciamento de armazenamento (DISM, Optimize-Volume) e limpeza idempotente de arquivos temporários.

---

## 2. O que o Script `sysclean` Executa

O script [`Invoke-WorkstationMaintenance.ps1`](../windows/scripts/Invoke-WorkstationMaintenance.ps1) é estruturado em 9 módulos modulares:

| Módulo | Escopo de Limpeza / Diagnóstico | Benefício para o Notebook |
| :--- | :--- | :--- |
| **1. Telemetria & Bateria** | Leitura de hardware, espaço C: e relatório XML de bateria (`powercfg`) | Exibe capacidade de projeto, capacidade atual de carga total, ciclos e índice de saúde da bateria. |
| **2. Temporários & Dumps** | `%LOCALAPPDATA%\Temp`, `CrashDumps`, relatórios WER e Lixeira | Remove gigabytes de instaladores e arquivos temporários com mais de 12 horas, ignorando arquivos em uso. |
| **3. Shaders & Gaming** | DirectX (`D3DSCache`), NVIDIA (`DXCache`, `GLCache`) e Miniaturas | Força a recriação limpa de pipelines gráficos, eliminando stutters e quedas de FPS em jogos. |
| **4. Caches Dev** | `npm-cache`, `pip\cache`, `cargo\registry\cache`, `winget` e VS Code | Recupera tipicamente entre 4 GB e 8 GB de pacotes compilados e tarballs redundantes. |
| **5. WSL 2 & Docker VHDX** | Varredura e cálculo de tamanho de discos virtuais `.vhdx` | Monitora o crescimento de `docker_data.vhdx` e `ext4.vhdx`, alertando quando a compactação é recomendada. |
| **6. Rede & DNS** | `ipconfig /flushdns` e redefinição de tabela ARP | Elimina instabilidades de conexão ao alternar entre o Wi-Fi da faculdade, trabalho e residência. |
| **7. SO & NVMe (Admin)** | `DISM StartComponentCleanup`, WinUpdate Cache e NVMe ReTrim | Expulsa backups antigos da pasta `WinSxS` e envia comandos TRIM ao SSD para manter taxas máximas de I/O. |
| **8. Auditoria de Startup** | Mapeamento de chaves de registro `Run` (HKCU / HKLM) | Identifica apps pesados (ex: Docker Desktop) que inicializam com o Windows e drenam a bateria. |
| **9. Resumo Executivo** | Cálculo de delta de espaço livre antes vs. depois | Apresenta relatório consolidado com o total de bytes liberados e recomendações técnicas. |

---

## 3. Como Executar a Rotina Mensal

O script está integrado aos profiles do PowerShell 7 (`pwsh`) e Windows PowerShell 5.1 através do alias `sysclean`.

### 3.1. Execução Padrão (Manutenção de Usuário)
Abra o terminal do PowerShell (WezTerm ou Windows Terminal) e execute:

```powershell
sysclean
```

Limpa caches de desenvolvimento, temporários de usuário, shaders DirectX/NVIDIA, limpa a Lixeira, reseta o DNS e exibe a telemetria completa.

### 3.2. Simulação sem Exclusão (`-DryRun`)
Para auditar quanto espaço pode ser recuperado antes de realizar qualquer alteração física no disco:

```powershell
sysclean -DryRun
```

### 3.3. Manutenção Profunda como Administrador (`-DeepClean`)
Recomendada uma vez por mês com o notebook conectado à tomada:

1. Abra o **PowerShell como Administrador** (botão direito no menu Iniciar > *Terminal (Administrador)*).
2. Execute:
   ```powershell
   sysclean -DeepClean
   ```
3. O parâmetro `-DeepClean` inclui:
   - Limpeza da pasta `C:\Windows\Temp` e downloads do Windows Update (`SoftwareDistribution\Download`).
   - Expurgador de componentes obsoletos do Windows via `DISM /Online /Cleanup-Image /StartComponentCleanup`.
   - Otimização física do SSD NVMe via `Optimize-Volume -DriveLetter C -ReTrim`.
   - `docker system prune -f` para descartar containers parados e camadas anônimas (caso o Docker esteja ativo).

---

## 4. Recomendações de TI para o Perfil do Usuário

### 4.1. Mobilidade, Bateria e Faculdade
- **Desative a Inicialização Automática do Docker Desktop:** O Docker Desktop executa um subsistema WSL 2 em segundo plano consumindo entre 1.5 GB e 3 GB de RAM e mantendo a CPU ativa. Desative a opção *"Start Docker Desktop when you log in"* nas configurações do Docker e inicie-o apenas quando for desenvolver.
- **Cuidados com a Bateria:**
  - O diagnóstico do `sysclean` reporta o índice de saúde baseado no desgaste dos ciclos de carga.
  - Se o notebook tiver suporte a software OEM (ex: Acer Care Center, Lenovo Vantage, ASUS MyASUS, Dell Command), habilite o **Modo de Conservação da Bateria** (limite de carga em 80%) caso use o notebook majoritariamente na tomada.
- **Intel Thread Director:** Em processadores Intel de 13ª Geração híbridos (P-cores para tarefas pesadas e E-cores para tarefas de fundo), deixe o slider de energia do Windows em *"Melhor Eficiência Energética"* ao usar na bateria para forçar navegação e edição de texto para os núcleos eficientes.

### 4.2. Jogos (Gaming) na Tomada
- **Limpeza de Shaders Mensal:** Ao atualizar o driver da NVIDIA RTX 3050 ou instalar atualizações grandes de jogos, execute o `sysclean` para expurgar o cache de shaders compilado para versões antigas. O jogo recompilará os shaders frescos na primeira abertura, prevenindo quedas abruptas de taxa de quadros (*frametime spikes*).
- **SSD com Espaço de Respiro:** Mantenha sempre pelo menos 15% a 20% do SSD NVMe livre (cerca de 70 GB a 90 GB livres). SSDs NVMe que operam acima de 85% de capacidade perdem a capacidade de alocação de SLC Cache dinâmico, reduzindo drasticamente a velocidade de escrita contínua.

### 4.3. Desenvolvimento de Produtos (WSL 2 e Docker)
- **Compactação Manual de Discos VHDX:**
  Se o relatório do `sysclean` indicar que `docker_data.vhdx` ou `ext4.vhdx` ultrapassou 30 GB, execute a rotina de compactação segura:

  ```powershell
  # 1. Encerrar todas as instâncias do WSL
  wsl --shutdown

  # 2. Abrir o utilitário diskpart como Administrador
  diskpart

  # 3. Selecionar o arquivo virtual (exemplo para Docker):
  select vdisk file="C:\Users\pedrohpsantos\AppData\Local\Docker\wsl\disk\docker_data.vhdx"

  # 4. Encolher o arquivo virtual recuperando o espaço liberado
  compact vdisk

  # 5. Sair do diskpart
  exit
  ```
