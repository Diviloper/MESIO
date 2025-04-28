function mehrotra_normal_system(
  step::MehrotraStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF
)::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A)
    X = spdiagm(x); S = spdiagm(s); S⁻¹ = spdiagm(1 ./ s)
    Θ = X * S⁻¹; e = ones(n)
    μ = x's / n

    # System
    AΘAᵀ = cholesky!(Symmetric(A * Θ * A'); check=false)
    if !issuccess(AΘAᵀ)
        @warn "Cholesky factorization failed. Adding perturbation"
        AΘAᵀ = cholesky!(Symmetric(A * Θ * A') + 1e-6 * I)
    end

    # Predictor
    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ = X * S * e
    R = -rᵇ + A * (-Θ*rᶜ + S⁻¹*rˣˢ)
    
    Δλᵃ = AΘAᵀ \ R
    Δsᵃ = -rᶜ - A'Δλᵃ
    Δxᵃ = -S⁻¹ * (rˣˢ + X * Δsᵃ)
    
    αpᵃ = min(1, minimum((-x ./ Δxᵃ)[Δxᵃ .< -1e-10]; init=Inf))
    αdᵃ = min(1, minimum((-s ./ Δsᵃ)[Δsᵃ .< -1e-10]; init=Inf))
    μᵃ = ((x + αpᵃ * Δxᵃ)' * (s + αdᵃ * Δsᵃ)) / n
    σ = (μᵃ / μ)^3

    # Centering + Corrector
    if μ > 10
        c = -σ * μ * e + αdᵃ * Δxᵃ .* Δsᵃ
    else
        c = -σ * μ * e + Δxᵃ .* Δsᵃ
    end
    C = A * S⁻¹ * c
    
    Δλᶜ = AΘAᵀ \ C
    Δsᶜ = -A'Δλᶜ
    Δxᶜ = -S⁻¹ * (c + X * Δsᶜ)

    return Δxᵃ + Δxᶜ, Δλᵃ + Δλᶜ, Δsᵃ + Δsᶜ, μ
end