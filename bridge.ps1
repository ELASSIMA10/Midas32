$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:8080/")
try {
    $listener.Start()
    Write-Host "`n--- SERVEUR MIDAS M32 PRIVÉ ACTIF ---" -ForegroundColor Green
    Write-Host "Le pont est prêt et écoute..." 
    
    $udp = New-Object System.Net.Sockets.UdpClient
    $htmlPath = Join-Path $PSScriptRoot "index.html"

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request; $response = $context.Response
        $response.AddHeader("Access-Control-Allow-Origin", "*")
        
        $path = $request.Url.LocalPath
        
        if ($path -eq "/" -or $path -eq "/index.html") {
            if (Test-Path $htmlPath) {
                $content = [System.IO.File]::ReadAllBytes($htmlPath)
                $response.ContentType = "text/html"; $response.OutputStream.Write($content, 0, $content.Length)
            }
        } 
        elseif ($path.StartsWith("/ch/")) {
            $parts = $path.Split("/")
            if ($parts.Count -ge 5) {
                $ch = $parts[2] # Déjà formaté par le JS en 01, 02...
                $type = $parts[3] 
                $val = [float]$parts[4] / 100.0
                
                # Récupérer l'IP cible depuis l'URL ou utiliser défaut
                $query = [System.Web.HttpUtility]::ParseQueryString($request.Url.Query)
                $targetIP = if ($query["target"]) { $query["target"] } else { "192.168.1.200" }

                if ($type -eq "fader" -or $type -eq "gain" -or $type.StartsWith("aux")) {
                    $oscAddr = switch($type) {
                        "fader" { "/ch/$ch/mix/fader" }
                        "gain"  { "/ch/$ch/config/gain" }
                        "aux1"  { "/ch/$ch/mix/01/level" }
                        "aux2"  { "/ch/$ch/mix/02/level" }
                        "aux3"  { "/ch/$ch/mix/03/level" }
                        "aux4"  { "/ch/$ch/mix/04/level" }
                        default { "/ch/$ch/mix/fader" }
                    }

                    # Encodage OSC
                    $pAddr = $oscAddr + "`0"
                    while ($pAddr.Length % 4 -ne 0) { $pAddr += "`0" }
                    $pType = ",f`0`0"
                    $pVal = [System.BitConverter]::GetBytes([float]$val)
                    if ([System.BitConverter]::IsLittleEndian) { [System.Array]::Reverse($pVal) }
                    
                    $packet = [System.Text.Encoding]::ASCII.GetBytes($pAddr) + [System.Text.Encoding]::ASCII.GetBytes($pType) + $pVal
                    $udp.Send($packet, $packet.Length, $targetIP, 10023)
                    Write-Host "OSC >> $targetIP : $oscAddr = $val" -ForegroundColor Yellow
                }
            }
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("OK")
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        $response.Close()
    }
} finally { $listener.Stop(); $udp.Close() }
