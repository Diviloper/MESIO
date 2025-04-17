#let global_config(content) = {
  set text(font: "New Computer Modern")
  set heading(numbering: "1.")

  set page(paper: "a4")

  set par(
  first-line-indent: 1em,
  justify: true,
)

  show raw: set text(font: "JetBrains Mono")
  
  content
}

#let content_config(content) = {
  set page(
    header: grid(
      columns: (1fr, 1fr),
      align: (left, right),
      
      text(fill: luma(50%), "Benders' Decomposition"),
      text(fill: luma(50%), "Víctor Diví i Cuesta")
    ),
    numbering: "1"
  )

  set enum(numbering: "a)")

  counter(page).update(1)
  content
}

