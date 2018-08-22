# Very basic blockchain functions


Function Get-StringHash([String] $String,$HashName = "MD5") {
    if ($IsMacOS) {
        $return = iex "echo $string | md5"
        Return $Return
        }
    If ($IsWindows){
    $StringBuilder = New-Object System.Text.StringBuilder
    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{
        [Void]$StringBuilder.Append($_.ToString("x2"))
        }
        $StringBuilder.ToString()
        }
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

Function Initialize-BlockChain ($Data,$BlockFilePath){
    $InitialHash = Get-StringHash -String $Data
    $BlockFile = @"
index,data,datahash,blockhash
0,$Data,$InitialHash,$InitialHash
"@
    $BlockFile | Out-File $BlockFilePath
    }   



