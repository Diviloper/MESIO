#import "config.typ"
#show: config.global_config

#include "title.typ"

#outline()
#outline(title: [List of Tables], target: figure.where(kind: table))
#outline(title: [List of Codes], target: figure.where(kind: "Code"))


#show: config.content_config
#show raw.where(lang: "ampl"): set raw(block: true, syntaxes: "ampl.sublime-syntax")

#show raw.where(block: true): it => [
  #let nlines = it.lines.len()
  #table(
    columns: (auto, auto), 
    align: (right, left), 
    inset: 0.0em, 
    gutter: 0.5em, 
    stroke: none,
    ..it.lines.enumerate().map(((i, line)) => (math.mono(text(gray)[#(i + 1)]), line)).flatten()
  )
]


= Introduction

Interior-point methods are a family of algorithms used to solve linear and nonlinear problems, exploring the interior of the feasible region, instead of traversing its boundary (as Simplex does). One of the most efficient and commonly used is the Primal-Dual Path-Following Algorithm.
In this report, a Julia implementation is presented with several alternative steps (@section:implementation). These steps are then evaluated with several Netlib problems against each other and other open-source solvers#footnote[Spoiler Alert: it doesn't lose :).] (@section:results).

= Implementation <section:implementation>

The Primal-Dual Path-Following (PDPF) Algorithm has been implemented in Julia#footnote[#link("https://julialang.org")]. The complete code (split into several files) is delivered along this report. The actual functions may be slightly different from the codes#footnote[This time it's actual code rather than screenshots because I ditched Latex to try Typst.] shown here, but only in formatting or minor changes to improve readability, not in functionality.

== Main Algorithm

The main #raw("primal_dual_path_following") function is shown in #ref(<code:pdpf>).
It takes an optimization in standard equality form, an initial point for the algorithm (divided into the three components $x^0, lambda^0, s^0$), and, optionally, a #raw("Step") object indicating the kind of step that will be performed (a Newton step by default), the feasibility and optimality tolerances $epsilon^f$ and $epsilon^o$ (both of which default to $1e-8$) and the step reduction factor $rho$ (which defaults to $0.99$).

The function starts making sure the given coefficient matrix is full-rank.
If it is not, we try to transform the problem so it is#footnote[The transformation is exactly the same as in the Primal Affine Scaling report, and is therefore not explained in more detail here.], and call again the function with the now-full-rank problem. 
If the transformation fails, we abort.

We then create the variables that in which we will store the points, directions, residuals, and gaps of every iteration, and initialize them.
Once inside the loop, we perform the following steps:
- Compute the direction (lines 32-33): this computation is not made here, but rather delegated to the #raw("compute_direction") function, which, depending on the value of #raw("step") will perform different movements. This method and all the step possibilities are explained in detail in #ref(<section:implementation.step>) below.
- Compute the step sizes and new point (lines 35-40): the primal and dual step sizes ($alpha^p$ and $alpha^d$) are computed and used to compute the next point.
- Calculate and check gaps (lines 44-53): the residuals and gaps are computed and checked against the given tolerances. If all the gaps are lower than their respective tolerances, we stop. Otherwise, we repeat the steps again. The primal and dual gaps are computed using the #raw("gap") function defined right after the main function.


#show figure: set block(breakable: true)
#figure(
  [
    #line(length: 90%)
    #raw(read("code/pdpf.jl"), lang: "julia", block: true)
    #line(length: 90%)
  ],
  caption: [Implementation of the #raw("primal_dual_path_following") function in Julia.],
  supplement: "Code",
  kind: "Code",
) <code:pdpf>

== Step computation <section:implementation.step>

As mentioned above, the computation of the step at each iteration is performed by the #raw("compute_step") function.
The #raw("step") parameter indicates exactly which step will be computed, and how: both the Newton Step and the Mehrothra (Corrector-Predictor) Step are implemented with the three methods to solve the linear systems of equations (base system, augmented system and normal equations).

This approach of moving the computation to dedicated functions has its advantages, namely the ability of seamlessly swap between step types and computations without changing the base code, but it also has its drawbacks.
In this case, the methods recreate many matrices at every iterations that could be either completely reused or at least overwritten to avoid reallocating memory.
Since the main goal of this implementations is not pure performance, 

#ref(<code:step>) shows the definition of the #raw("Step") type. Only two kind exist: #raw("NewtonStep") and #raw("MehrotraStep"). Both hold a #raw("system") member indicating which system of equations will be used to compute it, which can be any of the three mentioned before.

A comparison between the performances is presented in #ref(<section:results.step>).

#figure(
  [
    #line(length: 90%)
    #raw(read("code/step.jl"), lang: "julia", block: true)
    #line(length: 90%)
  ],
  caption: [Definition and subtypes of #raw("Step") in Julia.],
  supplement: "Code",
  kind: "Code",
) <code:step>

=== Newton Step <section:implementation.step.newton>

Codes #ref(<code:newton.base>, supplement: none), #ref(<code:newton.augmented>, supplement: none), and #ref(<code:newton.normal>, supplement: none) show the implementations of the Newton Step solving the Base, Augmented and Normal systems respectively.
The Base and Augmented systems have been solved using the #link("https://docs.sciml.ai/LinearSolve/stable/")[LinearSolve.jl] package, which provides a unified interface for many solvers and can choose the best depending on the system characteristics.

#figure(
  [
    #line(length: 90%)
    #raw(read("code/newton_base.jl"), lang: "julia", block: true)
    #line(length: 90%)
  ],
  caption: [Implementation of the Newton Step with Base System.],
  supplement: "Code",
  kind: "Code",
) <code:newton.base>

In the function solving the Augmented system (#ref(<code:newton.augmented>)), note that $Theta$ has been computed as $-(X S^(-1))^(-1)$ instead of the normal $X S^(-1)$ to make the system matrix prettier, since it has no other use.

#figure(
  [
    #line(length: 90%)
    #raw(read("code/newton_augmented.jl"), lang: "julia", block: true)
    #line(length: 90%)
  ],
  caption: [Implementation of the Newton Step with Augmented System.],
  supplement: "Code",
  kind: "Code",
) <code:newton.augmented>

The Normal system has been solved directly using a Cholesky factorization.
Sometimes, due to numerical issues, the factorization fails. In these cases, we perform the factorization again but adding a small perturbation in the diagonal (lines 13-16 in #ref(<code:newton.normal>)). Note that here, unlike in the Augmented system, $Theta$ is computed normally as $X S^(-1)$.

#figure(
  [
    #line(length: 90%)
    #raw(read("code/newton_normal.jl"), lang: "julia", block: true)
    #line(length: 90%)
  ],
  caption: [Implementation of the Newton Step with Normal Equations.],
  supplement: "Code",
  kind: "Code",
) <code:newton.normal>


=== Mehrotra Step <section:implementation.step.mehrotra>

The Mehrotra (Corrector-Predictor) step with the base, normal and augmented systems are shown in Codes #ref(<code:mehrotra.base>, supplement: none), #ref(<code:mehrotra.augmented>, supplement: none), and #ref(<code:mehrotra.normal>, supplement: none) respectively. Now, all systems have been solved without using the LinearSolve.jl library, since it couldn't reuse the factorizations#footnote[In theory, caching and reusing the factorizations should be possible, and it is stated in #link("https://docs.sciml.ai/LinearSolve/dev/tutorials/caching_interface/")[their documentation]. However, when used in the code, it didn't yield correct results, so manual factorization and solving was the used approach.].

In all 3 systems, the suggested modification of the right-hand-side component of the complementarity equations has been applied (i.e. using $sigma mu e − alpha^text("aff")_d Delta^text("aff")_X Delta^text("aff")_S e$ instead of $sigma mu e − Delta^text("aff")_X Delta^text("aff")_S e$) has been applied in the first iterations ($mu gt 10$), since in some cases the procedure would get stuck at the beginning.

For the Base System (#ref(<code:mehrotra.base>)), an LU factorization has been used, since it's the one provided by Julia for generic square matrices.
#figure(
  [
    #line(length: 90%)
    #raw(read("code/mehrotra_base.jl"), lang: "julia", block: true)
    #line(length: 90%)
  ],
  caption: [Implementation of the Mehrotra Step with Base System.],
  supplement: "Code",
  kind: "Code",
) <code:mehrotra.base>

The Augmented System has been solved using also a LU factorization, since the Bunch-Kaufman factorization implementation is only available for dense matrices. According to the #link("https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/#LinearAlgebra.factorize")[Julia documentation], the LDLᵀ factorization supports arbitrary symmetric sparse matrices, but in practice, it fails due to the zeros in the diagonal (and suggests using the LU factorization in the error message). As in the Newton Step, here $Theta eq -(X S^(-1))^(-1)$ instead of $X S^(-1)$.

#figure(
  [
    #line(length: 90%)
    #raw(read("code/mehrotra_augmented.jl"), lang: "julia", block: true)
    #line(length: 90%)
  ],
  caption: [Implementation of the Mehrotra Step with Augmented System.],
  supplement: "Code",
  kind: "Code",
) <code:mehrotra.augmented>

For the Normal System, a Cholesky factorization is used. As in the Newton step implementation, when the factorization of the matrix fails, a small permutation is added to the diagonal.

#figure(
  [
    #line(length: 90%)
    #raw(read("code/mehrotra_normal.jl"), lang: "julia", block: true)
    #line(length: 90%)
  ],
  caption: [Implementation of the Mehrotra Step with Normal Equations.],
  supplement: "Code",
  kind: "Code",
) <code:mehrotra.normal>

= Results <section:results>

#import "results.typ"

== Step Computation <section:results.step>

An initial comparison between the performance of the different step and computation methods has been carried out. 
A total of 77 Netlib problems have been used, and the full results are provided in the #raw("pdpf_step.csv") file.
However, due to size and readability constraints, only a representative subset of the results are shown here.

The characteristics of the 6 representative problems are shown in #ref(<results:step:problems>), and as can be seen, include problems of varying size, both in standard and non-standard form.

#figure(
  results.problem_dimensions(csv("data/step_problems.csv")),
  caption: [Characteristics of the Netlib problems used in the Step comparison.]
) <results:step:problems>


The results of the comparison are shown in Tables #ref(<results:step:iterations>, supplement: none) and #ref(<results:step:time>, supplement: none), the first showing the number of iterations for each method/system, and the seconds showing the execution time. Experiments for which the execution failed have a dash in their values.

As can be seen, the Newton step with the Base system (and Augmented) are the most robust, and didn't fail for any of the shown problems.
In practice all of them fail for some problems, but the Newton step with the Base system remains the most robust one.
In many cases, the starting point is the factor that dictates whether a step fails or not. For example, the #raw("lp_stocfor1") problem failed in the experiment, but when running it again several times with different starting points (chosen at random), it solved many of them.

In #ref(<results:step:iterations>) we can see that normally, different computation methods don't modify the number of iterations (as is expected), but that's not always the case. For example, in many cases (such as #raw("lp_etamacro")), the Augmented system requires more iterations (in both step types), while in others (#raw("lp_grow22")), all computation methods require a different number of iterations. This is due to numerical errors in the computations yielding slightly different results, which end up being significant enough to make the algorithm run longer.

#figure(
  results.step_comparison(csv("data/step_iterations.csv")),
  caption: [Number of iterations for the different step types and systems]
) <results:step:iterations>

Regarding execution times, shown in #ref(<results:step:time>), the behavior is as expected. Within the step type, the Normal system is significantly faster then the Augmented system, which, in turn, is significantly faster than the Base System.
In general, the Mehrotra Step is faster than the Newton Step, but the speedup is directly tied to the number of iterations required, and not because the step is inherently faster to compute (which shouldn't be since it requires more computations).

#figure(
  results.step_comparison(csv("data/step_time.csv")),
  caption: [Execution time in seconds for the different step types and systems]
) <results:step:time>

== Solver comparison

The implemented procedure has been tested with a total of 77 of Netlib’s LP problems.
In particular the first 77 problems after sorting them ascendingly by the size of their coefficient matrices after applying standardization. 
All problems have been run with a feasibility tolerance $ epsilon^f eq 1e^(-8)$, an optimality tolerance $epsilon^o eq 1e^(-8)$ and a step size reduction factor $rho$ = 0.99. The full results of the comparison are provided in the `pdpf_comparison.csv` file.

The same problems have been solved using two of the many solvers available in Julia: Tulip @Tulip.jl and HiGHS @HiGHS.
Tulip is a pure Julia solver that implements the homogeneous primal-dual interior point algorithm with multiple centrality corrections, while HiGHS is a Julia wrapper of the HiGHS solver written in C++ based on the dual revised simplex solver presented in @HiGHS.
 
Of the 77 problems, our implementation of the Primal-Dual Path-Following Algorithm has been able to solve 74, although not with every step type. @results:comparison:step shows the number of problems that have been solved by each step type. We can see that while we were able to solve almost all of them with the Newton step with Base system, we could solve less with the rest, the least being the Mehrotra step with the Normal system, with 32 problems solved. Tulip and HiGHS were able to solve 72 and 67 problems each.

#figure(
  table(
    columns: 9,
    align: center+horizon,
    row-gutter: (auto, 2.2pt, auto),
    column-gutter: (2.2pt, auto, auto, 2.2pt, auto, auto, 2.2pt),
    table.cell(rowspan: 2, [], stroke: white),
    table.cell(colspan: 3, [Newton]),
    table.cell(colspan: 3, [Mehrotra]),
    table.cell(rowspan: 2, [Tulip]),
    table.cell(rowspan: 2, [HiGHS]),
    [Base], [Augmented], [Normal],
    [Base], [Augmented], [Normal],
    [Num Solved],
    [74], [58], [36],
    [35], [33], [32],
    [72], [67]
    
  ),
  caption: [Problems solved by each Step]
) <results:comparison:step>

We showcase here a handpicked selection of 6 problems in which the Mehrotra step with Normal system successfully solves the problems and compare its performance with that of the Tulip and HiGHS solvers. @results:comparison:problems show the dimensions and characteristics of the problems shown.

#figure(
results.problem_dimensions(csv("data/comparison_problems.csv")),
  caption: [Characteristics of the Netlib problems used in the Solver comparison.]
) <results:comparison:problems>

@results:comparison:results shows the number of iterations, cost of the solution and execution time for our implementation, the Tulip solver and the HiGHS solver.

We can see that in all 6 cases, our implementation of the PDPF obtains a similar result as both solvers. In number of iterations, it requires (generally) much fewer iterations than the HiGHS solver, which is to be expected since HiGHS is simplex-based. However, it still requires more than Tulip, which is interior-point-based. 

As can be seen, our implementation manages to compete with the other solvers, even being faster in some cases (e.g. faster than Tulip for `lp_sctap3`).

#pad(
  x: -4em,
[#figure(
  results.solver_comparison(csv("data/comparison_data.csv")),
  caption: [Experimental results between presented implementation, Tulip and HiGHS.]
) <results:comparison:results>]
)

= Conclusions

In this assignment we have provided a Julia implementation of the Primal-Dual Path-Following algorithm with two different step types (Newton and Mehrotra), with three different computations methods (Base, Augmented, and Normal).

Moreover we have presented a performance comparison between all the implemented steps, comparing both robustness and performance.
The performance of our implementation has been also compared against two open-source solvers implementing different algorithms (both simplex-based and interior-point) using Netlib problems. Our implementation is capable of solving the majority of the used problems, and can keep up with the other solvers, not only regarding the solution obtained, but also in the time consumed.


#bibliography("references.bib")