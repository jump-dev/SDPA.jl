sdpawrap = library_dependency("sdpawrap", aliases=["libsdpawrap"], depends=[depends; sdpa])

jlcxx_dir = joinpath(CxxWrap.prefix().path, "lib", "cmake")

prefix=joinpath(BinDeps.depsdir(sdpawrap), "usr")
sdpawrap_srcdir = joinpath(BinDeps.depsdir(sdpawrap), "src", "sdpawrap")
sdpawrap_builddir = joinpath(BinDeps.depsdir(sdpawrap), "builds", "sdpa_wrap")

lib_prefix = @static Sys.iswindows() ? "" : "lib"
libdir_opt = ""

makeopts = ["--", "-j", "$(Sys.CPU_THREADS + 2)"]

# Set generator if on windows
genopt = "Unix Makefiles"
@static if Sys.iswindows()
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
                # See https://github.com/blegat/SDPA.jl/pull/11#issuecomment-422353638 for `-D_GLIBCXX_USE_CXX11_ABI=1`
                `cmake -G "$genopt" -D_GLIBCXX_USE_CXX11_ABI=1 -DJulia_ROOT="$(dirname(Sys.BINDIR))" -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_PREFIX_PATH="$jlcxx_dir" -DSDPA_DIR="$sdpa_dir" -DMUMPS_INCLUDE_DIR="$mumps_include_dir" -DSDPA_LIBRARY="$sdpa_library" $sdpawrap_srcdir`
               `cmake --build . --config Release --target install $makeopts`
            end)
    end
    end), sdpawrap)
