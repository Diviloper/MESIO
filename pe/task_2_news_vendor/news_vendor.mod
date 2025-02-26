# Stochastic Model of the News Vendor Problem

# Deterministic Params
param limit >= 0; 				# Newspaper buy limit
param recovery >= 0;			# Recovery on return (€/np) 
param cost >= recovery;			# Cost (€/np)
param price >= cost;			# Price (€/np)


# Demand assuming uniform distributions U~[demand_lower, demand_upper]
param discretizations >= 2;					# Number of discretizations used
param demand_lower >= 0;					# Lowest demand
param demand_upper >= demand_lower;			# Highest demand
param discretization_step = 				# Distance between discretizations used
	(demand_upper - demand_lower) / discretizations;

set SCENARIOS := 0..discretizations-1;		# Scenarios (number of discretizations)

# Stochastic Params
param demand {s in SCENARIOS} = demand_lower + discretization_step * s; # Demand of scenario
param prob {s in SCENARIOS} = 1 / discretizations;   					# Probability of scenario

# First-Stage Decision Variables
var x >= 0 <= limit;		# Newspapers bought

# Second-Stage Decision Variables
var y {SCENARIOS} >= 0;		# Newspapers sold
var w {SCENARIOS} >= 0;		# Newspapers returned

# Objective function
minimize CostTotal: 
		cost * x - sum {s in SCENARIOS} prob[s] * (y[s]*price + w[s]*recovery);

# Constraints
subject to SellLessThanDemand {s in SCENARIOS}:
	y[s] <= demand[s];

subject to SoldPlusReturnedLessThanBought{s in SCENARIOS}:
	y[s] + w[s] <= x;
