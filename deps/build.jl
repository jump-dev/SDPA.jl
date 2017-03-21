using BinDeps
# If I do not do using CxxWrap, when BinDeps try dlopen on libsdpawrap.so, I get
# ERROR: could not load library "~/.julia/v0.5/SDPA/deps/usr/lib/libsdpawrap"
# libcxx_wrap.so.0: cannot open shared object file: No such file or directory
using CxxWrap

lib_prefix = @static is_windows() ? "" : "lib"
libdir_opt = ""

@BinDeps.setup

blas="/usr/lib/julia/libopenblas64_.so"
lapack="/usr/lib/julia/libopenblas64_.so"

official_download="http://downloads.sourceforge.net/project/sdpa/sdpa/sdpa_7.3.8.tar.gz?r=&ts=1479039688&use_mirror=vorboss"

#configure="./configure CFLAGS=-funroll-all-loops CXXFLAGS=-funroll-all-loops FFLAGS=-funroll-all-loops --prefix=$HOME/sdpa --with-blas="${OB}" --with-lapack="${OB}""

# FIXME replace Pkg.dir
cxx_wrap_dir = Pkg.dir("CxxWrap","deps","usr","lib","cmake")

sdpawrap = library_dependency("sdpawrap", aliases=["libsdpawrap"])

sdpaname = "sdpa-7.3.8"

provides(Sources,
        Dict(URI(official_download) => sdpawrap), unpacked_dir=sdpaname)

#includedirs = AbstractString[src_dir]
#targetdirs = AbstractString["libsdpa.a"] #$(Libdl.dlext)"]
#libdirs = AbstractString["/usr/lib/julia"]
configureopts = AbstractString["CFLAGS=-funroll-all-loops", "CXXFLAGS=-funroll-all-loops", "FFLAGS=-funroll-all-loops"] #, "--with-blas=$blas", "--with-lapack=$lapack"] # FFLAGS=-funroll-all-loops"]
#configureopts = AbstractString["CFLAGS='-funroll-all-loops' CXXFLAGS='-funroll-all-loops' FFLAGS='-funroll-all-loops' --with-blas=$blas --with-lapack=$lapack"]

sdpasrcdir = joinpath(BinDeps.srcdir(sdpawrap), sdpaname)
sdpaprefixdir = joinpath(BinDeps.usrdir(sdpawrap))
sdpalibdir = joinpath(sdpaprefixdir, "lib")
sdpaprefixdir = joinpath(BinDeps.usrdir(sdpawrap))

prefix=joinpath(BinDeps.depsdir(sdpawrap), "usr")
sdpawrap_srcdir = joinpath(BinDeps.depsdir(sdpawrap),"src","sdpawrap")
sdpawrap_builddir = joinpath(BinDeps.depsdir(sdpawrap), "builds", "sdpa_wrap")

target="libsdpa.$(Libdl.dlext)"

makeopts = ["--", "-j", "$(Sys.CPU_CORES+2)"]

# Set generator if on windows
genopt = "Unix Makefiles"
@static if is_windows()
  makeopts = "--"
  if Sys.WORD_SIZE == 64
    genopt = "Visual Studio 14 2015 Win64"
    cmake_prefix = joinpath(QT_ROOT, "msvc2015_64")
  else
    genopt = "Visual Studio 14 2015"
    cmake_prefix = joinpath(QT_ROOT, "msvc2015")
  end
end

sdpa_steps = @build_steps begin
	`cmake -G "$genopt" -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_BUILD_TYPE="Release" -DCxxWrap_DIR="$cxx_wrap_dir" $sdpawrap_srcdir`
	`cmake --build . --config Release --target install $makeopts`
end

provides(BuildProcess,
(@build_steps begin
    GetSources(sdpawrap)
    CreateDirectory(sdpaprefixdir)
    CreateDirectory(sdpalibdir)
    @build_steps begin
        ChangeDirectory(sdpasrcdir)
        FileRule(joinpath(sdpalibdir,"$target"),@build_steps begin
                 pipeline(`sed 's/_a_/_la_/' Makefile.am`, stdout="Makefile.am.1")
                 pipeline(`sed 's/libsdpa.a/libsdpa.la\nlibsdpa_la_LDFLAGS = -shared/' Makefile.am.1`, stdout="Makefile.am")
                 pipeline(`sed 's/lib_LIB/lib_LTLIB/' Makefile.am`, stdout="Makefile.am.1")
                 `mv Makefile.am.1 Makefile.am`
                 pipeline(`sed 's/AC_FC_LIBRARY/LT_INIT\nAC_FC_LIBRARY/' configure.in`, stdout="configure.ac")
                 `rm configure.in`
                 `autoreconf -i`
                 `./configure CFLAGS=-funroll-all-loops CXXFLAGS=-funroll-all-loops FFLAGS=-funroll-all-loops --with-blas="-L$blas -lblas" --with-lapack="-L$lapack -llapack"`
            `make`
            `cp .libs/$target $sdpalibdir/$target`
        end)
    end
    CreateDirectory(sdpawrap_builddir)
    @build_steps begin
        ChangeDirectory(sdpawrap_builddir)
        FileRule(joinpath(prefix, "lib$libdir_opt", "$(lib_prefix)sdpawrap.$(Libdl.dlext)"), sdpa_steps)
    end
    end), sdpawrap)

@BinDeps.install Dict(:sdpawrap => :_l_sdpa_wrap)
