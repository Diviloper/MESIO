using LinearAlgebra, LinearSolve, SparseArrays

include("types.jl")
include("problem_utils.jl")

function primal_affine_scaling(P::Problem, ϵ::Float64=10e-8, ρ::Float64=0.995)::Result
    PM, x̄⁰ = expand_problem(P)

    (; o, x, Δ, gap) = primal_affine_scaling(PM, x̄⁰, ϵ, ρ)

    if o[end] > ϵ
        println("Problem is unfeasible: xₙ₊₁ = $(o[end])")
    end

    return Result([xᵢ[1:end-1] for xᵢ in x], [Δᵢ[1:end-1] for Δᵢ in Δ], gap)
end

function primal_affine_scaling(P::Problem, x⁰::VF, ϵ::Float64, ρ::Float64)::Result
    # Constants
    (; A, b, c) = P
    Aᵀ = transpose(A)

    # Checks
    if rank(A) != size(A, 1)
        throw("Matrix A is not full-rank :(. Transform the input and try again please :)")
    end

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
        println("Iteration $k")
        println("\tgap = $(gap[k])")
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

function dual_gap(b::VF, c::VF, x::VF, y::VF)::Float64
    cᵀx = transpose(c) * x
    bᵀy = transpose(b) * y

    return abs(cᵀx - bᵀy) / (1 + abs(cᵀx))
end

function compute(A::MF, b::VF)::VF
    return solve(LinearProblem(A, b)).u
end
