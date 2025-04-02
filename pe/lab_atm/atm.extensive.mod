# ----------------------------------------
# ATM Money Problem Model
# ----------------------------------------

set S; # Scenarios

param l >= 0; 	# Minimum money to be deposited
param u > l; 	# Maximum money to be deposited

param c; # Cost of deposited money €/€
param q; # Cost of lack of money €/€

param p {S} >= 0 <= 1; 	# Probability of each scenario
param d {S} >= 0; 		# Demand of each scenario

var x >= l <= u; 	# Amount deposited
var y {S} >= 0;		# Missing amount in each scenario

minimize Total_Cost:
   c*x +
   sum {i in S} p[i] * q * y[i];

subj to Demand {i in S}:
	x + y[i] >= d[i]
