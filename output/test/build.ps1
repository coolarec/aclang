param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile
)

# ---------------------------------------------------------
# 1. Environment & Variable Setup
# ---------------------------------------------------------
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
# Define the output directory based on the file name
$outputDir = $baseName
$asmFile = "$outputDir/$baseName.asm"
$objFile = "$outputDir/$baseName.o"
$exeFile = "$outputDir/$baseName.exe"

# Directory Check: Create the folder if it doesn't exist
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
    Write-Host "[INFO] Created output directory: $outputDir" -ForegroundColor Gray
}

Write-Host "`n[INFO] Initializing build pipeline for: $InputFile" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------"

# ---------------------------------------------------------
# 2. Step 1: Transpilation (AC to Assembly)
# ---------------------------------------------------------
Write-Host "[STEP 1] Running AC Transpiler (acc)..." -ForegroundColor White

# Executing the compiler
$asmContent = Get-Content $InputFile | ./acc

# Error Handling: Check if 'acc' failed
if ($LASTEXITCODE -ne 0) {
    Write-Host "[CRITICAL ERROR] Transpiler failed with Exit Code: $LASTEXITCODE" -ForegroundColor Red
    Write-Host "Check your $InputFile for syntax errors." -ForegroundColor Yellow
    exit 1
}

# Write the assembly code to the file (No-BOM UTF8)
try {
    [System.IO.File]::WriteAllLines((Join-Path $pwd $asmFile), $asmContent)
    Write-Host "  >> Success: Created $asmFile" -ForegroundColor Gray
} catch {
    Write-Host "[CRITICAL ERROR] Failed to write $asmFile. Ensure the path is valid." -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------
# 3. Step 2: Assembly (NASM)
# ---------------------------------------------------------
Write-Host "[STEP 2] Assembling with NASM (win64)..." -ForegroundColor White
nasm -f win64 $asmFile -o $objFile

# Error Handling: Check if 'nasm' failed
if ($LASTEXITCODE -ne 0) {
    Write-Host "[CRITICAL ERROR] NASM Assembly failed with Exit Code: $LASTEXITCODE" -ForegroundColor Red
    exit 1
}
Write-Host "  >> Success: Created $objFile" -ForegroundColor Gray

# ---------------------------------------------------------
# 4. Step 3: Linking (GCC)
# ---------------------------------------------------------
Write-Host "[STEP 3] Linking with GCC..." -ForegroundColor White
gcc $objFile -o $exeFile

# Error Handling: Check if 'gcc' failed
if ($LASTEXITCODE -ne 0) {
    Write-Host "[CRITICAL ERROR] GCC Linker failed with Exit Code: $LASTEXITCODE" -ForegroundColor Red
    exit 1
}
Write-Host "  >> Success: Created $exeFile" -ForegroundColor Gray

# ---------------------------------------------------------
# 5. Build Finalization
# ---------------------------------------------------------
Write-Host "--------------------------------------------------------"
Write-Host "[COMPLETED] Application built successfully!" -ForegroundColor Green
Write-Host "Executable Path: .\$exeFile" -ForegroundColor Cyan