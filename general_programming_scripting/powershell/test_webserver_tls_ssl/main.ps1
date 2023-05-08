#!/usr/bin/env pwsh
# Original Script found
# https://www.sysadmins.lv/blog-en/test-web-server-ssltls-protocol-support-with-powershell.aspx

param(
  [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$HostName,
  [UInt16]$Port = 443
)

function Test-ServerSSLSupport {
  [CmdletBinding()]
    param(
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
      [ValidateNotNullOrEmpty()]
      [string]$HostName,
      [UInt16]$Port = 443
    )
    process {
      $RetValue = New-Object psobject -Property @{
        Host = $HostName
        Port = $Port
        SSLv2 = $false
        SSLv3 = $false
        TLSv1_0 = $false
        TLSv1_1 = $false
        TLSv1_2 = $false
        TLSv1_3 = $false
        KeyExhange = $null
        HashAlgorithm = $null
      }
      "ssl2", "ssl3", "tls", "tls11", "tls12", "tls13" | %{
        $TcpClient = New-Object Net.Sockets.TcpClient
        $TcpClient.Connect($RetValue.Host, $RetValue.Port)
        $SslStream = New-Object Net.Security.SslStream $TcpClient.GetStream(),
          $true,
          ([System.Net.Security.RemoteCertificateValidationCallback]{ $true })
        $SslStream.ReadTimeout = 15000
        $SslStream.WriteTimeout = 15000
        try {
          $SslStream.AuthenticateAsClient($RetValue.Host,$null,$_,$false)
          $RetValue.KeyExhange = $SslStream.KeyExchangeAlgorithm
          $RetValue.HashAlgorithm = $SslStream.HashAlgorithm
          $status = $true
        } catch {
          $status = $false
        }
        switch ($_) {
          "ssl2" {$RetValue.SSLv2 = $status}
          "ssl3" {$RetValue.SSLv3 = $status}
          "tls" {$RetValue.TLSv1_0 = $status}
          "tls11" {$RetValue.TLSv1_1 = $status}
          "tls12" {$RetValue.TLSv1_2 = $status}
          "tls13" {$RetValue.TLSv1_3 = $status}
        }
        # dispose objects to prevent memory leaks
        $TcpClient.Dispose()
        $SslStream.Dispose()
      }
      $RetValue
    }
  }

Test-ServerSSLSupport -HostName $HostName -Port $Port