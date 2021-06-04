$resourceGroupName = "your-rsg"
$storageAccountName = "saname"
$containerName = "extensions"

Set-AzCurrentStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName

$templates = Get-ChildItem .\*.json -Exclude ("base-*.json", "master-*.json", "*.params.json")
foreach($template in $templates)
{
  $filePath = $template.fullname
  Set-AzStorageBlobContent -Container $containerName -File $filePath -Force
}
