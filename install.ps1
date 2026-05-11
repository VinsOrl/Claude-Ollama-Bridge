Write-Host "Starting claude-ollama installation..." -ForegroundColor Cyan

# 1. Ensure the Profile exists
if (!(Test-Path -Path $PROFILE)) { 
    Write-Host "Creating PowerShell profile at $PROFILE..."
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# 2. Define the exact function code (Fully Escaped for Installer)
$FunctionCode = @"

# --- claude-ollama start ---
function claude-ollama {
    `$rawList = ollama list
    if (`$null -eq `$rawList) { Write-Host "Error: Ollama not found." -ForegroundColor Red; return }

    `$models = `$rawList | Select-Object -Skip 1 | ForEach-Object { (`$_ -split "\s+")[0] }
    if (`$models.Count -eq 0) { Write-Host "Error: No models found." -ForegroundColor Red; return }

    Write-Host "`n--- Choose your model ---" -ForegroundColor Cyan
    for (`$i=0; `$i -lt `$models.Count; `$i++) { Write-Host "`$(`$i+1)) `$(`$models[`$i])" }

    `$selection = Read-Host "`nSelect a model (number)"
    `$index = [int]`$selection - 1

    if (`$index -ge 0 -and `$index -lt `$models.Count) { `$selectedModel = `$models[`$index] } 
    else { Write-Host "Invalid selection." -ForegroundColor Red; return }

    Write-Host "`n--- Session Options ---" -ForegroundColor Cyan
    Write-Host "1) Start a New Session"
    Write-Host "2) Resume an Existing Session"
    `$sessionChoice = Read-Host "`nSelect an option (1 or 2)"

    `$env:ANTHROPIC_BASE_URL = "http://localhost:11434"
    `$env:ANTHROPIC_API_KEY = "ollama"

    if (`$sessionChoice -eq '1') {
        Write-Host "Starting new session with `$selectedModel..." -ForegroundColor Green
        claude --model `$selectedModel
    } 
    elseif (`$sessionChoice -eq '2') {
        `$SessionId = Read-Host "`nEnter Session ID (Leave blank for latest)"
        if ([string]::IsNullOrWhiteSpace(`$SessionId)) {
            Write-Host "Resuming latest session with `$selectedModel..." -ForegroundColor Green
            claude --model `$selectedModel --continue
        } else {
            Write-Host "Resuming session `$SessionId with `$selectedModel..." -ForegroundColor Green
            claude --model `$selectedModel --resume `$SessionId
        }
    } 
    else {
        Write-Host "Invalid choice. Exiting." -ForegroundColor Red
    }
}
# --- claude-ollama end ---
"@

# 3. Prevent duplicate installations
$ProfileContent = Get-Content $PROFILE -ErrorAction SilentlyContinue
if ($ProfileContent -match "function claude-ollama") {
    Write-Host "Warning: claude-ollama is already installed in your profile!" -ForegroundColor Yellow
    Write-Host "If you want to update it, please manually remove the old version from your `$PROFILE first."
} else {
    # 4. Inject the code
    Add-Content -Path $PROFILE -Value $FunctionCode
    Write-Host "Installation Successful!" -ForegroundColor Green
    Write-Host "Please restart your terminal, or run: . `$PROFILE" -ForegroundColor White
}