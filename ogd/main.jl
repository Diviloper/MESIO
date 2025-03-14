include("types.jl")
include("utils.jl")
include("primal_affine_scaling.jl")
include("jump.jl")
include("runner.jl")

using DataFrames, CSV

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

function get_problem_summaries(dir_path)::DataFrame
    files = readdir(dir_path, join=true)

    df = DataFrame(
        # Name
        File=String[], Problem=String[], 
        # Size 
        N=Int[], M=Int[], Size=Int[], NonZeros=Int[], 
        # Standardized Size
        Standard=Bool[], SN=Int[], SM=Int[], SSize=Int[], SNonZeros=Int[]
        )

    for file in files
        if contains(file, "lpi_")
            @info "Skipping MIP $(basename(file))"
            continue
        end
        problem = read_from_mat_file(file)
        standard = count(!=(0), problem.lo) + count(!=(Inf), problem.hi) == 0
        sp = problem
        if !standard
            sp, _, _ = standardize(problem)
        end
        push!(df, (
            # Name
            file, basename(file), 
            # Size
            size(problem.A, 2), size(problem.A, 1), prod(size(problem.A)), size(problem.A.nzval, 1), 
            # Standardized Size
            standard, size(sp.A, 2), size(sp.A, 1), prod(size(sp.A)), size(sp.A.nzval, 1)))
    end
    return df
end

function compare_multiplications(A::SMF, c::VF)
    dA = collect(A)
    D = Diagonal(ones(size(c, 1)))

    @time "Sparse Multiplication - Sparse Solve" begin
        ADA = A*D*A'
        ADc = A*D*c
        y = solve(LinearProblem(ADA, ADc))
    end

    @time "Sparse Multiplication - Dense Solve" begin
        ADA = collect(A*D*A')
        ADc = collect(A*D*c)
        y = solve(LinearProblem(ADA, ADc))
    end

    @time "Dense Multiplication - Dense Solve" begin
        ADA = dA*D*dA'
        ADc = dA*D*c
        y = solve(LinearProblem(ADA, ADc))
    end

    @time "Sparse Multiplication - Dense Cholesky Solve" begin
        ADA = collect(A*D*A')
        ADc = collect(A*D*c)
        y = cholesky!(Symmetric(ADA)) \ ADc
    end
    return
end
