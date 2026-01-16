import matplotlib.pyplot as plt
import networkx as nx


# Función para pintar la solución final
def plot_simple_solution(G, pos, tour):
    tour_edges = list(zip(tour, tour[1:]))

    plt.figure(figsize=(8, 8))
    nx.draw_networkx_nodes(G, pos, node_size=300, node_color="lightblue")
    nx.draw_networkx_labels(G, pos, font_size=8)
    nx.draw_networkx_edges(
        G,
        pos,
        edgelist=tour_edges,
        width=2,
        edge_color="black",
        arrows=True,
        arrowstyle="-|>",
        connectionstyle="arc3,rad=0.25",
    )

    plt.axis("off")
    plt.title("Ruta Final")
    plt.show()


# Solo un plot, compara iteración previa con nueva
def plot_single_iteration(G, pos, current_tour, prev_tour=None, iteration=0):
    plt.figure(figsize=(8, 8))

    nx.draw_networkx_nodes(G, pos, node_size=60, node_color="lightblue")
    nx.draw_networkx_labels(G, pos, font_size=5)

    if prev_tour is None:
        # esto ni haria falta la vd
        edges = list(zip(current_tour, current_tour[1:]))
        nx.draw_networkx_edges(
            G,
            pos,
            edgelist=edges,
            width=0.25,
            edge_color="blue",
            arrows=True,
            arrowstyle="-|>",
            connectionstyle="arc3,rad=0.25",
        )
    else:
        current_edges = {
            tuple(sorted((current_tour[i], current_tour[i + 1])))
            for i in range(len(current_tour) - 1)
        }
        prev_edges = {
            tuple(sorted((prev_tour[i], prev_tour[i + 1])))
            for i in range(len(prev_tour) - 1)
        }

        added = current_edges - prev_edges
        removed = prev_edges - current_edges
        kept = current_edges & prev_edges

        # Dibujar aristas que siguen (negro)
        if kept:
            nx.draw_networkx_edges(
                G,
                pos,
                edgelist=list(kept),
                width=2,
                edge_color="black",
                alpha=0.8,
                arrowstyle="-|>",
                connectionstyle="arc3,rad=0.25",
            )

        # Dibujar aristas añadidas (verde)
        if added:
            nx.draw_networkx_edges(
                G,
                pos,
                edgelist=list(added),
                edge_color="green",
                width=2.5,
                arrows=True,
                arrowstyle="-|>",
                connectionstyle="arc3,rad=0.5",
            )

        # Dibujar aristas eliminadas (rojo)
        if removed:
            nx.draw_networkx_edges(
                G,
                pos,
                edgelist=list(removed),
                edge_color="red",
                width=2.5,
                arrows=True,
                arrowstyle="-|>",
                connectionstyle="arc3,rad=0.5",
            )

    # Calcular coste
    cost = sum(
        G[current_tour[j]][current_tour[j + 1]]["weight"]
        for j in range(len(current_tour) - 1)
    )

    plt.axis("off")
    plt.title(f"Iteración {iteration}\nCoste: {cost:.2f}")
    plt.show()


# Función para ver cómo mejora el algoritmo (versión original) Esta salian todas juntas
def plot_tour_evolution(G, pos, tours, max_panels=None, curve="arc3,rad=0.25"):
    k = len(tours)
    if k == 0:
        return

    if max_panels is None or k <= max_panels:
        idx = list(range(k))
    else:
        idx = sorted(
            {int(round(i * (k - 1) / (max_panels - 1))) for i in range(max_panels)}
        )

    fig, axes = plt.subplots(1, len(idx), figsize=(4 * len(idx), 4))
    if len(idx) == 1:
        axes = [axes]

    prev_edges = set()
    for ax, i in zip(axes, idx):
        tour = tours[i]
        edges = list(zip(tour, tour[1:]))

        curr_edges = {tuple(sorted(e)) for e in edges}
        added = curr_edges - prev_edges
        removed = prev_edges - curr_edges
        kept = curr_edges & prev_edges

        nx.draw_networkx_nodes(
            G, pos, ax=ax, node_size=40, node_color="lightblue", alpha=0.9
        )
        nx.draw_networkx_labels(G, pos, ax=ax, font_size=5)

        # aristas mantenidas
        if kept:
            nx.draw_networkx_edges(
                G,
                pos,
                ax=ax,
                edgelist=list(kept),
                width=2,
                alpha=0.6,
                edge_color="black",
                arrowstyle="-|>",
                connectionstyle="arc3,rad=0.5",
            )
        # aristas añadidas
        if added:
            nx.draw_networkx_edges(
                G,
                pos,
                ax=ax,
                edgelist=list(added),
                width=2.5,
                edge_color="green",
                alpha=0.9,
                arrowstyle="-|>",
                connectionstyle="arc3,rad=0.5",
            )
        # aristas eliminadas
        if removed:
            nx.draw_networkx_edges(
                G,
                pos,
                ax=ax,
                edgelist=list(removed),
                width=2.5,
                edge_color="red",
                style="dashed",
                alpha=0.9,
                arrowstyle="-|>",
                connectionstyle="arc3,rad=0.5",
            )

        cost = sum(G[tour[j]][tour[j + 1]]["weight"] for j in range(len(tour) - 1))
        ax.set_title(f"Iter {i}\nCoste: {cost:.2f}", fontsize=9)
        ax.axis("off")

        prev_edges = curr_edges

    plt.tight_layout()
    plt.show()
