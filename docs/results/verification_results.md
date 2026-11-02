# Verification and Synthesis Results

## 1. Verification Summary

Randomized integration verification was completed for the following array dimensions:

| Configuration | Randomized Matrix Multiplications | Output Comparisons | Result |
|---|---:|---:|---|
| 1x1 | 10 | 10 | PASS |
| 2x2 | 10 | 40 | PASS |
| 4x4 | 10 | 160 | PASS |
| 8x8 | 10 | 640 | PASS |
| **Total** | **40** | **850** | **PASS** |

The tests compare the RTL results against reference matrix multiplication for signed input data. These results represent the recorded randomized integration test campaign.

Additional earlier tests covered signed arithmetic, identity matrices, general matrix multiplication, random full-range 8-bit inputs, arithmetic corner cases, and control behavior.

## 2. Lint

Verilator lint was run on the parameterized array design. The documented configuration used an 8-bit data width and a 32-bit accumulator.

Command:

```powershell
verilator --lint-only --Wall --top-module systolic_array -GARRAY_SIZE=4 -GDATA_WIDTH=8 -GACC_WIDTH=32 rtl/pe/processing_element.sv rtl/array/systolic_array.sv
```

The final lint run completed without warnings for this configuration.

## 3. Generic Synthesis

Yosys generic synthesis was completed for 2x2, 4x4, and 8x8 configurations.

| Configuration | Processing Elements | Generic Synthesized Cells |
|---|---:|---:|
| 2x2 | 4 | 4,053 |
| 4x4 | 16 | 15,981 |
| 8x8 | 64 | 64,214 |

Source CSV: `synthesis/configuration_summary.csv`

Synthesis logs:

- `synthesis/yosys_2x2.log`
- `synthesis/yosys_4x4.log`
- `synthesis/yosys_8x8.log`

The reports indicate that Yosys completed synthesis and reported zero problems in its checks.

## 4. Interpretation

The processing-element count scales quadratically with array dimension:

N x N -> N² processing elements.

Generic cell counts increase with array size because the implementation contains more processing elements, registers, arithmetic logic, and interconnect/control logic.

Generic cell counts are dependent on the synthesis tool, optimization settings, and RTL representation. They are not equivalent to physical area in square micrometres.

## 5. Physical PPA Status

The current project does not have a verified SKY130 technology-mapped result.

| Metric | Status |
|---|---|
| Functional simulation | Completed; recorded tests passed |
| Verilator lint | Completed for the documented configuration |
| Generic Yosys synthesis | Completed for 2x2, 4x4, 8x8 |
| SKY130 mapped cell area | Not measured |
| Post-placement timing | Not measured |
| Power consumption | Not measured |
| Physical design / routing | Not completed |

A valid standard-cell Liberty file and an appropriate mapping or physical-design flow are required before reporting technology-specific area and timing. Power estimation additionally requires suitable activity and implementation information.

## 6. Reproducibility

Run commands from the repository root. The recorded generic synthesis command pattern is:

```powershell
yosys -p "read_verilog -sv -defer rtl/pe/processing_element.sv rtl/array/systolic_array.sv; chparam -set ARRAY_SIZE 4 -set DATA_WIDTH 8 -set ACC_WIDTH 32 systolic_array; hierarchy -top systolic_array; synth -top systolic_array; check; stat"
```

Replace `ARRAY_SIZE 4` with `2` or `8` to evaluate the other configurations. The recorded logs are the primary source for the reported counts.

## 7. Conclusion

The project demonstrates a parameterized SystemVerilog systolic-array matrix multiplication accelerator with successful recorded randomized verification and generic synthesis across three array sizes. Technology-mapped PPA remains future work.
