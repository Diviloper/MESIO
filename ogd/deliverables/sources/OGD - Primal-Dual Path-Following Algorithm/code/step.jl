abstract type Step end

@enum System begin
    base
    augmented
    normal
end

struct NewtonStep <: Step
    σ::Float64
    system::System
end
NewtonStep(σ::Float64) = NewtonStep(σ, normal)
NewtonStep() = NewtonStep(0.1, normal)

struct MehrotraStep <: Step
    system::System
end
MehrotraStep() = MehrotraStep(normal)