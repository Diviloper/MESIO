# Common Parameters
set N;                      # Nodes
set FN;                     # Fake Nodes
set O within N;             # Origins
set A within N cross N;     # Existing Arcs
param MC;                   # Default maximum arc capacity
param Y {A} default MC;     # Maximum arc capacity

param XC {N};               # Node X Coordinate
param YC {N};               # Node Y Coordinate
param T {i in N, l in O};   # Out Flow
param C {(i, j) in A} :=    # Exploitation Cost
    95 + (XC[i] - XC[j])^2 + 8 * (YC[i] - YC[j])^2;
param BIGM > 0;              # Big-M Multiplier for artificial costs