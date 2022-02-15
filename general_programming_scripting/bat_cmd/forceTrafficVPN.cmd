@echo off
rem Now with paramaters
rem .\forceTrafficVPN.cmd ip 123.0.0.1
rem .\forceTrafficVPN.cmd domain google.com
rem .\forceTrafficVPN.cmd google.com


set argCount=0
for %%x in (%*) do (
    set /A argCount+=1
)

set routeSubnetMask=255.255.255.128 
set routeVPNIP=10.33.2.128

set nerderyVPNIP=""

if %nerderyVPNIP% EQU "" call :GetVPNIP nerderyVPNIP 10.33
if %nerderyVPNIP% EQU "" (
    set routeSubnetMask=255.255.255.255
    
    call :GetVPNIP nerderyVPNIP 10.15
    set routeVPNIP=""
    
    
   
)

if %nerderyVPNIP% EQU "" (
    echo Please check that you are connected to the VPN
    exit /B 0
)

if %routeVPNIP% EQU "" (
    set routeVPNIP=%nerderyVPNIP%
)

setlocal enableextensions enabledelayedexpansion

for /f "tokens=* delims= " %%a in ("%nerderyVPNIP%") do set nerderyVPNIP=%%a
for /l %%a in (1,1,100) do if "!nerderyVPNIP!"==" " set nerderyVPNIP=!nerderyVPNIP:~0,-1!

endlocal && set nerderyVPNIP=%nerderyVPNIP%/32

if %nerderyVPNIP% EQU "" (
    echo Please check that you are connected to the VPN
    exit /B 0
)

set typeKey=""

set domainname=""

if %argCount% GTR 0 (
    if /I "%1"=="IP" ( 
        set typeKey="IP"
        set domainname=%2
    ) else (
        if /I "%1"==DOMAIN ( 
            set typeKey="DOMAIN" 
            set domainname=%2
        ) else ( 
            set typeKey="DOMAIN"
            set domainname=%1 
        )
    )
)

if %argCount% LEQ 1 (
    call :ProcessVPNRequest %nerderyVPNIP% %typeKey% %domainname% %routeSubnetMask% %routeVPNIP%
) else (
    for %%x in (%*) do (
        if /I not "%%x" EQU %typeKey% (
            call :ProcessVPNRequest %nerderyVPNIP% %typeKey% %%x %routeSubnetMask% %routeVPNIP%
        )
    )
)


exit /B 0

:ProcessVPNRequest

set nerderyVPNIP=%1
set typeKey=%2
set domainname=%3
set ipaddress=""

set routeSubnetMask=%4 
set routeVPNIP=%5


if %typeKey% EQU "" set /p domainname="Enter Site Domain (Or press enter to enter IP): "

if /I NOT %typeKey% EQU "IP" (
    if NOT %domainname% EQU "" (
        echo Getting IP for Domain: %domainname%
        call :GetIPFromPing domainname,ipaddress
    )
) else (
    set ipaddress=%domainname%
)

if %ipaddress% EQU "" set /p ipaddress="Enter Ip: "

setlocal enabledelayedexpansion

for /f "tokens=* delims= " %%a in ("%ipaddress%") do set ipaddress=%%a
for /l %%a in (1,1,100) do if "!ipaddress!"==" " set ipaddress=!ipaddress:~0,-1!

endlocal && set ipaddress=%ipaddress%/32

if %ipaddress% EQU "" echo "Could not get the IP for the domain %domainname% please manually get and send"


if NOT %ipaddress% EQU "" if NOT %nerderyVPNIP% EQU "" (
    echo Adding IP: %ipaddress% to force traffic via Nerdery VPN: %routeVPNIP%
    route add %ipaddress% mask %routeSubnetMask% %routeVPNIP%
)


exit /B 0


:GetVPNIP

    for /f "usebackq tokens=2 delims=:" %%f in (`ipconfig ^| findstr /c:%~2`) do set %~1=%%f

EXIT /B 0


:GetIPFromPing

set pingResults=""
set ipResult=""
for /f "tokens=*" %%a in ('ping -n 1 %domainname% ^| findstr /c:"Ping statistics for"') do set pingResults=%%a

:findLastLoop
for /f "tokens=1*" %%a in ("%pingResults%") do (
	set ipResult=%%a
	set pingResults=%%b	
)
set count=0
call :strlen count pingResults

if %count% GTR 1 goto :findLastLoop

for /f "tokens=1 delims=:" %%a in ("%ipResult%") do set %~2=%%a

EXIT /B 0

:strlen <resultVar> <stringVar>
(   
    setlocal EnableDelayedExpansion
    (set^ tmp=!%~2!)
    if defined tmp (
        set "len=1"
        for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
            if "!tmp:~%%P,1!" NEQ "" ( 
                set /a "len+=%%P"
                set "tmp=!tmp:~%%P!"
            )
        )
    ) ELSE (
        set len=0
    )
)
( 
    endlocal
    set "%~1=%len%"
    exit /b
)