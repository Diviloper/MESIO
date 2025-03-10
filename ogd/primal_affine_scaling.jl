using LinearAlgebra, LinearSolve, SparseArrays, Logging

function primal_affine_scaling(P::StandardProblem, ϵ::Float64=10e-6, ρ::Float64=0.995)::Result
    PM, x̄⁰ = expand_problem(P)

    (; o, x, Δ, gap) = primal_affine_scaling(PM, x̄⁰, ϵ, ρ)

    if o[end] > ϵ
        @warn "Problem is unfeasible: xₙ₊₁ = $(o[end])"
    end

    return Result(x[:, 1:end-1], Δ[:, 1:end-1], gap)
end

function primal_affine_scaling(P::ExtendedProblem, ϵ::Float64=10e-6, ρ::Float64=0.995)::Result
    (SP, m, n) = standardize(P)

    (; o, x, Δ, gap) = primal_affine_scaling(SP, ϵ, ρ)

    # Keep only original variables
    return Result(x[:, 1:n], Δ[:, 1:n], gap)
end

function primal_affine_scaling(P::StandardProblem, x⁰::VF, ϵ::Float64=10e-6, ρ::Float64=0.995)::Result
    # Constants
    (; A, b, c) = P
    Aᵀ = transpose(A)

    # Checks
    @assert rank(A) == size(A, 1) "Matrix A must be full-rank (rank: $(rank(A)), #rows: $(size(A, 1)))"

    # History
    x::VVF = [x⁰]
    Δ::VVF = []
    gap::VF = []

    # Initializations
    k = 1
    D = Diagonal(x[k])^2
    y = compute(A * D * Aᵀ, A * D * c)
    push!(gap, dual_gap(c'x[k], b'y))
    
    @info "Iteration $k"
    @debug "Auxiliar variables" diag(D)' y' gap[k]

    while gap[k] > ϵ

        @assert A*x[k] ≈ b "Problem no longer feasible"
        
        z = c - Aᵀ * y
        push!(Δ, -D * z) # Δₖ = -Dz

        @assert !all(Δ[k] .>= 0) "Unbounded Problem"

        α = ρ * minimum(-xᵏᵢ / Δᵏᵢ for (xᵏᵢ, Δᵏᵢ) = zip(x[k], Δ[k]) if Δᵏᵢ <= 0)
        push!(x, x[k] + α * Δ[k]) # xᵏ = αΔᵏ

        @debug "Step $k variables" α Δ[k]

        k += 1

        D = Diagonal(x[k])^2
        y = compute(A * D * Aᵀ, A * D * c)
        
        @debug "Gap variables" c'x[k] b'y
        push!(gap, dual_gap(c'x[k], b'y))
        
        @info "New point x[$k]" x[k]' c'x[k] gap[k]

        @info "Iteration $k"
        @debug "Auxiliar variables" diag(D)' y'
    end

    return Result(x, Δ, gap)
end

dual_gap(cᵀx::Float64, bᵀy::Float64)::Float64 = abs(cᵀx - bᵀy) / (1 + abs(cᵀx))
    

function compute(A::MF, b::VF)::VF
    return solve(LinearProblem(A, b)).u
end
