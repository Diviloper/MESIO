function mehrotra_augmented_system(
  step::MehrotraStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF
)::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A)
    X = spdiagm(x); X⁻¹ = spdiagm(1 ./ x); S = spdiagm(s)
    Θ = -spdiagm(s ./ x) # -(X*S⁻¹)⁻¹,  Makes matrix below prettier :)
    e = ones(n); Zᵐ = spzeros(m, m)
    μ = x's / n

    # System
    F = lu!(dropzeros!([
        Θ A';
        A Zᵐ
    ]))

    # Predictor
    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ = X * S * e
    P = [-rᶜ + X⁻¹ * rˣˢ; -rᵇ]

    Δᵃ = Fᶠ \ P
    Δxᵃ = Δᵃ[1:n]
    Δλᵃ = Δᵃ[n+1:n+m]
    Δsᵃ = -X⁻¹ * (rˣˢ + S * Δxᵃ)

    αpᵃ = min(1, minimum((-x./Δxᵃ)[Δxᵃ.<0]; init=Inf))
    αdᵃ = min(1, minimum((-s./Δsᵃ)[Δsᵃ.<0]; init=Inf))
    μᵃ = ((x + αpᵃ * Δxᵃ)' * (s + αdᵃ * Δsᵃ)) / n
    σ = (μᵃ / μ)^3

    # Centering + Corrector 
    if μ > 10
        c = -σ * μ * e + αdᵃ * Δxᵃ .* Δsᵃ
    else
        c = -σ * μ * e + Δxᵃ .* Δsᵃ
    end
    C = [X⁻¹ * c; zeros(m)]

    Δᶜ = Fᶠ \ C
    Δxᶜ = Δᶜ[1:n]
    Δλᶜ = Δᶜ[n+1:n+m]
    Δsᶜ = -A'Δλᶜ

    return Δxᵃ + Δxᶜ, Δλᵃ + Δλᶜ, Δsᵃ + Δsᶜ, μ
end