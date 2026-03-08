<#
IMPORTANT:
- Script performs rollback by running `terraform destroy` with the same var file.
- It validates Terraform availability, var file presence, and initializes if needed.
- Use `-AutoApprove` only when you are sure.

NOT IMPORTANT:
- Console messages are informational; core action is destroy.
#>

<#
SECTION: Input parameters
IMPORTANT:
- AutoApprove controls interactive vs non-interactive destroy.
- VarFile must match the values used during apply.
#>
param(
  [switch]$AutoApprove,
  [string]$VarFile = "terraform.tfvars"
)

<#
SECTION: Preconditions
IMPORTANT:
- Enforces fail-fast behavior and runs in this script's folder.
#>
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
  Write-Error "Terraform CLI is not installed or not available in PATH."
}

if (-not (Test-Path $VarFile)) {
  Write-Error "Var file '$VarFile' was not found in $scriptDir."
}

<#
SECTION: Init check
IMPORTANT:
- Ensures providers are initialized before destroy.
#>
if (-not (Test-Path ".terraform")) {
  Write-Host "Terraform is not initialized in this folder. Running terraform init..."
  terraform init
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

<#
SECTION: Destroy execution
IMPORTANT:
- This is the actual rollback operation.
#>
$destroyArgs = @("destroy", "-var-file=$VarFile")
if ($AutoApprove) {
  $destroyArgs += "-auto-approve"
}

Write-Host "Running: terraform $($destroyArgs -join ' ')"
terraform @destroyArgs
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "Rollback complete. Terraform-managed resources were destroyed."
