# SDPA.jl

[![Build Status](https://github.com/jump-dev/SDPA.jl/workflows/CI/badge.svg?branch=master)](https://github.com/jump-dev/SDPA.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/jump-dev/SDPA.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jump-dev/SDPA.jl)

[SDPA.jl](https://github.com/jump-dev/SDPA.jl) is a wrapper for the
[SDPA](http://sdpa.sourceforge.net/) semidefinite programming solver in double
precision floating point arithmetic.

## Affiliation

This wrapper is maintained by the JuMP community and is not a product of the
SDPA developers.

## License

`SDPA.jl` is licensed under the [MIT License](https://github.com/jump-dev/SDPA.jl/blob/master/LICENSE.md).

The underlying solver, [SDPA](http://sdpa.sourceforge.net/) is licensed
under the [GPL v2 license](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).

## Installation

Install SDPA using `Pkg.add`:
```julia
import Pkg
Pkg.add("SDPA")
```

In addition to installing the SDPA.jl package, this will also download and
install the SDPA binaries. (You do not need to install SDPA separately.)

If you see an error similar to:
```julia
INFO: Precompiling module GZip.
ERROR: LoadError: LoadError: error compiling anonymous: could not load library "libz"
```
please see [GZip.jl#54](https://github.com/JuliaIO/GZip.jl/issues/54) or [Flux.jl#343](https://github.com/FluxML/Flux.jl/issues/343). In particular, in Ubuntu this issue may be resolved by running
```bash
sudo apt-get install zlib1g-dev
```

See [SDPAFamily](https://github.com/ericphanson/SDPAFamily.jl) for the other
solvers, SDPA-GMP, SDPA-DD, and SDPA-QD of the family.

## Use with JuMP

```julia
using JuMP, SDPA
model = Model(SDPA.Optimizer)
set_attribute(model, "Mode", SDPA.PARAMETER_DEFAULT)
```

## MathOptInterface API

The SDPA optimizer supports the following constraints and attributes.

List of supported objective functions:

 * [`MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}`](@ref)

List of supported variable types:

 * [`MOI.Nonnegatives`](@ref)
 * [`MOI.PositiveSemidefiniteConeTriangle`](@ref)

List of supported constraint types:

 * [`MOI.ScalarAffineFunction{Float64}`](@ref) in [`MOI.EqualTo{Float64}`](@ref)

List of supported model attributes:

 * [`MOI.ObjectiveSense()`](@ref)

## Options

SDPA has three modes that give default value to all ten parameters.

The following table gives the default values for each parameter and mode.

| Parameter    | `PARAMETER_DEFAULT` | `PARAMETER_UNSTABLE_BUT_FAST` | `PARAMETER_STABLE_BUT_SLOW` |
| ------------ | ------- | ------ | ------ |
| MaxIteration | 100     | 100    | 1000   |
| EpsilonStar  | 1.0e-7  | 1.0e-7 | 1.0e-7 |
| LambdaStar   | 1.0e+2  | 1.0e+2 | 1.0e+4 |
| OmegaStar    | 2.0     | 2.0    | 2.0    |
| LowerBound   | 1.0e+5  | 1.0e+5 | 1.0e+5 |
| UpperBound   | 1.0e+5  | 1.0e+5 | 1.0e+5 |
| BetaStar     | 0.1     | 0.01   | 0.1    |
| BetaBar      | 0.2     | 0.02   | 0.3    |
| GammaStar    | 0.9     | 0.95   | 0.8    |
| EpsilonDash  | 1.0e-7  | 1.0e-7 | 1.0e-7 |

By default, we put SDPA in the `SDPA.PARAMETER_DEFAULT` mode.

Change the mode using the `"Mode"` option:
```julia
using JuMP, SDPA
model = Model(SDPA.Optimizer)
set_attribute(model, "Mode", SDPA.PARAMETER_STABLE_BUT_SLOW)
```

Note that the parameters are set in the order they are given, so you can set
a mode and then modify parameters from this mode.

```julia
using JuMP, SDPA
model = Model(SDPA.Optimizer)
set_attribute(model, "Mode", SDPA.PARAMETER_STABLE_BUT_SLOW)
set_attribute(model, "MaxIteration", 100)
```

The choice of parameter mode has a large impact on the performance
and stability of SDPA. You should try each mode to see how it performs on
your specific problem. See [SDPA.jl#17](https://github.com/jump-dev/SDPA.jl/issues/17)
for more details.
