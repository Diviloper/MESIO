function mehrotra_base_system(
  step::MehrotraStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF
)::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A)
    X = spdiagm(x); S = spdiagm(s)
    e = ones(n); I = spdiagm(e)
    Zᵐ = spzeros(m, m); Zⁿ = spzeros(n, n)
    Zᵐⁿ = spzeros(m, n); Zⁿᵐ = spzeros(n, m)
    μ = x's / n

    # System
    F = lu!(dropzeros!([
        Zⁿ A'  I;
        A  Zᵐ  Zᵐⁿ;
        S  Zⁿᵐ X
    ]))

    # Predictor
    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ = X * S * e
    P = [-rᶜ; -rᵇ; -rˣˢ]

    Δᵃ = F \ P
    Δxᵃ = Δᵃ[1:n]
    Δsᵃ = Δᵃ[n+m+1:end]
    
    αpᵃ = min(1, minimum((-x ./ Δxᵃ)[Δxᵃ .< 0]; init=Inf))
    αdᵃ = min(1, minimum((-s ./ Δsᵃ)[Δsᵃ .< 0]; init=Inf))
    μᵃ = ((x + αpᵃ * Δxᵃ)' * (s + αdᵃ * Δsᵃ)) / n
    σ = (μᵃ / μ)^3

    # Centering + Corrector 
    if μ > 10
        c = μ * σ * e - αdᵃ * Δxᵃ .* Δsᵃ
    else
        c = μ * σ * e - Δxᵃ .* Δsᵃ
    end
    C = [zeros(n); zeros(m); c]

    Δᶜ = F \ P
    Δ = Δᵃ + Δᶜ

    return Δ[1:n], Δ[n+1:n+m], Δ[n+m+1:end], μ
end