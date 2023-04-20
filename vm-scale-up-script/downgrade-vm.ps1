# Scale-Down VM and Disk Configuration

# Variables
$ResourceGroupName = 'rg-demo'
$VMName = 'vm-jumpbox'
$OriginalVMSize = 'Standard_B2s'
$OriginalOSDiskSku = 'Standard_LRS'
$OriginalDataDiskSku = 'Standard_LRS' # Specify original data disk SKU
$OriginalDataDiskCaching = 'None' # Host caching disabled for data disk

Write-Host "Starting scale-down process..." -ForegroundColor Green

# Stop and deallocate the VM
Write-Host "Stopping and deallocating the VM..."
Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force

# Update the VM size
Write-Host "Updating the VM size..."
$vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
$vm.HardwareProfile.VmSize = $OriginalVMSize
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm

# Update the OS disk tier
Write-Host "Updating the OS disk tier..."
$osDiskName = $vm.StorageProfile.OsDisk.Name
$osDisk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $osDiskName
$osDisk.Sku = [Microsoft.Azure.Management.Compute.Models.DiskSku]::new($OriginalOSDiskSku)
Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $osDisk.Name -Disk $osDisk

# Update the data disk tier and caching (assuming a single data disk attached)
Write-Host "Updating the data disk tier and caching..."
$dataDiskName = $vm.StorageProfile.DataDisks[0].Name
$dataDisk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $dataDiskName
$dataDisk.Sku = [Microsoft.Azure.Management.Compute.Models.DiskSku]::new($OriginalDataDiskSku)
Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $dataDisk.Name -Disk $dataDisk
$vm.StorageProfile.DataDisks[0].Caching = $OriginalDataDiskCaching
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm

# Start the VM
Write-Host "Starting the VM..."
Start-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName

Write-Host "Scale-down process completed successfully!" -ForegroundColor Green
