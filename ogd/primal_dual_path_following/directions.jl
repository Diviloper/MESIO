abstract type Step end

@enum System begin
    base
    augmented
    normal
end

struct NewtonStep <: Step
    σ::Float64
    system::System
end
NewtonStep(σ::Float64) = NewtonStep(σ, normal)
NewtonStep() = NewtonStep(0.1, normal)

struct MehrotraStep <: Step
end

function compute_direction(step::NewtonStep, P::StandardProblem, x::VF, λ::VF, s::VF)::Tuple{VF,VF,VF,Float64}
    if step.system == base
        return newton_base_system(step, P, x, λ, s)
    elseif step.system == augmented
        return newton_augmented_system(step, P, x, λ, s)
    elseif step.system == normal
        return newton_normal_system(step, P, x, λ, s)
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

    Zᵐ = sparse([m], [m], [0])
    Zᵐⁿ = sparse([m], [n], [0])
    Zⁿᵐ = sparse([n], [m], [0])
    Zⁿ = sparse([n], [n], [0])

    μ = x's / n

    # System construction

    F = dropzeros!([
        Zⁿ  A'  I  ;
        A   Zᵐ  Zᵐⁿ;
        S   Zⁿᵐ X
    ])

    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ = X * S * e - σ * μ * e
    R = [-rᶜ; -rᵇ; -rˣˢ]

    Δ = solve(LinearProblem(F, R)).u

    return Δ[1:n], Δ[n+1:n+m], Δ[n+m+1:end], μ
end

function newton_augmented_system(step::NewtonStep, (; A, b, c)::StandardProblem, x::VF, λ::VF, s::VF)::Tuple{VF,VF,VF,Float64}
    # Vars
    (m, n) = size(A)
    (; σ) = step

    X = spdiagm(x)
    X⁻¹ = spdiagm(1 ./ x)
    S = spdiagm(s)

    Θ = -spdiagm(s./x) # -(X*S⁻¹)⁻¹,  Makes matrix below prettier :)

    e = ones(n)

    Zᵐ = sparse([m], [m], [0])

    μ = x's / n

    # System construction

    F = dropzeros!([
        Θ  A';
        A  Zᵐ ;
    ])

    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ = X * S * e - σ * μ * e
    R = [-rᶜ + X⁻¹*rˣˢ; -rᵇ]

    r = solve(LinearProblem(F, R)).u

    Δx = r[1:n]
    Δλ = r[n+1:n+m]
    Δs = -X⁻¹*(rˣˢ + S*Δx)

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

    Θ = X*S⁻¹

    e = ones(n)

    μ = x's / n

    # System construction

    AΘAᵀ = A * Θ * A'

    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ = X * S * e - σ * μ * e

    R = -rᵇ + A * Θ * (-rᶜ + X⁻¹ * rˣˢ)
    Δλ = solve(LinearProblem(AΘAᵀ, R)).u
    Δs = -rᶜ - A'Δλ
    Δx = -S⁻¹ * (rˣˢ + X*Δs)

    return Δx, Δλ, Δs, μ
end

function compute_direction(step::MehrotraStep, A::SMF, x::SMF, s::SMF)
end