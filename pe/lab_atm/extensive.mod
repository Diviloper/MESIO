# ----------------------------------------
# ATM Money Problem Model
# ----------------------------------------

set S; # Scenarios

param L >= 0; 	# Minimum money to be deposited
param U > L; 	# Maximum money to be deposited

param C; # Cost of deposited money €/€
param Q; # Cost of lack of money €/€

param P {S} >= 0 <= 1; 	# Probability of each scenario
param D {S} >= 0; 		# Demand of each scenario

var x >= L <= U; 	   # Amount deposited
var y {S} >= 0;		# Missing amount in each scenario

minimize Total_Cost:
   C*x +
   sum {i in S} P[i] * Q * y[i];

subj to Demand {i in S}:
	x + y[i] >= D[i]
