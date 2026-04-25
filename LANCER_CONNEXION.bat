@echo off
title REPARATEUR DE CONNEXION MIDAS
echo.
echo  [43m [ TENTATIVE DE CONNEXION AVEC DROITS ADMIN ] [0m
echo.

:: Demander les droits admin si pas presents
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Droits administrateur confirmes.
) else (
    echo [!] ERREUR: Vous devez lancer ce fichier par CLIC DROIT -> 'Executer en tant qu'administrateur'
    pause
    exit
)

echo.
echo Lancement du moteur de mixage...
powershell -ExecutionPolicy Bypass -File bridge.ps1
pause
