function newton_augmented_system(
  step::NewtonStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF)
  ::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A); (; σ) = step
    X = spdiagm(x); X⁻¹ = spdiagm(1 ./ x); S = spdiagm(s); 
    Θ = -spdiagm(s ./ x) # -(X*S⁻¹)⁻¹,  Makes matrix below prettier :)
    e = ones(n); Zᵐ = spzeros(m, m)
    μ = x's / n

    # System
    F = dropzeros!([
        Θ A';
        A Zᵐ
    ])

    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ = X * S * e - σ * μ * e
    R = [-rᶜ + X⁻¹ * rˣˢ; -rᵇ]

    Δ = solve(LinearProblem(F, R)).u
    Δx = Δ[1:n]
    Δλ = Δ[n+1:n+m]
    Δs = -X⁻¹ * (rˣˢ + S * Δx)

    return Δx, Δλ, Δs, μ
end