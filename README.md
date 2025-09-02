# DefenderScanGUI
DefenderScanGUI is a lightweight graphical front-end for Microsoft Defender Antivirus. It simplifies the process of running Quick, Full, or Custom scans without needing to type PowerShell or command-line commands.

---

# 📖 Features
✅ GUI wrapper for Windows Defender scans
✅ Supports Quick, Full, and Defination Updates
✅ Displays real-time scan progress and results
✅ Generates optional logs
✅ Can be extended for SOAR / XDR automation
✅ New Features:
 - System Status Indicator: Shows admin rights and Defender availability
 - Real-time Logging: Timestamped activity log
 - Clear Log Button: Clean the results area
 - Better Visual Design: Modern, professional appearance
 - Threat Summary: Detailed threat information with counts
 - Automatic Cleanup: Proper resource management

---

# 🛠️ Requirements:
- Windows 10/11 with Windows Defender
- PowerShell 5.1 or later
- .NET Framework (usually pre-installed)

---

# 💡 Usage Instructions:
 - Download the File and Save as DefenderGUI.ps1
 - Run as Administrator (recommended): powershellPowerShell -ExecutionPolicy Bypass -File "DefenderGUI.ps1"
   Or run normally with limited features: powershell.\DefenderGUI.ps1

This version should work much more reliably and handle edge cases that were causing the previous version to fail. The error handling will also provide better feedback about what's going wrong if issues occur.
