function expand_problem((; A, b, c)::StandardProblem)::Tuple{Problem,VF}
    n = size(c, 1)
    x⁰ = [1.0 for _ = 1:n]

    r = b - A * x⁰
    Ā = hcat(A, r)

    M = maximum(abs.(c)) * 1000
    c̄ = push!(copy(c), M)

    x̄⁰ = push!(x⁰, 1)

    return StandardProblem(Ā, b, c̄), x̄⁰
end