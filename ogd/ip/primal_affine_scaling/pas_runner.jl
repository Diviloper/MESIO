using Tulip, HiGHS, DataFrames, CSV

function run_from_mat_file(path::String, ϵ::Float64=1e-7, ρ::Float64=0.99)::Tuple{ExtendedProblem,Result,Summary,Summary,Summary}
    problem = read_from_mat_file(path)

    result_pas = Result([], [], [], [], 0, stop_error, false)
    pas_summary = Summary(0, Inf, Inf, false)
    tulip_summary = Summary(0, Inf, Inf, false)
    highs_summary = Summary(0, Inf, Inf, false)

    try
        result_tulip, tulip_model = solve_with_jump(problem, Tulip.Optimizer)
        tulip_feasible = isapprox(problem.A * result_tulip, problem.b, rtol=ϵ)
        @info "Tulip cost: $(problem.c'result_tulip) | Feasible: $tulip_feasible"
        tss = solution_summary(tulip_model; verbose=true)
        tulip_summary = Summary(tss.barrier_iterations, tss.solve_time, problem.c'result_tulip, tulip_feasible)
    catch x
        if x isa InterruptException
            rethrow
        end
        tulip_summary = Summary(0, Inf, Inf, false)
    end

    try
        result_highs, highs_model = solve_with_jump(problem, HiGHS.Optimizer)
        highs_feasible = isapprox(problem.A * result_highs, problem.b, rtol=ϵ)
        @info "HiGHS cost: $(problem.c'result_highs) | Feasible: $highs_feasible"
        hss = solution_summary(highs_model; verbose=true)
        highs_summary = Summary(hss.simplex_iterations, hss.solve_time, problem.c'result_highs, highs_feasible)
    catch x
        if x isa InterruptException
            rethrow
        end
        highs_summary = Summary(0, Inf, Inf, false)
    end

    try
        pas_time = @elapsed begin
            result_pas = primal_affine_scaling(problem, ϵ, ρ)
        end
        @info "Primal-Affine Scaling: $(problem.c'result_pas.o) | Feasible: $(result_pas.feasible)"
        pas_summary = Summary(result_pas.iterations, pas_time, problem.c'result_pas.o, result_pas.feasible)
    catch x
        @warn x
        if x isa InterruptException
            rethrow
        end
        result_pas = Result([], [], [], [], 0, stop_error, false)
        pas_summary = Summary(0, Inf, Inf, false)
    end

    return problem, result_pas, pas_summary, tulip_summary, highs_summary
end

function run_all_in_dir(dir_path::String, out_filepath::String, ϵ::Float64=1e-8, ρ::Float64=0.999)
    problems = get_problem_summaries(dir_path)
    problems = sort(problems, :SSize)

    df = DataFrame(
        # Problem characteristics
        Problem=String[], N=Int[], M=Int[], Size=Int[], NonZeros=Int[],
        # Standardized characteristics
        Standard=Bool[], SN=Int[], SM=Int[], SSize=Int[], SNonZeros=Int[],
        # Primal-Affine Scaling
        PAS_Iterations=Int[], PAS_Cost=Float64[], PAS_Time=Float64[], PAS_Feasible=Bool[], PAS_Stop_Reason=StopReason[],
        # Tulip
        Tulip_Iterations=Int[], Tulip_Cost=Float64[], Tulip_Time=Float64[], Tulip_Feasible=Bool[],
        # HiGHS
        HiGHS_Iterations=Int[], HiGHS_Cost=Float64[], HiGHS_Time=Float64[], HiGHS_Feasible=Bool[],
    )

    for (i, problem) in pairs(eachrow(problems))
        @info "----------------------------------------------Running $(problem.Problem) ($i of $(nrow(problems)))----------------------------------------------"
        p, r, rs, ts, hs = run_from_mat_file(problem.File, ϵ, ρ)
        push!(df,
            (
                # Problem characteristics
                problem.Problem, problem.N, problem.M, problem.Size, problem.NonZeros,
                # Standardized characteristics
                problem.Standard, problem.SN, problem.SM, problem.SSize, problem.SNonZeros,
                # Primal-Affine Scaling
                rs.iterations, rs.cost, rs.time, rs.feasible, r.reason,
                # Tulip
                ts.iterations, ts.cost, ts.time, ts.feasible,
                # HiGHS
                hs.iterations, hs.cost, hs.time, hs.feasible,
            )
        )
        @info "Finished $(problem.Problem): PAS: $(rs.cost) | Tulip: $(ts.cost) | HiGHS: $(hs.cost)"
        CSV.write(out_filepath, df)
    end
end
