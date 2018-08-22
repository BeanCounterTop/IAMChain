#This is an example partial implementation of a blockchain-secured group membership assignment system.  
# This example does these things:
#  *Creates a blockchain
#  *Adds 1000 Base64-encoded JSON objects to the blockchain
#  *Verifies the blockchain's integrity
#  *Decodes the verified data
#  *Parses the data back into objects ready for further processing
#
# The main point of the example is to show how easy it is to secure data in this manner, and how simply
# it could be applied to Access Management.  It is presently missing the components necessary to secure the writes
# and implement the results against a directory, among other things.
#
# Compatibility:
#  *Windows
#  *MacOS
#
# Written by: Nate Schoolfield (nate.schoolfield@gmail.com)


Import-Module ./IAMChain.psm1
Import-Module ./Blockchain.psm1

if ($IsWindows) {
    $BlockFilePath = "$Env:userprofile\desktop\blockfile.txt"
    }
If ($IsMacOS) {
    $BlockFilePath = "$Env:HOME/Desktop/blockfile.txt"
    }

$InitialObject = New-AuthEntry -User "Init" -Group "Init" -Domain "Init" -Action "ADD" -ReferenceID "Init"
Initialize-BlockChain -Data $InitialObject -BlockFilePath $BlockFilePath

Foreach ($i in 1..10) {
    Foreach ($j in 1..10){
        Foreach ($k in 1..10){
            $Random = Get-Random -Maximum 100
            If ($Random -gt 50) { $Action = "Add"} else {$Action = "Remove"}
            $Entry = New-AuthEntry -User "User$k" -Group "TestGroup$j" -Domain "TestDomain$i" -Action $Action -ReferenceID "$i`:$j`:$k"
            Add-BlockchainEntry -Data $Entry -BlockFilePath $BlockFilePath
            }
        }
    }

$ValidatedBlockchain = Validate-BlockChain -BlockFilePath $BlockFilePath
$PresummaryData = Decode-JSONBlockchain -BlockData $ValidatedBlockchain
$SummarizedData = Summarize-GroupData $PresummaryData

$SummarizedData
    
    
