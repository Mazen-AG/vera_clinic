# Run the full CI pipeline locally
# Use before pushing to catch issues without waiting for CI/CD

$ErrorActionPreference = "Stop"

function Assert-ExitCode {
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "========================================="
        Write-Host "  CI FAILED (exit code $LASTEXITCODE)"
        Write-Host "========================================="
        exit $LASTEXITCODE
    }
}

Write-Host "========================================="
Write-Host "  Running full CI pipeline locally"
Write-Host "========================================="
Write-Host ""

# Project root = parent of scripts folder
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

# 1. Update dependencies
Write-Host "[1/5] Updating dependencies..."
flutter pub get ; Assert-ExitCode
Write-Host "  Done"
Write-Host ""

# 2. Create apiKeys.dart from template (if needed)
Write-Host "[2/5] Setting up Firebase configurations..."
if (Test-Path "lib/firebase_setup/apiKeys.dart.example") {
    Copy-Item lib/firebase_setup/apiKeys.dart.example lib/firebase_setup/apiKeys.dart -Force
}
Write-Host "  Done"
Write-Host ""

# 3. Apply dart fixes (unused imports, deprecated APIs, etc.)
Write-Host "[3/5] Applying dart fixes..."
dart fix --apply . ; Assert-ExitCode
Write-Host "  Done"
Write-Host ""

# 4. Analyze
Write-Host "[4/5] Analyzing..."
flutter analyze ; Assert-ExitCode
Write-Host "  Done"
Write-Host ""

# 5. Tests
Write-Host "[5/5] Running tests..."
flutter test ; Assert-ExitCode
Write-Host ""

Write-Host "========================================="
Write-Host "  All CI checks passed!"
Write-Host "========================================="
