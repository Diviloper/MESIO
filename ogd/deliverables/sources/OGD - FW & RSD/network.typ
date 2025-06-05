#let arc_flow_table(title, arcs) = {
  show table.cell.where(y: 0): strong
  show table.cell.where(y: 1): strong
  set table(fill: (x, y) => if y >= 2 and arcs.at(y - 2).at(2) == "true" {rgb("#96cc9c")} else {white})
  
  show table.cell : c => {
    if c.y < 2 {return text(1em, c)}
    else {return text(0.8em, font: "JetBrains Mono", c)}
  }
  set table(align: (x, y) => {
    if y < 2 or x == 0 { center + horizon } 
    else { right }
  }
)
  
  table(
    columns: (auto, auto),
    row-gutter: (2.2pt, auto),
    table.header(
      table.cell(colspan: 2, title),
      [Arc], [Flow],
    ),

    ..arcs.map(a => (
      [#a.at(1) #sym.arrow #a.at(2)], 
      [#a.at(3)]
    )).flatten() 
  )
}

#let result_comparison_table(total_cost, optimal_cost, gap, relative_gap, iterations) = {
  show table.cell : c => {
    if c.x == 0 {return text(1em, c)}
    else {return text(0.9em, font: "JetBrains Mono", c)}
  }
  table(
    columns: 2, 
    strong([Total Cost]), align(right, total_cost),
    strong([Optimal Cost]), align(right, optimal_cost),
    strong([Gap]), align(right, gap),
    strong([Relative Gap]), align(right, relative_gap),
    strong([Iterations]), align(right, iterations),
  )
}