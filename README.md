# Powerdp

Powerdp is a powershell script. This script performs rpd dictionary attack on specified windows device. Powerdp uses 'mstsc.exe' for rdp connections. So, you can use this script any windows device that 'mstsc.exe' and 'powershell.exe' installed on.

### Syntax

``` powershell
PS> .\powerdp.ps1 [-t] <String> [-u] <String> [-d] <String> [[-o] <String>] [[-to] <Int32>]
```
### Parameters
-t &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Specifies target computer's address <br>
-u &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Specifies username                      
-d &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Specifies dictionary's path <br>
-o &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Specifies output file's path <br>
-to &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;      Specifies timeout value for connection in seconds

### Examples

``` powershell
PS> .\powerdp.ps1 -t 192.168.1.100 -u user1 -d .\dictionary.txt
```
This command performs rdp dictionary attack on 'user1' at '192.168.1.100' with possible passwords the 'dictionary.txt' contains

``` powershell
PS> .\powerdp.ps1 -t 192.168.1.100 -u user1 -d .\dictionary.txt
```
With option '-o' this command writes result of attack to 'out.txt'

### Usage
