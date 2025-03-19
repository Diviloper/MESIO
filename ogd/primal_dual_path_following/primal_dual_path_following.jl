function primal_dual_path_following(P::StandardProblem, ϵᶠ::Float64=1e-8, ϵᵒ::Float64=1e-18)::Result
    @info "Creating random initial point"
    x⁰ = rand(size(P.c, 1)) .* 40 
    return primal_dual_path_following(PM, x⁰, ϵᶠ, ϵᵒ)
end


function primal_dual_path_following(P::StandardProblem, x⁰::VF, ϵᶠ::Float64=1e-8, ϵᵒ::Float64=1e-18)::Result

    
end
