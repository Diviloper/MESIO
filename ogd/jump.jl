using JuMP

function solve_with_jump((; A, b, c)::StandardProblem, optimizer)::Tuple{VF,Model}
    model = Model(optimizer)
    set_silent(model)

    n = size(A, 2)

    @variable(model, x[1:n])
    @constraint(model, A * x == b)
    @constraint(model, x .>= 0)
    @objective(model, Min, c' * x)

    optimize!(model)

    return value.(x), model
end

function solve_with_jump(EP::ExtendedProblem, optimizer)::Tuple{VF,Model}
    (P, m, n) = standardize(EP)
    x, model = solve_with_jump(P, optimizer)
    return x[1:n], model
end