param(
  [switch]$AutoApprove,
  [string]$VarFile = "terraform.tfvars"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
  Write-Error "Terraform CLI is not installed or not available in PATH."
}

if (-not (Test-Path $VarFile)) {
  Write-Error "Var file '$VarFile' was not found in $scriptDir."
}

if (-not (Test-Path ".terraform")) {
  Write-Host "Terraform is not initialized in this folder. Running terraform init..."
  terraform init
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

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
