#import "config.typ"
#import "network.typ"
#show: config.global_config

#import "@preview/diagraph:0.3.3": *
#import "@preview/equate:0.3.1": equate

#show: equate.with(breakable: true, sub-numbering: false, number-mode: "label")
#set math.equation(numbering: "(A)")

#include "title.typ"

#let in-outline = state("in-outline", false)
#let flex-caption(long, short) = context if in-outline.get() { short } else { long }
#show outline: it => {
  in-outline.update(true)
  it
  in-outline.update(false)
}

#outline()
#outline(title: [List of Codes], target: figure.where(kind: "Code"))
#outline(title: [List of Tables], target: figure.where(kind: table))
#outline(title: [List of Summaries], target: figure.where(kind: "Summary"))

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

== Problem

In the Network Design Problem at hand, we initially have a network configuration given by $G' eq (N, A')$, with the possibility to extend it taking candidate links from a set $hat(A)$, so that the final network may become $G eq (N, A)$ with $A eq A' union hat(A)'$. Within the network, we have to distribute a certain amount of flow from a set of origin nodes $O subset.eq N$ to a set of destination nodes $D subset.eq N$. Each destination $d in D$ requires a fixed amount of flow from each origin $l in O$. Links between nodes have infinite capacity.

The problem is identifying the suitable subset $hat(A)' subset.eq hat(A)$ so that adding them to the network minimizes the total cost, which is made up by two components:

+ Investment cost: fixed cost for adding a new link from $hat(A)$ to the network.
  $ F_(i j), forall (i,j) in hat(A) $
+ Exploitation cost: origin-dependent cost per unit of flow crossing a link in the network.
  $ C_(i j)^l, forall (i,j) in A, forall l in O $

Let $g_d^l$ be the demand required by node $d in D$ from node $l in O$, we define $T_i^l$ as:
$ T_i^l = mat(
  sum_(d in D) g_d^l\,  &,, &text("if") i eq l;
  -g_i^l\,  &,, &text("if") i in D;
  0\,    &,, &text("otherwise");
  delim: #("{", none),
) quad quad forall i in N, forall l in O $

Then, with variables $x_(i j)^l$ representing the flow from origin $l in O$ crossing arc $(i,j) in A union hat(A)$ and $y_(i j)$ representing whether or not arc $(i,j) in hat(A)$ is built, we have the following problem:
$
  text("Min")  quad quad & sum_(a in hat(A)) F_a y_a + sum_(l in O) sum_(a in A) C_a^l x_a^l & \
  text("s.t.") quad quad & sum_((i,j) in A) x_(i j)^l - sum_((j,i) in A) x_(j i)^l = T_i^l quad quad & forall i in N, forall l in O \
  & x_a^l lt.eq rho y_a & forall a in hat(A), forall l in O \
  & x_a^l gt.eq 0 & forall a in A, forall l in O \
  & y_a in {0, 1} & forall a in hat(A)
$

Constant $rho$ must be big enough so that it doesn't interfere with the arc flows ($rho > sum_(l in O) T_l^l$).

To solve the problem using Benders' Decomposition, we won't solve the problem directly, but rather iteratively solve a #raw("Master Problem") and a #raw("SubProblem") until the values of both converge. For a fixed solution $macron(y)$ for variables $y$, the structure of the #raw("SubProblem") is as follows:

$
  text("Min")  quad quad & sum_(a in hat(A)) F_a macron(y)_a + sum_(l in O) sum_(a in A) C_a^l x_a^l & \
  text("s.t.") quad quad & sum_((i,j) in A) x_(i j)^l - sum_((j,i) in A) x_(j i)^l = T_i^l quad quad & forall i in N, forall l in O #<eq:m1>\
  & x_a^l lt.eq rho y_a & forall a in hat(A), forall l in O #<eq:m2>\
  & x_a^l gt.eq 0 & forall a in A, forall l in O #<eq:m3>\
$

Meanwhile, at iteration M of the algorithm, the #raw("Master Problem") has the following structure:

$
  text("Min")  quad quad & sum_(a in hat(A)) F_a y_a + z & \
  text("s.t.") quad quad & z gt.eq sum_(l in O) (sum_(i in N) T_i^l U_i^l^k - rho sum_(a in hat(a)\ macron(y)_a^k eq 1) hat(tau)_a^l^k y_a) quad&& forall k = 1, dots, M \
  &y_a in {0, 1} && forall a in hat(A)
$

Where $macron(y)^k$ is the value of $macron(y)$ at iteration $k$, and $U^k$ and $hat(tau)^k$ are the Lagrangian multipliers of (#ref(<eq:m1>, supplement: none)) and (#ref(<eq:m2>, supplement: none)) respectively at iteration $k$, with $U^k$ being equal to the dual variables of (#ref(<eq:m1>, supplement: none)) and $tau^k$ is computed as follows (skipping super-index $k$ for $tau$ and $U$):
$
  tau_(i j)^l = max(0, U_i^l - U_j^l - C_(i j)^l) quad forall (i j) in hat(A)
$

Note that the formulation used in this report is slightly different (although equivalent) than the one presented in the questionnaire. Apart from notation changes done to be closer to the implementation, the main big changes are:

- #raw("SubProblem") cost includes investment cost of $macron(y)$, so $z_D$ is the objective value of the #raw("SubProblem"), instead of being the fixed cost plus the value of the #raw("SubProblem").
- Investment cost in the #raw("Master Problem") is moved from each cut to the objective function, since it depends in the current value of $y$ and therefore equal in all cuts.

== Scenario

The scenario used in this report is Scenario 19, with:

$ 
N &= {1, dots, 24}\
O &= {3, 11} \
D &= {5, 8, 12, 13, 14, 17, 18, 19, 21, 23} \
F_(i j) &= 10|x_i - x_j| + 60|y_i - y_j| && forall (i, j) in hat(A) \
C_(i j)^l &= 95 + (x_i - x_j)^2 + 8(y_i - y_j)^2 quad &quad& forall (i, j) in A union hat(A), forall l in O \
T_i^l &= mat(
  500\,  &,, &text("if") i eq l;
  -50\,  &,, &text("if") i in D;
  0\,    &,, &text("otherwise");
  delim: #("{", none),
) && forall i in N, forall l in O
$

The costs for candidate links and the network graph of the scenario can be seen in #ref(<summary:scenario>). 
The origins (${3, 11}$) are represented with colored double-circled nodes, while their corresponding destinations are represented with nodes filled with their color.
In this case, both origins have the same destinations, so all of them are colored with both colors.
Preexisting links are represented with solid edges, while dashed ones represent the candidate links that can be added to the network.

The scenario data in `AMPL` format is provided in the `network_design.dat` file.

#let base_graph = read("graphs/graph.dot")
#figure(
  grid(
    columns: (3fr, 4fr),
    align: center+horizon,
    gutter: 5pt,
    network.arc_costs_table(csv("data/scenario_arcs.csv")),
    raw-render(raw(base_graph), engine: "neato", width: 100%)

),
  caption: flex-caption([Scenario 19. Origins are represented by double-circled nodes, while destinations by filled nodes. Candidate links are represented by dashed edges. Table only shows costs for candidate links.],
  [Scenario 19.]),
  supplement: "Summary",
  kind: "Summary"
) <summary:scenario>

= Extensive Version

The model used to solve the extensive version of the Network Design Problem is shown in #ref(<code:extensive>).
The code is also provided in the `extensive.mod` file, along a small runner script in the `extensive.run` file.

#figure(
  [
    #line(length: 90%)
    #raw(read("code/extensive.mod"), lang: "ampl", block: true)
    #line(length: 90%)
  ],
  caption: [AMPL Code for Extensive model.],
  supplement: "Code",
  kind: "Code",
) <code:extensive>

The results obtained with the execution of the extensive model can be seen in #ref(<summary:extensive>). As can be seen, a total of three candidate links are added with an investment cost ($f^top y$) of 40:

$ hat(A)_1 = {a | a in hat(A), y_a=1} = {(4, 5), (14, 13), (22, 23)} $

The exploitation costs add up to 346200 ($sum_(l in O) sum_(a in A) C_a^l x_a^l$), for a total cost $macron(z)$ of 346240.

The flows of the final solution are listed in the flow tables of #ref(<summary:extensive>), and which links are used can be seen in the visualization of the network, where edges are painted according to the flow they carry from each origin. Candidate links can be identified by dashed edges.

The execution time of the #raw("solve") command is approximately 0.5 seconds, although measurements are not very consistent.

#figure(
  grid(
    columns: (auto, auto),
    align: center,
    gutter: 2pt,
    grid(
      columns: 2,
      rows: 2,
      inset: 3pt,
      grid.cell(colspan: 2, network.result_table([40], [346200], [346240])),
      network.arc_capacity_table([Flows for $l=3$], csv("data/extended_flows_3.csv")),
      network.arc_capacity_table([Flows for $l=11$], csv("data/extended_flows_11.csv")),
    ),
    raw-render(raw(read("graphs/extensive.dot")), engine: "neato", width: 100%)
),
  caption: flex-caption(
    [Results of the extensive model. Candidate links are represented by dashed edges in the graph and green rows in the flow tables. Unused links are greyed in the graph and not included in the flow tables.],
    [Results of the extensive model.]
  ),
  supplement: "Summary",
  kind: "Summary"
) <summary:extensive>

= Benders' Decomposition

For the Benders' Decomposition Algorithm, we start by transforming the original problem into two different problems: the #raw("Master Problem") and the #raw("SubProblem").
The AMPL models for both are shown in #ref(<code:benders-mod>), while the code for the actual Benders' Decomposition is shown in #ref(<code:benders-run>).
The code is also provided in the `benders.mod` and `benders.run` files respectively.

Two scenarios have been executed, one in which we start adding none of the candidate links (Scenario 0: $y_a eq 0, forall a in hat(A)$) and another in which we start adding all of them (Scenario 1: $y_a eq 1, forall a in hat(A)$).
For each scenario, a table describing the evolution of the costs throughout the iterations (#ref(<table:results_0>) and #ref(<table:results_1>)) and a summary showing the final arc flows (#ref(<summary:benders_0>) and #ref(<summary:benders_1>)) are shown. 
 
#figure(
  [
    #line(length: 90%)
    #raw(read("code/benders.mod"), lang: "ampl", block: true)
    #line(length: 90%)
  ],
  caption: [AMPL Code for Benders' Decomposition models.],
  supplement: "Code",
  kind: "Code",
) <code:benders-mod>

#figure(
  [
    #line(length: 90%)
    #raw(read("code/benders.run"), lang: "ampl", block: true)
    #line(length: 90%)
  ],
  caption: [AMPL Code for Benders' Decomposition algorithm.],
  supplement: "Code",
  kind: "Code",
) <code:benders-run>

As can be seen in the tables, both scenarios end with the same objective value as the extensive version and with a similar number of iterations (11 for Scenario 0 and 10 for Scenario 1).

Note that even though both scenarios have the same objective value and the same candidate links are added, the flows in the final configuration all differ from each other. These differences are clear in the visualizations provided in the summaries. For instance, the solution obtained in Scenario 0 using the Benders' Decomposition (#ref(<summary:benders_0>)), there are two arcs ($(13,17)$ and $(14,18)$) that are used for both origins (shown in purple in the visualization), while this doesn't happen for neither of the other scenarios (#ref(<summary:extensive>) and #ref(<summary:benders_1>)).

These differences are shown in detail in Tables #ref(<table:diffs_3>, supplement: none) and #ref(<table:diffs_11>, supplement: none), where the links with differences in their flows and their associated cost are listed. As can be seen, even with the differences in the flows, the resulting costs for these arcs are the same in all solutions. Note that links with the same flow in all solutions are not listed.

The execution time of all the #raw("solve") commands executed add up to approximately 0.1 seconds, although similarly to the extensive model, this measurement is not consistent.

#figure(
  table(
    columns: 5,
    row-gutter: (2.2pt, auto),
    ..([Iteration], [$z_D$], [Investment Cost], [Exploitation Cost], [$macron(z)$]).map(x => strong(x)),
    ..csv("data/benders_0_iterations.csv").flatten()
  ),
  caption: [Evolution of costs for scenario 0.]
) <table:results_0>

#linebreak()

#figure(
  table(
    columns: 5,
    row-gutter: (2.2pt, auto),
    ..([Iteration], [$z_D$], [Investment Cost], [Exploitation Cost], [$macron(z)$]).map(x => strong(x)),
    ..csv("data/benders_1_iterations.csv").flatten()
  ),
  caption: [Evolution of costs for scenario 1.]
) <table:results_1>

#figure(
  grid(
    columns: (auto, auto),
    align: center,
    gutter: 2pt,
    grid(
      columns: 2,
      rows: 2,
      inset: 3pt,
      grid.cell(colspan: 2, network.result_table([40], [346200], [346240])),
      network.arc_capacity_table([Flows for $l=3$], csv("data/benders_0_flows_3.csv")),
      network.arc_capacity_table([Flows for $l=11$], csv("data/benders_0_flows_11.csv")),
    ),
    raw-render(raw(read("graphs/benders_0.dot")), engine: "neato", width: 100%)
),
  caption: flex-caption(
    [Results of Benders' Decomposition for Scenario 0. Candidate links are represented by dashed edges in the graph and green rows in the flow tables. Unused links are greyed in the graph and not included in the flow tables.],
    [Results of the Scenario 0.]
  ),
  supplement: "Summary",
  kind: "Summary"
) <summary:benders_0>


#figure(
  grid(
    columns: (auto, auto),
    align: center,
    gutter: 2pt,
    grid(
      columns: 2,
      rows: 2,
      inset: 3pt,
      grid.cell(colspan: 2, network.result_table([40], [346200], [346240])),
      network.arc_capacity_table([Flows for $l=3$], csv("data/benders_1_flows_3.csv")),
      network.arc_capacity_table([Flows for $l=11$], csv("data/benders_1_flows_11.csv")),
    ),
    raw-render(raw(read("graphs/benders_1.dot")), engine: "neato", width: 100%)
),
  caption: flex-caption(
    [Results of Benders' Decomposition for Scenario 1. Candidate links are represented by dashed edges in the graph and green rows in the flow tables. Unused links are greyed in the graph and not included in the flow tables.],
    [Results of the Scenario 1.]
  ),
  supplement: "Summary",
  kind: "Summary"
) <summary:benders_1>

#figure(
  network.diff_table([Differences for $l eq 3$], csv("data/differences3.csv")),
  caption: [Differences in link flows between solutions for origin $l eq 3$]
) <table:diffs_3>

#linebreak()

#figure(
  network.diff_table([Differences for $l eq 11$], csv("data/differences11.csv")),
  caption: [Differences in link flows between solutions for origin $l eq 11$]
) <table:diffs_11>

#linebreak()

= Conclusions

In this report we have solved a scenario of a Network Design Problem using two different methods: solving directly the classical MILP formulation and using the Benders' Decomposition (with two different initial scenarios). 
Comparing the results obtained, we see that both of them reach the optimal cost, although the actual solutions generated differ from each other. 
Time-wise, and although measurements across executions of the same method are not consistent, the Benders' Decomposition does consistently outperform the Extensive model, even with a small scenario as the one we deal with. 

