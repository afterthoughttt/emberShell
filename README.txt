== How to set up ESH on your system ==

-- Beginners Guide --

in file explorer, navigate to the root of your emberShell folder.
next, in the address bar type in "powershell" (or pwsh if you have a PowerShell 7+ install).
in terminal, it should now say the folder that you have emberShell stored in.
for simplicity we will assume its in D:\emberShell
if it DOES indeed say the right path -> good
if it does NOT, use the command `cd "d:\emberShell"`
now that you're in the emberShell folder, type in `.\setup.ps1`
this should associate .esh and .esx files to emberShell and create the emberShell profile in terminal.

-- Advanced Guide --

```
powershell # OR pwsh
cd "c:\your\path\to\emberShell"
.\setup.ps1
```

== Launching ESH ==

------------
-- step 1 --
------------

run setup.ps1 in powershell, either by
- right clicking and selecting run in powershell
- opening powershell in your emberShell folder and running the command .\setup  <- that lets you see the output too without closing

------------
-- step 2 --
------------

-- Windows 11 --
Open Terminal
click on the dropdown menu next to the new tab icon
select emberShell

-- Windows 10 and below -- # WORKS FOR WINDOWS 11 TOO
open any cmd or powershell window
type in emberShell


== Compatibility ==

-----------
-- Linux --
-----------
as of now, Linux is not natively supported.
however you can probably get it working on Linux if you try hard enough
there are plans for a Linux fork of emberShell.

-----------
-- MacOS --
-----------
as of now, MacOS is not natively supported.
there are plans for a MacOS fork, however it is not as prioritized as Linux.

------------------------
-- Windows 10 & below --
------------------------
Windows 10 should be mostly natively supported by emberShell as of version 1.2.0,
clib core will NOT run on Windows 10 and below, unless you install PowerShell 7.x
you can still use clib compat, however that may have certain features missing.
currently clib compat is only missing most render assets, only having cfetch assets out of the box.

support for Windows 8.1 & below is not guaranteed and also not planned.
there may be issues with emberShell & clib.
if you know PowerShell,
i'd appreciate if you fork emberShell to work on Windows 8.1 and below if they do not already.
clib should work on any operating system out of the box if PowerShell 7.x is installed.
^ note: without emberShell, you will need to run it as a .psm1 rather than an .esx. .esx is only recognized by emberShell.

you can change the automatically starting version of clib to clib compat by using the command
`set-config "clib_compat" $true`.

== Dependencies ==

emberShell depends on PowerShell.
it is recommended to install PowerShell 7 or higher.
it is also recommended to use Windows 11, as most testing happens on Windows 11.
(in the future, emberShell will be optimized for Arch Linux rather than Windows 11)

== ESH Imports behaving strangely ==

-------------------------
-- Why does it happen? --
-------------------------

i genuinely have no clue why imports behave strangely sometimes
if i would, i would've fixed it by now

----------------------------------
-- What filetypes are affected? --
----------------------------------

as far as i know only .esx files are affected.

----------------------
-- How do i fix it? --
----------------------

rerunning setup.ps1 usually fixes it,
if that does not work try deleting all .ps1 files in your %TEMP% folder
if THAT does not work then try restarting your pc through terminal (`shutdown /r /t 0`)

-----------------------------
-- why would those fix it? --
-----------------------------

.esx and .esh files work by storing temporary files in %TEMP%.
if those files stay after theyre not needed anymore, the shell can get confused and start reading parts from there.
rerunning setup fixes it, however i do not know why it does.
restarting your pc is just always a good way to fix some smaller issues, hence why i included it in the guide