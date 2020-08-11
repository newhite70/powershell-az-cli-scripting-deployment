# TODO: set variables
$studentName = "Nick"
$lcName = "lc0820-ps"
$rgName = "${studentName}-${lcName}-rg"
$vmName = "${studentName}-${lcName}-vm"
$vmSize = "Standard_B2s"
$vmImage = "Canonical:UbuntuServer:18.04-LTS:latest"
$vmAdminUsername = "student"
$vmAdminPass='LaunchCode-@zure1'
$kvName = "${studentName}-${lcName}-kv4"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

# default location
az configure --default location=eastus

# TODO: provision RG
az group create -n "$rgName"

# set group default
az configure --default group=$rgName
# TODO: provision VM
$vmDeets = az vm create -n $vmName --size $vmSize --image "$vmImage" --admin-username $vmAdminUsername --admin-password $vmAdminPass --authentication-type password --assign-identity
az configure --default vm=$vmName

# TODO: capture the VM systemAssignedIdentity



$vmId = ($vmDeets | ConvertFrom-Json).identity.systemAssignedIdentity

# get the ip for output

$vmIp=($vmDeets | ConvertFrom-Json).publicIpAddress



# TODO: open vm port 443
az vm open-port --port 443
# provision KV

az keyvault create -n $kvName --enable-soft-delete false --enabled-for-deployment true
az configure --default kv=$kvName
# TODO: create KV secret (database connection string)
az keyvault secret set --vault-name "$kvName" -n "$kvSecretName"  --value "$kvSecretValue"

# TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)
az keyvault set-policy -n "$kvName" --object-id "$vmId" --secret-permissions get list

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/1configure-vm.sh

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/2configure-ssl.sh

az vm run-command invoke --command-id RunShellScript --scripts @deliver-deploy.sh


# TODO: print VM public IP address to STDOUT or save it as a file

Write-Output "The IP of the VM is $vmIp"