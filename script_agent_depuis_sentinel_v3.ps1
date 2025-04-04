# Chemins
$glpiAgentPath = "C:\Program Files\GLPI-agent"
$tempPath = "C:\temp"
$requiredVersion = [version]"1.13"

# Fonction : obtenir la version depuis le registre
function Get-GLPIAgentRegistryVersion {
    $regPath = "HKLM:\SOFTWARE\GLPI-Agent\Installer"
    try {
        $version = Get-ItemPropertyValue -Path $regPath -Name Version
        return [version]$version
    } catch {
        return $null
    }
}

# Vérification de la version installée via registre
$installedVersion = Get-GLPIAgentRegistryVersion

if ($installedVersion -eq $null -or $installedVersion -lt $requiredVersion) {
    Write-Host "Agent GLPI absent ou version trop ancienne ($installedVersion). Installation/Mise à jour..."

    # Créer le dossier C:\temp si nécessaire
    if (-not (Test-Path $tempPath)) {
        New-Item -Path $tempPath -ItemType Directory
    }

    # Télécharger l'installeur GLPI-Agent
    $msiUrl = "https://github.com/glpi-project/glpi-agent/releases/download/1.13/GLPI-Agent-1.13-x64.msi"
    $msiPath = "$tempPath\GLPI-Agent-1.13-x64.msi"
    Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath

    # Ajouter les clés de registre nécessaires
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\GLPI-Agent" /v "no-ssl-check" /t "REG_SZ" /d "1" /f
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\GLPI-Agent" /v "tag" /t "REG_SZ" /d "LAD" /f
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\GLPI-Agent" /v "server" /t "REG_SZ" /d "https://213.56.106.220/front/inventory.php" /f

    # Installer le MSI en mode silencieux
    Start-Process msiexec.exe -ArgumentList "/i", "`"$msiPath`"", "/quiet", "/norestart" -Wait
} else {
    Write-Host "L'agent GLPI est déjà à jour (version $installedVersion)."
}

# Redémarrer le service 
net stop glpi-agent
net start glpi-agent

# Lancer une synchro d'inventaire
cd $glpiAgentPath
Start-Process -FilePath "glpi-agent.bat" -ArgumentList "--force" -Wait




# Supprimer le fichier MSI téléchargé
if (Test-Path $msiPath) {
    Remove-Item -Path $msiPath -Force
    Write-Host "Fichier MSI supprimé : $msiPath"
}