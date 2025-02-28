# Stochastic Model of Study or Play Basketball game

param study_scenarios > 0;
param basketball_scenarios > 0;

param study_prob = (1/study_scenarios);
param basketball_prob = (1/basketball_scenarios);


#Deterministic Params
param N >= 0; 	# Total available hours

# Stochastic Params
param study_hours {1..study_scenarios} >= 0; 			# Hours required for studying
param basketball_hours {1..basketball_scenarios} >= 0;  # Hours required for basketball

# First-Stage Decision Variables
var x1 >= 0;	# Hours of study
var x2 >= 0;	# Hours of basketball

# Second-Stage Decision Variables
var y1 {1..study_scenarios} >= 0;		# Hour shortage of study
var y2 {1..basketball_scenarios} >= 0;	# Hours shortage of basketball

# Objective function
minimize cost_total: 
		sum {s in 1..study_scenarios} study_prob * y1[s]*2
		+ sum {b in 1..basketball_scenarios} basketball_prob * y2[b]
;

# Constraints
subject to TotalHours:
	x1 + x2 <= N;

subject to StudyHours {s in 1..study_scenarios}:
	x1 + y1[s] >= study_hours[s];

subject to BasketballHours {b in 1..basketball_scenarios}:
	x2 + y2[b] >= basketball_hours[b];



