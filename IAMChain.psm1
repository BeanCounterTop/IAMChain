# These functions are part of the IAMChain.ps1 example blockchain Access Management script.

Function New-AuthEntry ($User, $Group, $Domain, $Action, $ReferenceID) {
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
    $DataObject = @{
            domain=$Domain; 
            user=$User; 
            group=$Group; 
            action=$Action; 
            ReferenceID=$ReferenceID; 
            timestamp=$TimeStamp} | ConvertTo-JSON
    $EncodedData = Base64Encode-String -String $DataObject
    Return $EncodedData
    }

Function Base64Encode-String ($String) {
    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($String)
    $EncodedData =[Convert]::ToBase64String($Bytes)
    Return $EncodedData
    }
        
Function Base64Decode-JSON ($String){
    [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($String))
    }
    

Function Decode-JSONBlockchain ($BlockData){
        $ReturnCollection = @() 
        Foreach ($Datum in $BlockData[1..($BlockData.Length)]) {
            $DecodedData = $Null
            $DecodedData = Base64Decode-JSON -String $Datum.data | ConvertFrom-JSON
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

