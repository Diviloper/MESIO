# Base parameters
param ncells;				# Number of cells
param npcells;				# Number of primary cells
param nconstraints;			# Number of constraints (num rows of A and b)
param nnz;					# Number of nonzeros in A

# Sets
set I  := 1..ncells;        # Cell set
set P  := 1..npcells;       # Primary cell set
set C  := 1..nconstraints;	# Constraint set
set C1 := 1..nconstraints+1;# Constraint set
set NZ := 1..nnz;			# Non-zero set

# Cell parameters
param a	   {I};				# Cell value
param lb   {I};				# Lower bound
param ub   {I};				# Upper bound
param c	   {I};				# Suppression cost
param is_p {I} binary;		# Primary cell

# Primary cell parameters
param p {P};				# Primary cell index
param plpl {P};				# Lower protection level
param pupl {P};				# Upper protection level

# Matrix parameters
param b {C};				# Constraint rhs
param begconst {C1};		# Index range of constraint coefficients
param coef {NZ};			# Coeficients i of A
param xcoef {NZ};			# Column for coefficient i of A

param A{C, I} default 0;	# Matrix A
                            


#------------------------------------
#-----------Master Problem-----------
#------------------------------------

# Variables
var y {I} binary;           # Cell i suppressed
var z >= 0; 				# Cost from cuts for a given selection

# Parameters
param NCuts >= 0 integer;   # Number of cuts
param Gamma {1..NCuts};		# Gamma
param Lambda {1..NCuts, I};	# Lambda

# Objective
minimize Total_Cost: 
    sum {i in I} c[i] * y[i] + z;
    
subj to Cuts {k in 1..NCuts}:
   Gamma[k] + sum {i in I} Lambda[k, i] * y[i] <= 0;

#------------------------------------
#-------------SubProblem-------------
#------------------------------------

# Variables
var alpha_l {P,C};
var alpha_u {P,C};
var gamma_l {P} >= 0;
var gamma_u {P} >= 0;
var lambda_l {P, I} >= 0;
var lambda_u {P, I} >= 0;
var mu_l {P, I} >= 0;
var mu_u {P, I} >= 0;

# Parameters
param Y {I} binary; 		# Cell i suppressed (fixed from Master)

# Objective
maximize Subproblem_Cost:
	sum {px in P} (
		plpl[px] * gamma_l[px] +
		pupl[px] * gamma_u[px] +
		sum {i in I} (
			(lb[i] - a[i]) * Y[i] * lambda_l[px, i] -
			(ub[i] - a[i]) * Y[i] * mu_l[px, i] +
			(lb[i] - a[i]) * Y[i] * lambda_u[px, i] -
			(ub[i] - a[i]) * Y[i] * mu_u[px, i]
		)
	);
	
# Constraints
subject to

Conservation_L {i in I, px in P}:
	sum {cx in C} A[cx, i] * alpha_l[px, cx] 
	+ lambda_l[px, i] 
	- mu_l[px, i] 
	- (if p[px] = i then 1) * gamma_l[px] 
	= 0;
	
Conservation_U {i in I, px in P}:
	sum {cx in C} A[cx, i] * alpha_u[px, cx] 
	+ lambda_u[px, i] 
	- mu_u[px, i] 
	+ (if p[px] = i then 1) * gamma_u[px] 
	= 0;
