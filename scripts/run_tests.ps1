$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

New-Item -ItemType Directory -Force sim | Out-Null

$iverilog = Get-Command iverilog -ErrorAction SilentlyContinue
$vvp = Get-Command vvp -ErrorAction SilentlyContinue

if (-not $iverilog -or -not $vvp) {
    throw "Icarus Verilog (iverilog and vvp) is required. Add its bin directory to PATH."
}

$tests = @(
    @{
        Name = "MAC unit"
        Source = @("rtl/mac/mac_unit.sv", "tb/unit/mac_unit_tb.sv")
        Top = "mac_unit_tb"
        Output = "sim/mac_unit_tb.vvp"
    },
    @{
        Name = "Processing element"
        Source = @("rtl/pe/processing_element.sv", "tb/unit/processing_element_tb.sv")
        Top = "processing_element_tb"
        Output = "sim/processing_element_tb.vvp"
    },
    @{
        Name = "Systolic array integration"
        Source = @("rtl/pe/processing_element.sv", "rtl/array/systolic_array.sv", "tb/integration/systolic_array_tb.sv")
        Top = "systolic_array_tb"
        Output = "sim/systolic_array_tb.vvp"
    }
)

$failed = 0

foreach ($test in $tests) {
    Write-Host "`n=== $($test.Name) ===" -ForegroundColor Cyan

    $compileArgs = @("-g2012", "-s", $test.Top, "-o", $test.Output) + $test.Source
    & $iverilog.Source @compileArgs

    if ($LASTEXITCODE -ne 0) {
        Write-Host "COMPILE FAILED: $($test.Name)" -ForegroundColor Red
        $failed++
        continue
    }

    & $vvp.Source $test.Output

    if ($LASTEXITCODE -ne 0) {
        Write-Host "TEST FAILED: $($test.Name)" -ForegroundColor Red
        $failed++
    } else {
        Write-Host "Simulation exited successfully: $($test.Name)" -ForegroundColor Green
    }
}

if ($failed -gt 0) {
    throw "$failed test group(s) failed."
}

Write-Host "`nAll regression test groups completed successfully." -ForegroundColor Green
