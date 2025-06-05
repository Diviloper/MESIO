#import "config.typ"
#import "tables.typ"
#show: config.global_config

#let labeled(equation, label) = {
  math.equation(
    block: true, 
    numbering: (x) => label, 
    equation
  )
}

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

== Problem <section:problem>

In the problem at hand, which we will call the ATM Deposit Problem, a bank branch wants to determine the amount of money to be deposited in an ATM on Fridays, before the weekend.
The branch estimates that money has a cost (associated to the loss of benefits by interest rates) of $c$ € for each € in the ATM.
The demand of money during the weekend is a discrete random variable $xi$, taking $s$ values $xi_i$ with probabilities $p_i, i eq 1, dots, s$.
The ATM has a capacity of $u$ €, with a technical minimum of $l$ €.
If the demand is greater than $x$, then the ATM has to be refilled, with a cost of $q$ € for each € the demand exceeds $x$.
The bank branch formulates the following stochastic optimization problem in extensive form:

#labeled(
  $
    text("Min")  quad quad & c x + sum_(i = 1)^s p_i q y_i & \
    text("s.t.") quad quad & l lt.eq x lt.eq u & \
    & x + y_i gt.eq xi_i & i = 1, dots, s \
    & y_i gt.eq 0 & i = 1, dots, s
  $,
  [($sans("P")$)]
) <eq:P>

Fixing the value $x$ to a valid value $macron(x)$ ($l lt.eq macron(x) lt.eq u$) and removing the now-constant cost from the objective function, from the extensive version of the problem #ref(<eq:P>, supplement: none) we obtain the following problem:

#labeled(
  $
    text("Min")  quad quad & sum_(i = 1)^s p_i q y_i & \
    text("s.t.") quad quad& y_i gt.eq xi_i - macron(x) quad quad & i = 1, dots, s \
    & y_i gt.eq 0                          & i = 1, dots, s
  $,
  [($sans("Q")$)]
) <eq:Q>

and its dual, which will be the Bender's #raw("Subproblem") used:

#labeled(
  $
    text("Max") quad quad & sum_(i = 1)^s u_i (xi_i - macron(x)) & \
    text("s.t.") quad quad& u_i lt.eq p_i q      quad quad & i = 1, dots, s \
    & u_i gt.eq 0                    & i = 1, dots, s
  $,
  [($sans("Q")_sans("D")$)]
) <eq:QD>

Using the #raw("Subproblem") #ref(<eq:QD>, supplement: none), we rewrite the original extensive problem #ref(<eq:P>, supplement: none) as follows:

#labeled(
  $
    text("Min")  quad quad & c x + max{sum_(i eq 1)^s u_i (xi_i - x) : 0 lt.eq u_i lt.eq p_i q, i eq 1, dots, s} & \
    text("s.t.") quad quad & l lt.eq x lt.eq u & \
  $,
  [($sans("P'")$)]
) <eq:Pp>

With the set of vertices ${v^1, dots, v^V}$ and extreme rays ${r^1, dots, r^R}$ of the feasible polyhedron of #ref(<eq:QD>, supplement: none), we can rewrite #ref(<eq:Pp>, supplement: none) again as:

#labeled(
  $
    text("Min")  quad quad & c x + z & \
    text("s.t.") quad quad & z gt.eq sum_(j = 1)^s v_j^i (d_j - x) quad quad & i = 1, dots, V \
                           & 0 gt.eq sum_(j = 1)^s r_j^i (d_j - x)           & i = 1, dots, R \
                           & l lt.eq x lt.eq u & \
  $,
  [($sans("BP")$)]
) <eq:BP>

For the Benders' Decomposition, we will use a relaxation #ref(<eq:BPr>, supplement: none) of #ref(<eq:BP>, supplement: none) in which we only use a subset of vertices and extreme points:

#labeled(
  $
    text("Min")  quad quad & c x + z & \
    text("s.t.") quad quad & z gt.eq sum_(j = 1)^s v_j^i (d_j - x) quad quad & i in cal(V) subset.eq {1, dots, V} \
                           & 0 gt.eq sum_(j = 1)^s r_j^i (d_j - x)           & i in cal(R) subset.eq {1, dots, R} \
                           & l lt.eq x lt.eq u & \
  $,
  [($sans("BPr")$)]
) <eq:BPr>

However, note that #ref(<eq:QD>, supplement: none) is bounded, since all variables $u_i$ have a lower bound ($0$) and an upper bound ($p_i q$). In fact, it is straightforward to see that the values of $u_i$ will be 0 if $xi_i - macron(x) lt.eq 0$ and $p_i q$ otherwise. Therefore, its feasible polyhedron doesn't have any extreme ray, so we can simplify #ref(<eq:BPr>, supplement: none) to obtain our #raw("Master Problem") formulation:

#labeled(
  $
    text("Min")  quad quad & c x + z & \
    text("s.t.") quad quad & z gt.eq sum_(j = 1)^s v_j^i (d_j - x) quad quad & i in cal(V) subset.eq {1, dots, V} \
                           & l lt.eq x lt.eq u & \
  $,
  [($sans("MP")$)]
) <eq:MP>

== Scenario

The scenario used in this report have the following characteristics:

#{
  show table.cell.where(y: 0): strong
  set table(stroke: (x, y) => (
    left: if x == 0 or y > 0 { 1pt } else { 0pt },
    right: 1pt,
    top: if y <= 1 { 1pt } else { 0pt },
    bottom: 1pt,
  ))
  set table(align: (x, y) => if x == 0 or y == 0 { center } else { right })
  
  grid(
    columns: (1fr, 1fr),
    align: center + horizon,
    $
      c &eq 2.5 dot 10^(-4) \
      q &eq 1.1 dot 10^(-3) \
      l &eq 21 dot 10^3 \
      u &eq 147 dot 10^3 \
      s &eq 7
    $,
    table(
      columns: 3,
      $i$, $p_i$, $xi_i$,
      [1], [0.04], [150],
      [2], [0.09], [120],
      [3], [0.10], [110],
      [4], [0.21], [100],
      [5], [0.27], [80],
      [6], [0.23], [60],
      [7], [0.06], [50],
    )
  )
}

The units of $l$, $u$ and $xi_i$ are thousands of €. #linebreak()
The scenario data in `AMPL` format is provided in the `atm.dat` file.

#pagebreak()

= Extensive Version

The model used to solve the extensive version of the ATM Problem is shown in #ref(<code:extensive>).
The code is also provided in the `extensive.mod` file, along a small runner script in the `extensive.run` file.

#figure(
  [
    #line(length: 90%)
    #raw(read("code/extensive.mod"), lang: "ampl", block: true)
    #line(length: 90%)
  ],
  caption: [AMPL Code for the Extensive model.],
  supplement: "Code",
  kind: "Code",
) <code:extensive>

The results obtained with the execution of the extensive model can be seen in #ref(<summary:extensive>). As can be seen, a total of 110k€ are deposited on the ATM, accounting for a cost of 27.5€. This amount falls short only in two scenarios, which adds 2.75€ to the expected cost for a total of 30.25€.

#figure(
  grid(
    columns: (1fr, auto),
    align: center + horizon,
    inset: 2pt,
    gutter: 2pt,
    tables.result_table([27.50], [2.75], [30.25]),
    tables.variables_table(110000, (40000, 10000, 0, 0, 0, 0)),
),
  caption: [Results of the extensive model.],
  supplement: "Summary",
  kind: "Summary"
) <summary:extensive>

#pagebreak()

= Benders' Decomposition

For the Benders' Decomposition, we use the formulations of the #raw("Master Problem") and the #raw("Subproblem") described in #ref(<section:problem>).
The AMPL models for both are shown in #ref(<code:benders-mod>), while the code for the actual Benders' Decomposition is shown in #ref(<code:benders-run>).
The code is also provided in the `benders_simplified.mod` and `benders_simplified.run` files respectively.
#footnote[
Another pair of AMPL files (`benders.mod` and `benders.run`) are provided without the simplification of the #raw("Master Problem"), i.e. using #ref(<eq:BPr>, supplement: none) instead of #ref(<eq:MP>, supplement: none). The only difference is that it handles both point and ray cuts instead of only point cuts. In practice, both are equivalent since ray cuts are never generated.
]
 
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

The AMPL code is a direct copy of the formulations presented above, with parameters in uppercase and variables in lowercase.

#figure(
  [
    #line(length: 90%)
    #raw(read("code/benders.run"), lang: "ampl", block: true)
    #line(length: 90%)
  ],
  caption: [AMPL Code for Benders' Decomposition.],
  supplement: "Code",
  kind: "Code",
) <code:benders-run>

We start the algorithm initializing $macron(x)$.
Then, at each iteration, we start solving the #raw("Subproblem") (which is guaranteed to find a solution).
Then, we check if the gap between the dual cost and $z$ is lower than the accepted relative tolerance $epsilon z$ (with a fixed $epsilon eq 10^(-8)$).
If it is, we stop. Otherwise, we create an optimality cut with the values of $u_i, i eq 1, dots, s$.
We then proceed to solve the #raw("Master Problem"), use the resulting $x$ as the new value for $macron(x)$, and move on to the next iteration.

Two scenarios have been executed, one in which we start with $macron(x) eq l$ and another in with $macron(x) eq u$.
Both scenarios reach the same final results as the extensive model (shown in #ref(<summary:extensive>)). The evolution in the costs and $macron(x)$ over the iterations for each scenario are shown in Tables #ref(<table:results_l>, supplement: none) and #ref(<table:results_u>, supplement: none). The Gap column shows the absolute gap between the dual cost of the same iteration and the value of $z$ of the previous one.

As can be seen, both scenarios end with the same objective value as the extensive version in the same number of iterations. In fact, note that the costs between scenarios only differ in the first two iterations. In the second execution of the #raw("Master Problem") (in iteration 2), we obtain the same result in both scenarios, and from that moment on, the results are always the same for both of them.

#figure(
  tables.evolution_table(csv("data/results_l.csv")),
  caption: [Evolution of costs for scenario $l$.]
) <table:results_l>

#linebreak()

#figure(
  tables.evolution_table(csv("data/results_u.csv")),
  caption: [Evolution of costs for scenario $u$.]
) <table:results_u>

#linebreak()

= Conclusions

In this report we have solved an scenario of the stochastic ATM Deposit Problem using two different methods: solving directly the classical MILP formulation and using the Benders' Decomposition (with two different initial scenarios).
We have presented a classic Benders' Master and subproblem formulations, as well as a simplification of the Master formulation that relies on the nature of the problem at hand.
The computational results show that both methods (extensive version and Bender's Decomposition) yield exactly the same results.
