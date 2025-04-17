#let arc_costs_table(arcs) = {
  show table.cell.where(y: 0): strong
  
  table(
      columns: (auto, auto, auto),
      row-gutter: (2.2pt, auto),
      [Arc], [Investment Cost], [Exploitation Cost],

      ..arcs.map(
        a => (
          [#a.at(0) #sym.arrow #a.at(1)], 
          [#a.at(2)],
          [#a.at(3)],
        )
      ).flatten()
    )
}

#let result_table(investment, exploitation, total) = {
  show table.cell.where(y: 0): strong
  set table(align: (x, y) => if x == 0 or y == 0 { center } else { right })

  
  table(
    columns: (auto, auto),
    row-gutter: (2.2pt, auto, 2.2pt),
    table.header([Cost], [Value]),
    [Investment], investment,
    [Exploitation], exploitation,
    [Total], total,   
    )
}

#let added_links_table(links) = {
  show table.cell.where(y: 0): strong
  
  table(
    columns: (auto, auto),
    row-gutter: (2.2pt, auto),
    [From], [To],
    ..links.flatten().map(x => [#x])
  )
}

#let arc_capacity_table(title, arcs) = {
  show table.cell.where(y: 0): strong
  show table.cell.where(y: 1): strong
  set table(fill: (x, y) => if y >= 2 and arcs.at(y - 2).at(2) == "true" {rgb("#96cc9c")} else {white})
  show table: set text(size: 0.9em)
  
  table(
    columns: (auto, auto),
    row-gutter: (2.2pt, auto),
    table.cell(colspan: 2, title),
    [Arc], [Flow],

    ..arcs.map(a => (
      [#a.at(0) #sym.arrow #a.at(1)], 
      [#a.at(3)]
    )).flatten()
    
  )
}

#let diff_table(title, rows) = {
  show table.cell.where(y: 0): strong
  show table.cell.where(y: 1): strong
  
  let extensive_total = rows.slice(1).map(r => int(r.at(4))).sum()
  let benders0_total = rows.slice(1).map(r => int(r.at(6))).sum()
  let benders1_total = rows.slice(1).map(r => int(r.at(8))).sum()
  set table(align: (x, y) => if x == 0 or y < 3 { center } else { right })
  table(
    columns: 7,
    row-gutter: (2.2pt, auto, 2.2pt, auto),
    column-gutter: (2.2pt, auto, 2.2pt, auto, 2.2pt, auto),
    table.cell(colspan: 7, title),
    table.cell(rowspan: 2, "Arc", align: center+horizon),
    table.cell(colspan: 2, "Extensive"),
    table.cell(colspan: 2, "Benders 0"),
    table.cell(colspan: 2, "Benders 1"),
    [Flow], [Cost], [Flow], [Cost], [Flow], [Cost],

    ..rows.slice(1).map(a => (
      [#a.at(0) #sym.arrow #a.at(1)], 
      [#a.at(3)],
      [#a.at(4)],
      [#a.at(5)],
      [#a.at(6)],
      [#a.at(7)],
      [#a.at(8)]
    )).flatten(),
    
    strong("Total"), 
    table.cell(colspan: 2, align:center, strong(str(extensive_total))), 
    table.cell(colspan: 2, align:center, strong(str(benders0_total))), 
    table.cell(colspan: 2, align:center, strong(str(benders1_total)))
  )
}