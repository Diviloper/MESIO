using MAT

function read_from_mat_file(path::String)::ExtendedProblem
    vars = matread(path)["Problem"]
    return ExtendedProblem(vars["A"], vars["b"], vars["aux"]["c"], vars["aux"]["lo"], vars["aux"]["hi"])
end

function get_problem_summaries(dir_path::String)::DataFrame
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