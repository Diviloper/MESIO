# Stochastic Model of Farmer's Problem

set SCENARIOS;
set CROP1;
set CROP2;
set CROP := CROP1 union CROP2;

# Deterministic Params
param cplant {CROP} >= 0; 			# Planting cost ($/acre)
param min_crop {CROP1} >= 0; 		# Minimun crop required
param psell {CROP1} >= 0; 			# Selling price ($/Tona)
param ppurchase {CROP1} >= 0; 		# Purchasing price ($/Tona)
param pvbelow >= 0; 				# Selling price corn below 6000T production
param pvabove >= 0;					# Selling price corn above 6000T production
param land_total >= 0;

# Stochastic Params
param yield {SCENARIOS, CROP} >= 0; # Productivity Tones/acre
param prob {SCENARIOS} >= 0 <= 1;   # Probability of scenario

# First-Stage Decision Variables
var x {i in CROP} >= 0;				# Ha of land devoted to wheat, corn and sugarbeet

# Second-Stage Decision Variables
var w {SCENARIOS, i in CROP1} >= 0;			# Tons of wheat and corn to be sold
var y {SCENARIOS, i in CROP1} >= 0;			# Tons of wheat and corn to be purchased
var wbelow {SCENARIOS, i in CROP2} >= 0;	# Tons of sugar beet sold at the favorable price
var wabove {SCENARIOS, i in CROP2} >= 0;	# Tons of sugar beet sold at the lowest price

# Objective function
minimize cost_total: 
		sum {i in CROP} cplant[i] * x[i]
		+ sum {s in SCENARIOS, i in CROP1} prob[s] * (ppurchase[i] * y[s,i]- psell[i] * w[s,i])
	    - sum {s in SCENARIOS, i in CROP2} prob[s] * (pvbelow * wbelow[s,i] + pvabove *wabove[s,i]);

# Constraints
subject to LandTotal:
	sum {i in CROP} x[i] <= land_total;

subject to MinCrop {s in SCENARIOS, i in CROP1}:
	yield[s,i]*x[i]+y[s,i]-w[s,i] >= min_crop[i];
	

subject to ProdControlled1 {s in SCENARIOS, i in CROP2}:
	wbelow[s,i]+wabove[s,i] <= yield[s,i]*x[i];

subject to ProdControlled2 {s in SCENARIOS, i in CROP2}:
	wbelow[s,i] <= 6000;



