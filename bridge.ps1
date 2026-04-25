$port = 5555
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Prefixes.Add("http://127.0.0.1:$port/")

try {
    $listener.Start()
    Write-Host "`n[ SCANNER DE RECEPTION ]" -ForegroundColor Cyan
    Write-Host "Le programme va maintenant chercher la table physiquement..."
    
    $udp = New-Object System.Net.Sockets.UdpClient
    $udp.Client.ReceiveTimeout = 1000

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request; $response = $context.Response
        $response.AddHeader("Access-Control-Allow-Origin", "*")
        
        # On envoie un signal de recherche (BROADCAST)
        $msg = [System.Text.Encoding]::ASCII.GetBytes("/xinfo`0`0`0`0")
        $udp.Send($msg, $msg.Length, "255.255.255.255", 10023)
        $udp.Send($msg, $msg.Length, "192.168.1.255", 10023)
        $udp.Send($msg, $msg.Length, "192.168.0.255", 10023)
        
        Write-Host "Recherche de la console sur tout le reseau..." -ForegroundColor Yellow
        
        try {
            $remoteEP = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
            $receiveBytes = $udp.Receive([ref]$remoteEP)
            $returnData = [System.Text.Encoding]::ASCII.GetString($receiveBytes)
            Write-Host "TROUVÉ !! Console detectee a l'adresse : $($remoteEP.Address)" -ForegroundColor Green
            Write-Host "Reponse de la console : $returnData"
        } catch {
            Write-Host "AUCUNE RÉPONSE : La console ne repond pas au signal de recherche." -ForegroundColor Red
            Write-Host "Verifiez le cable reseau derriere la table (port REMOTE)."
        }

        $buffer = [System.Text.Encoding]::UTF8.GetBytes("OK")
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
    }
} finally { $listener.Stop(); $udp.Close() }
