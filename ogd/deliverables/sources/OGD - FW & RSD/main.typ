#import "template.typ": *
#import "tables.typ": * 
#import "plots.typ": * 
#import "network.typ" as network; 
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
  title: [Frank Wolfe & RSD Algorithms],
  subject: "Large-Scale Optimization",
  authors: ("Víctor Diví i Cuesta", ),
  outlines: (
    (
      title: "List of Figures",
      target: "plot"
    ),
    (
      title: "List of Tables",
      target: table
    ),
    (
      title: "List of Summaries",
      target: "Summary"
    ),
  ),
  use-codly: false
)
#show raw.where(lang: "ampl"): set raw(block: true, syntaxes: "fonts/ampl.sublime-syntax")

= Introduction

In this assignment, we will solve a Traffic Assignment Problem (TAP), also known as Network Equilibrium Problem, in which we aim to obtain an equilibrium state assigning the flow that must go from every origin to its destinations to the best possible path.

In this Section, the problem and scenario at hand are introduced. In @sec:base, the base formulation of the equilibrium problem is solved directly. In Sections #ref(<sec:fw>, supplement: none) and #ref(<sec:rsd>, supplement: none), the same problem is solved using the Frank Wolfe (FW) algorithm and the Restricted Simplicial Decomposition (RSD) algorithm, respectively. Then, in @sec:wardrop an analysis of the Wardrop Equilibrium of the solutions is presented. Finally, in @sec:conc, a small summary is provided as conclusion.

== Problem

The equilibrium problem at hand can be formulated in several ways. Here we will use the origin-based formulation, obtaining the following non-linear optimization problem in scalar notation:

#labeled(
  $
  text("Min")  quad quad & sum_(a in A) integral_0^(x_a)S_a (x) d x & \
  text("s.t.") quad quad & sum_((i,j) in A) x_(i j)^l - sum_((j,i) in A) x_(j i)^l = T_i^l quad quad & forall i in N, forall l in O \
  & sum_(l in O) x_a^l eq x_a & forall a in A \
  & x_a^l gt.eq 0 & forall a in A, forall l in O \
$,
[(TAP)]
) <eq:tap>

Where given an arc $a$, an origin $l$ and a node $i$, $x_a^l$ is the flow at $a$ from $l$, $x_a$ os the total flow at $a$, $S_a$ is the link-cost function of $a$, and $T_i^l$ is the net output flow at $i$ for flow from $l$.

Here, the link-cost function are linear volume-delay functions:

$
S_a (x) &= C_a + d x & quad quad forall a in A
$

In which $C_a >= 0$ is the base link cost and $d >= 0$ is a fixed constant. The problem can be expressed as an optimization problem because $S_a$ are all non-negative, non-decreasing and continuous.

== Scenario

The data used in this report is from Scenario 19, with:

$ 
N &= {1, dots, 24}\
O &= {3, 11} \
D &= {5, 8, 12, 13, 14, 17, 18, 19, 21, 23} \
C_(i j) &= 95 + (x_i - x_j)^2 + 8(y_i - y_j)^2 quad &quad& forall (i, j) in A \
T_i^l &= mat(
  500K\,  &,, &text("if") i eq l;
  -50K\,  &,, &text("if") i in D;
  0\,    &,, &text("otherwise");
  delim: #("{", none),
) && forall i in N, forall l in O \
d &= 0.0035 \
K &= 200
$
To appreciate the difference in performance of the different algorithms, we multiply the flows for each OD pair by a factor $K$ (here set at 200), so the resulting network is significantly congested. The values for all these parameters is provided in the `net.dat` file.


= Base Formulation <sec:base>

We start solving the problem by solving directly the base formulation #ref(<eq:tap>, supplement: none), which will serve as the goal solution to achieve by the FW and RSD algorithms.

The AMPL code for the model is provided in `base.mod` and `base.run` for the model definition and the runner script respectively.

The obtained solution has a total cost of 101181657, and the detailed flows are presented in @summary:base, along with a visualization of the resulting assignation on the network. On the tables on the left, we can see, for each used arc, the amount of flow they carry from each origin. On the right, we can see the resulting assignation on the network.

#figure(
  grid(
    columns: (auto, auto),
    align: center,
    gutter: 2pt,
    grid(
      columns: 2,
      rows: 2,
      inset: 3pt,
      grid.cell(colspan: 2, 
        table(
          columns: 2, 
          strong([Total Cost]), 
          text([101181657], font: "JetBrains Mono", size: 0.9em),
        )
      ),
      network.arc_flow_table([Flows for $l=3$], csv("data/results/base_3.csv")),
      network.arc_flow_table([Flows for $l=11$], csv("data/results/base_11.csv")),
    ),
    raw-render(raw(read("graphs/base.dot")), engine: "neato", width: 100%)
),
  caption: flex-caption(
    [Results of the base model. Origin nodes have a colored double border, while destination nodes are filled with the origin color. Used links are painted with the color of the origin whose flow they carry (purple for both), while unused links are greyed. Exact flows are shown in flow tables.],
    [Results of the base model.]
  ),
  supplement: "Summary",
  kind: "Summary"
) <summary:base>


#pagebreak()
= Frank Wolfe Algorithm <sec:fw>

Now, we will solve the same problem using the Frank Wolfe Algorithm. The algorithm follows these steps:


+ Start with a feasible solution $x^0$.
+ Repeat until a stopping criteria is met (at each iteration k):
  + Solve linear approximation of the problem to obtain new point $hat(x)^k$.
  + Compute the descent direction: $d^k = hat(x)^k - x^k$.
  + Calculate the optimal step size $alpha^k$ minimizing the objective function.
  + Update the solution: $x^(k+1) = x^k + alpha^k hat(x)^k$.

In our case, the linear approximation of the #ref(<eq:tap>, supplement: none) is the following:

#labeled(
  $
  text("Min")  quad quad & sum_(a in A) x_a (C_a + d x^k) & \
  text("s.t.") quad quad & sum_((i,j) in A) x_(i j)^l - sum_((j,i) in A) x_(j i)^l = T_i^l quad quad & forall i in N, forall l in O \
  & sum_(l in O) x_a^l eq x_a & forall a in A \
  & x_a^l gt.eq 0 & forall a in A, forall l in O \
$,
[(LTAP)]
) <eq:ltap>

An we stop the algorithm when we reach 500 iterations or a relative gap lower than $epsilon$ (set to $5e^(-4)$), computed as follows:
$

"gap" = (-sum_(a in A) S_a (x^k)(hat(x)^k - x^k))/(sum_(a in A) S_a (x^k) x^k)

$

Moreover, due to the nature of the link-cost functions, we can compute the optimal $alpha^k$ analytically as the following expression:

$

alpha^k = min(1,  (-sum_(a in A) S_a (x^k)(hat(x)^k - x^k)) / (d sum_(a in A) (hat(x)^k - x^k)^2))

$

The full AMPL model and runner script is provided  in the `fw.mod` and `fw.run` files respectively.

After a total of 112 iterations, the result obtained has a total cost of 101218966, which is 37309 higher than the optimal cost (101181657) obtained with the base formulation (see @sec:base). This gap is within acceptable limits, since in relative terms it is a gap of $3.68e^(-4)$, which is lower than the accepted tolerance $epsilon = 5e^(-4)$ (note, however, that this is not the gap that was used to stop the algorithm).

The obtained flows can be seen in @summary:fw, both listed on the flow tables on the left, as well as visualized in the network on the right.
As can be observed, the generated flows differ slightly (as expected) from the optimal solution generated before.
For example, there is a cycle in the flow of origin 3 between nodes 9 and 10 that doesn't exist in the previous solution.
Arcs ($9 arrow 10$) and ($10 arrow 9$) both carry very little flow and only increase the overall cost without contributing anything, so most probably this cycle would be removed in subsequent iterations.
For origin 11, the values of the flows vary slightly, but the used arcs are the same as in the optimal solution.

#figure(
  grid(
    columns: (auto, auto),
    align: center,
    gutter: 2pt,
    grid(
      columns: 2,
      rows: 2,
      inset: 3pt,
      grid.cell(colspan: 2, 
        network.result_comparison_table(
          [101218966],
          [101181657],
          [37309],
          [3.68e-4],
          [112],
        )
      ),
      network.arc_flow_table([Flows for $l=3$], csv("data/results/fw_3.csv")),
      network.arc_flow_table([Flows for $l=11$], csv("data/results/fw_11.csv")),
    ),
    align(center + horizon, 
      raw-render(raw(read("graphs/fw.dot")), engine: "neato", width: 100%)
    )
),
  caption: flex-caption(
    [Results of the FW algorithm. Origin nodes have a colored double border, while destination nodes are filled with the origin color. Used links are painted with the color of the origin whose flow they carry (purple for both), while unused links are greyed. Exact flows are shown in flow tables.],
    [Results of the FW algorithm.]
  ),
  supplement: "Summary",
  kind: "Summary"
) <summary:fw>


@table:fw shows the evolution of the objective function value (Obj. Fun.), the relative gap (Rel. Gap), and the step length (Step ($alpha$)) over the iterations (I) of the execution.

As can be seen, the objective function constantly decreases, although slowly, while the relative gap has some fluctuation, although always keeps a descending tendency. The step length ($alpha$) is always comprised between $6e^(-1)$ and $2e^(-3)$, and fluctuates heavily over the iterations, although in general, it gets smaller as the algorithm progresses.


#{
  show figure: set block(breakable: true)  
  [
    #figure(
      fw_results_table("data/iterations/fw.csv", 135%),
      caption: [Iteration values of the FW algorithm execution.],
      kind: "plot",
      supplement: "Figure",
    ) <table:fw>
  ]
}

The evolution of the Objective Function and the Relative Gap can be better observed in Figures #ref(<plot:fw:of>, supplement: none) and #ref(<plot:fw:gap>, supplement: none) respectively.

#figure(
  plot_log((13, 6), csv("data/iterations/fw.csv"), 0, 1, "Iteration", "log(OF)"),
  caption: [Evolution of the Objective Function (log) over the FW algorithm execution.]
) <plot:fw:of>

 As mentioned before, the value of the objective function has a constant decreasing behavior, while the gap is much more chaotic and fluctuates constantly, although the overall tendency is still decreasing.

 It is important to not how both values decrease significantly fast on the first iterations (\~15), and then stagnates and progresses very slowly until reaching the accepted gap.

#figure(
    plot_log((13, 6), csv("data/iterations/fw.csv"), 0, 2, "Iteration", "log(Gap)"),
    caption: [Evolution of the Relative Gap (log) over the FW algorithm execution.],
    kind: "plot",
    supplement: "Figure",
) <plot:fw:gap>


= RSD Algorithm <sec:rsd>

Now, we will solve the problem with the Restricted Simplicial Decomposition Algorithm, an extension of the FW algorithm used in the previous Section. 

The RSD algorithm consists of these steps:

+ Initialize:
  - Initial feasible point $x^0$.
  - Lower Bound $B L B = -infinity$.
  - Working Sets $W_x^0 eq {x^0}$ and $W_s^0 eq emptyset$.
+ Repeat while finishing criteria is not met (at iteration k):
  + Solve linear approximation of the problem to obtain new point $hat(x)^k$.
  + Update Working Sets:
    - If $|W_s^k| < rho$, then $W_s^(k+1) = W_s^k + {hat(x)^k}$ and $W_x^(k+1) = W_x^k$.
    - Otherwise, let $tilde(x)$ be the element in $W_s^k$ for which $x^k$ has the smaller barycentric coordinate, $W_s^(k+1) = W_s^k - {tilde(x)} + {hat(x)^k}$ and $W_x^(k+1) = {x^k}$ .
  + Obtain new point $x^(k+1)$ within the convex hull of $W_s^k union W_x^k$ that minimizes the objective function.
  + Purge elements from working sets for which $x^(k+1)$ has null barycentric coordinates.

Step 1 of the loop is the same as in the FW algorithm, and is preformed solving the same optimization problem #ref(<eq:ltap>, supplement: none), called the SubProblem in this algorithm. For step 3, we solve the so-called Master Problem, which for the problem at hand has the following formulation:

#labeled(
  $
  text("Min")  quad quad & sum_(a in A) (C_a x_a + 0.5d x_a^2 ) & \
  text("s.t.") quad quad & sum_(i = 1)^(|W|) alpha^i eq 1 &  \
  & sum_(i = 1)^(|W|) alpha^i W_a^i eq x_a & forall a in A \
  & x_a gt.eq 0 & forall a in A \
  & alpha^i gt.eq 0 & i eq 1, dots, |W| \
$,
[(MP)]
) <eq:mp>

Where the $alpha$ variables are the barycentric coordinates used in steps 2 and 4 of the loop. To avoid precision errors, the purging of the working sets has been performed with a tolerance of $1e^(-8)$ (i.e. if the its corresponding barycentric coordinate is lower than $1e^(-8)$, the vertex is purged).

The solution obtained required 22 iterations (against the 112 of the FW), and has a total cost of 101192206, only 10549 higher than the optimal solution found in @sec:base (and 26760 lower than the FW solution), which corresponds to a relative gap of $1.04e^(-4)$.

The solution can be seen in @summary:rsd. Due to the fact that #ref(<eq:mp>, supplement: none) deals with the aggregated flows, only the aggregated arc flows are shown, instead of the segregated ones as in the previous sections. In the network, black arcs represent links carrying flow whose origin is not known for certain (may be only one or both).

#{show figure: set block(breakable: true);  [
  #figure(
    grid(
      columns: (auto, auto),
      align: center,
      gutter: 2pt,
      grid(
        columns: 2,
        rows: 2,
        inset: 3pt,
        grid.cell(colspan: 2, 
          network.result_comparison_table(
            [101192206],
            [101181657],
            [10549],
            [1.04e-4],
            [22],
          )
        ),
        block(
          breakable: true,
          height: 55%,
          columns(
            2,
            network.arc_flow_table([General Flows], csv("data/results/rsd.csv"))
          )
        ),
      ),
      align(center + horizon, 
        raw-render(raw(read("graphs/rsd.dot")), engine: "neato", width: 100%)
      )
  ),
    caption: flex-caption(
      [Results of the RSD algorithm. Origin nodes have a colored double border, while destination nodes are filled with the origin color. Used links are painted with the color of the origin whose flow they carry (purple for both, black for unknown), while unused links are greyed. Exact flows are shown in flow tables.],
      [Results of the RSD algorithm.]
    ),
    supplement: "Summary",
    kind: "Summary"
  ) <summary:rsd>
]}

@table:rsd shows the evolution of the objective function (Obj. Fun.), relative gap (Rel. Gap), number of vertices used (\#V), and the barycentric coordinates ($alpha_0$ to  $alpha_4$) through the iterations (I) of the RSD algorithm execution.

In the AMPL model implemented, the working set $W$ for the Master Problem is a static set of 5 points with a bit matrix indicating which points are being used. Thus, we see in the table gaps in the barycentric coordinates such as for iteration 8, in which there are no $alpha_2$ nor $alpha_3$ but $alpha_4$ does exist.

#figure(
  rsd_results_table("data/iterations/rsd.csv", 135%),
  caption: [Iteration values of the RSD algorithm execution.]
) <table:rsd>

A more clear view of the evolution of the objective function and the relative gap can be seen Figures #ref(<plot:rsd:of>, supplement: none) and #ref(<plot:rsd:gap>, supplement: none). As in the FW algorithm the objective functions decreases very steeply at the beginning (until iteration 4), and much slower afterwards. The behavior of the relative gap is also similar, having slight fluctuations, although not as pronounced as before (also probably due to the reduced number of iterations in the plot).

#figure(
  plot_log((13, 5.5), csv("data/iterations/rsd.csv"), 0, 1, "Iteration", "log(OF)"),
  caption: [Evolution of the Objective Function (log) over the RSD algorithm execution.],
  kind: "plot",
  supplement: "Figure",
) <plot:rsd:of>


#figure(
    plot_log((13, 5.5), csv("data/iterations/rsd.csv"), 0, 2, "Iteration", "log(Gap)"),
  caption: [Evolution of the Relative Gap (log) over the RSD algorithm execution.],
  kind: "plot",
  supplement: "Figure",
) <plot:rsd:gap>


@plot:rsd:comparison shows the evolution of the objective function for both the FW and the RSD algorithms, and we can clearly see the drastic difference in performance between the two algorithms for the problem solved.

#figure(
  cetz.canvas({
    let fw_data = csv("data/iterations/fw.csv")
    let fw_x = fw_data.map(x => int(x.at(0)))
    let fw_y = fw_data.map(x => calc.log(float(x.at(1))))
    
    let rsd_data = csv("data/iterations/rsd.csv")
    let rsd_x = rsd_data.map(x => int(x.at(0)))
    let rsd_y = rsd_data.map(x => calc.log(float(x.at(1))))

    plot.plot(
      size: (13, 5.5),
      legend: (10.5, 5),
      y-label: "log(OF)",
      y-break: true,
      y-decimals: 4,
      x-label: "Iteration",
      {
        plot.add(label:"FW", fw_x.zip(fw_y))
        plot.add(label:"RSD", rsd_x.zip(rsd_y))
      }
    )
  }),
  caption: flex-caption(
      [Comparison between the Objective Function (log) over the FW and RSD algorithms executions.],
      [Objective Function comparison between FW and RSD algorithms..]
    ),
  kind: "plot",
  supplement: "Figure",
) <plot:rsd:comparison>

= Wardrop Equilibrium <sec:wardrop>

A traffic network reaches Wardrop Equilibrium if changing the path of any single flow unit (traveler, vehicle, etc.) only increases its travel time.

While the solutions found with both FW and RSD algorithms may be close to Wardrop Equilibrium, it is clear the FW one is not: it contains cycles (see arcs ($9 arrow 10$) and ($10 arrow 9$)) that could be removed to decrease the overall cost of the solution. However, the solution found with the base formulation in @sec:base should be in Wardrop Equilibrium.

We will perform a partial check on the optimal solution and analyze several paths to see if they are optimal paths for their OD pairs and whether they are used. In particular, for each OD pair in our scenario, @table:wardrop shows two possible paths, their cost, and whether they are used in the optimal solution found (see @summary:base).

As can be seen, for all the OD pairs, the paths selected either have the same cost and are both used in the solution, or they have different cost and the more expensive one is not used (it also happens to happen that the cheaper one is used, but it is because in all cases, it happens to be the optimal one).


#{show figure: set block(breakable: true);  [
#figure(
  {
    let cells = csv("data/results/paths.csv").flatten()
    cells = cells.map(x => if x == "true" {"✅"} else if x == "false" {"❌"} else {x})

    show table.cell.where(y: 0): strong
    show table.cell : c => {
    if c.y == 0 {return text(0.8em, c)}
    else {return text(0.7em, font: "JetBrains Mono", c)}
  }
      table(
        columns: 5,
        row-gutter: (3pt, ..(auto, 2pt) * 20),
        table.header(
          [O],
          [D],
          [Path],
          [Cost],
          [Used],
        ),
        ..cells
  )
  },
  caption: [Path analysis for Wardrop Equilibrium Check on Optimal Assignment.]
) <table:wardrop>
]}

The script to get the costs of all the paths is provided in `paths.run` #footnote[Which has been generated with a Python script from a series of manually created paths, also provided in `paths.py` ].

A quick show that the FW solution doesn't have Wardrop Equilibrium is that the paths chosen for the OD pair (3, 13) have much different cost, and are still both used (see @summary:fw):

#figure(
  {
    let cells = csv("data/results/paths_fw.csv").flatten()
    cells = cells.map(x => if x == "true" {"✅"} else if x == "false" {"❌"} else {x})

    show table.cell.where(y: 0): strong
    show table.cell : c => {
    if c.y == 0 {return text(0.8em, c)}
    else {return text(0.7em, font: "JetBrains Mono", c)}
  }
      table(
        columns: 5,
        row-gutter: (3pt, ..(auto, 2pt) * 20),
        table.header(
          [O],
          [D],
          [Path],
          [Cost],
          [Used],
        ),
        ..cells
  )
  },
  caption: [FW Wardrop Equilibrium Check.]
) <table:wardrop:fw>

= Conclusions <sec:conc>

In this report we have solved a scenario of a Traffic Assignment Problem using three different methods: solving directly non-linear optimization formulation, using the Frank Wolfe Algorithm (FW), and using the Restricted Simplicial Decomposition Algorithm (RSD).

Experimental results show that the RSD is significantly more efficient than the FW, and reaches a better solution in a fraction of the iterations. However, none of the algorithms provide a solution for the problem that satisfy the Wardrop Equilibrium, which the non-linear optimization problem does. This is checked by performing a path analysis between all the OD pairs in the scenario.
