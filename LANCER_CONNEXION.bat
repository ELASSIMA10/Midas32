@echo off
title PONT DE CONNEXION MIDAS M32
echo.
echo  [42m [ CONNEXION REELLE MIDAS M32 ACTIVEE ] [0m
echo.
echo Ce programme fait le lien entre votre application et la console.
echo Gardez cette fenetre ouverte pendant que vous mixez.
echo.
powershell -ExecutionPolicy Bypass -File bridge.ps1
pause
