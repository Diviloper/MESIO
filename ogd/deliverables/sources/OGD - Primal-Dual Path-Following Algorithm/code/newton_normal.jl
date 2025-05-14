function newton_normal_system(
  step::NewtonStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF
)::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A); (; σ) = step
    X = spdiagm(x); X⁻¹ = spdiagm(1 ./ x)
    S = spdiagm(s); S⁻¹ = spdiagm(1 ./ s)
    Θ = X * S⁻¹; e = ones(n)
    μ = x's / n

    # System
    AΘAᵀ = cholesky!(Symmetric(A * Θ * A'); check=false)
    if !issuccess(AΘAᵀ)
        @warn "Cholesky factorization failed. Adding perturbation"
        AΘAᵀ = cholesky!(Symmetric(A * Θ * A' + 1e-6 * I); check=false)
    end

    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ = X * S * e - σ * μ * e
    R = -rᵇ + A * (-Θ*rᶜ + S⁻¹ * rˣˢ)

    Δλ = AΘAᵀ \ R
    Δs = -rᶜ - A'Δλ
    Δx = -S⁻¹ * (rˣˢ + X * Δs)

    return Δx, Δλ, Δs, μ
end