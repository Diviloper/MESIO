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
                            

# Variables
var y {I} binary;           # Cell I suppressed
var x_l {P, I};             # Upper deviation from original value
var x_u {P, I};             # Lower deviation from original value

# Objective
minimize Total_Cost: 
    sum {i in I} c[i] * y[i];

# Constraints
subject to

# A xlp = 0
Conservation_L {px in P, cx in C}:
    sum {i in I} A[cx, i] * x_l[px, i] = 0;

# Bounds for xlp linked to y_i
Lower_Bound_L {px in P, i in I}:
    x_l[px, i] >= (lb[i] - a[i]) * y[i];

Upper_Bound_L {px in P, i in I}:
    x_l[px, i] <= (ub[i] - a[i]) * y[i];

# Scenario specific bound for x^l,p (for specific index p)
Scenario_Bound_L {px in P}:
    x_l[px, p[px]] <= -plpl[px];

# Conservation/System equations for x^u,p
Conservation_U {px in P, cx in C}:
    sum {i in I} A[cx, i] * x_u[px, i] = 0;

# Bounds for x^u,p linked to y_i
Lower_Bound_U {px in P, i in I}:
    x_u[px, i] >= (lb[i] - a[i]) * y[i];

Upper_Bound_U {px in P, i in I}:
    x_u[px, i] <= (ub[i] - a[i]) * y[i];

# Scenario specific bound for x^u,p (for specific index p)
Scenario_Bound_U {px in P}:
    x_u[px, p[px]] >= pupl[px];