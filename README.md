# SDPA

| **Build Status** |
|:----------------:|
| [![Build Status][build-img]][build-url] |
| [![Coveralls branch][coveralls-img]][coveralls-url] [![Codecov branch][codecov-img]][codecov-url] |

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

You can install SDPA.jl as follows:
```julia
julia> Pkg.add("https://github.com/blegat/SDPA.jl.git")
julia> Pkg.build("SDPA")
```

The `Pkg.build` command will compile SDPA from source, you will need to install the following dependencies for the compilation to work.

### Ubuntu
```sh
$ sudo apt-get install build-essential gfortran liblapack-dev libopenblas-dev
```
**Note**: This package currently does not work with the LAPACK/OPENBLAS versions shipped with Julia; see [#1](https://github.com/blegat/SDPA.jl/issues/1).

### Arch Linux
```sh
$ sudo pacman -S gcc-gfortran
```
**Note**: The Julia Arch Linux package has already installed the system LAPACK and OPENBLAS so you shouldn't need to do anything for these two dependencies.

### Mac OS X
```sh
$ xcode-select --install # Optional, that makes homebrew downloads a precompiled binary for gcc
$ brew install libtool gcc cmake wget autoconf automake # gfortran comes with the gcc package
```

### Windows
Windows support is still a work in progress.

[build-img]: https://travis-ci.org/blegat/SDPA.jl.svg?branch=master
[build-url]: https://travis-ci.org/blegat/SDPA.jl
[coveralls-img]: https://coveralls.io/repos/blegat/SDPA.jl/badge.svg?branch=master&service=github
[coveralls-url]: https://coveralls.io/github/blegat/SDPA.jl?branch=master
[codecov-img]: http://codecov.io/github/blegat/SDPA.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/blegat/SDPA.jl?branch=master
