import json
import networkx as nx
from itertools import combinations
from collections import deque
from utils import plot_simple_solution, plot_single_iteration


class TSPSolver:
    """Solver for the Travelling Salesman Problem using Christofides and tabu search."""

    def __init__(self, json_path):
        """Initialize the TSP solver by loading data from a JSON file."""
        self.G, self.pos, self.dimension = self.load_data(json_path)

    def load_data(self, path):
        """Load problem data from a JSON file and convert it to a NetworkX graph."""
        try:
            with open(path, "r") as f:
                data = json.load(f)
        except FileNotFoundError:
            print("Error: JSON file not found.")
            return None, None, 0

        # Extract node information
        nodes = data["nodes"]
        matrix = data["distance_matrix"]
        dim = len(nodes)

        # Create complete weighted graph
        G = nx.Graph()
        # Dictionary storing geographic coordinates for each node
        pos = {n["id"]: (n["lon"], n["lat"]) for n in nodes}

        # Add all edges with their weights (distances)
        for i in range(dim):
            for j in range(i + 1, dim):
                G.add_edge(i, j, weight=matrix[i][j])

        return G, pos, dim

    def christofides(self):
        """Solve TSP using Christofides algorithm: MST, odd-degree matching, Eulerian circuit."""
        # Step 1: Calculate Minimum Spanning Tree
        mst = self.get_mst()

        # Step 2: Find nodes with odd degree
        odd_nodes = [v for v, d in mst.degree() if d % 2 == 1]

        # Step 3: Calculate minimum weight matching for odd-degree nodes
        if odd_nodes:
            matching = self.get_matching(odd_nodes)

        # Step 4: Create multigraph combining MST and matching
        multi_G = nx.MultiGraph()
        multi_G.add_edges_from(mst.edges(data=True))
        for u, v, w in matching:
            multi_G.add_edge(u, v, weight=w)

        # Step 5: Obtain Eulerian circuit
        euler_circuit = list(nx.eulerian_circuit(multi_G))

        # Step 6: Convert to Hamiltonian tour through shortcuts
        path = self.make_hamiltonian(euler_circuit)

        return path

    def get_mst(self):
        """Compute the Minimum Spanning Tree using a greedy algorithm similar to Kruskal's."""
        # Sort all edges by weight
        edges = sorted(self.G.edges(data=True), key=lambda x: x[2]["weight"])
        # Create new graph for MST
        mst = nx.Graph()
        # Add all nodes without edges initially
        mst.add_nodes_from(self.G.nodes())

        # Add edges one by one if they do not create cycles
        for u, v, data in edges:
            if not nx.has_path(mst, u, v):
                mst.add_edge(u, v, weight=data["weight"])

            # Stop when we have n-1 edges
            if mst.number_of_edges() == self.dimension - 1:
                break
        return mst

    def get_matching(self, odd_nodes):
        """Compute minimum weight matching between odd-degree nodes."""
        # Generate all possible pairs between odd-degree nodes
        candidates = []
        for u, v in combinations(odd_nodes, 2):
            candidates.append((self.G[u][v]["weight"], u, v))

        # Sort pairs by weight
        candidates.sort(key=lambda x: x[0])

        # Select greedy matching
        matching = []
        used = set()

        # Iterate and add pairs whose nodes have not been used
        for w, u, v in candidates:
            if u not in used and v not in used:
                matching.append((u, v, w))
                used.add(u)
                used.add(v)

            # Stop when all odd-degree nodes are matched
            if len(used) == len(odd_nodes):
                break

        return matching

    def make_hamiltonian(self, euler_circuit):
        """Convert Eulerian circuit to Hamiltonian tour using shortcutting technique."""
        if not euler_circuit:
            return []

        # Extract sequence of nodes from Eulerian circuit
        route = [euler_circuit[0][0]]
        for u, v in euler_circuit:
            route.append(v)

        # Remove duplicate nodes maintaining first visit order
        visited = set()
        final_path = []
        for node in route:
            if node not in visited:
                visited.add(node)
                final_path.append(node)

        # Close the tour by adding initial node at the end
        final_path.append(final_path[0])
        return final_path

    def edges_from_tour(self, tour):
        """Extract the set of edges from a given tour."""
        return {(tour[i], tour[i + 1]) for i in range(len(tour) - 1)}

    def diff_edges(self, old_tour, new_tour):
        """Identify edge differences between two tours and critical 2-opt nodes."""
        # Calculate edge sets for both tours
        e_old = self.edges_from_tour(old_tour)
        e_new = self.edges_from_tour(new_tour)

        # Identify differences
        removed = e_old - e_new
        added = e_new - e_old

        # Nodes involved in any edge change
        nodes_diff = set()
        for u, v in removed | added:
            nodes_diff.add(u)
            nodes_diff.add(v)

        # Find the four critical nodes of the 2-opt move
        n = len(old_tour) - 1
        start = end = 0
        for i in range(n):
            if old_tour[i] != new_tour[i]:
                start = i
                break
        # Find where differences end
        for j in range(n - 1, -1, -1):
            if old_tour[j] != new_tour[j]:
                end = j
                break

        # The four critical nodes of 2-opt
        a, b = old_tour[start - 1], old_tour[start]
        c, d = old_tour[end], old_tour[(end + 1) % n]
        real_nodes = {a, b, c, d}

        return real_nodes, nodes_diff, removed, added

    def tabu_search(self, initial_tour, max_iter=100, tabu_len=15):
        """Optimize tour using tabu search with 2-opt operator to escape local optima."""
        # Initialize with the initial tour (without repeating the initial node at the end)
        current_tour = initial_tour[:-1]
        best_tour = list(current_tour)

        # Calculate initial cost
        best_cost = self.get_cost(best_tour + [best_tour[0]])

        # Deque to maintain tabu list of moves
        tabu_list = deque(maxlen=tabu_len)
        # Save history of improvements for visualization
        history = [best_tour + [best_tour[0]]]

        # Counter for iterations without improvement
        contador = 0

        # Display initial state
        print(f"[ITER 0] Cost = {best_cost:.2f}")

        # Main tabu search iterations
        for i in range(1, max_iter + 1):
            # Generate neighborhood of current tour using 2-opt
            neighborhood = self.get_vecinos(current_tour)

            # Search for best non-tabu neighbor (or tabu if it improves global best)
            local_best_tour = None
            local_best_cost = float("inf")
            local_move = None

            for neighbor, move in neighborhood:
                c = self.get_cost(neighbor + [neighbor[0]])

                # Check if move is tabu
                is_tabu = move in tabu_list
                # Accept if not tabu OR if it improves global best solution
                if (not is_tabu) or (c < best_cost):
                    if c < local_best_cost:
                        local_best_tour = neighbor
                        local_best_cost = c
                        local_move = move

            # If no valid neighbor found, terminate search
            if local_best_tour is None:
                break

            # Update current tour and add move to tabu list
            prev_tour = current_tour
            current_tour = local_best_tour
            tabu_list.append(local_move)

            print(f"[ITER {i}] Cost = {local_best_cost:.2f}")

            # Check if improvement was found
            if local_best_cost < best_cost:
                print("  -> IMPROVEMENT FOUND")

                # Analyze details of the change
                real_nodes, nodes_diff, removed, added = self.diff_edges(
                    prev_tour + [prev_tour[0]], current_tour + [current_tour[0]]
                )

                # Display detailed improvement information used to generate table in report
                print(f"     2-opt real nodes: {sorted(real_nodes)}")
                print(f"     All involved nodes: {sorted(nodes_diff)}")
                print(f"     Removed edges: {sorted(removed)}")
                print(f"     Added edges:   {sorted(added)}")
                print(f"     Previous path: {prev_tour + [prev_tour[0]]}")
                print(f"     New path : {current_tour + [current_tour[0]]}")

                # Update best solution found
                best_cost = local_best_cost
                best_tour = list(local_best_tour)
                contador = 0
                # Save to history for visualization
                history.append(best_tour + [best_tour[0]])
            else:
                # Increment counter for iterations without improvement
                contador += 1

            # Terminate if no improvements in too many iterations
            if contador > 15:
                print(f"Stopped due to repetition at iteration {i}")
                break

        print("Best tour:", best_tour)
        return best_tour + [best_tour[0]], best_cost, history

    def get_vecinos(self, tour):
        """Generate neighborhood of current tour using 2-opt operator."""
        vecinos = []
        n = len(tour)
        # Generate all neighbors by 2-opt
        for i in range(n):
            for j in range(i + 2, n):
                # Reverse segment between positions i and j
                new_t = tour[:i] + tour[i:j][::-1] + tour[j:]
                # Identify move as the two "broken" nodes
                move = tuple(sorted((tour[i], tour[j])))
                vecinos.append((new_t, move))
        return vecinos

    def get_cost(self, tour):
        """Calculate total tour cost by summing distances between consecutive nodes."""
        total = 0
        for i in range(len(tour) - 1):
            total += self.G[tour[i]][tour[i + 1]]["weight"]
        return total


if __name__ == "__main__":
    """Execute the complete TSP resolution pipeline."""

    # Initialize solver by loading problem data
    solver = TSPSolver("data.json")

    print("=" * 60)
    print("CHRISTOFIDES ALGORITHM FOR THE TRAVELLING SALESMAN PROBLEM")
    print("=" * 60)

    # Solve using Christofides algorithm
    print("\n[1] Running Christofides Algorithm...")
    tour_base = solver.christofides()
    cost_base = solver.get_cost(tour_base)

    print(f"\n    Base Cost: {cost_base:.2f}")
    print(f"    Base Route: {tour_base}")

    # Improve solution using tabu search
    print("\n[2] Running Tabu Search for local optimization...")
    tour_opt, cost_opt, history = solver.tabu_search(tour_base, max_iter=50)

    print(f"\n    Final Cost: {cost_opt:.2f}")

    # Calculate and display improvement percentage
    mejora = 100 * (cost_base - cost_opt) / cost_base
    print(f"    Improvement: {mejora:.2f}%")

    # Visualize results
    print("\n[3] Generating plots...")

    # Generate plot for initial solution (iteration 0)
    plot_simple_solution(solver.G, solver.pos, history[0])

    # Generate individual plots for each improvement iteration
    for i in range(1, len(history)):
        plot_single_iteration(
            solver.G, solver.pos, history[i], prev_tour=history[i - 1], iteration=i
        )

    # Generate final plot with best solution
    print(f"\n[4] Generating final solution plot...")
    plot_simple_solution(solver.G, solver.pos, tour_opt)
