using BinDeps
# If I do not do using CxxWrap, when BinDeps try dlopen on libsdpawrap.so, I get
# ERROR: could not load library "~/.julia/v0.5/SDPA/deps/usr/lib/libsdpawrap"
# libcxx_wrap.so.0: cannot open shared object file: No such file or directory
using CxxWrap

lib_prefix = @static is_windows() ? "" : "lib"
libdir_opt = ""

@BinDeps.setup

#blas = library_dependency("libblas", alias=["libblas.dll"])
#lapack = library_dependency("liblapack", alias=["liblapack.dll"])
depends = [] # [blas, lapack]

official_download="http://downloads.sourceforge.net/project/sdpa/sdpa/sdpa_7.3.8.tar.gz?r=&ts=1479039688&use_mirror=vorboss"

#configure="./configure CFLAGS=-funroll-all-loops CXXFLAGS=-funroll-all-loops FCFLAGS=-funroll-all-loops --prefix=$HOME/sdpa --with-blas="${OB}" --with-lapack="${OB}""

sdpaname = "sdpa-7.3.8"
sdpa_dir = joinpath(dirname(@__FILE__), "src", sdpaname)
mumps_include_dir = joinpath(sdpa_dir, "mumps", "build", "include")
cxx_wrap_dir = joinpath(dirname(@__FILE__), "..", "..", "CxxWrap", "deps", "usr", "lib", "cmake")

sdpa = library_dependency("sdpa", aliases=["libsdpa"], depends=depends)
sdpawrap = library_dependency("sdpawrap", aliases=["libsdpawrap"], depends=[depends; sdpa])

provides(Sources,
        Dict(URI(official_download) => sdpa), unpacked_dir=sdpaname)

#includedirs = AbstractString[src_dir]
#targetdirs = AbstractString["libsdpa.a"] #$(Libdl.dlext)"]
#libdirs = AbstractString["/usr/lib/julia"]
#configureopts = AbstractString["CFLAGS=-funroll-all-loops", "CXXFLAGS=-funroll-all-loops", "FCFLAGS=-funroll-all-loops"] #, "--with-blas=$blas", "--with-lapack=$lapack"] # FCFLAGS=-funroll-all-loops"]
#configureopts = AbstractString["CFLAGS='-funroll-all-loops' CXXFLAGS='-funroll-all-loops' FCFLAGS='-funroll-all-loops' --with-blas=$blas --with-lapack=$lapack"]

sdpasrcdir = joinpath(BinDeps.srcdir(sdpawrap), sdpaname)
sdpaprefixdir = joinpath(BinDeps.usrdir(sdpawrap))
sdpalibdir = joinpath(sdpaprefixdir, "lib")
target="libsdpa.$(Libdl.dlext)"
sdpa_library = joinpath(sdpalibdir, target)
mumps_dir = joinpath(sdpasrcdir, "mumps", "build")
mumps_lib_dir = joinpath(mumps_dir, "lib")
mumps_libseq_dir = joinpath(mumps_dir, "libseq")

prefix=joinpath(BinDeps.depsdir(sdpawrap), "usr")
sdpawrap_srcdir = joinpath(BinDeps.depsdir(sdpawrap), "src", "sdpawrap")
sdpawrap_builddir = joinpath(BinDeps.depsdir(sdpawrap), "builds", "sdpa_wrap")

makeopts = ["--", "-j", "$(Sys.CPU_CORES+2)"]

const FORTRAN_FUNCTIONS =
    [:dnrm2, :dasum, :ddot, :idamax, :dgemm, :dgemv, :dger,
     :dtrsm, :dtrmv, :dpotrf, :dpotrs, :dpotri, :dtrtri]

# It needs to be a function so that it is called only when blas and lapack dependencies have been resolved
function ldflags(libname)
    # I use [4:end] to drop the "lib" at the beginning
    "-L$(dirname(Libdl.dlpath(libname))) -l$(libname[4:end])"
end
# Now I use Julia's LAPACK so it shouldn't change anything
function blas_lib()
    if false
        "-L$(dirname(first(BinDeps._find_library(blas))[2])) -lblas"
    else
        ldflags(LinAlg.BLAS.libblas)
    end
end

function lapack_lib()
    if false
        "-L$(dirname(first(BinDeps._find_library(blas))[2])) -llapack"
    else
        ldflags(LinAlg.LAPACK.liblapack)
    end
end

function fix64(flags)
    flags *= " -DCOPYAMATRIX -DDLONG -DCTRLC=1"
    if Base.BLAS.vendor() == :openblas64
        flags *= " -DBLAS64"
        flags *= " -march=x86-64 -m64 -fdefault-integer-8"
        # -Dinteger=long cannot be put in FCFLAGS
        for f in FORTRAN_FUNCTIONS
            let ext=string(LinAlg.BLAS.@blasfunc "")
                flags *= " -D$(f)_=$(f)_$(ext[1:end])"
                # do not use the trailing _ in ext
                flags *= " -D$(f)=$(f)_$(ext[1:end-1])"
            end
        end
        info(flags)
        flags
    else
        flags
    end
end

provides(BuildProcess,
(@build_steps begin
    GetSources(sdpa)
    CreateDirectory(sdpaprefixdir)
    CreateDirectory(sdpalibdir)
    @build_steps begin
        ChangeDirectory(sdpasrcdir)
        FileRule(joinpath(sdpa_library), @build_steps begin
            # See https://sourceforge.net/p/sdpa/discussion/1393613/thread/1a6d8897/
            pipeline(`sed "s/cut -f2 -d=/cut --complement -f1 -d=/" mumps/Makefile`, stdout="mumpsMakefile")
            pipeline(`sed "s/OPTF = \"/OPTF = \" '-I\$\$(topdir)\/libseq'/" mumpsMakefile`, stdout="mumps/Makefile")
            `rm mumpsMakefile`
            pipeline(`sed 's/_a_/_la_/' Makefile.am`, stdout="Makefile.am.1")
            pipeline(`sed 's/libsdpa.a/libsdpa.la\nlibsdpa_la_LDFLAGS = -shared/' Makefile.am.1`, stdout="Makefile.am")
            pipeline(`sed 's/lib_LIB/lib_LTLIB/' Makefile.am`, stdout="Makefile.am.1")
            `mv Makefile.am.1 Makefile.am`
            pipeline(`sed 's/AC_FC_LIBRARY/LT_INIT\nAC_FC_LIBRARY/' configure.in`, stdout="configure.ac")
            # Short-circuit test because they do
            # #define dgemm_ innocuous_dgemm_
            # #include <limits.h>
            # #undef dgemm_
            # because "Define dgemm_ to an innocuous variant, in case <limits.h> declares dgemm_."
            # For example, HP-UX 11i <limits.h> declares gettimeofday.
            # This makes it impossible for us to pass it since we redefine dgemm_ as dgemm_64_
            pipeline(`sed 's/HAVE_BLAS=""/HAVE_BLAS="yes"/' configure.ac`, stdout="configure.ac.1")
            pipeline(`sed 's/HAVE_LAPACK=""/HAVE_LAPACK="yes"/' configure.ac.1`, stdout="configure.ac")
            `rm configure.in configure.ac.1`
            `autoreconf -i`
            `./configure CFLAGS="$(fix64("-funroll-all-loops"))" CXXFLAGS="$(fix64("-funroll-all-loops"))" FCFLAGS="$(fix64("-funroll-all-loops"))" --with-blas="$(blas_lib())" --with-lapack="$(lapack_lib())"`
            `make`
            `cp .libs/$target .libs/$target.0 $sdpalibdir` # It seems that sdpawrap links itself with $target.0
        end)
    end
end), sdpa)

# The zip on SDPA does not contain DLLs, only an EXE :(
# provides(Binaries,
#     URI("https://sourceforge.net/projects/sdpa/files/sdpa/windows/sdpa-7.3.9-windows.zip"),
#     [sdpa], unpacked_dir="usr", os = :Windows)

# Set generator if on windows
genopt = "Unix Makefiles"
@static if is_windows()
  makeopts = "--"
  if Sys.WORD_SIZE == 64
    genopt = "Visual Studio 14 2015 Win64"
  else
    genopt = "Visual Studio 14 2015"
  end
end

provides(BuildProcess,
(@build_steps begin
    CreateDirectory(sdpawrap_builddir)
    @build_steps begin
        ChangeDirectory(sdpawrap_builddir)
        FileRule(joinpath(prefix, "lib$libdir_opt", "$(lib_prefix)sdpawrap.$(Libdl.dlext)"),
            @build_steps begin
               `cmake -G "$genopt" -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_BUILD_TYPE="Release" -DCxxWrap_DIR="$cxx_wrap_dir" -DSDPA_DIR="$sdpa_dir" -DMUMPS_INCLUDE_DIR="$mumps_include_dir" -DSDPA_LIBRARY="$sdpa_library" -DMUMPS_LIB_DIR="$mumps_lib_dir" -DMUMPS_LIBSEQ_DIR="$mumps_libseq_dir" -DBLAS_LIB="$(blas_lib())" -DLAPACK_LIB="$(lapack_lib())" $sdpawrap_srcdir`
               `cmake --build . --config Release --target install $makeopts`
            end)
    end
    end), sdpawrap)

@BinDeps.install Dict(:sdpawrap => :_l_sdpa_wrap)
