# SDPA

| **Build Status** | **References to cite** |
|:----------------:|:----------------------:|
| [![Build Status][build-img]][build-url] | [![DOI][zenodo-img]][zenodo-url] |
| [![Coveralls branch][coveralls-img]][coveralls-url] [![Codecov branch][codecov-img]][codecov-url] | |

Julia wrapper to [SDPA](http://sdpa.sourceforge.net/) semidefinite programming solver.
Write `SDPASolver()` to use this solver with [JuMP](github.com/JuliaOpt/JuMP.jl), [Convex](https://github.com/JuliaOpt/Convex.jl) or any other package using the [MathProgBase](https://github.com/JuliaOpt/MathProgBase.jl) interface.

## Parameters

SDPA has 10 parameters that can be set separately using, e.g. `SDPASolver(MaxIteration=100)` to set the parameter with name `MaxIteration` at the value 100.
SDPA has 3 modes that give values to all 10 parameters. By default, we put SDPA in the `PARAMETER_DEFAULT` mode.
The three modes are as follow:

| Mode    | Name                          |
| ------- | ----------------------------- |
| Default | `PARAMETER_DEFAULT`           |
| Fast    | `PARAMETER_UNSTABLE_BUT_FAST` |
| Slow    | `PARAMETER_STABLE_BUT_SLOW`   |

To set the SDPA solver in a mode you do, e.g. `SDPASolver(Mode=PARAMETER_UNSTABLE_BUT_FAST)`.
Note that the parameters are set in the order they are given so you can set it in a mode and then modify one parameter from this mode, e.g. `SDPASolver(Mode=PARAMETER_UNSTABLE_BUT_FAST, MaxIteration=1000)`.

Note that `PARAMETER_UNSTABLE_BUT_FAST` appears to be the most reliable of the three modes, at least in some cases; e.g. it gives the fewest failures on Convex.jl's tests (see [#17](https://github.com/JuliaOpt/SDPA.jl/issues/17#issuecomment-502045684)).

The following table gives the default value for each parameter.

| Parameter name | Default | Fast   | Slow   |
| -------------- | ------- | ------ | ------ |
| MaxIteration   | 100     | 100    | 1000   |
| EpsilonStar    | 1.0e-7  | 1.0e-7 | 1.0e-7 |
| LambdaStar     | 1.0e+2  | 1.0e+2 | 1.0e+4 |
| OmegaStar      | 2.0     | 2.0    | 2.0    |
| LowerBound     | 1.0e+5  | 1.0e+5 | 1.0e+5 |
| UpperBound     | 1.0e+5  | 1.0e+5 | 1.0e+5 |
| BetaStar       | 0.1     | 0.01   | 0.1    |
| BetaBar        | 0.2     | 0.02   | 0.3    |
| GammaStar      | 0.9     | 0.95   | 0.8    |
| EpsilonDash    | 1.0e-7  | 1.0e-7 | 1.0e-7 |

## Installation

The package is registered in `METADATA.jl` and so can be installed with `Pkg.add`.

```
julia> import Pkg; Pkg.add("SDPA")
```

SDPA.jl will use [BinaryProvider.jl](https://github.com/JuliaPackaging/BinaryProvider.jl) to automatically install the SDPA binaries for Linux and OS X. This should work for both the official Julia binaries from `https://julialang.org/downloads/` and source-builds that used `gcc` versions 7 or 8. 

*NOTE:* If you see an error similar to 
```julia
INFO: Precompiling module GZip.
ERROR: LoadError: LoadError: error compiling anonymous: could not load library "libz"
```
please see [GZip.jl#54](https://github.com/JuliaIO/GZip.jl/issues/54) or [Flux.jl#343](https://github.com/FluxML/Flux.jl/issues/343). In particular, in Ubuntu this issue may be resolved by running
```bash
sudo apt-get install zlib1g-dev
```

## Custom Installation

To install custom built SDPA binaries set the environmental variable `JULIA_SDPA_LIBRARY_PATH` and call `import Pkg; Pkg.build("SDPA")`. For instance, if the libraries are installed in `/opt/lib`, then call
```julia
ENV["JULIA_SDPA_LIBRARY_PATH"] = "/opt/lib"
import Pkg; Pkg.build("SDPA")
```
If you do not want BinaryProvider to download the default binaries on install, set `JULIA_SDPA_LIBRARY_PATH` before calling `import Pkg; Pkg.add("SDPA")`.

To switch back to the default binaries clear `JULIA_SDPA_LIBRARY_PATH` and call `import Pkg; Pkg.build("SDPA")`.


[build-img]: https://travis-ci.org/JuliaOpt/SDPA.jl.svg?branch=master
[build-url]: https://travis-ci.org/JuliaOpt/SDPA.jl
[coveralls-img]: https://coveralls.io/repos/blegat/SDPA.jl/badge.svg?branch=master&service=github
[coveralls-url]: https://coveralls.io/github/blegat/SDPA.jl?branch=master
[codecov-img]: http://codecov.io/github/JuliaOpt/SDPA.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/JuliaOpt/SDPA.jl?branch=master

[zenodo-url]: https://doi.org/10.5281/zenodo.1285668
[zenodo-img]: https://zenodo.org/badge/DOI/10.5281/zenodo.1285668.svg
