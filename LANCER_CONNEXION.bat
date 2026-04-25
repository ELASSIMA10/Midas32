@echo off
title REPARATEUR DE CONNEXION MIDAS
echo.
echo  [43m [ TENTATIVE DE CONNEXION AVEC DROITS ADMIN ] [0m
echo.

:: Demander les droits admin si pas presents
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ERREUR: Vous devez lancer ce fichier par CLIC DROIT -> 'Executer en tant qu'administrateur'
    pause
    exit
)

echo [OK] Droits administrateur confirmes.
echo Deblocage du port 9999 pour l'iPhone...
netsh http delete urlacl url=http://*:9999/ >nul 2>&1
netsh http add urlacl url=http://+:9999/ user=Everyone >nul 2>&1
netsh http add urlacl url=http://+:9999/ user="Tout le monde" >nul 2>&1

echo.
echo Lancement du moteur de mixage...
powershell -ExecutionPolicy Bypass -File bridge.ps1
pause
