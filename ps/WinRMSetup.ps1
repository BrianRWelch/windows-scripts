$hostname=$(Get-NetIPAddress)[2].IPv4Address

try {
  $cert = New-SelfSignedCertificate -Subject $("CN=" + $hostname) -TextExtension '2.5.29.37={text}1.3.6.1.5.5.7.3.1'
} catch {
  Write-Host $("ERROR:Failed to create self signed certificate: " + $_.Exception.Message)
  Exit 1
}

if ($cert) {
  Write-Host "OK:Self signed certificate created"
  $valueset = @{
    Hostname = $hostname
    CertificateThumbprint = $cert.Thumbprint
  }

  $selectorset = @{
    Transport = "HTTPS"
    Address = "*"
  }
 
  try {
    $result = New-WSManInstance -ResourceURI 'winrm/config/Listener' -SelectorSet $selectorset -ValueSet $valueset
  } catch {
    Write-Host $("ERROR:Failed to create WinRM listener: " + $_.Exception.Message)
    Exit 1
  }
  Write-Host "OK:WinRM setup w/ SSL"
  $FirewallParam = @{
    DisplayName = 'Windows Remote Management (HTTPS-In)'
    Direction = 'Inbound'
    LocalPort = 5986
    Protocol = 'TCP'
    Action = 'Allow'
    Program = 'System'
  }
  try {
    $result = New-NetFirewallRule @FirewallParam
  } catch {
    Write-Host $("ERROR:Failed to create firewall rule: " + $_.Exception.Message)
  }
  Write-Host "OK:Windows Firewall configured"
  Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
  Write-Host "OK:Enabled basic authentication"
} else {
  Write-Host $("ERROR:Failed to create self signed certificate")
  Exit 1
}
