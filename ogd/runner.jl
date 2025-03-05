using MAT

function run_from_mat_file(path::String, ϵ::Float64=10e-8, ρ::Float64=0.995)::Tuple{Problem, Result}
    problem = read_from_mat_file(path)

    if rank(problem.A) != size(problem.A, 1)
        problem = make_full_rank(problem)
    end

    result = primal_affine_scaling(problem, ϵ, ρ)

    return problem, result
end

function read_from_mat_file(path::String)::Problem
    vars = matread(path)["Problem"]
    return Problem(vars["A"], vars["b"], vars["aux"]["c"])
end