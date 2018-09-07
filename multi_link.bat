@echo off
setlocal enableextensions 
setlocal enabledelayedexpansion

REM -- Start by counting the number of links in the link file
GOTO :count

REM -- Main procedure of script
:start
REM -- Grab the first link from the link file
set /p search=<links.txt
echo %search%

REM -- Do this so we can just get the file size for comparing later
wget --spider %search% -o wget.out
findstr /C:"Length:" wget.out > wget.size

REM -- Get the line with the file size, still need to parse to get actual size
SET /p fsize= < wget.size

REM -- Remove the temp files
del wget.out
del wget.size

REM -- Parse the wget output line with the file size and get the second token which is the actual number we want
FOR /F "tokens=1,2" %%a in ("%fsize%") do SET filesize=%%b

REM -- Loop controls to be able to get the file name from the link
SET i=0
SET var1=%search%

REM -- Deliminate the link by / and loop through each piece
REM -- All we really want here is the number of tokens in the link so we can get the last one later
:LOOP
FOR /F "tokens=1* delims=/" %%A in ( "%var1%" ) do (
  SET /A i+=1
  SET var1=%%B
  GOTO :LOOP
)

REM -- Grab the last token which is the file name
FOR /F "tokens=%i% delims=/" %%G in ( "%search%" ) do set filename=%%G

REM -- URL un-encode the file name
set "filename=!filename:%%20= !"
set "filename=!filename:%%28=(!"
set "filename=!filename:%%29=)!"
set "filename=!filename:%%2B=+!"
set "filename=!filename:%%5B=[!"
set "filename=!filename:%%5D=]!"
set "filename=!filename:%%5F=_!"
set "filename=!filename:%%2D=-!"
set "filename=!filename:%%2E=.!"
set "filename=!filename:%%27='!"
set "filename=!filename:%%2c=,!"

REM -- Actually get the file
wget -N -c %search%

REM -- Get the file size of the file we downloaded
FOR %%A in ("%filename%") DO set size=%%~zA

REM -- Compare file size to what it's supposed to be to determine if we should try and download it again
IF "%size%" NEQ "%filesize%" GOTO :start

REM -- Once the file is the correct size, remove that link from the link file and count the links to determine whether or not to proceed
findstr /V /C:"%search%" links.txt > link_copy.txt
del links.txt
ren link_copy.txt links.txt
GOTO :count

REM -- Link counting
:count
REM -- Remove blank lines from link file and send count to external file
type links.txt | find "" /V /C > num.txt
REM -- Count links from external file
set /p count=<num.txt
echo %count%
REM -- Remove the external file that holds the count
del num.txt
GOTO :if

REM -- Check if we should continue or not by checking the count
:if
IF %count% LSS 1 (
	GOTO :END
) ELSE (
	GOTO :start
)

:END
echo Complete
endlocal
