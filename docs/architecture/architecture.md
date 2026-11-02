# Architecture Documentation

## 1. Overview

The accelerator implements matrix multiplication using a parameterized systolic array. For matrices A and B, the output matrix C is defined as:

C[i][j] = sum over k of A[i][k] * B[k][j]

The implementation is built from processing elements connected through registered data paths. Each processing element performs signed multiplication and accumulation.

## 2. RTL Modules

### Multiply-Accumulate Unit

File: `rtl/mac/mac_unit.sv`

This module provides the multiply-accumulate building block used by the design. Its implementation and interface are defined in the RTL source.

### Processing Element

File: `rtl/pe/processing_element.sv`

The processing element accepts signed operands, propagates input data through registered outputs, and maintains an accumulator.

Important signals include:

- `clk`: clock.
- `rst_n`: active-low reset.
- `enable`: enables sequential updates.
- `clear_acc`: clears the accumulator when enabled.
- `valid_in`: indicates a valid input operation.
- `a_in`, `b_in`: signed input operands.
- `a_out`, `b_out`: registered operand outputs.
- `acc`: signed accumulated result.
- `valid_out`: registered validity indicator.

The default operand width is 8 bits, and the default accumulator width is 32 bits.

### Systolic Array

File: `rtl/array/systolic_array.sv`

The top-level module integrates processing elements and array control. The array dimension and data widths are configurable through parameters.

The implementation includes parameter checks to reject invalid configurations, including an accumulator width smaller than twice the operand width.

## 3. Parameterization

| Parameter | Default | Purpose |
|---|---:|---|
| `ARRAY_SIZE` | 4 | Number of processing elements along each array dimension |
| `DATA_WIDTH` | 8 | Signed operand width |
| `ACC_WIDTH` | 32 | Accumulator width |

An N x N array contains N² processing elements.

| Array | Processing Elements |
|---|---:|
| 2x2 | 4 |
| 4x4 | 16 |
| 8x8 | 64 |

## 4. Arithmetic

Operands are interpreted as signed two's-complement values. An 8-bit signed operand ranges from -128 to 127.

The product of two signed DATA_WIDTH-bit operands requires up to 2 * DATA_WIDTH bits. The product is sign-extended to the accumulator width before accumulation.

The accumulator is a finite-width register. As with other fixed-width digital arithmetic, sufficiently large accumulated results can overflow the representable range.

## 5. Dataflow

A systolic architecture distributes computation across multiple processing elements, with operands propagated through registered connections and partial sums maintained locally.

This structure supports spatial parallelism and regular data movement. Actual latency and throughput depend on the implemented input scheduling, control logic, and array dimension.

Refer to the RTL and integration testbench for the precise cycle-level behavior and matrix-loading protocol.

## 6. Reset and Control

The processing element uses an active-low asynchronous reset. When reset is asserted, registered operand outputs, the accumulator, and the validity output are cleared.

Sequential updates are controlled by `enable`. The accumulator is cleared when `clear_acc` is asserted during an enabled update; otherwise, a valid input triggers accumulation.

## 7. Verification Structure

- Unit tests: `tb/unit/`
- Integration test: `tb/integration/systolic_array_tb.sv`
- Simulation outputs: `sim/`

Randomized integration tests compare the accelerator outputs with a software reference matrix multiplication across several array sizes.
