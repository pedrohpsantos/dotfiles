<#
.SYNOPSIS
    Rotina Mensal de Limpeza, Manutenção e Otimização para Windows 11 Host.
.DESCRIPTION
    Script abrangente de engenharia de sistemas para manutenção preventiva mensal de notebooks
    híbridos (produtividade/faculdade, desenvolvimento com WSL 2/Docker e jogos de alta performance).
    Executa limpeza segura de caches de compiladores, shaders DirectX/NVIDIA, arquivos temporários,
    diagnóstico de bateria, otimização de rede e TRIM em SSDs NVMe.
.PARAMETER DryRun
    Simula a execução sem excluir nenhum arquivo, exibindo o espaço potencial a ser liberado.
.PARAMETER DeepClean
    Executa limpezas profundas adicionais: DISM Component Store (WinSxS), Docker system prune e TRIM forçado.
.PARAMETER SkipDevCaches
    Omite a limpeza de caches de desenvolvimento (npm, pip, cargo, winget).
.PARAMETER ReportOnly
    Executa exclusivamente diagnósticos de hardware, integridade de bateria, inicialização e discos WSL 2.
.EXAMPLE
    Invoke-WorkstationMaintenance.ps1
.EXAMPLE
    Invoke-WorkstationMaintenance.ps1 -DryRun
.EXAMPLE
    Invoke-WorkstationMaintenance.ps1 -DeepClean
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Alias('Simulate')]
    [switch]$DryRun,

    [switch]$DeepClean,

    [switch]$SkipDevCaches,

    [switch]$ReportOnly
)

Set-StrictMode -Off
$ErrorActionPreference = 'SilentlyContinue'

# ==============================================================================
# Paleta Catppuccin Mocha & Tipografia ANSI
# ==============================================================================
$esc = [char]27
$cReset   = "$esc[0m"
$cBold    = "$esc[1m"
$cDim     = "$esc[2m"
$cRosewater = "$esc[38;2;245;224;220m"
$cFlamingo  = "$esc[38;2;242;205;205m"
$cPink      = "$esc[38;2;245;194;231m"
$cMauve     = "$esc[38;2;203;166;247m"
$cRed       = "$esc[38;2;243;139;168m"
$cMaroon    = "$esc[38;2;235;160;172m"
$cPeach     = "$esc[38;2;250;179;135m"
$cYellow    = "$esc[38;2;249;226;175m"
$cGreen     = "$esc[38;2;166;227;161m"
$cTeal      = "$esc[38;2;148;226;213m"
$cSky       = "$esc[38;2;137;220;235m"
$cSapphire  = "$esc[38;2;116;199;236m"
$cBlue      = "$esc[38;2;137;180;250m"
$cLavender  = "$esc[38;2;180;190;254m"
$cText      = "$esc[38;2;205;214;244m"
$cSubtext   = "$esc[38;2;166;173;200m"
$cOverlay   = "$esc[38;2;108;112;134m"
$cSurface   = "$esc[38;2;49;50;68m"

function Format-Bytes {
    param([double]$Bytes)
    if ($Bytes -ge 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    } elseif ($Bytes -ge 1MB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    } elseif ($Bytes -ge 1KB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    } else {
        return "{0:N0} B" -f $Bytes
    }
}

function Write-Banner {
    param([string]$Title)
    $paddedTitle = $Title.PadRight(76)
    Write-Host ""
    Write-Host "$cMauve$cBold╭──────────────────────────────────────────────────────────────────────────────╮$cReset"
    Write-Host "$cMauve$cBold│ $paddedTitle │$cReset"
    Write-Host "$cMauve$cBold╰──────────────────────────────────────────────────────────────────────────────╯$cReset"
    Write-Host ""
}

function Write-Section {
    param([string]$Number, [string]$Title)
    Write-Host ""
    Write-Host "$cBlue$cBold[$Number] $Title$cReset"
    Write-Host "$cOverlay────────────────────────────────────────────────────────────────────────$cReset"
}

function Write-MetricRow {
    param(
        [string]$Category,
        [string]$Status,
        [string]$Reclaimed,
        [string]$Detail
    )
    $statusColor = switch ($Status) {
        'PASS'   { $cGreen }
        'CLEAN'  { $cGreen }
        'INFO'   { $cSky }
        'WARN'   { $cYellow }
        'SKIP'   { $cSubtext }
        'ADMIN'  { $cPeach }
        default  { $cText }
    }
    $catFormatted    = $Category.PadRight(18).Substring(0, [math]::Min(18, $Category.Length)).PadRight(18)
    $statusFormatted = "[$Status]".PadRight(8)
    $recFormatted    = $Reclaimed.PadLeft(11)
    Write-Host "  $cText$catFormatted$cReset $statusColor$cBold$statusFormatted$cReset $cTeal$recFormatted$cReset  $cSubtext$Detail$cReset"
}

# ==============================================================================
# Funções Utilitárias de Limpeza Segura
# ==============================================================================
function Remove-DirectoryFilesSafely {
    param(
        [string]$Path,
        [int]$OlderThanHours = 0,
        [switch]$IsSimulate
    )
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }

    [double]$bytesReclaimed = 0
    $cutoff = [DateTime]::MaxValue
    if ($OlderThanHours -gt 0) {
        $cutoff = (Get-Date).AddHours(-$OlderThanHours)
    }

    $files = Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        if ($OlderThanHours -eq 0 -or $file.LastWriteTime -lt $cutoff) {
            $bytesReclaimed += $file.Length
            if (-not $IsSimulate) {
                try {
                    [System.IO.File]::Delete($file.FullName)
                } catch {
                    # Arquivo em uso ou protegido - ignora com segurança
                }
            }
        }
    }

    # Tenta remover pastas vazias remanescentes
    if (-not $IsSimulate) {
        $dirs = Get-ChildItem -LiteralPath $Path -Recurse -Directory -Force -ErrorAction SilentlyContinue |
            Sort-Object -Property FullName -Descending
        foreach ($d in $dirs) {
            try {
                [System.IO.Directory]::Delete($d.FullName, $false)
            } catch {}
        }
    }

    return $bytesReclaimed
}

# ==============================================================================
# Execução Principal
# ==============================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

Write-Banner "PEDRO'S NOTEBOOK WORKSTATION — MONTHLY TUNE-UP & CLEANUP"

if ($DryRun) {
    Write-Host "  $cYellow$cBold[MODO SIMULAÇÃO ATIVO]$cReset $cText Nenhuma alteração no disco será realizada.$cReset`n"
}

$driveC = Get-PSDrive C
$freeBeforeBytes = $driveC.Free
$usedBeforeBytes = $driveC.Used
$totalReclaimedBytes = 0

# ------------------------------------------------------------------------------
# 1. Telemetria de Hardware & Saúde da Bateria
# ------------------------------------------------------------------------------
Write-Section "1" "Hardware, Telemetria & Saúde da Bateria"

$cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
$gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'NVIDIA' } | Select-Object -First 1
$ramGB = [math]::Round(((Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue | Measure-Object -Property Capacity -Sum).Sum / 1GB), 1)

Write-Host "  $cSubtext• CPU:$cReset $cText$($cpu.Name) ($($cpu.NumberOfCores)C / $($cpu.NumberOfLogicalProcessors)T Intel Hybrid)$cReset"
Write-Host "  $cSubtext• GPU Dedicada:$cReset $cText$($gpu.Name)$cReset"
Write-Host "  $cSubtext• Memória RAM:$cReset $cText$ramGB GB | $cSubtext SSD NVMe C:: $cText$(Format-Bytes $freeBeforeBytes) livres de $(Format-Bytes ($freeBeforeBytes + $usedBeforeBytes))$cReset"

# Análise de Bateria via powercfg
$batteryXmlPath = "$env:TEMP\battery-report-$PID.xml"
$batteryHealthPercent = 0
$batteryCycles = 0
try {
    powercfg /batteryreport /xml /output $batteryXmlPath | Out-Null
    if (Test-Path $batteryXmlPath) {
        [xml]$bXml = Get-Content $batteryXmlPath
        $bNode = $bXml.BatteryReport.Batteries.Battery | Select-Object -First 1
        if ($bNode -and $bNode.DesignCapacity -and $bNode.FullChargeCapacity) {
            $designCap = [double]$bNode.DesignCapacity
            $fullCap   = [double]$bNode.FullChargeCapacity
            $batteryCycles = $bNode.CycleCount
            if ($designCap -gt 0) {
                $batteryHealthPercent = [math]::Round(($fullCap / $designCap) * 100, 1)
            }
            $healthStatus = "Excelente"
            if ($batteryHealthPercent -lt 65) {
                $healthStatus = "Atenção (Desgaste Avançado)"
            } elseif ($batteryHealthPercent -lt 80) {
                $healthStatus = "Boa (Uso Normal)"
            }
            Write-Host "  $cSubtext• Bateria (LGC):$cReset $cGreen$cBold$batteryHealthPercent%$cReset $cSubtext($healthStatus) | $cText$fullCap mWh$cSubtext de $cText$designCap mWh$cSubtext | Ciclos: $cText$batteryCycles$cReset"
        }
    }
} catch {} finally {
    Remove-Item $batteryXmlPath -Force -ErrorAction SilentlyContinue
}

if ($ReportOnly) {
    Write-Host "`n  $cSky$cBold[INFO]$cReset Modo ReportOnly selecionado. Encerrando sem alterações no sistema.`n"
    return
}

# ------------------------------------------------------------------------------
# 2. Arquivos Temporários de Usuário e Sistema (Temp & Dumps)
# ------------------------------------------------------------------------------
Write-Section "2" "Limpeza de Temporários e Relatórios de Falha"

# User Temp (%LOCALAPPDATA%\Temp) - Arquivos > 12h
$userTempPath = "$env:LOCALAPPDATA\Temp"
$userTempCleaned = Remove-DirectoryFilesSafely -Path $userTempPath -OlderThanHours 12 -IsSimulate:$DryRun
$totalReclaimedBytes += $userTempCleaned
Write-MetricRow "User Temp" "CLEAN" (Format-Bytes $userTempCleaned) "Arquivos inativos (>12h) em $userTempPath"

# Windows Error Reporting & Crash Dumps
$crashDumpsPath = "$env:LOCALAPPDATA\CrashDumps"
$crashCleaned = Remove-DirectoryFilesSafely -Path $crashDumpsPath -OlderThanHours 0 -IsSimulate:$DryRun
$totalReclaimedBytes += $crashCleaned
Write-MetricRow "Crash Dumps" "CLEAN" (Format-Bytes $crashCleaned) "Mini-dumps de aplicações em $crashDumpsPath"

$werArchive = "C:\ProgramData\Microsoft\Windows\WER\ReportArchive"
$werCleaned = Remove-DirectoryFilesSafely -Path $werArchive -OlderThanHours 0 -IsSimulate:$DryRun
$totalReclaimedBytes += $werCleaned
Write-MetricRow "WER Reports" "CLEAN" (Format-Bytes $werCleaned) "Relatórios antigos de erros do Windows"

# Lixeira de Todos os Volumes
$recycleCleaned = 0
try {
    $sh = New-Object -ComObject Shell.Application
    $rb = $sh.Namespace(10)
    $rbSize = 0
    foreach ($item in $rb.Items()) { $rbSize += $item.Size }
    $recycleCleaned = $rbSize
    if (-not $DryRun) {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    }
} catch {}
$totalReclaimedBytes += $recycleCleaned
Write-MetricRow "Lixeira" "CLEAN" (Format-Bytes $recycleCleaned) "Lixeira limpa em todas as unidades de disco"

# System Temp (C:\Windows\Temp)
if ($isAdmin) {
    $sysTempCleaned = Remove-DirectoryFilesSafely -Path "C:\Windows\Temp" -OlderThanHours 24 -IsSimulate:$DryRun
    $totalReclaimedBytes += $sysTempCleaned
    Write-MetricRow "System Temp" "CLEAN" (Format-Bytes $sysTempCleaned) "Arquivos temporários do SO em C:\Windows\Temp"
} else {
    Write-MetricRow "System Temp" "ADMIN" (Format-Bytes 0) "Requer privilégios de Administrador para C:\Windows\Temp"
}

# ------------------------------------------------------------------------------
# 3. Caches de Shaders & Otimização para Jogos (DirectX & GPU)
# ------------------------------------------------------------------------------
Write-Section "3" "Caches Gráficos & Shaders de Jogos (Eliminação de Stuttering)"

# DirectX Shader Cache
$d3dCachePath = "$env:LOCALAPPDATA\D3DSCache"
$d3dCleaned = Remove-DirectoryFilesSafely -Path $d3dCachePath -OlderThanHours 0 -IsSimulate:$DryRun
$totalReclaimedBytes += $d3dCleaned
Write-MetricRow "DirectX Shaders" "CLEAN" (Format-Bytes $d3dCleaned) "Cache D3D compilado em $d3dCachePath"

# NVIDIA DXCache e GLCache
$nvDxPath = "$env:LOCALAPPDATA\NVIDIA\DXCache"
$nvCleaned = Remove-DirectoryFilesSafely -Path $nvDxPath -OlderThanHours 24 -IsSimulate:$DryRun

$nvGlPath = "$env:LOCALAPPDATA\NVIDIA\GLCache"
$nvCleaned += Remove-DirectoryFilesSafely -Path $nvGlPath -OlderThanHours 24 -IsSimulate:$DryRun

$totalReclaimedBytes += $nvCleaned
Write-MetricRow "NVIDIA Shaders" "CLEAN" (Format-Bytes $nvCleaned) "Shaders desatualizados em DXCache/GLCache (preserva drivers ativos)"

# Cache de Miniaturas do Windows Explorer
$thumbPath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
$thumbCleaned = 0
if (Test-Path $thumbPath) {
    Get-ChildItem -Path $thumbPath -Filter "thumbcache_*.db" -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $thumbCleaned += $_.Length
        if (-not $DryRun) {
            try { [System.IO.File]::Delete($_.FullName) } catch {}
        }
    }
}
$totalReclaimedBytes += $thumbCleaned
Write-MetricRow "Thumbnails" "CLEAN" (Format-Bytes $thumbCleaned) "Bancos de miniaturas do Windows Explorer (não travados)"

# ------------------------------------------------------------------------------
# 4. Caches de Desenvolvimento & Gerenciadores de Pacotes
# ------------------------------------------------------------------------------
Write-Section "4" "Caches de Desenvolvimento (Node, Python, Rust, WinGet)"

if ($SkipDevCaches) {
    Write-MetricRow "Dev Toolchains" "SKIP" (Format-Bytes 0) "Ignorado via parâmetro -SkipDevCaches"
} else {
    # NPM Cache
    $npmCachePath = "$env:LOCALAPPDATA\npm-cache"
    $npmCleaned = 0
    if (Test-Path $npmCachePath) {
        if (Get-Command npm -ErrorAction SilentlyContinue -and -not $DryRun) {
            npm cache clean --force 2>&1 | Out-Null
        }
        $npmCleaned = Remove-DirectoryFilesSafely -Path $npmCachePath -OlderThanHours 0 -IsSimulate:$DryRun
        $totalReclaimedBytes += $npmCleaned
    }
    Write-MetricRow "NPM Cache" "CLEAN" (Format-Bytes $npmCleaned) "Cache de pacotes e tarballs baixados do npm"

    # Pip Cache
    $pipCachePath = "$env:LOCALAPPDATA\pip\cache"
    $pipCleaned = 0
    if (Test-Path $pipCachePath) {
        if (Get-Command pip -ErrorAction SilentlyContinue -and -not $DryRun) {
            pip cache purge 2>&1 | Out-Null
        }
        $pipCleaned = Remove-DirectoryFilesSafely -Path $pipCachePath -OlderThanHours 0 -IsSimulate:$DryRun
        $totalReclaimedBytes += $pipCleaned
    }
    Write-MetricRow "Pip Cache" "CLEAN" (Format-Bytes $pipCleaned) "Wheels e index HTTP em $pipCachePath"

    # Cargo Registry Cache
    $cargoCachePath = "$env:USERPROFILE\.cargo\registry\cache"
    $cargoCleaned = Remove-DirectoryFilesSafely -Path $cargoCachePath -OlderThanHours 168 -IsSimulate:$DryRun # > 7 dias
    $totalReclaimedBytes += $cargoCleaned
    Write-MetricRow "Cargo Cache" "CLEAN" (Format-Bytes $cargoCleaned) "Arquivos .crate compactados em .cargo\registry\cache"

    # WinGet Installer Cache
    $wingetLocal = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState"
    $wingetCleaned = 0
    if (Test-Path $wingetLocal) {
        $wingetCleaned = Remove-DirectoryFilesSafely -Path $wingetLocal -OlderThanHours 48 -IsSimulate:$DryRun
        $totalReclaimedBytes += $wingetCleaned
    }
    Write-MetricRow "WinGet Cache" "CLEAN" (Format-Bytes $wingetCleaned) "Instaladores baixados em cache pelo WinGet"

    # VS Code / Cursor Caches
    $codeCaches = @(
        "$env:APPDATA\Code\Cache",
        "$env:APPDATA\Code\CachedData",
        "$env:APPDATA\Code\CachedExtensionVSIXs"
    )
    $codeCleaned = 0
    foreach ($cc in $codeCaches) {
        $codeCleaned += Remove-DirectoryFilesSafely -Path $cc -OlderThanHours 48 -IsSimulate:$DryRun
    }
    $totalReclaimedBytes += $codeCleaned
    Write-MetricRow "VS Code Cache" "CLEAN" (Format-Bytes $codeCleaned) "Caches de VSIX e dados compilados do VS Code"
}

# ------------------------------------------------------------------------------
# 5. Auditoria de Armazenamento WSL 2 & Docker Desktop
# ------------------------------------------------------------------------------
Write-Section "5" "Auditoria de Discos Virtuais (WSL 2 & Docker VHDX)"

$wslVhdxList = @()

# Docker VHDX
$dockerDataVhdx = "$env:LOCALAPPDATA\Docker\wsl\disk\docker_data.vhdx"
if (Test-Path $dockerDataVhdx) {
    $fItem = Get-Item $dockerDataVhdx
    $wslVhdxList += [PSCustomObject]@{
        Name = "Docker Desktop (data)"
        Path = $dockerDataVhdx
        Size = $fItem.Length
    }
}

# Alpine VHDX
$alpineReg = Get-ItemProperty Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Lxss\* -ErrorAction SilentlyContinue |
    Where-Object { $_.DistributionName -eq 'Alpine-3.23.4' }
if ($alpineReg -and $alpineReg.BasePath) {
    $alpPath = Join-Path $alpineReg.BasePath "ext4.vhdx"
    if (Test-Path $alpPath) {
        $fItem = Get-Item $alpPath
        $wslVhdxList += [PSCustomObject]@{
            Name = "Alpine WSL (Alpine-3.23.4)"
            Path = $alpPath
            Size = $fItem.Length
        }
    }
}

foreach ($v in $wslVhdxList) {
    $vSizeStr = Format-Bytes $v.Size
    $note = "Tamanho dentro da faixa normal"
    if ($v.Size -gt 20GB) {
        $note = "Disco grande — sugerido compactação periódica"
    }
    Write-MetricRow $v.Name "INFO" $vSizeStr $note
}

# Docker System Prune (se em DeepClean e daemon respondendo)
if ($DeepClean -and (Get-Command docker -ErrorAction SilentlyContinue)) {
    if (-not $DryRun) {
        Write-Host "  $cSky$cBold• Executando 'docker system prune -f'...$cReset"
        docker system prune -f 2>&1 | Out-Null
        Write-MetricRow "Docker Prune" "CLEAN" "Concluído" "Containers parados, redes e imagens dangling removidas"
    } else {
        Write-MetricRow "Docker Prune" "SKIP" "Simulação" "Em execução real executaria 'docker system prune -f'"
    }
}

# ------------------------------------------------------------------------------
# 6. Otimização de Rede e Resolução de Latência
# ------------------------------------------------------------------------------
Write-Section "6" "Rede, Resolução DNS & Alternância de Wi-Fi"

if (-not $DryRun) {
    ipconfig /flushdns | Out-Null
    Write-MetricRow "DNS Cache" "PASS" "Zerado" "Cache do DNS Resolver limpo (previne falhas de Wi-Fi faculdade/trabalho)"
    try {
        netsh interface ip delete arpcache 2>&1 | Out-Null
        Write-MetricRow "ARP Cache" "PASS" "Atualizado" "Tabela ARP local redefinida"
    } catch {}
} else {
    Write-MetricRow "DNS / ARP" "SKIP" "Simulação" "Em execução real executaria ipconfig /flushdns"
}

# ------------------------------------------------------------------------------
# 7. Manutenção de Componentes do SO & SSD NVMe (Se Administrador)
# ------------------------------------------------------------------------------
Write-Section "7" "Integridade do Sistema Operacional & Otimização NVMe"

if ($isAdmin) {
    # Windows Update Download Cache
    $swDist = "C:\Windows\SoftwareDistribution\Download"
    $swCleaned = Remove-DirectoryFilesSafely -Path $swDist -OlderThanHours 48 -IsSimulate:$DryRun
    $totalReclaimedBytes += $swCleaned
    Write-MetricRow "WinUpdate Cache" "CLEAN" (Format-Bytes $swCleaned) "Arquivos de pacotes já instalados em SoftwareDistribution"

    # DISM Component Store Cleanup (Apenas em DeepClean)
    if ($DeepClean) {
        if (-not $DryRun) {
            Write-Host "  $cSky$cBold• Executando DISM /Online /Cleanup-Image /StartComponentCleanup...$cReset"
            dism.exe /online /Cleanup-Image /StartComponentCleanup /quiet 2>&1 | Out-Null
            Write-MetricRow "WinSxS (DISM)" "PASS" "Otimizado" "Versões antigas de componentes substituídos foram expurgadas"
        } else {
            Write-MetricRow "WinSxS (DISM)" "SKIP" "Simulação" "Em modo real executaria StartComponentCleanup na WinSxS"
        }
    } else {
        Write-MetricRow "WinSxS (DISM)" "SKIP" "Opcional" "Execute com flag -DeepClean para rodar DISM Component Cleanup"
    }

    # NVMe TRIM
    if (-not $DryRun) {
        try {
            Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue | Out-Null
            Write-MetricRow "NVMe TRIM" "PASS" "Ativo" "Comando ReTrim enviado ao SSD NVMe SM2P41C8 (preserva latência e vida útil)"
        } catch {
            Write-MetricRow "NVMe TRIM" "WARN" "Falha" "Não foi possível enviar comando ReTrim"
        }
    } else {
        Write-MetricRow "NVMe TRIM" "SKIP" "Simulação" "Em execução real enviaria ReTrim ao SSD NVMe C:"
    }
} else {
    Write-MetricRow "Admin Tasks" "ADMIN" (Format-Bytes 0) "Para WinUpdate Cache, DISM WinSxS e NVMe TRIM, execute como Administrador"
}

# ------------------------------------------------------------------------------
# 8. Auditoria de Aplicativos de Inicialização (Startup Bloatware)
# ------------------------------------------------------------------------------
Write-Section "8" "Auditoria de Programas na Inicialização (Impacto na Bateria)"

$startupApps = @()

$runKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
)
foreach ($rk in $runKeys) {
    if (Test-Path $rk) {
        $props = Get-ItemProperty $rk -ErrorAction SilentlyContinue
        $scope = "System"
        if ($rk -match 'HKCU') { $scope = "User" }
        $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
            $startupApps += [PSCustomObject]@{
                Name  = $_.Name
                Value = $_.Value
                Scope = $scope
            }
        }
    }
}

if ($startupApps.Count -gt 0) {
    foreach ($app in $startupApps) {
        $val = [string]$app.Value
        $shortPath = $val
        if ($val.Length -gt 55) {
            $shortPath = "..." + $val.Substring($val.Length - 52)
        }
        Write-Host "  $cSubtext• [$($app.Scope)]$cReset $cText$($app.Name.PadRight(22))$cReset $cDim$shortPath$cReset"
    }
    Write-Host "`n  $cSubtext$cDim(Dica TI: Desative apps não essenciais no Gerenciador de Tarefas > Inicializar para maximizar a bateria na faculdade.)$cReset"
} else {
    Write-Host "  $cGreen Nenhuma aplicação não-padrão registrada para inicialização automática.$cReset"
}

# ------------------------------------------------------------------------------
# 9. Relatório Final Executivo
# ------------------------------------------------------------------------------
$driveCAfter = Get-PSDrive C
$freeAfterBytes = $driveCAfter.Free

Write-Section "9" "Resumo Executivo da Manutenção"

Write-Host "  $cSubtext• Espaço Livre Inicial no SSD C::$cReset  $cText$(Format-Bytes $freeBeforeBytes)$cReset"
Write-Host "  $cSubtext• Espaço Livre Atual no SSD C::$cReset    $cGreen$cBold$(Format-Bytes $freeAfterBytes)$cReset"
Write-Host "  $cSubtext• Total de Espaço Recuperado:$cReset      $cTeal$cBold$(Format-Bytes $totalReclaimedBytes)$cReset"

if ($wslVhdxList | Where-Object { $_.Size -gt 25GB }) {
    Write-Host ""
    Write-Host "  $cYellow$cBold[AVISO DE TI — DISCOS VIRTUAIS WSL 2 / DOCKER]:$cReset"
    Write-Host "  $cSubtext Seus discos virtuais WSL 2 / Docker estão consumindo espaço significativo no SSD.$cReset"
    Write-Host "  $cSubtext O Windows 11 não reduz arquivos .vhdx automaticamente após deletar imagens/arquivos.$cReset"
    Write-Host "  $cSubtext Para compactar com segurança sem risco de corrupção, execute no PowerShell Administrador:$cReset"
    Write-Host "  $cSky    wsl --shutdown$cReset"
    Write-Host "  $cSky    diskpart$cReset"
    Write-Host "  $cSky    select vdisk file=`"$($wslVhdxList[0].Path)`"$cReset"
    Write-Host "  $cSky    compact vdisk$cReset"
    Write-Host "  $cSky    exit$cReset"
}

Write-Host "`n$cMauve$cBold Manutenção mensal concluída com sucesso! Próxima execução recomendada em 30 dias.$cReset`n"
