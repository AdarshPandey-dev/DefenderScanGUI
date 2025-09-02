# Windows Defender Interactive Scan GUI - Adarsh
# Run as Administrator for full functionality

<#
.SYNOPSIS
    Automated Antivirus Scan Script using Windows Defender.

.DESCRIPTION
    This PowerShell script triggers an antivirus scan using Microsoft Defender. 
    It supports Quick Scan, Full Scan, or Signature updates. 
    to run automatically as part of system hardening or incident response.

.PARAMETER ScanType
    Defines the type of scan to perform:
        - QuickScan   : Scans common malware locations (fast, lightweight).
        - FullScan    : Scans all files and running processes on the system.
        - Update Signature  : Allows updating the threat signatures.

.EXAMPLE
    # Run a quick scan
    .\AVScan.ps1 -ScanType QuickScan

    # Run a full system scan
    .\AVScan.ps1 -ScanType FullScan

.AUTOMATION
    - This script can be scheduled with Windows Task Scheduler 
      (e.g., daily/weekly scans).
    - Useful in SOAR/XDR integrations for automated response playbooks.
    - Can be extended to log results or forward events to SIEM tools.

.REQUIREMENTS
    - Windows 10/11 or Windows Server with Microsoft Defender enabled.
    - PowerShell 5.1 or later.
    - Admin privileges recommended for Full Scans.

.NOTES
    Author   : Adarsh Pandey
    Version  : 1.0
    Date     : 2nd Sep, 2025
    Tested   : Windows 11 Pro, Windows Server 2022

#>


# Import required assemblies
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
} catch {
    Write-Error "Failed to load required assemblies. Please ensure .NET Framework is installed."
    exit 1
}

# Global variables
$global:isScanning = $false
$global:scanProcess = $null

# Check if Windows Defender is available
function Test-DefenderAvailability {
    try {
        $service = Get-Service -Name "WinDefend" -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq "Running") {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

# Check if running as administrator
function Test-Administrator {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Defender Scan Manager - Adarsh Pandey"
$form.Size = New-Object System.Drawing.Size(650, 550)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
$form.Icon = [System.Drawing.SystemIcons]::Shield

# Title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Windows Defender Scan Manager - Adarsh Pandey"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(600, 35)
$titleLabel.TextAlign = "MiddleCenter"
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(13, 110, 253)

# Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$statusLabel.Location = New-Object System.Drawing.Point(20, 70)
$statusLabel.Size = New-Object System.Drawing.Size(600, 25)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(108, 117, 125)

# System status
$isAdmin = Test-Administrator
$defenderAvailable = Test-DefenderAvailability

$systemStatusLabel = New-Object System.Windows.Forms.Label
if ($isAdmin -and $defenderAvailable) {
    $systemStatusLabel.Text = "✅ Administrator • Windows Defender Ready"
    $systemStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(25, 135, 84)
} elseif ($defenderAvailable) {
    $systemStatusLabel.Text = "⚠️ Limited Access • Run as Administrator for full features"
    $systemStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 193, 7)
} else {
    $systemStatusLabel.Text = "❌ Windows Defender not available or not running"
    $systemStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
}
$systemStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$systemStatusLabel.Location = New-Object System.Drawing.Point(20, 100)
$systemStatusLabel.Size = New-Object System.Drawing.Size(600, 25)

# Progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 140)
$progressBar.Size = New-Object System.Drawing.Size(600, 30)
$progressBar.Style = "Continuous"
$progressBar.Value = 0

# Progress label
$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Text = "0% Complete"
$progressLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$progressLabel.Location = New-Object System.Drawing.Point(20, 180)
$progressLabel.Size = New-Object System.Drawing.Size(300, 25)

# Buttons panel
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Location = New-Object System.Drawing.Point(20, 220)
$buttonPanel.Size = New-Object System.Drawing.Size(680, 80)

# Quick Scan button
$quickScanBtn = New-Object System.Windows.Forms.Button
$quickScanBtn.Text = "Quick Scan"
$quickScanBtn.Location = New-Object System.Drawing.Point(10, 10)
$quickScanBtn.Size = New-Object System.Drawing.Size(175, 50)
$quickScanBtn.BackColor = [System.Drawing.Color]::FromArgb(13, 110, 253)
$quickScanBtn.ForeColor = [System.Drawing.Color]::White
$quickScanBtn.FlatStyle = "Flat"
$quickScanBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$quickScanBtn.Cursor = "Hand"
$quickScanBtn.FlatAppearance.BorderSize = 0

# Full Scan button
$fullScanBtn = New-Object System.Windows.Forms.Button
$fullScanBtn.Text = "Full Scan"
$fullScanBtn.Location = New-Object System.Drawing.Point(210, 10)
$fullScanBtn.Size = New-Object System.Drawing.Size(175, 50)
$fullScanBtn.BackColor = [System.Drawing.Color]::FromArgb(25, 135, 84)
$fullScanBtn.ForeColor = [System.Drawing.Color]::White
$fullScanBtn.FlatStyle = "Flat"
$fullScanBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$fullScanBtn.Cursor = "Hand"
$fullScanBtn.FlatAppearance.BorderSize = 0

# Update button
$updateBtn = New-Object System.Windows.Forms.Button
$updateBtn.Text = "Update"
$updateBtn.Location = New-Object System.Drawing.Point(410, 10)
$updateBtn.Size = New-Object System.Drawing.Size(175, 50)
$updateBtn.BackColor = [System.Drawing.Color]::FromArgb(255, 193, 7)
$updateBtn.ForeColor = [System.Drawing.Color]::Black
$updateBtn.FlatStyle = "Flat"
$updateBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$updateBtn.Cursor = "Hand"
$updateBtn.FlatAppearance.BorderSize = 0

# Add buttons to panel
$buttonPanel.Controls.AddRange(@($quickScanBtn, $fullScanBtn, $updateBtn))

# Results area
$resultsLabel = New-Object System.Windows.Forms.Label
$resultsLabel.Text = "Scan Results:"
$resultsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$resultsLabel.Location = New-Object System.Drawing.Point(20, 300)
$resultsLabel.Size = New-Object System.Drawing.Size(300, 25)

$resultsBox = New-Object System.Windows.Forms.TextBox
$resultsBox.Location = New-Object System.Drawing.Point(20, 330)
$resultsBox.Size = New-Object System.Drawing.Size(600, 120)
$resultsBox.Multiline = $true
$resultsBox.ScrollBars = "Vertical"
$resultsBox.ReadOnly = $true
$resultsBox.BackColor = [System.Drawing.Color]::White
$resultsBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$resultsBox.Text = "Ready to perform security scan...`r`n"

# Control buttons
$controlPanel = New-Object System.Windows.Forms.Panel
$controlPanel.Location = New-Object System.Drawing.Point(20, 460)
$controlPanel.Size = New-Object System.Drawing.Size(600, 35)

$stopBtn = New-Object System.Windows.Forms.Button
$stopBtn.Text = "Stop Scan"
$stopBtn.Location = New-Object System.Drawing.Point(380, 5)
$stopBtn.Size = New-Object System.Drawing.Size(100, 30)
$stopBtn.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
$stopBtn.ForeColor = [System.Drawing.Color]::White
$stopBtn.FlatStyle = "Flat"
$stopBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$stopBtn.Enabled = $false
$stopBtn.Cursor = "Hand"
$stopBtn.FlatAppearance.BorderSize = 0

$clearBtn = New-Object System.Windows.Forms.Button
$clearBtn.Text = "Clear Log"
$clearBtn.Location = New-Object System.Drawing.Point(500, 5)
$clearBtn.Size = New-Object System.Drawing.Size(100, 30)
$clearBtn.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
$clearBtn.ForeColor = [System.Drawing.Color]::White
$clearBtn.FlatStyle = "Flat"
$clearBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$clearBtn.Cursor = "Hand"
$clearBtn.FlatAppearance.BorderSize = 0

$controlPanel.Controls.AddRange(@($stopBtn, $clearBtn))

# Functions
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $resultsBox.AppendText("[$timestamp] $Message`r`n")
    $resultsBox.SelectionStart = $resultsBox.Text.Length
    $resultsBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Update-Progress {
    param([int]$Percentage, [string]$Status = "")
    $progressBar.Value = [Math]::Min(100, [Math]::Max(0, $Percentage))
    $progressLabel.Text = "$Percentage% Complete"
    if ($Status) {
        $statusLabel.Text = $Status
    }
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-ScanState {
    param([bool]$IsScanning)
    $global:isScanning = $IsScanning
    $quickScanBtn.Enabled = -not $IsScanning
    $fullScanBtn.Enabled = -not $IsScanning
    $updateBtn.Enabled = -not $IsScanning
    $stopBtn.Enabled = $IsScanning
    
    if (-not $IsScanning) {
        Update-Progress -Percentage 0 -Status "Ready"
    }
}

function Start-DefenderScan {
    param([string]$ScanType)
    
    if (-not $defenderAvailable) {
        Write-Log "ERROR: Windows Defender is not available or not running"
        [System.Windows.Forms.MessageBox]::Show(
            "Windows Defender service is not available or not running.`nPlease ensure Windows Defender is enabled and try again.",
            "Service Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }

    if ($global:isScanning) {
        Write-Log "A scan is already in progress"
        return
    }

    Set-ScanState -IsScanning $true
    Write-Log "Starting $ScanType scan..."
    Update-Progress -Percentage 5 -Status "Initializing $ScanType scan..."

    try {
        # Use PowerShell command instead of cmdlets for better compatibility
        $scanCommand = switch ($ScanType) {
            "Quick" { "powershell.exe -Command `"& { Start-MpScan -ScanType QuickScan }`"" }
            "Full" { "powershell.exe -Command `"& { Start-MpScan -ScanType FullScan }`"" }
        }

        # Start scan in background
        $global:scanProcess = Start-Process -FilePath "powershell.exe" -ArgumentList "-WindowStyle Hidden -Command `"Start-MpScan -ScanType $ScanType`"" -PassThru -NoNewWindow

        # Progress simulation
        $progressTimer = New-Object System.Windows.Forms.Timer
        $progressTimer.Interval = 2000
        $currentProgress = 10
        
        $progressTimer.Add_Tick({
            if ($global:scanProcess -and -not $global:scanProcess.HasExited) {
                $script:currentProgress += [System.Random]::new().Next(2, 8)
                if ($script:currentProgress -gt 90) { $script:currentProgress = 90 }
                Update-Progress -Percentage $script:currentProgress -Status "Scanning system..."
            } else {
                $this.Stop()
                Complete-Scan -ScanType $ScanType
            }
        })
        
        $progressTimer.Start()
        
    } catch {
        Write-Log "ERROR: Failed to start $ScanType scan - $($_.Exception.Message)"
        Set-ScanState -IsScanning $false
    }
}

function Complete-Scan {
    param([string]$ScanType)
    
    Update-Progress -Percentage 95 -Status "Finalizing scan..."
    Write-Log "Scan completed. Checking for threats..."
    
    try {
        # Check for threats using Get-MpThreatDetection
        $threats = powershell.exe -Command "Get-MpThreatDetection | Where-Object { \$_.ThreatStatusID -eq 1 -or \$_.ThreatStatusID -eq 2 }"
        
        if ($threats) {
            $threatCount = @($threats).Count
            Write-Log "WARNING: $threatCount threat(s) detected!"
            
            $threatNames = @($threats) | ForEach-Object { $_.ThreatName } | Select-Object -Unique
            $threatList = $threatNames -join ", "
            
            $result = [System.Windows.Forms.MessageBox]::Show(
                "⚠️ THREATS DETECTED ⚠️`n`nFound $threatCount threat(s): $threatList`n`nWould you like to attempt automatic remediation?",
                "Security Alert",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                Write-Log "Attempting to remove threats..."
                try {
                    powershell.exe -Command "Remove-MpThreat -All"
                    Write-Log "Threat removal completed"
                } catch {
                    Write-Log "ERROR: Failed to remove threats - $($_.Exception.Message)"
                }
            }
        } else {
            Write-Log "✅ No threats detected - System is clean"
        }
        
        Update-Progress -Percentage 100 -Status "$ScanType scan completed"
        
    } catch {
        Write-Log "ERROR: Failed to check threats - $($_.Exception.Message)"
    } finally {
        Start-Sleep -Seconds 2
        Set-ScanState -IsScanning $false
    }
}

function Update-Definitions {
    if ($global:isScanning) {
        Write-Log "Cannot update during active scan"
        return
    }

    Set-ScanState -IsScanning $true
    Write-Log "Starting definition update..."
    Update-Progress -Percentage 10 -Status "Downloading latest definitions..."

    try {
        # Update definitions
        for ($i = 20; $i -le 80; $i += 20) {
            Start-Sleep -Seconds 1
            Update-Progress -Percentage $i -Status "Updating virus definitions..."
        }
        
        powershell.exe -Command "Update-MpSignature"
        
        Update-Progress -Percentage 100 -Status "Definitions updated successfully"
        Write-Log "✅ Virus definitions updated successfully"
        
        Start-Sleep -Seconds 2
        
    } catch {
        Write-Log "ERROR: Failed to update definitions - $($_.Exception.Message)"
    } finally {
        Set-ScanState -IsScanning $false
    }
}

# Event Handlers
$quickScanBtn.Add_Click({ Start-DefenderScan -ScanType "Quick" })
$fullScanBtn.Add_Click({ Start-DefenderScan -ScanType "Full" })
$updateBtn.Add_Click({ Update-Definitions })

$stopBtn.Add_Click({
    if ($global:scanProcess -and -not $global:scanProcess.HasExited) {
        try {
            $global:scanProcess.Kill()
            Write-Log "Scan stopped by user"
        } catch {
            Write-Log "Unable to stop scan process"
        }
    }
    Set-ScanState -IsScanning $false
})

$clearBtn.Add_Click({
    $resultsBox.Clear()
    $resultsBox.Text = "Log cleared...`r`n"
})

# Form closing event
$form.Add_FormClosing({
    if ($global:scanProcess -and -not $global:scanProcess.HasExited) {
        $global:scanProcess.Kill()
    }
})

# Disable buttons if Defender is not available
if (-not $defenderAvailable) {
    $quickScanBtn.Enabled = $false
    $fullScanBtn.Enabled = $false
    $updateBtn.Enabled = $false
    Write-Log "Windows Defender is not available. Please enable Windows Defender and restart the application."
}

# Add all controls to form
$form.Controls.AddRange(@(
    $titleLabel,
    $statusLabel,
    $systemStatusLabel,
    $progressBar,
    $progressLabel,
    $buttonPanel,
    $resultsLabel,
    $resultsBox,
    $controlPanel
))

# Show the form
Write-Host "Windows Defender Scan Manager - Starting GUI..."
if (-not $isAdmin) {
    Write-Host "Note: For full functionality, run as Administrator"
}

[System.Windows.Forms.Application]::Run($form)