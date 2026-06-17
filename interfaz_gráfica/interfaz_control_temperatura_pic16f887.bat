@echo off
title Interfaz de Control de Temperatura - PIC16F887
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0interfaz_control_temperatura_pic16f887.ps1"

pause
