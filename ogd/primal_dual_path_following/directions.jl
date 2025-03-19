abstract type Step end

struct NewtonStep <: Step
    σ::Float64
end

struct MehrotraStep <: Step
end

function compute_direction(step::NewtonStep, A::SMF, x::VF, λ::VF, s::VF)::Tuple{VF, VF, VF, Float64}
    # Vars
    (m, n) = size(A)
    (;σ) = step

    X = spdiagm(x) 
    S = spdiagm(s)
    
    e = ones(n)
    I = spdiagm(e)

    Zᵐ = sparse([m], [m], [0])
    Zᵐⁿ = sparse([m], [n], [0])
    Zⁿᵐ = sparse([n], [m], [0])
    Zⁿ = sparse([n], [n], [0])

    μ = x's/n

    # System construction

    F = dropzeros!([
        Zⁿ A'  I  ;
        A  Zᵐ  Zᵐⁿ;
        S  Zⁿᵐ X
    ])

    rᶜ = A' * λ + s - c
    rᵇ = A * x - b
    rˣˢ= X*S*e - σ*μ*e
    R = [-rᶜ; -rᵇ; -rˣˢ]

    r = solve(LinearProblem(F, R))
    
    return r[1:n], r[n+1:n+m], r[n+m+1:end], μ
end

function compute_direction(step::MehrotraStep, A::SMF, x::SMF, s::SMF)
end