# SDPA

| **Build Status** |
|:----------------:|
| [![Build Status][build-img]][build-url] |
| [![Coveralls branch][coveralls-img]][coveralls-url] [![Codecov branch][codecov-img]][codecov-url] |

Julia wrapper to [SDPA](http://sdpa.sourceforge.net/) semidefinite programming solver.
Write `SDPASolver()` to use this solver with [JuMP](github.com/JuliaOpt/JuMP.jl), [Convex](https://github.com/JuliaOpt/Convex.jl) or any other package using the [MathProgBase](https://github.com/JuliaOpt/MathProgBase.jl) interface.

## Installation

You can install SDPA.jl as follows:
```julia
julia> Pkg.add("https://github.com/blegat/SDPA.jl.git")
julia> Pkg.build("https://github.com/blegat/SDPA.jl.git")
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
