$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8080/")
try {
    $listener.Start()
    Write-Host "--- PONT MIDAS M32 ACTIF ---" -ForegroundColor Green
    Write-Host "En attente de commandes de l'application..."
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        # Autoriser le site web à parler au pont
        $response.AddHeader("Access-Control-Allow-Origin", "*")
        
        $path = $request.Url.LocalPath # Ex: /ch/01/fader/0.75
        $parts = $path.Split("/")
        
        if ($parts.Count -ge 5) {
            $ch = $parts[2]    # 01
            $type = $parts[3]  # fader, mute, gain
            $val = $parts[4]   # valeur
            
            # Ici on prépare le paquet OSC pour la Midas (UDP Port 10023)
            # Pour l'instant on simule l'envoi réseau
            Write-Host "CMD: Canal $ch -> $type -> $val" -ForegroundColor Cyan
            
            # Tentative d'envoi UDP réel vers la Midas (IP ciblée)
            # $udp = New-Object System.Net.Sockets.UdpClient
            # $udp.Connect("192.168.1.200", 10023)
            # ... encodage OSC ...
        }

        $buffer = [System.Text.Encoding]::UTF8.GetBytes("OK")
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
    }
} finally {
    $listener.Stop()
}
