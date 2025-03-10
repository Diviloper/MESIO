include("types.jl")
include("utils.jl")
include("primal_affine_scaling.jl")
include("jump.jl")
include("runner.jl")

function run_all_in_dir(dir_path)
    problems = readdir(dir_path, join=true)

    for problem in problems
        @info "Running $(basename(problem))"
        p, r, tr = run_from_mat_file(problem)
        @info "Finished $(basename(problem)): PAS: $(p.c'r.o) | Tulip: $(p.c'tr)"
    end
end