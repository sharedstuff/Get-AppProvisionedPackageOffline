function Invoke-WebRequestTechbench {

    <#

        .SYNOPSIS
        Wrapper for Invoke-WebRequest

        .DESCRIPTION
        Wrapper for Invoke-WebRequest to query Techbench API (rg-adguard.net)

    #>


    [CmdletBinding()]
    param(

        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $Value,

        [Parameter(Mandatory)]
        [ValidateSet('url', 'ProductId', 'PackageFamilyName', 'CategoryId')]
        [string]
        $Type,

        [Parameter()]
        [ValidateSet('RP', 'Retail', 'WIF', 'WIS')]
        [string]
        $Ring,

        [Parameter()]
        [string]
        $Lang,

        [Parameter()]
        [string]
        $Uri = 'https://store.rg-adguard.net/api/GetFiles'

    )

    begin {

        $WebRequestParamsPrototype = @{
            UseBasicParsing = $true
            Uri             = 'https://store.rg-adguard.net/api/GetFiles'
            Method          = 'POST'
            Headers         = @{
                method = 'POST'
                path   = '/api/GetFiles'
                scheme = 'https'
                accept = '*/*'
            }
            ContentType     = 'application/x-www-form-urlencoded'
        }

    }

    process {

        $Value | ForEach-Object {

            $WebRequestParams = $WebRequestParamsPrototype

            $WebRequestParams.Body = 'type={0}&url={1}' -f $Type, $_

            if ($Ring) {
                $WebRequestParams.Body += '&ring={0}' -f $Ring
            }

            if ($Lang) {
                $WebRequestParams.Body += '&lang={0}' -f $Lang
            }

            Invoke-WebRequest @WebRequestParams

        }

    }

}

function Get-StoreDownloadLinks {

    <#

        .SYNOPSIS
        Retrieves Microsoft Store download links queried from Techbench API (rg-adguard.net)

        .DESCRIPTION
        Retrieves Microsoft Store download links queried from Techbench API (rg-adguard.net) as a PSCustomObject

        Example:
        Name : Microsoft.WindowsCalculator_2021.2210.0.0_neutral_~_8wekyb3d8bbwe.msixbundle
        Uri  : http://tlu.dl.delivery.mp.microsoft.com/filestreamingservice/...

    #>


    [CmdletBinding()]
    param(

        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $Value,

        [Parameter(Mandatory)]
        [ValidateSet('url', 'ProductId', 'PackageFamilyName', 'CategoryId')]
        [string]
        $Type,

        [Parameter()]
        [ValidateSet('RP', 'Retail', 'WIF', 'WIS')]
        [string]
        $Ring,

        [Parameter()]
        [string]
        $Lang,

        [Parameter()]
        [string]
        $Uri = 'https://store.rg-adguard.net/api/GetFiles'

    )

    begin {

        $InvokeWebRequestTechbenchParams = @{
            Uri  = $Uri
            Type = $Type
        }

    }

    process {

        $Value | ForEach-Object {

            $TryCounter = 0
            do {

                if ($TryCounter -gt 0) {
                    'TryCounter >0 : {0} - Sleeping 5sec' -f $TryCounter | Write-Host
                    Start-Sleep -Seconds 5
                }

                $WebRequest = $_ | Invoke-WebRequestTechbench @InvokeWebRequestTechbenchParams

                $TryCounter++

            } until ( $TryCounter -eq 3 -or $WebRequest.Links.Count -gt 0 )

            if ($TryCounter -eq 3) {
                Write-Error 'Failed to fetch after 3 tries'
            }
            else {
                $WebRequest.Links | ForEach-Object {
                    [PSCustomObject]@{
                        Name = & {
                            if ($_.outerHTML -match '<.*>(.*)<\/.*>') {
                                $Matches[1]
                            }
                        }
                        Uri  = $_.href
                    }
                } | Where-Object { $_.Uri -match '\.microsoft\.com\/filestreamingservice' }
            }

        }

    }

}

function Get-WingetInformation {

    <#

        .SYNOPSIS
        Wrapper for winget.exe

        .DESCRIPTION
        Wrapper for winget.exe
        Returns a structured PSCustomObject

        Example:
        Name    : Windows Calculator
        ID      : 9WZDNCRFHVN5
        Version : Unknown
        Source  : msstore

    #>

    [CmdletBinding()]
    param(

        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $Query

    )

    process {
        $Query | ForEach-Object {

            $Winget = winget.exe find $_
            $Split = $Winget[-1] -split ' '
            [pscustomobject]@{
                Name    = $Split[0..($Split.Count - 4)] -join ' '
                ID      = $Split[$Split.Count - 3]
                Version = $Split[$Split.Count - 2]
                Source  = $Split[$Split.Count - 1]
            }

        }
    }

}

function Test-AppProvisionedPackageOfflineFunction {
    $ProductId = '9WZDNCRFHVN5'
    $ProductId | Invoke-WebRequestTechbench -Type ProductId
    $ProductId | Get-StoreDownloadLinks -Type ProductId
    $ProductId | Get-WingetInformation
}
