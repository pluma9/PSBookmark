#TODO: Don't like this method; will update this without breaking the module later
$dataPath = "${env:USERPROFILE}\PSBookmarkData.ps1"

#Credit: June Blender - https://www.sapien.com/blog/2014/10/21/a-better-tostring-method-for-hash-tables/
function Convert-HashToString
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Hash
    )
    $hashstr = "@{"
    $keys = $Hash.keys
    foreach ($key in $keys)
    {
        $v = $Hash[$key]
        if ($key -match "\s")
        {
            $hashstr += "`"$key`"" + "=" + "`"$v`"" + ";"
        }
        else
        {
            $hashstr += $key + "=" + "`"$v`"" + ";"
        }
    }
    $hashstr += "}"
    return $hashstr
}

function New-DynamicParameter
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [String] $Name,

        [Parameter()]
        $actionObject
    )

        $ParameterName = $Name
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 0

        $AttributeCollection.Add($ParameterAttribute)
            
        $arrSet = $actionObject.Keys
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        $AttributeCollection.Add($ValidateSetAttribute)

        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
}

function Save-LocationBookmark
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position=0)]
        [string] $Alias,

        [Parameter(Position=1)]
        [String] $Location = $PWD.Path
    )

    if (Test-Path -Path $dataPath)
    {
        $locationHash = .$dataPath
    }
    else
    {
        $locationHash = @{}
    }
    $locationHash.Add($Alias,$Location)
    Convert-HashToString -Hash $locationHash | Out-File -FilePath $dataPath -Force
}

function Set-LocationBookmarkAsPWD
{
    [CmdletBinding()]
    param (

    )

    DynamicParam
    {
        if (Test-Path -Path $dataPath)
        {
            $locationHash = .$dataPath
            return (New-DynamicParameter -Name 'Alias' -actionObject $locationHash)
        }
    }

    begin
    {
        $alias = $PsBoundParameters['Alias']
    }

    process
    {
        if ($locationHash[$alias])
        {
            Set-Location -Path $locationHash[$alias]
        }
    }
}

function Get-LocationBookmark
{
    if (Test-Path -Path $dataPath)
    {
        $locationHash = .$dataPath
        return $locationHash
    }
    else
    {
        Write-Warning -Message 'No location aliases or bookmarks exist yet. Create one using either Save-LocationBookmark or save'
    }
}

function Get-LocationBookmarkValue
{
    [CmdletBinding()]
    param (

    )

    DynamicParam
    {
        if (Test-Path -Path $dataPath)
        {
            $locationHash = .$dataPath
            return (New-DynamicParameter -Name 'Alias' -actionObject $locationHash)
        }
    }

    begin
    {
        $alias = $PsBoundParameters['Alias']
    }

    process
    {
        return $locationHash[$alias]
    }
}

function Remove-LocationBookmark
{
    [CmdletBinding()]
    param (

    )

    DynamicParam
    {
        if (Test-Path -Path $dataPath)
        {
            $locationHash = .$dataPath
            return (New-DynamicParameter -Name 'Alias' -actionObject $locationHash)
        }
    }

    begin
    {
        $alias = $PsBoundParameters['Alias']
    }

    process
    {
        $locationHash.Remove($alias)
        Convert-HashToString -Hash $locationHash | Out-File -FilePath $dataPath -Force
    }
}

Set-Alias -Name goto -Value Set-LocationBookmarkAsPWD
Set-Alias -Name save -Value Save-LocationBookmark
Set-Alias -Name glb -Value Get-LocationBookmark
Set-Alias -Name rlb -Value Remove-LocationBookmark
Set-Alias -Name glbv -Value Get-LocationBookmarkValue

Export-ModuleMember -Function Save-LocationBookmark,Set-LocationBookmarkAsPWD,Get-LocationBookmark,Remove-LocationBookmark,Get-LocationBookmarkValue -Alias goto,save,glb,rlb,glbv
