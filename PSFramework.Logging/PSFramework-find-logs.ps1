$logPath = Get-PSFConfigValue -FullName PSFramework.Logging.FileSystem.LogPath
Invoke-Item $logPath

Get-PSFConfig -Fullname PSFramework.Logging.FileSystem.*
