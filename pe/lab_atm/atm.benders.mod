# ----------------------------------------
# ATM Money Problem Model
# Benders' Decomposition
# ----------------------------------------

# Common Params
set S;                  # Scenarios

param P {S} >= 0, <= 1; # Probability of each scenario
param D {S} >= 0; 		# Demand of each scenario


# Master Problem
param NCuts >= 0 integer;   # Number of cuts
param CutType {1..NCuts}    # Type of each cut
   symbolic within {"point", "ray"};

param L >= 0; 	            # Minimum money to be deposited
param U > L; 	            # Maximum money to be deposited

param C;                   # Cost of deposited money €/€

param Y {S, 1..NCuts};	   # Missing amount in each scenario

var x >= L, <= U; 	      # Amount deposited
var z;                     # Maximum cost for missing money

minimize Total_Cost: C * x + z;

subj to Cuts {k in 1..NCuts}:
   (if CutType[k] = "point" then z) >=
      sum {i in S} Y[i,k] * (D[i] - x);


# Subproblem
param Q; # Cost of lack of money €/€
param X; # Amount deposited

var u {S} >= 0;

maximize Dual_Cost: sum{i in S} u[i] * (D[i] - X);

subj to MissingCost {i in S}: u[i] <= P[i] * Q;