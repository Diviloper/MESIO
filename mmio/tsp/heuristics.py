import json
import networkx as nx
from itertools import combinations
from collections import deque
from utils import plot_simple_solution, plot_tour_evolution

class TSPSolver:
    def __init__(self, json_path):
        self.G, self.pos, self.dimension = self.load_data(json_path)

    def load_data(self, path):
        try:
            with open(path, "r") as f:
                data = json.load(f)
        except FileNotFoundError:
            print("Error: No encuentro el json.")
            return None, None, 0

        nodes = data["nodes"]
        matrix = data["distance_matrix"]
        dim = len(nodes)

        G = nx.Graph()
        pos = {n["id"]: (n["lon"], n["lat"]) for n in nodes}

        for i in range(dim):
            for j in range(i + 1, dim):
                G.add_edge(i, j, weight=matrix[i][j])

        return G, pos, dim

    def christofides(self):
        # 1. MST
        mst = self.get_mst()
        
        # 2. Nodos de grado impar
        odd_nodes = [v for v, d in mst.degree() if d % 2 == 1]
        
        # 3. Matching  de peso mínimo para los nodos de grado impar
        if odd_nodes:
            matching = self.get_matching(odd_nodes)
        
        # 4. Unir MST + Matching
        multi_G = nx.MultiGraph()
        multi_G.add_edges_from(mst.edges(data=True))
        for u, v, w in matching:
            multi_G.add_edge(u, v, weight=w)

            
        euler_circuit = list(nx.eulerian_circuit(multi_G))
        
        # 5. Hacemos grafo hamiltoniano
        path = self.make_hamiltonian(euler_circuit)
        
        return path

    def get_mst(self):
        edges = sorted(self.G.edges(data=True), key=lambda x: x[2]["weight"])
        mst = nx.Graph()
        mst.add_nodes_from(self.G.nodes())

        for u, v, data in edges:
            if not nx.has_path(mst, u, v):
                mst.add_edge(u, v, weight=data["weight"])
            
            if mst.number_of_edges() == self.dimension - 1:
                break
        return mst

    def get_matching(self, odd_nodes):

        candidates = []
        for u, v in combinations(odd_nodes, 2):
            candidates.append((self.G[u][v]["weight"], u, v))

        candidates.sort(key=lambda x: x[0])
        
        matching = []
        used = set()

        for w, u, v in candidates:
            if u not in used and v not in used:
                matching.append((u, v, w))
                used.add(u)
                used.add(v)
            
            if len(used) == len(odd_nodes):
                break
                
        return matching

    def make_hamiltonian(self, euler_circuit):
        if not euler_circuit:
            return []
            
        route = [euler_circuit[0][0]]
        for u, v in euler_circuit:
            route.append(v)

        visited = set()
        final_path = []
        for node in route:
            if node not in visited:
                visited.add(node)
                final_path.append(node)
        
        final_path.append(final_path[0])
        return final_path

    def tabu_search(self, initial_tour, max_iter=100, tabu_len=15):
        current_tour = initial_tour[:-1] 
        best_tour = list(current_tour)
        
        best_cost = self.get_cost(best_tour + [best_tour[0]])
        
        tabu_list = deque(maxlen=tabu_len)
        history = [best_tour + [best_tour[0]]]  #para hacer plot de las mejoras
        
        contador = 0 # contador si no mejora x veces

        for i in range(max_iter):
            neighborhood = self.get_vecinos(current_tour)
            
            local_best_tour = None
            local_best_cost = float('inf')
            local_move = None

            for neighbor, move in neighborhood:
                c = self.get_cost(neighbor + [neighbor[0]])
                
                is_tabu = move in tabu_list
                if (not is_tabu) or (c < best_cost):
                    if c < local_best_cost:
                        local_best_tour = neighbor
                        local_best_cost = c
                        local_move = move

            if local_best_tour is None:
                break

            current_tour = local_best_tour
            tabu_list.append(local_move)

            if local_best_cost < best_cost:
                best_cost = local_best_cost
                best_tour = list(local_best_tour)
                contador = 0
                history.append(best_tour + [best_tour[0]])
            else:
                contador += 1
            
            if contador > 15:
                print(f"Parada por repetición en iter {i}")
                break
        
        print(best_tour)
        return best_tour + [best_tour[0]], best_cost, history

    def get_vecinos(self, tour):
        vecinos = []
        n = len(tour)
        # 2-opt simple
        for i in range(n):
            for j in range(i + 2, n):
                new_t = tour[:i] + tour[i:j][::-1] + tour[j:]
                move = tuple(sorted((tour[i], tour[j])))
                vecinos.append((new_t, move))
        return vecinos

    def get_cost(self, tour):
        total = 0
        for i in range(len(tour) - 1):
            total += self.G[tour[i]][tour[i+1]]["weight"]
        return total


if __name__ == "__main__":
    # path al archivo
    
    solver = TSPSolver("data.json")
    
    print("Christofides...")
    tour_base = solver.christofides()
    cost_base = solver.get_cost(tour_base)
    
    print(f"Coste Base: {cost_base:.2f}")
    print(f"Ruta Base: {tour_base}")

    print("\n Tabu Search...")
    tour_opt, cost_opt, history = solver.tabu_search(tour_base, max_iter=50)
    
    print(f"Coste Final: {cost_opt:.2f}")
    
    mejora = 100 * (cost_base - cost_opt) / cost_base
    print(f"Mejora: {mejora:.2f}%")

  
    print("\nGenerando gráficos...")
    plot_simple_solution(solver.G, solver.pos, tour_opt)
    plot_tour_evolution(solver.G, solver.pos, history)