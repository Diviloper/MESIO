using LinearAlgebra, LinearSolve

function primal_affine_scaling(A::Matrix{Float64}, b::Vector{Float64}, c::Vector{Float64}, ϵ::Float64, ρ::Float64)::Vector{Float64}

    xᵏ = initial()
    while true
        Δᵏ, y = direction(A, c, xᵏ);
        α = step_size(xᵏ, Δᵏ, ρ);
        xᵏ = xᵏ + α*Δᵏ;

        stop(b, c, xᵏ, y, ϵ) || break;
    end

    return xᵏ;
end

function initial()::Vector{Float64}
    # TODO: Complete initial
end

function stop(b::Vector{Float64}, c::Vector{Float64}, x::Vector{Float64}, y::Vector{Float64}, ϵ::Float64)::Bool
    cᵀx = transpose(c)*x;
    bᵀy = transpose(b)*y;
    
    return abs(cᵀx - bᵀy) / (1 + abs(cᵀx)) <= ϵ;
end

function direction(A::Matrix{Float64}, c::Vector{Float64}, xᵏ::Vector{Float64})::Tuple{Vector{Float64}, Vector{Float64}}
    Aᵀ = transpose(A);

    D = Diagonal(xᵏ)^2;
    y =  solve(A*D*Aᵀ, A*D*c);
    z = c - Aᵀ*y;

    Δᵏ = -D*z;

    return Δᵏ, y
end

function step_size(xᵏ::Vector{Float64}, Δᵏ::Vector{Float64}, ρ::Float64)::Vector{Float64}
    ᾱ = min(-xᵏᵢ/Δᵏᵢ for (xᵏᵢ, Δᵏᵢ) = zip(xᵏ,Δᵏ) if Δᵏᵢ<= 0);
    return ρ*ᾱ;
end