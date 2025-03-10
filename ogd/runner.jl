using MAT, Tulip

function run_from_mat_file(path::String, ϵ::Float64=1e-6, ρ::Float64=0.995)::Tuple{ExtendedProblem, Result, VF}
    problem = read_from_mat_file(path)

    result_pas = primal_affine_scaling(problem, ϵ, ρ)
    result_tulip = solve_with_jump(problem, Tulip.Optimizer)

    return problem, result_pas, result_tulip
end

function read_from_mat_file(path::String)::ExtendedProblem
    vars = matread(path)["Problem"]
    return ExtendedProblem(vars["A"], vars["b"], vars["aux"]["c"], vars["aux"]["lo"], vars["aux"]["hi"])
end