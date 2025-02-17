# Activer WINRM
Enable-PSRemoting -Force

# Autoriser les connexions non sécurisées (HTTP)
Set-Item WSMan:\localhost\Client\AllowUnencrypted $true
Set-Item WSMan:\localhost\Server\Auth\Basic $true

# Ouvrir le port 5985 dans le pare-feu Windows
New-NetFirewallRule -DisplayName "Allow WINRM" -Direction Inbound -Protocol TCP -Action Allow -LocalPort 5985
