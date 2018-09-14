using LinearAlgebra

# If Julia use OpenBlas with the 64_ suffix, I cannot handle that yet, see
# https://discourse.julialang.org/t/blas-headers/3141/4
# So I will use blas installed by the system, i.e. the package manager
const JULIA_LAPACK = LinearAlgebra.BLAS.vendor() != :openblas64

blas = library_dependency("libblas", alias=["libblas.dll"])
lapack = library_dependency("liblapack", alias=["liblapack.dll"])
depends = JULIA_LAPACK ? [] : [blas, lapack]

# It will be called immediately, so if we add providers for blas/lapack, it won't work and BinDeps._find_library will return an empty vector
function ldflags(libpath::AbstractString, libname::AbstractString)
    libdir = dirname(libpath)
    # I use [4:end] to drop the "lib" at the beginning
    linkname = libname[4:end]
    @info("Using $libname at $libpath : -L$libdir -l$linkname")
    @static if Sys.isapple()
        # On Mac OS, -L$libdir/$linkname throws an error since it is not a directory
        return "-L$libdir -l$linkname"
    else
        # In Ubuntu, /usr/lib/lapack.so.3 is detected but we need to link to /usr/lib/lapack. To fix this, we add -L$libdir/$linkname
        return "-L$libdir -L$libdir/$linkname -l$linkname"
    end
end

function ldflags_from_libname(libname::AbstractString)
    return ldflags(Libdl.dlpath(libname), libname)
end
function ldflags_from_libpath(libpath::AbstractString)
    return ldflags(libpath, first(split(basename(libpath), '.', limit=2)))
end

function blas_lib()
    if JULIA_LAPACK
        ldflags_from_libname(LinearAlgebra.BLAS.libblas)
    else
        @info(BinDeps._find_library(blas))
        ldflags_from_libpath(first(BinDeps._find_library(blas))[2])
    end
end

function lapack_lib()
    if JULIA_LAPACK
        ldflags_from_libname(LinearAlgebra.LAPACK.liblapack)
    else
        @info(BinDeps._find_library(lapack))
        ldflags_from_libpath(first(BinDeps._find_library(lapack))[2])
    end
end

const FORTRAN_FUNCTIONS =
    [:dnrm2, :dasum, :ddot, :idamax, :dgemm, :dgemv, :dger,
     :dtrsm, :dtrmv, :dpotrf, :dpotrs, :dpotri, :dtrtri]

function fix64(flags)
    if false # Base.BLAS.vendor() == :openblas64
        # See https://discourse.julialang.org/t/blas-headers/3141/4
        flags *= " -DCOPYAMATRIX -DDLONG -DCTRLC=1"
        flags *= " -DBLAS64"
        flags *= " -march=x86-64 -m64 -fdefault-integer-8"
        # -Dinteger=long cannot be put in FCFLAGS
        for f in FORTRAN_FUNCTIONS
            let ext=string(LinearAlgebra.BLAS.@blasfunc "")
                flags *= " -D$(f)_=$(f)_$(ext[1:end])"
                # do not use the trailing _ in ext
                flags *= " -D$(f)=$(f)_$(ext[1:end-1])"
            end
        end
        @info(flags)
        flags
    else
        flags
    end
end
