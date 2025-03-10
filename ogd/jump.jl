using JuMP

function solve_with_jump((; A, b, c)::StandardProblem, optimizer)::VF
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

function solve_with_jump(EP::ExtendedProblem, optimizer)::VF
    (P, m, n) = standardize(EP)
    x = solve_with_jump(P, optimizer)
    return x[1:n]
end