using MAT, Tulip, HiGHS

function run_from_mat_file(path::String, ϵ::Float64=1e-7, ρ::Float64=0.99)::Tuple{ExtendedProblem, Result, Summary, Summary, Summary}
    problem = read_from_mat_file(path)

    result_pas = Result([], [], [], [], 0, stop_error)
    pas_summary = Summary(0, Inf, Inf, false)
    tulip_summary = Summary(0, Inf, Inf, false)
    highs_summary = Summary(0, Inf, Inf, false)

    try
        result_tulip, tulip_model = solve_with_jump(problem, Tulip.Optimizer)
        @info "Tulip cost: $(problem.c'result_tulip)"
        tss = solution_summary(tulip_model; verbose=true)
        tulip_summary = Summary(tss.barrier_iterations, tss.solve_time, problem.c'result_tulip, isapprox(problem.A*result_tulip, problem.b, rtol=ϵ))
    catch x
        if x isa InterruptException
            rethrow
        end
        tulip_summary = Summary(0, Inf, Inf, false)
    end
    
    try
        result_highs, highs_model = solve_with_jump(problem, HiGHS.Optimizer)
        @info "HiGHS cost: $(problem.c'result_highs)"
        hss = solution_summary(highs_model; verbose=true)
        highs_summary = Summary(hss.simplex_iterations, hss.solve_time, problem.c'result_highs, isapprox(problem.A*result_highs, problem.b, rtol=ϵ))
    catch x
        if x isa InterruptException
            rethrow
        end
        highs_summary = Summary(0, Inf, Inf, false)
    end
    
    try
        pas_time = @elapsed begin result_pas = primal_affine_scaling(problem, ϵ, ρ) end
        @info "Primal-Affine Scaling: $(problem.c'result_pas.o)"
        pas_summary = Summary(result_pas.iterations, pas_time, problem.c'result_pas.o, isapprox(problem.A*result_pas.o, problem.b, rtol=ϵ))
    catch x
        if x isa InterruptException
            rethrow
        end
        result_pas = Result([], [], [], [], 0, stop_error)
        pas_summary = Summary(0, Inf, Inf, false)
    end

    return problem, result_pas, pas_summary, tulip_summary, highs_summary
end

function read_from_mat_file(path::String)::ExtendedProblem
    vars = matread(path)["Problem"]
    return ExtendedProblem(vars["A"], vars["b"], vars["aux"]["c"], vars["aux"]["lo"], vars["aux"]["hi"])
end