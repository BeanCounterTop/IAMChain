
Function Get-StringHash([String] $String,$HashName = "MD5") {
    $StringBuilder = New-Object System.Text.StringBuilder
    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{
    [Void]$StringBuilder.Append($_.ToString("x2"))
    }
    $StringBuilder.ToString()
    }

Function Add-BlockchainEntry ($Data, $BlockFilePath) {
    $LastBlock = Get-Content $BlockFilePath -Tail 1
    $LastBlockData = $LastBlock -split ","
    [int]$LastEntryIndex = $LastBlockData[0]
    $LastEntryHash = $LastBlockData[3]
    $NewEntryIndex = $LastEntryIndex + 1
    $NewEntryDataHash = Get-StringHash $Data
    $NewEntryBlockHash = Get-StringHash "$NewEntryDataHash$LastEntryHash"
    $ContentLine = "$NewEntryIndex,$Data,$NewEntryDataHash,$NewEntryBlockHash"
    Add-Content -Value $ContentLine -Path $BlockFilePath
    Return "Adding line: $ContentLine"
    }

Function Validate-BlockChain ($BlockFilePath) {
    Write-Debug "Validating blockchain..."
    $BlockData = Import-CSV -Path $BlockFilePath
    $StartBlock = $BlockData | ? index -eq 0
    $CurrentIndex = 1
    $End = $False

    while ($End -eq $False) {
        $CurrentBlock = $BlockData | ? Index -eq $CurrentIndex
        If (!$CurrentBlock) {$End = $True; Continue}
        $LastBlock = $BlockData | ? Index -eq ($CurrentIndex - 1)

        $CurrentBlockStoredDataHash = $CurrentBlock.datahash
        $CurrentBlockCalculatedDataHash = Get-StringHash $CurrentBlock.data
        If (-NOT $CurrentBlockStoredDataHash -eq $CurrentBlockCalculatedDataHash) {
           Throw "Blockchain entry failed data hash verification on index $CurrentIndex"
           } 
        $CurrentBlockStoredBlockHash = $CurrentBlock.blockhash
        $LastBlockStoredBlockHash = $LastBlock.blockhash
        $CurrentBlockCalculatedBlockhash = Get-StringHash "$CurrentBlockCalculatedDataHash$LastBlockStoredBlockHash"
        If ($CurrentBlockStoredBlockHash -ne $CurrentBlockCalculatedBlockhash) {
           Throw "Blockchain entry failed block hash verification on index $CurrentIndex"
           } 
        Write-Debug "Valid: $($CurrentBlock.data)"
        $CurrentIndex++
        }
    Return $BlockData
    }

Function Set-BlockchainedGroupMembership ($User, $Group, $Domain, $Action, $ReferenceID, $BlockFilePath) {
    switch ($Action) {
        "Add" {
            $ActionString = "ADD"
            }
        "Remove" {
            $ActionString = "REMOVE"
            }
        Default {
            Throw "Missing or invalid action parameter"
            }
        }

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff z"
    $DataObject = @{domain=$Domain; user=$User; group=$Group; action=$Action; ReferenceID=$ReferenceID; timestamp=$TimeStamp} | ConvertTo-JSON
    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($DataObject)
    $EncodedData =[Convert]::ToBase64String($Bytes)
    Add-BlockchainEntry -Data $EncodedData -BlockFilePath $BlockFilePath
    }


Function Decode-JSONBlockchain ($BlockData){
    $ReturnCollection = @() 
    Foreach ($Datum in $BlockData[1..($BlockData.Length)]) {
        $DecodedData = $Null
        $DecodedData = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($Datum.data)) | ConvertFrom-JSON
        $ReturnCollection += $DecodedData
        }
    Return $ReturnCollection
    }

Function Summarize-GroupData ($PresummaryData) {
    $SummarizedChanges = @()
    $DomainChanges = $Presummarydata | Group-Object -Property domain
    Foreach ($Domain in $DomainChanges) {
        $UserChanges = $Null
        $UserChanges = $Domain.Group | Group-Object -Property user
        Foreach ($User in $UserChanges) {
            $GroupChanges = $Null
            $GroupChanges = $User.group | Group-Object -Property group
            Foreach ($Group in $GroupChanges) {
                $SummarizedChange = $Null
                $SummarizedChange = $Group.group | Sort-Object -Property timestamp -Descending | Select-Object -First 1
                $SummarizedChanges += $SummarizedChange
                }
            
            }
        }
    Return $SummarizedChanges
    }



$BlockFile = @"
index,data,datahash,blockhash
0,ewANAAoAIAAgACAAIAAiAGIAbABvAGMAawBjAGgAYQBpAG4AaQBkACIAOgAgACAAIgAwADAAMQAiAA0ACgB9AA==,9524499c0ee5cedcd4892f1a2c36c5ba,9524499c0ee5cedcd4892f1a2c36c5ba
"@

$BlockFilePath = "$Env:userprofile\desktop\blockfile.txt"
$BlockFile | Out-File $BlockFilePath

Set-BlockchainedGroupMembership -User "banana1" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana2" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana3" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana1" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana2" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana3" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana1" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana2" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana3" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana2" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana3" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana1" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana2" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana3" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana1" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana2" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana3" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana2" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana1" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana2" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana3" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana1" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana2" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana3" -Group "Domain Admins" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana1" -Group "Administrators" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana2" -Group "Administrators" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana3" -Group "Administrators" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana1" -Group "Administrators" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana2" -Group "Administrators" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana3" -Group "Administrators" -Domain "TestDomain" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana1" -Group "Domain Admins" -Domain "TestDomain2" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana2" -Group "Domain Admins" -Domain "TestDomain2" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana3" -Group "Domain Admins" -Domain "TestDomain2" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana1" -Group "Domain Admins" -Domain "TestDomain2" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana2" -Group "Domain Admins" -Domain "TestDomain2" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana3" -Group "Domain Admins" -Domain "TestDomain2" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana1" -Group "Administrators" -Domain "TestDomain2" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana2" -Group "Administrators" -Domain "TestDomain2" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana3" -Group "Administrators" -Domain "TestDomain2" -BlockFilePath $BlockFilePath -Action "Add"
Set-BlockchainedGroupMembership -User "banana1" -Group "Administrators" -Domain "TestDomain2" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana2" -Group "Administrators" -Domain "TestDomain2" -BlockFilePath $BlockFilePath -Action "Remove"
Set-BlockchainedGroupMembership -User "banana3" -Group "Administrators" -Domain "TestDomain2" -BlockFilePath $BlockFilePath -Action "Remove"


$ValidatedBlockchain = Validate-BlockChain -BlockFilePath $BlockFilePath
$PresummaryData = Decode-JSONBlockchain -BlockData $ValidatedBlockchain
$SummarizedData = Summarize-GroupData $PresummaryData

$SummarizedData


