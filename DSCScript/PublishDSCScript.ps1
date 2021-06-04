param(

    [Parameter(Mandatory = $true, HelpMessage="The name of the storage account.")]
    [string]$storageaccountname, 
    
    [Parameter(Mandatory = $true, HelpMessage="The name of the container.")]
    [string]$containername, 
    
    [Parameter(Mandatory = $false, HelpMessage="The name of the VM.")]
    [string]$vmname,
    
    [Parameter(Mandatory = $true, HelpMessage="The resource group name.")]
    [string]$resourcegroup, 
	
	[Parameter(Mandatory = $true, HelpMessage="The scriptpath.")]
    [string]$scriptpath,
	
	[Parameter(Mandatory = $false, HelpMessage="The version.")]
    [string]$version = '2.76',
	
	[Parameter(Mandatory = $false, HelpMessage="This is the name of the zip file that gets created to publish.")]
    [string]$ArchiveBlobName,

	[Parameter(Mandatory = $false, HelpMessage="This is the name of the DSC function to run.")]
    [string]$ConfigurationName
)




$parameters = @{
    'configurationpath'     = $scriptpath 
    'resourcegroupname'     = $resourcegroup
    'storageaccountname'    = $storageaccountname
    'ContainerName'         = $containername
}

publish-azvmdscconfiguration @parameters -force -verbose
