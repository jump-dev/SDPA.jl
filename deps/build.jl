using BinDeps

@BinDeps.setup

blas="/usr/lib/julia/libopenblas64_.so"
lapack="/usr/lib/julia/libopenblas64_.so"

official_download="http://downloads.sourceforge.net/project/sdpa/sdpa/sdpa_7.3.8.tar.gz?r=&ts=1479039688&use_mirror=vorboss"

#configure="./configure CFLAGS=-funroll-all-loops CXXFLAGS=-funroll-all-loops FFLAGS=-funroll-all-loops --prefix=$HOME/sdpa --with-blas="${OB}" --with-lapack="${OB}""
libsdpa = library_dependency("libsdpa")

sdpaname = "sdpa-7.3.8"

provides(Sources,
        Dict(URI(official_download) => libsdpa), unpacked_dir=sdpaname)

#includedirs = AbstractString[src_dir]
#targetdirs = AbstractString["libsdpa.a"] #$(Libdl.dlext)"]
#libdirs = AbstractString["/usr/lib/julia"]
configureopts = AbstractString["CFLAGS=-funroll-all-loops", "CXXFLAGS=-funroll-all-loops", "FFLAGS=-funroll-all-loops"] #, "--with-blas=$blas", "--with-lapack=$lapack"] # FFLAGS=-funroll-all-loops"]
#configureopts = AbstractString["CFLAGS='-funroll-all-loops' CXXFLAGS='-funroll-all-loops' FFLAGS='-funroll-all-loops' --with-blas=$blas --with-lapack=$lapack"]

sdpasrcdir = joinpath(BinDeps.srcdir(libsdpa), sdpaname)
sdpaprefixdir = joinpath(BinDeps.usrdir(libsdpa))
sdpalibdir = joinpath(sdpaprefixdir, "lib")
sdpaprefixdir = joinpath(BinDeps.usrdir(libsdpa))

target="libsdpa.$(Libdl.dlext)"

provides(BuildProcess,
	(@build_steps begin
		GetSources(libsdpa)
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
	end),libsdpa)

#provides(BuildProcess,
#        Dict(
#        Autotools(
#        libtarget = targetdirs,
#        include_dirs = includedirs,
#        configure_options = configureopts
#) => libsdpa))

@BinDeps.install Dict(:libsdpa => :libsdpa)
