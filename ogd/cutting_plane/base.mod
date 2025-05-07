# ---------------------------------------------------
# Model for the Multicommodity Network Flow Problem
# ---------------------------------------------------

# Parameters

set N;                     # Nodes
set O within N;            # Origins
set A within N cross N;    # Existing Arcs

param XC {N};                                       # Node X Coordinate
param YC {N};                                       # Node Y Coordinate
param T {i in N, l in O};                           # Out Flow
param C {(i, j) in A, l in O} :=                    # Exploitation Cost
    95 + (XC[i] - XC[j])^2 + 8*(YC[i] - YC[j])^2;

param MC > 0;                                       # Default maximum arc capacity
param Y {A} default MC;                             # Maximum arc capacity

# Flow constraints and variables

# Flow restritions and variables
node I {i in N, l in O}: net_out = T[i, l];    # Node flow Restrictions
arc xl {(i, j) in A, l in O} >= 0:             # Arc Flow
    from I [i, l], to I [j, l];

# Model

# Objective Function
minimize Cost: sum {l in O} (sum {(i, j) in A} C[i, j, l] * xl[i, j, l]);

# Restrictions

subject to JointCapacity {(i, j) in A}:        # Total flow capacity
    sum {l in O} xl[i, j, l] <= Y[i, j];
