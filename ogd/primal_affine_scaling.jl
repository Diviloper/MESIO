using LinearAlgebra, LinearSolve

const VF = Vector{Float64}
const VVF = Vector{VF}
const MF = Matrix{Float64}

struct Problem
    A::MF
    b::VF
    c::VF
end

struct Result
    o::VF
    x::VVF
    Δ::VVF
    gap::VF
    iterations::Int
end
Result(o, x, Δ, gap) = Result(o, x, Δ, gap, x.size[1])
Result(x, Δ, gap) = Result(round.(x[end], digits=6), x, Δ, gap, x.size[1])

function primal_affine_scaling(P::Problem, ϵ::Float64=10e-8, ρ::Float64=0.995)::Result
    PM, x̄⁰ = expand_problem(P)

    (; o, x, Δ, gap) = primal_affine_scaling(PM, x̄⁰, ϵ, ρ)

    if o[end] > ϵ
        throw("Problem is unfeasible: xₙ₊₁ = $(x[end])")
    end

    return Result([xᵢ[1:end-1] for xᵢ in x], [Δᵢ[1:end-1] for Δᵢ in Δ], gap)
end

function primal_affine_scaling(P::Problem, x⁰::VF, ϵ::Float64, ρ::Float64)::Result
    # Constants
    (; A, b, c) = P
    Aᵀ = transpose(A)

    # History
    x::VVF = [x⁰]
    Δ::VVF = []
    gap::VF = []

    # Initializations
    k = 1
    D = Diagonal(x[k])^2
    y = compute(A * D * Aᵀ, A * D * c)
    push!(gap, dual_gap(b, c, x[k], y))

    while gap[k] > ϵ
        z = c - Aᵀ * y
        push!(Δ, -D * z) # Δₖ = -Dz

        if all(Δ[k] .>= 0)
            throw("Unbounded Problem")
        end

        α = ρ * minimum(-xᵏᵢ / Δᵏᵢ for (xᵏᵢ, Δᵏᵢ) = zip(x[k], Δ[k]) if Δᵏᵢ <= 0)
        push!(x, x[k] + α * Δ[k]) # xᵏ = αΔᵏ

        k += 1

        D = Diagonal(x[k])^2
        y = compute(A * D * Aᵀ, A * D * c)
        push!(gap, dual_gap(b, c, x[k], y))
    end

    return Result(x, Δ, gap)
end

function expand_problem(P::Problem)::Tuple{Problem,VF}
    (; A, b, c) = P

    n = size(c, 1)
    x⁰ = [1.0 for _ = 1:n]

    r = b - A * x⁰
    Ā = hcat(A, r)

    M = sum(abs.(c)) * 10000
    c̄ = push!(copy(c), M)

    x̄⁰ = push!(x⁰, 1)

    return Problem(Ā, b, c̄), x̄⁰
end

function dual_gap(b::VF, c::VF, x::VF, y::VF)::Float64
    cᵀx = transpose(c) * x
    bᵀy = transpose(b) * y

    return abs(cᵀx - bᵀy) / (1 + abs(cᵀx))
end

function compute(A::MF, b::VF)::VF
    return solve(LinearProblem(A, b)).u
end
