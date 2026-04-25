$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:8080/") # Ecoute sur toutes les interfaces
try {
    $listener.Start()
    Write-Host "--- PONT MIDAS M32 CONNECTÉ AU RÉSEAU ---" -ForegroundColor Green
    Write-Host "Le pont écoute les ordres de l'application..."
    
    $udp = New-Object System.Net.Sockets.UdpClient
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $response.AddHeader("Access-Control-Allow-Origin", "*")
        
        $path = $request.Url.LocalPath # /ch/01/fader/50
        $parts = $path.Split("/")
        
        if ($parts.Count -ge 5) {
            $ch = $parts[2].PadLeft(2, '0')
            $type = $parts[3] 
            $val = [float]$parts[4] / 100.0 # On convertit 0-100 en 0.0-1.0
            $targetIP = "192.168.1.200" # Adresse IP de votre console Midas

            # Création manuelle d'un paquet OSC simple pour le fader
            # Path: /ch/01/mix/fader ,f [float]
            if ($type -eq "fader") {
                $oscPath = "/ch/$ch/mix/fader`0`0"
                if ($oscPath.Length % 4 -ne 0) { $oscPath += "`0" * (4 - ($oscPath.Length % 4)) }
                
                $oscType = ",f`0`0"
                $bytes = [System.BitConverter]::GetBytes([float]$val)
                if ([System.BitConverter]::IsLittleEndian) { [System.Array]::Reverse($bytes) }
                
                $packet = [System.Text.Encoding]::ASCII.GetBytes($oscPath) + 
                          [System.Text.Encoding]::ASCII.GetBytes($oscType) + 
                          $bytes
                
                $udp.Send($packet, $packet.Length, $targetIP, 10023)
                Write-Host "SENT TO MIXER: Canal $ch -> Volume $val" -ForegroundColor Yellow
            }
        }

        $buffer = [System.Text.Encoding]::UTF8.GetBytes("OK")
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
    }
} finally {
    $listener.Stop()
    $udp.Close()
}
