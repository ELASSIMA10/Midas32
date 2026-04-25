# Détection automatique de l'IP du PC
$ip = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'InterNetwork' -and $_.IPv4Mask -ne '255.255.255.255' -and $_.InterfaceAlias -notlike '*Loopback*' } | Select-Object -First 1).IPAddress

$listener = New-Object System.Net.HttpListener
try {
    # On écoute sur localhost ET sur l'IP réelle du PC
    $listener.Prefixes.Add("http://localhost:9999/")
    if ($ip) { $listener.Prefixes.Add("http://$ip:9999/") }
} catch {
    Write-Host "ERREUR INITIALISATION: Lancez le fichier en mode ADMINISTRATEUR (Clic droit)." -ForegroundColor Red
}

try {
    $listener.Start()
    Write-Host "`n===============================================" -ForegroundColor Green
    Write-Host "   SERVEUR MIXAGE MIDAS M32 OPÉRATIONNEL" -ForegroundColor Green
    Write-Host "===============================================" -ForegroundColor Green
    Write-Host "ADRESSE IP DE CE PC : $ip" -ForegroundColor Yellow
    Write-Host "-----------------------------------------------"
    Write-Host "1. SUR PC : Ouvrez index.html et tapez 'localhost' dans Bridge IP."
    Write-Host "2. SUR IPHONE : Allez sur http://$ip:9999" -ForegroundColor Cyan
    Write-Host "-----------------------------------------------`n"

    $udp = New-Object System.Net.Sockets.UdpClient
    $htmlPath = Join-Path $PSScriptRoot "index.html"

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request; $response = $context.Response
        $response.AddHeader("Access-Control-Allow-Origin", "*")
        
        $path = $request.Url.LocalPath
        if ($path -eq "/" -or $path -eq "/index.html") {
            if (Test-Path $htmlPath) {
                $content = [System.IO.File]::ReadAllBytes($htmlPath); $response.ContentType = "text/html"; $response.OutputStream.Write($content, 0, $content.Length)
            }
        } elseif ($path.Contains("/ch/")) {
            $parts = $path.Split("/")
            if ($parts.Count -ge 5) {
                $ch = $parts[2]; $type = $parts[3]; $val = [float]$parts[4] / 100.0
                $query = [System.Web.HttpUtility]::ParseQueryString($request.Url.Query)
                $targetIP = if ($query["target"]) { $query["target"] } else { "192.168.1.200" }

                # Encodage OSC
                $oscAddr = switch($type) { "fader"{"/ch/$ch/mix/fader"} "gain"{"/ch/$ch/config/gain"} default{"/ch/$ch/mix/fader"} }
                $pAddr = $oscAddr + "`0"; while ($pAddr.Length % 4 -ne 0) { $pAddr += "`0" }
                $pType = ",f`0`0"; $pVal = [System.BitConverter]::GetBytes([float]$val)
                if ([System.BitConverter]::IsLittleEndian) { [System.Array]::Reverse($pVal) }
                $packet = [System.Text.Encoding]::ASCII.GetBytes($pAddr) + [System.Text.Encoding]::ASCII.GetBytes($pType) + $pVal
                $udp.Send($packet, $packet.Length, $targetIP, 10023)
                Write-Host "COMMANDE REÇUE >> Canal $ch - $type à $val" -ForegroundColor Gray
            }
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("OK"); $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        $response.Close()
    }
} finally { $listener.Stop(); $udp.Close() }
