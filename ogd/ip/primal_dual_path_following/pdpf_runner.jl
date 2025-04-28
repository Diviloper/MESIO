using CSV, DataFrames

read_and_standardize(path::String)::StandardProblem = standardize(read_from_mat_file(path))[1]

function random_point(P::StandardProblem)::Tuple{VF,VF,VF}
    # Create random point
    x = rand(size(P.A, 2)) .* 40
    λ = rand(size(P.A, 1)) .* 40
    s = rand(size(P.A, 2)) .* 40
    return (x, λ, s)
end

function step_comparison(out_path::String)
    problems = get_problem_summaries("problems")
    problems = sort(problems, :SSize)

    df = DataFrame(
        # Problem characteristics
        File=String[], Problem=String[],
        # Size 
        N=Int[], M=Int[], Size=Int[], NonZeros=Int[],
        # Standardized Size
        Standard=Bool[], SN=Int[], SM=Int[], SSize=Int[], SNonZeros=Int[],
        # Results
        NBIterations=Int[], NBTime=Float64[], NBFeasible=Bool[], NBSolved=Bool[],
        NAIterations=Int[], NATime=Float64[], NAFeasible=Bool[], NASolved=Bool[],
        NNIterations=Int[], NNTime=Float64[], NNFeasible=Bool[], NNSolved=Bool[],
        MBIterations=Int[], MBTime=Float64[], MBFeasible=Bool[], MBSolved=Bool[],
        MAIterations=Int[], MATime=Float64[], MAFeasible=Bool[], MASolved=Bool[],
        MNIterations=Int[], MNTime=Float64[], MNFeasible=Bool[], MNSolved=Bool[],
    )

    # Steps
    nbstep = NewtonStep(0.1, base)
    nastep = NewtonStep(0.1, augmented)
    nnstep = NewtonStep(0.1, normal)

    mbstep = MehrotraStep(base)
    mastep = MehrotraStep(augmented)
    mnstep = MehrotraStep(normal)
    steps = [nbstep, nastep, nnstep, mbstep, mastep, mnstep]

    # Run all steps once to precompile everything
    for step in steps
        @info "Precompiling $(step)"
            Base.GC.gc()
            p = read_and_standardize(problems.File[1])
        try
            x, λ, s = random_point(p)
            primal_dual_path_following(p, x, λ, s, step)
        catch x
            @warn x
        end
    end
    readline()
    # Run all problems
    for (i, problem) in pairs(eachrow(problems))
        @info "----------Running $(problem.Problem) ($i of $(nrow(problems)))----------"
        step_data = []
        p = read_and_standardize(problem.File)
        x, λ, s = random_point(p)
        for step in steps
            @info "Running $(step)"
            try
                Base.GC.gc()
                time = @elapsed begin
                    result = primal_dual_path_following(p, x, λ, s, step)
                end
                push!(step_data, result.iterations, time, p.A*result.o ≈ p.b, true)
            catch x
                @warn "Error in $(step)"
                push!(step_data, 0, Inf, false, false)
            end
        end
        push!(df,
            (
                # Problem characteristics
                problem.File, problem.Problem,
                # Size 
                problem.N, problem.M, problem.Size, problem.NonZeros,
                # Standardized Size
                problem.Standard, problem.SN, problem.SM, problem.SSize, problem.SNonZeros,
                # Results
                step_data...
            )
        )
        CSV.write(out_path, df)
    end

end