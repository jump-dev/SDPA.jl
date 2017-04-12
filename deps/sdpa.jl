sdpa = library_dependency("sdpa", aliases=["libsdpa"], depends=depends)

official_download="http://downloads.sourceforge.net/project/sdpa/sdpa/sdpa_7.3.8.tar.gz?r=&ts=1479039688&use_mirror=vorboss"
sdpaname = "sdpa-7.3.8"
sdpa_dir = joinpath(dirname(@__FILE__), "src", sdpaname)
mumps_include_dir = joinpath(sdpa_dir, "mumps", "build", "include")

sdpasrcdir = joinpath(BinDeps.srcdir(sdpa), sdpaname)
sdpaprefixdir = joinpath(BinDeps.usrdir(sdpa))
sdpalibdir = joinpath(sdpaprefixdir, "lib")
target="libsdpa.$(Libdl.dlext)"
sdpa_library = joinpath(sdpalibdir, target)
mumps_dir = joinpath(sdpasrcdir, "mumps", "build")
mumps_lib_dir = joinpath(mumps_dir, "lib")
mumps_libseq_dir = joinpath(mumps_dir, "libseq")

provides(Sources,
        Dict(URI(official_download) => sdpa), unpacked_dir=sdpaname)

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
