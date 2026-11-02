# Parameterized Systolic-Array Matrix Multiplication Accelerator

A parameterized RTL implementation of a systolic-array accelerator for matrix multiplication, developed using SystemVerilog and evaluated with simulation, linting, and generic logic synthesis.

## Project Overview

Matrix multiplication is a fundamental operation in digital signal processing, machine learning, and computer vision. A systolic array uses interconnected processing elements (PEs) to perform multiply-accumulate operations in a structured, parallel dataflow.

This project implements a configurable N x N systolic array with signed 8-bit input data and 32-bit accumulators by default.

## Key Features

- Parameterized array dimensions.
- Modular SystemVerilog RTL.
- Processing elements with multiply-accumulate functionality.
- Signed arithmetic support.
- Unit-level and integration-level testbenches.
- Randomized matrix multiplication verification.
- Verilator lint checks.
- Yosys generic synthesis for multiple configurations.
- Recorded synthesis logs and machine-readable results.

## Architecture

The design is organized into three main RTL modules:

- `rtl/mac/mac_unit.sv` — multiply-accumulate logic.
- `rtl/pe/processing_element.sv` — processing element with registered data propagation and accumulation.
- `rtl/array/systolic_array.sv` — parameterized systolic-array integration and control.

See [Architecture Documentation](docs/architecture/architecture.md).

## Repository Structure

```text
.
├── docs/
│   ├── README.md
│   ├── architecture/
│   │   └── architecture.md
│   └── results/
│       └── verification_results.md
├── rtl/
│   ├── array/
│   ├── mac/
│   └── pe/
├── scripts/
│   └── run_tests.ps1
├── sim/
├── synthesis/
│   ├── configuration_summary.csv
│   ├── yosys_2x2.log
│   ├── yosys_4x4.log
│   └── yosys_8x8.log
└── tb/
    ├── integration/
    └── unit/
```

## Tools

- SystemVerilog
- Icarus Verilog for simulation
- Verilator for linting
- Yosys for synthesis
- GTKWave for waveform inspection, when needed

## Verification Results

Randomized integration tests completed successfully for 1x1, 2x2, 4x4, and 8x8 configurations.

The recorded multi-configuration campaign covered 40 randomized matrix multiplications and 850 output comparisons, all passing.

See [Verification and Synthesis Results](docs/results/verification_results.md).

## Generic Synthesis Results

| Configuration | Processing Elements | Generic Synthesized Cells |
|---|---:|---:|
| 2x2 | 4 | 4,053 |
| 4x4 | 16 | 15,981 |
| 8x8 | 64 | 64,214 |

These figures are generic Yosys synthesis cell counts. They are not physical standard-cell area measurements.

## Limitations

Technology-mapped SKY130 area, post-placement timing, power consumption, and physical-design results have not been established. The current synthesis results should not be presented as measured ASIC PPA.

## Future Work

- Complete standard-cell technology mapping with a valid Liberty library.
- Evaluate timing and area using a compatible physical-design flow.
- Add automated synthesis and regression scripts.
- Explore larger array dimensions and alternative data widths.
- Compare design configurations using consistent implementation constraints.

## License

No project license has been specified yet.
