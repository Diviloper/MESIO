function primal_dual_path_following(P::StandardProblem, step::Step=NewtonStep(0.1), ϵᶠ::Float64=1e-8, ϵᵒ::Float64=1e-8, ρ::Float64=0.99)::Result
    @info "Creating random initial point"
    x⁰ = rand(size(P.c, 1)) .* 40
    λ⁰ = rand(size(P.c, 1)) .* 40
    s⁰ = rand(size(P.c, 1)) .* 40
    return primal_dual_path_following(PM, x⁰, λ⁰, s⁰, step, ϵᶠ, ϵᵒ, ρ)
end


function primal_dual_path_following(P::StandardProblem, x⁰::VF, λ⁰::VF, s⁰::VF, step::Step=NewtonStep(0.1), ϵᶠ::Float64=1e-8, ϵᵒ::Float64=1e-8, ρ::Float64=0.99)::Result
    # Constants
    (; A, b, c) = P

    # Checks
    if rank(A, tol=1e-8) != size(A, 1)
        @info "Problem is not full rank. Fixing."
        frp = make_full_rank(P)
        if (rank(frp.A, tol=1e-8) != size(frp.A, 1))
            @warn "Couldn't make problem full rank. Aborting."
            return Result([x⁰], [λ⁰], [s⁰], [], [], [], [], [], [], [], [])
        end
        return primal_dual_path_following(frp, x⁰, step, ϵᶠ, ϵᵒ)
    end


    @info "Starting Primal-Dual Path-Following"

    # History
    x::VVF = [x⁰]
    λ::VVF = [λ⁰]
    s::VVF = [s⁰]

    Δx::VVF = []
    Δλ::VVF = []
    Δs::VVF = []


    rᶜ::VVF = [[]]
    rᵇ::VVF = [[]]
    μ::VF = [0]

    primal_gap::VF = [0]
    dual_gap::VF = [0]

    # Initializations

    k = 1
    progress = ProgressUnknown(desc="Iterations:")

    while true
        Δxᵏ, Δλᵏ, Δsᵏ, μᵏ = compute_direction(step, A, x[k], λ[k], s[k])
        push!(Δx, Δxᵏ)
        push!(Δλ, Δλᵏ)
        push!(Δs, Δsᵏ)

        αᵖ = min(1, ρ*minimum((-x[k] ./ Δxᵏ)[Δxᵏ .< 0]))
        αˢ = min(1, ρ*minimum((-s[k] ./ Δsᵏ)[Δsᵏ .< 0]))

        push!(x, x[k] + αᵖ * Δxᵏ)
        push!(λ, λ[k] + αˢ * Δλᵏ)
        push!(s, s[k] + αˢ * Δsᵏ)
        
        k += 1
        
        push!(rᶜ, A' * λ[k] + s[k] - c)
        push!(rᵇ, A * x[k] - b)
        
        push!(dual_gap, gap(b, rᶜ[k]))
        push!(primal_gap, gap(b, rᵇ[k]))
        push!(μ, μᵏ)
        
        next!(progress; showvalues=[("Objective function", c'x[k]), ("Primal Gap", primal_gap[k]), ("Dual Gap", dual_gap[k]), ("Complementarity Gap", μ[k])])
        
        if dual_gap[k] <= ϵᶠ && primal_gap[k] <= ϵᶠ && μ[k] <= ϵᵒ
            break
        end
    end

    @info "Primal-Dual Path-Following finished after $k iterations with cost $(c'x[k])"

    return Result(x, λ, s, Δx, Δλ, Δs, rᶜ, rᵇ, μ, primal_gap, dual_gap)
end

gap(v::VF, r::VF) = norm(r) / (1 + norm(v))