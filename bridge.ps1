$port = 5555
$listener = New-Object System.Net.HttpListener
# On écoute sur tous les noms pour que l'iPhone puisse se connecter
$listener.Prefixes.Add("http://*:5555/")

# Détection de l'IP pour l'affichage
$myIp = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'InterNetwork' -and $_.IPv4Mask -ne '255.255.255.255' -and $_.InterfaceAlias -notlike '*Loopback*' } | Select-Object -First 1).IPAddress

try {
    $listener.Start()
    Write-Host "`n===============================================" -ForegroundColor Green
    Write-Host "   SERVEUR MIDAS CONNECTÉ AU RÉSEAU" -ForegroundColor Green
    Write-Host "===============================================" -ForegroundColor Green
    Write-Host "1. SUR VOTRE IPHONE, OUVREZ CETTE ADRESSE :"
    Write-Host "   http://$myIp:5555" -ForegroundColor Cyan -BackgroundColor DarkBlue
    Write-Host "-----------------------------------------------"
    Write-Host "Laissez cette fenêtre ouverte pour que ça marche."
    
    $udp = New-Object System.Net.Sockets.UdpClient
    $htmlPath = Join-Path $PSScriptRoot "index.html"

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request; $response = $context.Response
        $response.AddHeader("Access-Control-Allow-Origin", "*")
        
        $path = $request.Url.LocalPath
        
        # SI ON DEMANDE LA PAGE (Depuis l'iPhone)
        if ($path -eq "/" -or $path -eq "/index.html") {
            if (Test-Path $htmlPath) {
                $content = [System.IO.File]::ReadAllBytes($htmlPath)
                $response.ContentType = "text/html"
                $response.OutputStream.Write($content, 0, $content.Length)
            }
        } 
        # SI ON ENVOIE UNE COMMANDE OSC
        elseif ($path.Contains("/ch/")) {
            $parts = $path.Split("/")
            if ($parts.Count -ge 5) {
                $ch = $parts[2]; $type = $parts[3]; $val = [float]$parts[4] / 100.0
                $targetIP = "192.168.1.200" # IP de la table
                
                # Construction binaire OSC
                $oscAddr = switch($type) {
                    "fader" { "/ch/$ch/mix/fader" }
                    "mute"  { "/ch/$ch/mix/on" }
                    "gain"  { "/ch/$ch/config/gain" }
                    default { "/ch/$ch/mix/fader" }
                }

                $ms = New-Object System.IO.MemoryStream; $bw = New-Object System.IO.BinaryWriter($ms)
                $bw.Write([System.Text.Encoding]::ASCII.GetBytes($oscAddr)); $bw.Write([byte]0)
                while ($ms.Position % 4 -ne 0) { $bw.Write([byte]0) }
                $pTag = if($type -eq "mute") { ",i" } else { ",f" }
                $bw.Write([System.Text.Encoding]::ASCII.GetBytes($pTag)); $bw.Write([byte]0)
                while ($ms.Position % 4 -ne 0) { $bw.Write([byte]0) }
                $vBytes = if($type -eq "mute") { [System.BitConverter]::GetBytes([int](if($val -gt 0){0}else{1})) } else { [System.BitConverter]::GetBytes([float]$val) }
                if ([System.BitConverter]::IsLittleEndian) { [System.Array]::Reverse($vBytes) }
                $bw.Write($vBytes)
                $packet = $ms.ToArray()
                $udp.Send($packet, $packet.Length, $targetIP, 10023)
                
                Write-Host "ACTION >> $oscAddr -> $val" -ForegroundColor Yellow
                $bw.Dispose(); $ms.Dispose()
            }
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("OK")
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        $response.Close()
    }
} catch {
    Write-Host "ERREUR : Verifiez que vous avez lance en ADMINISTRATEUR." -ForegroundColor Red
    Write-Host $_.Exception.Message
    pause
} finally { $listener.Stop(); $udp.Close() }
