import matplotlib.pyplot as plt
import networkx as nx

# Función para pintar la solución final
def plot_simple_solution(G, pos, tour):
    tour_edges = list(zip(tour, tour[1:]))
    
    plt.figure(figsize=(8, 8))
    nx.draw_networkx_nodes(G, pos, node_size=300, node_color='lightblue')
    nx.draw_networkx_labels(G, pos, font_size=8)
    nx.draw_networkx_edges(G, pos, edgelist=tour_edges, width=2, edge_color='r')
    
    plt.axis("off")
    plt.title("Ruta Final")
    plt.show()

# Función para ver cómo mejora el algoritmo
def plot_tour_evolution(G, pos, tours):
    k = len(tours)
    
    if len(tours) > 1:
        idx = [int(i * (len(tours)-1) / (k-1)) for i in range(k)]
    else:
        idx = [0]
    
    idx = sorted(list(set(idx)))
    k = len(idx)

    fig, axes = plt.subplots(1, k, figsize=(4*k, 4))
    
    if k == 1: 
        axes = [axes]

    for ax, i in zip(axes, idx):
        tour = tours[i]
        edges = list(zip(tour, tour[1:]))

        nx.draw_networkx_nodes(G, pos, ax=ax, node_size=200)
        nx.draw_networkx_edges(G, pos, edgelist=edges, ax=ax, width=2,arrows=True,arrowstyle='-|>',connectionstyle='arc3,rad=0.5')
        nx.draw_networkx_labels(G, pos, ax=ax, font_size=8)


        cost = sum(G[tour[j]][tour[j + 1]]["weight"] for j in range(len(tour) - 1))
        
        ax.set_title(f"Iter {i}\nCoste: {cost:.2f}")
        ax.axis("off")

    plt.tight_layout()
    plt.show()