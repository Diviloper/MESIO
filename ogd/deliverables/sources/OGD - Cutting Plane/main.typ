#import "template.typ": *
#import "results.typ"
#import "@preview/diagraph:0.3.3": *

#let in-outline = state("in-outline", false)
#let flex-caption(long, short) = context if in-outline.get() { short } else { long }
#show outline: it => {
  in-outline.update(true)
  it
  in-outline.update(false)
}

#let labeled(equation, label) = {
  math.equation(
    block: true, 
    numbering: (x) => label, 
    equation
  )
}

#show: project.with(
  title: [Cutting Plane Algorithm],
  subject: "Large-Scale Optimization",
  authors: ("Víctor Diví i Cuesta", ),
  outlines: (
    (
      title: "List of Tables",
      target: table
    ),
    (
      title: "List of Summaries",
      target: "Summary"
    ),
  ),
  use-codly: true
)


= Introduction

== Problem

The Multi-commodity Network Flow Problem must be solved (in scalar notation):

#labeled(
  $
  text("Min")  quad quad & sum_(l in O) sum_(a in A) C_a x_a^l & \
  text("s.t.") quad quad & sum_((i,j) in A) x_(i j)^l - sum_((j,i) in A) x_(j i)^l = T_i^l quad quad & forall i in N, forall l in O \
  & sum_(l in O) x_a^l lt.eq Y_a & forall a in A \
  & x_a^l gt.eq 0 & forall a in A, forall l in O \
$,
[($P$)]
) <eq:p>

Where given an arc $a$, an origin $l$ and a node $i$, $x_a^l$ is the flow at $a$ from $l$, $C_a$ is the unitary cost of $a$, $Y_a$ is the maximum capacity of $a$, and $T_i^l$ is the net output flow at $i$ for flow from $l$

In @sec:base, the problem will be solved directly, and later, in @sec:cut, the Cutting Plane Algorithm will be used to do so, and two additional variants are implemented and discussed.

== Scenario

The scenario used in this report is Scenario 19, with:

$ 
N &= {1, dots, 24}\
O &= {3, 11} \
D &= {5, 8, 12, 13, 14, 17, 18, 19, 21, 23} \
C_(i j)^l &= 95 + (x_i - x_j)^2 + 8(y_i - y_j)^2 quad &quad& forall (i, j) in A, forall l in O \
T_i^l &= mat(
  500\,  &,, &text("if") i eq l;
  -50\,  &,, &text("if") i in D;
  0\,    &,, &text("otherwise");
  delim: #("{", none),
) && forall i in N, forall l in O
$

= Base Formulation <sec:base>

We start by solving the unconstrained version of the problem:

#labeled(
  $
    text("Min")  quad quad & sum_(l in O) sum_(a in A) C_a x_a^l & \
    text("s.t.") quad quad & sum_((i,j) in A) x_(i j)^l - sum_((j,i) in A) x_(j i)^l = T_i^l quad quad & forall i in N, forall l in O \
    & x_a^l gt.eq 0 & forall a in A, forall l in O \
  $,
  [($U$)]
) <eq:uc>

The solution obtained with this version has a total cost of $346240$. Its flows are listed in the flow tables of @summary:unconstrained (in parenthesis, the total flow when the link is used by both origins), and which links are used can be seen in the visualization of the network, where edges are painted according to the flow they carry from each origin (blue for origin 3, red for origin 11, and purple for links used by both).
Among all the links carrying flow, six has been chosen to be limited by a new cap. The selected links can be identified by dashed edges in the visualization, by orange entries in the flow tables, and are listed, with their new capacities, in the new maximum capacities table in the summary.

#figure(
  grid(
    columns: (auto, auto),
    align: center + horizon,
    gutter: 2pt,
    grid(
      align: top,
      columns: 2,
      inset: 3pt,
      grid.cell(colspan: 2, results.result_table([346240])),
      results.arc_flows_table([Flows for $l=3$], csv("data/unconstrained/flows_3.csv")),
      results.arc_flows_table([Flows for $l=11$], csv("data/unconstrained/flows_11.csv")),
      grid.cell(colspan: 2, results.new_caps_table([New Maximum Capacities ($Y_a$)], csv("data/unconstrained/caps.csv"))),
    ),
    raw-render(raw(read("graphs/unconstrained.dot")), engine: "neato", width: 100%)
),
  caption: flex-caption(
    [Results of the Unconstrained Problem and New Maximum Capacities.
    Links affected by new caps are represented by dashed edges in the graph and orange rows in the flow tables.
    Unused links are greyed in the graph and not included in the flow tables.],
    [Results of the unconstrained model.]
  ),
  supplement: "Summary",
  kind: "Summary"
) <summary:unconstrained>

With the newly added caps, the original (capacited) version of the problem generates a new solution with a total cost of $379245$, an increase of $33005$ (around 10%) of the uncapacited cost. 
The new solution is shown in @summary:constrained. 
Again, links affected by caps are dashed in the visualization and marked with orange in the flow tables.
In the Maximum Capacities table of the summary, we can see how all but one link are at maximum capacity, the only one not being the $(10 arrow 13)$ link which becomes unused.

#figure(
  grid(
    columns: (auto, auto),
    align: center + horizon,
    gutter: 2pt,
    grid(
      align: top,
      columns: 2,
      inset: 3pt,
      grid.cell(colspan: 2, results.result_table([379245])),
      results.arc_flows_table([Flows for $l=3$], csv("data/capacited/flows_3.csv")),
      results.arc_flows_table([Flows for $l=11$], csv("data/capacited/flows_11.csv")),
      grid.cell(colspan: 2, results.new_caps_table([Maximum Capacities ($Y_a$)], csv("data/capacited/caps.csv"))),
    ),
    raw-render(raw(read("graphs/constrained.dot")), engine: "neato", width: 100%)
),
  caption: flex-caption(
    [Results of the Capacited Problem. Links affected by caps are represented by dashed edges in the graph and orange rows in the flow tables. Unused links are greyed in the graph and not included in the flow tables.],
    [Results of the capacited model.]
  ),
  supplement: "Summary",
  kind: "Summary"
) <summary:constrained>

For both #ref(<eq:p>, supplement: none) and #ref(<eq:uc>, supplement: none), the AMPL formulations and parameters are provided in `base.mod` and `base.dat` respectively. Separate runners are provided in `capacited.run` and `unconstrained.run`. The added caps are listed in `caps.dat`, while flows are listed in `total_flows.csv` (total flows) and `flows.csv` (segregated by origin) in the corresponding folder (`capacited` or `unconstrained`).

= Cutting Plane <sec:cut>

Now, the same problem will be solved using the Dantzig's Cutting Plane Algorithm. The problem that we will approximate is the following:

#labeled(
  $
    attach(limits(text("Min")), b: (z, mu))  quad quad & z & \
    text("s.t.") quad quad & z lt.eq sum_(a in A \ l in O) C_a x_a^l - mu sum_(a in A)(Y_a - sum_(l in O) x_a^l) quad  & forall x in X \
    & mu gt.eq 0 
  $,
  [($P_infinity$)]
)

Where $X = {x in bb(R)_+^(|A|times|O|) | sum_((i,j) in A) x_(i j)^l - sum_((j,i) in A) x_(j i)^l = T_i^l thick forall i in N, forall l in O }$.

The algorithm requires an initial feasible solution. To obtain such solution, we add an artificial point to $N$, namely node $0$, and connect it to every origin and every destination.
This means adding a total of $|O| + |D|$ arcs to the problem, and a total of $|O| + |O|times|D|$ (flows of origins to fake node and of fake node to destinations).
Then, the initial feasible solution is such that all previously existing arcs are unused, and all the flow goes through the new artificial arcs. Therefore, the initial solution is:
$
  x_0 = [
    overbrace(bb(0)^(|A|times|O|), text("Original arcs")),
    overbrace([T_l^l comma l in O], text("Origins to Fake")), 
    overbrace([-T_i^l comma i in N, l in O], text("Fake to Destinations"))
  ]
$

From this point on, variables $x$ without subindices or with one subindex refer to this kind of vector variables, while variables $x_i^l$ with a subindex and superindex refer to its elements.

The cost for these new artificial arcs (their $C_a$) is a value large enough so that using any combination of real arcs is cheaper (Big-M method), so that if the optimal solution obtained uses any of these arcs would mean that no feasible solution exists in the original problem.

With that initial point $x_0$, we then proceed to solve our Master Problem and SubProblem iteratively until the difference between their objective functions is lower than a given tolerance $epsilon$ (set to $1e^(-6)$).
The Master Problem formulation is as follows:

#labeled(
  $
    limits(text("Max"))_((z, mu))  quad quad & z & \
    text("s.t.") quad quad & z lt.eq sum_(a in A \ l in O) C_a x_a^l - mu sum_(a in A)(Y_a - sum_(l in O) x_a^l) quad  & forall x in {x_0, dots, x_k} \
    & mu gt.eq 0 
  $,
  [($M P$)]
) <eq:mp>

Where ${x_0, dots, x_k}$ is the set of existing cuts. The SubProblem is defined as follows:

#labeled(
  $
    limits(text("Min"))_((x))  quad quad & sum_(a in A \ l in O) C_a x_a^l - mu sum_(a in A)(Y_a - sum_(l in O) x_a^l) & \
    text("s.t.") quad quad & x in X \
  $,
  [($S P$)]
) <eq:sp>

At each iteration $k$ we start solving #ref(<eq:mp>, supplement: none), which yields a vector of dual variables $mu_k$. These are used as parameters to solve #ref(<eq:sp>, supplement: none) which, in turn, yields a new vector $x_k$, which gets added to the cut set.

This process is repeated until the termination criteria is met (i.e. the difference falls below the accepted tolerance $epsilon$). Once finished, the last solution $x$ obtained is not guaranteed to be the optimum solution for #ref(<eq:p>, supplement: none), it is not even guaranteed to be feasible. To obtain the actual optimum solution we must solve the corresponding Generalized Linear Problem (where $alpha_j$ are the dual variables of cut number $j$) :

#labeled(
  $
    mat(
      z_k = limits(text("Min"))_((alpha))  quad quad & sum_(j eq 0)^k alpha_j f(hat(x)_j) & ;
    text("s.t.") quad quad & sum_(j eq 0)^k alpha_j g(hat(x)_j) gt.eq 0 ;
    & sum_(j eq 0)^k alpha_j h(hat(x)_j) eq 0 ;
    & sum_(j eq 0)^k alpha_j eq 1 ;
    & alpha_j gt.eq 0 &  j = 1 comma dots comma k quad quad;
    delim: #(none, "}"),
  ) quad arrow.long quad tilde(x) eq sum_(j eq 0)^k alpha^* hat(x)_j
  $,
  [($G L P$)]
) <eq:glp>


The AMPL implementation, parameters, and runner for both problems is provided in `cutting_plane.mod`, `cutting_plane.dat`, `cutting_plane.run` respectively, with the maximum capacities again in `caps.dat`.

Running our implementation with Scenario 19, we reach the stopping criteria in 17 iterations.
Progress of the Master Problem and SubProblem costs ($z$ and $w$ respectively), their gap, the cost of the flow assignation and whether it is feasible or not is shown in @table:results:cutting.

#{
  show figure: set block(breakable: true)  
  [
    #figure(
      results.iterations_table(csv("data/cutting_plane/iterations.csv"), 25%),
      caption: flex-caption(
        [Evolution of $z$, $w$, Absolute Gap, Cost, and Feasibility (Feas) through the iterations of the Cutting Plane Algorithm.], 
        [Cutting Plane iterations]
      )
    ) <table:results:cutting>
  ] 
}

Note how of all the points generated through the iterations, only 2 are feasible, but neither is guaranteed to be the optimal solution. To get it, we will compute an approximation using the dual variables obtained from each cut in the right-hand-side equation in #ref(<eq:glp>, supplement: none). The final solution is shown in @summary:cutting, showing also said dual variables. Note that all of them are positive, and their sum is 1.

Note that while the cost of the final solution equals the one obtained by solving the #ref(<eq:p>, supplement: none) directly (@summary:constrained), the actual solution differs slightly. For example, arc $(20 arrow 23)$ is used by both origins in the direct solution, but only by origin 3 in the cutting plane one.

#figure(
  grid(
    columns: (auto, auto),
    align: center + horizon,
    gutter: 2pt,
    grid(
      align: top,
      columns: 2,
      inset: 3pt,
      grid.cell(colspan: 2, results.result_iters_table([379245], [17])),
      results.arc_flows_table([Flows for $l=3$], csv("data/cutting_plane/flows_3.csv")),
      results.arc_flows_table([Flows for $l=11$], csv("data/cutting_plane/flows_11.csv")),
      grid.cell(colspan: 2, results.new_caps_table([Maximum Capacities ($Y_a$)], csv("data/cutting_plane/caps.csv"))),
    ),
    grid( 
     gutter: 2em,
      align: center + horizon,
      raw-render(raw(read("graphs/cutting.dot")), engine: "neato", width: 100%),
      results.dual_table(csv("data/cutting_plane/duals.csv"))
    )
),
  caption: flex-caption(
    [Results of the Cutting Plane. Links affected by caps are represented by dashed edges in the graph and orange rows in the flow tables. Unused links are greyed in the graph and not included in the flow tables.],
    [Results of the Cutting Plane.]
  ),
  supplement: "Summary",
  kind: "Summary"
) <summary:cutting>

All data from the iterations table is provided in `iterations.csv`, while the flows are provided as in the basic version (`total_flows.csv` and `flows.csv`), all in the `cutting_plane` folder.

== Generalized Linear Problem

Now, instead of computing an approximation using the dual variables from the cuts,  we will compute it solving the corresponding Generalized Linear Problem #ref(<eq:glp>, supplement: none) to obtain the optimal dual variables.
The AMPL implementation of the code is provided in `dual.mod`, `dual.dat`, and `dual.run` (although it also uses `caps.dat` and `cutting_plane.dat` to read the scenario data).

The cost of the solution obtained for the #ref(<eq:glp>, supplement: none) is 379245. Due to space limitations, a summary of the solution to the primal problem generated from the solution of the #ref(<eq:glp>, supplement: none) is not shown, but it is identical to the one obtained by the Cutting Plane Algorithm (@summary:cutting), with the same objective cost of $379245$ (the list of total flows is provided in `total_flows_dual.csv`). However, the obtained $alpha^*$ do differ from the ones used before (see @table:results:duals), although they are still all positive and adding up to 1.

#figure(
  grid(
    columns: 2,
    inset: (x: 2em, y: 10pt),
    results.dual_table(csv("data/cutting_plane/duals.csv"), title: "Dual Variables (CP)"),
    results.dual_table(csv("data/dual/duals.csv"), title: "Dual Variables (GLP)"),
  ),
  caption: flex-caption([Comparison between the dual variables obtained through the Cutting Plane Algorithm (left) and those obtained solving the Generalized Linear Problem (right)],[Comparison between dual variables])
) <table:results:duals>


== Variants

To try and improve the convergence rate of the Cutting Plane Algorithm, we are going to explore two variants in which instead of passing directly the dual variables $mu_k$ from the Master Problem to the SubProblem, we apply some smoothing to it:

$
  mu_(k+1) eq hat(mu)_k + a^k (mu_k - hat(mu)_k)
$
Where $hat(mu)_k$ are the dual variables obtained as a result of the Master Problem at iteration $k$, and $mu_k$ are the values that will be passed to the subproblem at iteration k. 
The two variants differ in how $a^k$ is computed:
$
    text("1)") quad  a^k &eq 1 / (k + 1) quad quad quad quad quad
    text("2)") quad  a^k &eq k^2 / (sum_(i=1)^k i^2)\
$

While they both obtain an equivalent optimal solution, with the same objective cost of 379425, the number of iterations for both variants is larger than using the basic version (from 17 to 25 for the Variant 1 and 32 for Variant 2).
The evolution of the values at each iteration is shown in @table:results:variant:1 for Variant 1 and in @table:results:variant:2 for Variant 2.

Due to size limitations, the summaries of the obtained solutions are not shown here, but are provided as in the basic version in the folders `variant_1` and `variant_2`.

Note how, while during the first 9 iterations the gap evolution is similar in all three cases, in the basic version starts rapidly decreasing (although not consistently, it increases at iteration 15), while for the two variants it is much more steady and consistent, although also much slower.

#{
  show figure: set block(breakable: true)  
  [
    #figure(
      results.iterations_table(csv("data/variant_1/iterations.csv"), 36%),
      caption: flex-caption(
        [Evolution of $z$, $w$, Absolute Gap, Cost, and Feasibility (Feas) through the iterations of the Cutting Plane Algorithm with 1st Variant.], 
        [Cutting Plane iterations (Variant 1)]
      )
    ) <table:results:variant:1>
  ] 
}

#{
  show figure: set block(breakable: true)  
  [
    #figure(
      results.iterations_table(csv("data/variant_2/iterations.csv"), 44%),
      caption: flex-caption(
        [Evolution of $z$, $w$, Absolute Gap, Cost, and Feasibility (Feas) through the iterations of the Cutting Plane Algorithm with 2nd Variant.], 
        [Cutting Plane iterations (Variant 2)]
      )
    ) <table:results:variant:2>
  ] 
}


= Conclusions

In this report we have solved a scenario of the Multi-Commodity Network Design Problem using two different methods: solving directly the classical LP formulation and using the Dantzig's Cutting Plane Algorithm. 

Moreover, the corresponding Generalized Linear Problem has also been solved to find the optimal solution for the primal problem, and two variants of the Cutting Plane algorithm have been implemented and compared with the basic version.

Experimental results show that all 5 methods tried an optimal solution, although the actual flows within each solution differ from each other. 