@echo off
title REPARATEUR DE CONNEXION MIDAS
echo.
echo  [43m [ DEBLOCAGE DES FLUX SORTANTS ] [0m
echo.

:: Demande les droits Admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ERREUR: Lancez ce fichier par CLIC DROIT -> 'Executer en tant qu'administrateur'
    pause
    exit
)

echo [1/3] Ouverture du Pare-feu (Entree + Sortie)...
netsh advfirewall firewall delete rule name="MIDAS_BRIDGE" >nul 2>&1
netsh advfirewall firewall add rule name="MIDAS_BRIDGE" dir=in action=allow protocol=UDP localport=10023 >nul 2>&1
netsh advfirewall firewall add rule name="MIDAS_BRIDGE" dir=out action=allow protocol=UDP remoteport=10023 >nul 2>&1
netsh advfirewall firewall add rule name="MIDAS_BRIDGE_TCP" dir=in action=allow protocol=TCP localport=5555 >nul 2>&1

echo [2/3] Deblocage du service HTTP...
netsh http delete urlacl url=http://*:5555/ >nul 2>&1
netsh http add urlacl url=http://+:5555/ user=Everyone >nul 2>&1
netsh http add urlacl url=http://+:5555/ user="Tout le monde" >nul 2>&1

echo [3/3] Lancement du Pont...
powershell -ExecutionPolicy Bypass -File bridge.ps1
pause
