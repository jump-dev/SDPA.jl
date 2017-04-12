sdpawrap = library_dependency("sdpawrap", aliases=["libsdpawrap"], depends=[depends; sdpa])

cxx_wrap_dir = joinpath(dirname(@__FILE__), "..", "..", "CxxWrap", "deps", "usr", "lib", "cmake")

prefix=joinpath(BinDeps.depsdir(sdpawrap), "usr")
sdpawrap_srcdir = joinpath(BinDeps.depsdir(sdpawrap), "src", "sdpawrap")
sdpawrap_builddir = joinpath(BinDeps.depsdir(sdpawrap), "builds", "sdpa_wrap")

lib_prefix = @static is_windows() ? "" : "lib"
libdir_opt = ""

makeopts = ["--", "-j", "$(Sys.CPU_CORES+2)"]

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
