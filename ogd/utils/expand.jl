function expand_problem((; A, b, c)::StandardProblem)::Tuple{StandardProblem,VF}
    n = size(c, 1)

    r = b - A * ones(n)
    Ā = hcat(A, r)

    M = maximum(c) * 1000
    c̄ = push!(copy(c), M)

    return StandardProblem(Ā, b, c̄), ones(n+1)
end