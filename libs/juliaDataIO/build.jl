# INPUT
# ARGS: optional build directory and CMake executable.
# OUTPUT
# A local Julia package and native library below the repository build directory.
# Downloads Julia dependencies to the selected Julia depot.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

using Pkg

VERSION >= v"1.10" || error("Julia 1.10 or newer is required")
length(ARGS) <= 2 || error("Supply a build directory and a CMake executable")
root = normpath(joinpath(@__DIR__, "..", ".."))
build = abspath(isempty(ARGS) ? joinpath(root, "build", "julia") : ARGS[1])
relative = relpath(build, joinpath(root, "build"))
(isabspath(relative) || relative == ".." || startswith(relative, ".." * string(Base.Filesystem.path_separator))) &&
    error("Use a build directory below $(joinpath(root, "build"))")
cmake = length(ARGS) == 2 ? ARGS[2] : get(ENV, "CMAKE_COMMAND", "cmake")
package = joinpath(build, "libs", "juliaDataIO", "DataBionicIO")
mkpath(joinpath(package, "src"))
cp(joinpath(@__DIR__, "Project.toml"), joinpath(package, "Project.toml"); force=true)
cp(joinpath(@__DIR__, "src", "DataBionicIO.jl"), joinpath(package, "src", "DataBionicIO.jl"); force=true)
cp(joinpath(@__DIR__, "src", "common.jl"), joinpath(package, "src", "common.jl"); force=true)
Pkg.activate(package)
Pkg.instantiate(; allow_autoprecomp=false)
julia = joinpath(Sys.BINDIR, Base.julia_exename())
run(`$cmake -S $root -B $build -DBUILD_RPACKAGE=OFF -DBUILD_PYPACKAGE=OFF -DBUILD_MATLABPACKAGE=OFF -DBUILD_JULIAPACKAGE=ON -DCMAKE_BUILD_TYPE=Release -DJulia_EXECUTABLE=$julia -DJulia_PROJECT=$package`)
run(`$cmake --build $build --config Release --target JuliaPackage --parallel 2`)
println("Julia package: ", package)
println("Tests: ", cmake, " --build ", build, " --config Release --target JuliaTests")
