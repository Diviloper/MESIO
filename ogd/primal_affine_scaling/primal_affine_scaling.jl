using LinearAlgebra, LinearSolve, Logging, ProgressMeter, SparseArrays

function primal_affine_scaling(P::StandardProblem, ϵ::Float64=1e-6, ρ::Float64=0.995)::Result
    @info "No initial point provided. Expanding problem to obtain feasible initial point."
    PM, x̄⁰ = expand_problem(P)

    (; o, x, Δ, gap, reason, feasible) = primal_affine_scaling(PM, x̄⁰, ϵ, ρ)

    if o[end] > ϵ
        @warn "Problem is unfeasible: xₙ₊₁ > ϵ => $(o[end]) > $ϵ"
        feasible = false
    else
        @info "Problem is feasible: xₙ₊₁ < ϵ => $(o[end]) < $ϵ"
    end

    # Remove xₙ₊₁
    return Result([xᵢ[1:end-1] for xᵢ in x], [Δᵢ[1:end-1] for Δᵢ in Δ], gap, reason, feasible)
end

function primal_affine_scaling(P::ExtendedProblem, ϵ::Float64=1e-6, ρ::Float64=0.995)::Result
    @info "Problem doesn't have standard form. Standardizing."
    (SP, m, n) = standardize(P)

    (; o, x, Δ, gap, reason, feasible) = primal_affine_scaling(SP, ϵ, ρ)

    if any(x[end][1:n] .< 0)
        @warn "Negative variables"
        feasible = false
    end

    # Keep only original variables
    return Result([xᵢ[1:n] for xᵢ in x], [Δᵢ[1:n] for Δᵢ in Δ], gap, reason, feasible)
end

function primal_affine_scaling(P::StandardProblem, x⁰::VF, ϵ::Float64=1e-6, ρ::Float64=0.995)::Result
    # Constants
    (; A, b, c) = P
    Aᵀ = transpose(A)

    # Checks
    if rank(A) != size(A, 1)
        @info "Problem is not full rank. Fixing."
        frp = make_full_rank(P)
        if (rank(frp.A) != size(frp.A, 1))
            @warn "Couldn't make problem full rank. Aborting."
            return Result(x⁰, [x⁰], [], [], 0, stop_rank, false)
        end
        return primal_affine_scaling(frp, x⁰, ϵ, ρ)
    end
    @assert A * x⁰ ≈ b "Initial x⁰ point is not feasible"

    @info "Starting Primal-Affine Scaling"

    # History
    x::VVF = [x⁰]
    Δ::VVF = []
    gap::VF = []

    # Initializations
    previous_cost = Inf
    k = 1
    D = Diagonal(x[k])^2
    AD = A * D
    ADAᵀ = AD * Aᵀ
    ADc = AD * c
    y = cholesky!(Symmetric(collect(ADAᵀ))) \ ADc
    push!(gap, dual_gap(c'x[k], b'y))

    progress = ProgressThresh(ϵ; desc="Minimizing:", showspeed=true)

    reason = stop_gap_reached

    while gap[k] > ϵ
        if A * x[k] ≉ b || c'x[k] > previous_cost
            @info "Feasibility lost or objective fluctuation detected at $k."
            pop!(Δ)
            pop!(x)
            pop!(gap)
            k -= 1

            if ρ < 0.1
                @info "ρ too small ($ρ), stopping at last point."
                reason = stop_small_ρ
                break
            end
            ρ̂ = ρ > 0.6 ? 0.6 : 0.9ρ
            @info "Repeating iteration with reduced ρ ($ρ -> $ρ̂)"
            ρ = ρ̂
        end

        previous_cost = c'x[k]

        update!(progress, gap[k]; showvalues=[("Objective function", c'x[k]), ("Iteration", k)])


        z = c - Aᵀ * y
        push!(Δ, -D * z) # Δₖ = -Dz

        @assert !all(Δ[k] .>= 0) "Unbounded Problem"

        α = ρ * minimum((-x[k]./Δ[k])[Δ[k].<0])
        push!(x, x[k] + α * Δ[k])

        k += 1

        D = Diagonal(x[k])^2
        mul!(AD, A, D)
        mul!(ADAᵀ, AD, Aᵀ)
        mul!(ADc, AD, c)
        try
            y = cholesky!(Symmetric(collect(ADAᵀ))) \ ADc
        catch
            @info "Cholesky failed. Trying normal solve."
            try
                y = solve(LinearProblem(collect(ADAᵀ), ADc)).u
            catch
                @info "Normal solve failed. Stopping algorithm."
                reason = stop_cholesky_fail
                break
            end
        end

        push!(gap, dual_gap(c'x[k], b'y))
    end

    @info "Primal-Affine Scaling finished after $k iterations with cost $(c'x[k]) due to $reason"

    return Result(x, Δ, gap, reason, isapprox(A * x[end], b, rtol=ϵ))
end

dual_gap(cᵀx::Float64, bᵀy::Float64)::Float64 = abs(cᵀx - bᵀy) / (1 + abs(cᵀx))