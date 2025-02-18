# Active WinRM et configure le transport Basic
Write-Host "🔧 Configuration de WinRM..."
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/winrs '@{AllowRemoteShellAccess="true"}'
winrm set winrm/config/service/auth '@{CredSSP="true"}'

# Autorise le compte adminuser à utiliser WinRM
Write-Host "🔧 Autorisation de l'utilisateur adminuser sur WinRM..."
net localgroup Administrateurs /add adminuser

# Vérifie si l'authentification UAC est activée et la désactive si besoin
Write-Host "🔧 Désactivation de l'UAC pour l'accès distant..."
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f

# Redémarre le service WinRM
Write-Host "🔧 Redémarrage du service WinRM..."
Restart-Service WinRM -Force
