using JuMP

function solve_with_jump((; A, b, c)::Problem, optimizer)::Vector{Float64}
    model = Model(optimizer)
    set_silent(model)

    n = size(A, 2)

    @variable(model, x[1:n])
    @constraint(model, A*x == b)
    @constraint(model, x .>= 0)
    @objective(model, Min, c'*x)

    optimize!(model)
    
    return value.(x)
end