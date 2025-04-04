# ----------------------------------------
# ATM Money Problem Model
# Benders' Decomposition
# ----------------------------------------

# Common Params
set s;                  # Scenarios

param p {s} >= 0 <= 1; 	# Probability of each scenario
param d {s} >= 0; 		# Demand of each scenario


# Master Problem
param n_cuts >= 0 integer;   # Number of cuts
param cut_type {1..n_cuts}   # Type of each cut
   symbolic within {"point", "ray"};

param l >= 0; 	            # Minimum money to be deposited
param u > l; 	            # Maximum money to be deposited

param c;                   # Cost of deposited money €/€

param y {s, 1..n_cuts};	# Missing amount in each scenario

var X >= l <= u; 	         # Amount deposited
var Z;                     # Maximum cost for missing money

minimize Total_Cost: c * X + Z;

subj to Cuts {k in 1..n_cuts}:
   if cut_type[k] = "point" then Z else 0 >=
      sum {i in s} y[i,k] * (d[i] - X);


# Subproblem
param q; # Cost of lack of money €/€
param x; # Amount deposited

var U {s};

maximize Dual_Cost: sum{i in s} U[i] * (d[i] - x);

subj to MissingCost {i in s}: U[i] <= p[i] * q;