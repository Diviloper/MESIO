using AMD;
using LDLFactorizations;

abstract type Step end

@enum System begin
    base
    augmented
    normal
    normal_permuted
end

struct NewtonStep <: Step
    σ::Float64
    system::System
end
NewtonStep(σ::Float64) = NewtonStep(σ, normal)
NewtonStep() = NewtonStep(0.1, normal)

struct MehrotraStep <: Step
    system::System
end
MehrotraStep() = MehrotraStep(normal)

function compute_direction(step::NewtonStep, P::StandardProblem, x::VF, λ::VF, s::VF)::Tuple{VF,VF,VF,Float64}
    if step.system == base
        return newton_base_system(step, P, x, λ, s)
    elseif step.system == augmented
        return newton_augmented_system(step, P, x, λ, s)
    elseif step.system == normal
        return newton_normal_system(step, P, x, λ, s)
    elseif step.system == normal_permuted
        return newton_permuted_normal_system(step, P, x, λ, s)
    end
end

function compute_direction(step::MehrotraStep, P::StandardProblem, x::VF, λ::VF, s::VF)::Tuple{VF,VF,VF,Float64}
    if step.system == base
        return mehrotra_base_system(step, P, x, λ, s)
    elseif step.system == augmented
        return mehrotra_augmented_system(step, P, x, λ, s)
    else
        return mehrotra_normal_system(step, P, x, λ, s)
    end
end

function newton_base_system(step::NewtonStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF)::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A)
    (; σ) = step

    X = spdiagm(x)
    S = spdiagm(s)

    e = ones(n)
    I = spdiagm(e)

    Zᵐ = spzeros(m, m)
    Zᵐⁿ = spzeros(m, n)
    Zⁿᵐ = spzeros(n, m)
    Zⁿ = spzeros(n, n)

    μ = x's / n

    # System construction

    F = dropzeros!([
        Zⁿ A' I;
        A Zᵐ Zᵐⁿ;
        S Zⁿᵐ X
    ])

    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ = X * S * e - σ * μ * e
    R = [-rᶜ; -rᵇ; -rˣˢ]

    Δ = lu(F) \ R

    return Δ[1:n], Δ[n+1:n+m], Δ[n+m+1:end], μ
end

function newton_augmented_system(step::NewtonStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF)::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A)
    (; σ) = step

    X = spdiagm(x)
    X⁻¹ = spdiagm(1 ./ x)
    S = spdiagm(s)
    Θ = -spdiagm(s ./ x) # -(X*S⁻¹)⁻¹,  Makes matrix below prettier :)

    e = ones(n)
    Zᵐ = spzeros(m, m)

    μ = x's / n

    # System construction

    F = dropzeros!([
        Θ A';
        A Zᵐ
    ])

    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ = X * S * e - σ * μ * e
    R = [-rᶜ + X⁻¹ * rˣˢ; -rᵇ]

    r = lu(F) \ R

    Δx = r[1:n]
    Δλ = r[n+1:n+m]
    Δs = -X⁻¹ * (rˣˢ + S * Δx)

    return Δx, Δλ, Δs, μ
end

function newton_normal_system(step::NewtonStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF)::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A)
    (; σ) = step

    X = spdiagm(x)
    X⁻¹ = spdiagm(1 ./ x)
    S = spdiagm(s)
    S⁻¹ = spdiagm(1 ./ s)

    Θ = X * S⁻¹

    e = ones(n)

    μ = x's / n

    # System
    AΘAᵀ = cholesky(Symmetric(A * Θ * A'); check=false)
    if !issuccess(AΘAᵀ)
        @warn "Cholesky factorization failed. Adding perturbation"
        AΘAᵀ = cholesky(Symmetric(A * Θ * A' + 1e-6 * I); check=false)
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

function newton_permuted_normal_system(step::NewtonStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF)::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A)
    (; σ) = step

    X = spdiagm(x)
    X⁻¹ = spdiagm(1 ./ x)
    S = spdiagm(s)
    S⁻¹ = spdiagm(1 ./ s)

    Θ = X * S⁻¹

    e = ones(n)

    μ = x's / n

    # System construction

    AΘAᵀ = A * Θ * A'
    perm = symamd(AΘAᵀ)
    P = sparse(collect(1:m), perm, ones(size(perm, 1)))
    LDLᵀ = Symmetric(P * AΘAᵀ * P')

    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ = X * S * e - σ * μ * e

    R = -rᵇ + A * Θ * (-rᶜ + X⁻¹ * rˣˢ)
    Δλ = P' * (cholesky(LDLᵀ, Val(true)) \ (P * R))
    Δs = -rᶜ - A'Δλ
    Δx = -S⁻¹ * (rˣˢ + X * Δs)

    return Δx, Δλ, Δs, μ
end


function mehrotra_base_system(step::MehrotraStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF)::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A)

    X = spdiagm(x)
    S = spdiagm(s)

    e = ones(n)
    I = spdiagm(e)

    Zᵐ = spzeros(m, m)
    Zᵐⁿ = spzeros(m, n)
    Zⁿᵐ = spzeros(n, m)
    Zⁿ = spzeros(n, n)

    μ = x's / n

    # Predictor

    F = lu(dropzeros!([
        Zⁿ A' I;
        A Zᵐ Zᵐⁿ;
        S Zⁿᵐ X
    ]))

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

    Δᶜ = F \ C

    Δ = Δᵃ + Δᶜ

    return Δ[1:n], Δ[n+1:n+m], Δ[n+m+1:end], μ
end


function mehrotra_augmented_system(step::MehrotraStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF)::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A)

    X = spdiagm(x)
    X⁻¹ = spdiagm(1 ./ x)
    S = spdiagm(s)
    Θ = -spdiagm(s ./ x) # -(X*S⁻¹)⁻¹,  Makes matrix below prettier :)

    e = ones(n)
    Zᵐ = spzeros(m, m)

    μ = x's / n

    # System construction

    F = lu(dropzeros!([
        Θ A';
        A Zᵐ
    ]))

    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ = X * S * e
    P = [-rᶜ + X⁻¹ * rˣˢ; -rᵇ]

    Δᵃ = F \ P

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

    Δᶜ = F \ C

    Δxᶜ = Δᶜ[1:n]
    Δλᶜ = Δᶜ[n+1:n+m]
    Δsᶜ = -A'Δλᶜ

    return Δxᵃ + Δxᶜ, Δλᵃ + Δλᶜ, Δsᵃ + Δsᶜ, μ
end


function mehrotra_normal_system(step::MehrotraStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF)::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A)

    X = spdiagm(x)
    S = spdiagm(s)
    S⁻¹ = spdiagm(1 ./ s)

    Θ = X * S⁻¹

    e = ones(n)

    μ = x's / n

    # System
    AΘAᵀ = cholesky(Symmetric(A * Θ * A'); check=false)
    if !issuccess(AΘAᵀ)
        @warn "Cholesky factorization failed. Adding perturbation"
        AΘAᵀ = cholesky(Symmetric(A * Θ * A') + 1e-6 * I)
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