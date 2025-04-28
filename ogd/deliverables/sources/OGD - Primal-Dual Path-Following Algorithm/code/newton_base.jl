function newton_base_system(
  step::NewtonStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF
)::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A); (; σ) = step
    X = spdiagm(x); S = spdiagm(s)
    e = ones(n); I = spdiagm(e)
    Zᵐ = spzeros(m, m); Zⁿ = spzeros(n, n)
    Zᵐⁿ = spzeros(m, n); Zⁿᵐ = spzeros(n, m)
    μ = x's / n
    
    # System
    F = dropzeros!([
        Zⁿ A'  I;
        A  Zᵐ  Zᵐⁿ;
        S  Zⁿᵐ X
    ])

    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ = X * S * e - σ * μ * e
    R = [-rᶜ; -rᵇ; -rˣˢ]

    Δ = solve(LinearProblem(F, R)).u
    return Δ[1:n], Δ[n+1:n+m], Δ[n+m+1:end], μ
end