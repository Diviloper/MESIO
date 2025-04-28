function primal_dual_path_following(
  P::StandardProblem, x⁰::VF, λ⁰::VF, s⁰::VF, 
  step::Step=NewtonStep(), ϵᶠ::Float64=1e-8, ϵᵒ::Float64=1e-8, ρ::Float64=0.99
)::Result
    # Constants
    (; A, b, c) = P

    # Checks
    if rank(A, tol=ϵᶠ) != size(A, 1)
        @info "Problem is not full rank. Fixing."
        frp = make_full_rank(P)
        if (rank(frp.A, tol=ϵᶠ) != size(frp.A, 1))
            @warn "Couldn't make problem full rank. Aborting."
            return Result([x⁰], [λ⁰], [s⁰], [], [], [], [], [], [], [], [])
        end
        @info "Problem successfully full-ranked. Discarding initial point."
        return primal_dual_path_following(frp, step, ϵᶠ, ϵᵒ, ρ)
    end

    # History
    x::VVF = [x⁰]; λ::VVF = [λ⁰]; s::VVF = [s⁰]
    Δx::VVF = []; Δλ::VVF = []; Δs::VVF = []
    
    rᶜ::VVF = [[]], rᵇ::VVF = [[]], μ::VF = [0]
    primal_gap::VF = [0]; dual_gap::VF = [0]

    # Initializations

    k = 1

    while true
        Δxᵏ, Δλᵏ, Δsᵏ, μᵏ = compute_direction(step, P, x[k], λ[k], s[k])
        push!(Δx, Δxᵏ); push!(Δλ, Δλᵏ); push!(Δs, Δsᵏ)

        αᵖ = min(1, ρ * minimum((-x[k]./Δxᵏ)[Δxᵏ .< 0]; init=Inf))
        αˢ = min(1, ρ * minimum((-s[k]./Δsᵏ)[Δsᵏ .< 0]; init=Inf))

        push!(x, x[k] + αᵖ * Δxᵏ); 
        push!(λ, λ[k] + αˢ * Δλᵏ); 
        push!(s, s[k] + αˢ * Δsᵏ)

        k += 1

        push!(rᶜ, A' * λ[k] + s[k] - c)
        push!(rᵇ, A * x[k] - b)

        push!(dual_gap, gap(c, rᶜ[k]))
        push!(primal_gap, gap(b, rᵇ[k]))
        push!(μ, μᵏ)

        if dual_gap[k] <= ϵᶠ && primal_gap[k] <= ϵᶠ && μ[k] <= ϵᵒ
            break
        end
    end

    return Result(x, λ, s, Δx, Δλ, Δs, rᶜ, rᵇ, μ, primal_gap, dual_gap)
end

gap(v::VF, r::VF) = norm(r) / (1 + norm(v))