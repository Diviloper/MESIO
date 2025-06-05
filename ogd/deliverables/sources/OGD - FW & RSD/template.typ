// The project function defines how your document looks.
// It takes your content and some metadata and formats it.
// Go ahead and customize it to your liking!
#let project(
  title: "",
  header_title: none,
  authors: (),
  subject: "",
  degree: "Master in Statistics and Operative Research",
  university: "Universitat Politècnica de Catalunya",
  faculty: "Facultat de Matemàtiques i Estadística",
  outlines: (),
  use-codly: true,
  body
) = {
  // Fonts
  set text(font: "New Computer Modern")
  show raw: set text(font: ("JetBrains Mono", "Source Code Pro"))

  // Page config  
  set page(paper: "a4")
  set heading(numbering: "1.")
  set par(
    first-line-indent: 1em,
    justify: true,
  )


  // Title page.
  align(center, text(17pt, degree))
  
  align(center, text(17pt, smallcaps(subject)))
  
  v(4cm)
  
  align(center, text(26pt)[
    *#title*
  ])

  let before_spacing = 4 - calc.max(0, authors.len() - 4)
  let after_spacing = 5 - calc.min(5, authors.len())
  
  v(1cm * before_spacing)

  authors.map(a => align(center, text(17pt, style: "italic")[#a])).join()
  
  v(1cm + 1cm * after_spacing)
  
  align(center, text(17pt, smallcaps(university)))
  
  align(center, text(17pt, faculty))
  
  pagebreak()

  // Outlines
  
  outline()
  outlines.map(out => outline(title: out.title, target: figure.where(kind: out.target))).join()

  pagebreak()

  
  // Content page config
  
  set page(
    header: grid(
      columns: (auto, 1fr),
      align: (left, right),
      column-gutter: 5pt,
      
      par(
        justify: false,
        text(fill: luma(50%), if header_title != none {header_title} else {title}, )
      ),
      par(
        justify: false,
        text(fill: luma(50%), authors.join(", ", last: " and "))
      ),
    ),
    numbering: "1"
  )
  counter(page).update(1)
  set enum(numbering: "1)")  

  if use-codly {
    import "@preview/codly:1.3.0": *
    import "@preview/codly-languages:0.1.1": *
    show: codly-init
    codly(
      languages: codly-languages,
      zebra-fill: luma(98%),
      breakable: true,
      stroke: 1pt + luma(75%),
      number-align: right + horizon,
    )
    body
  } else {
    show raw.where(block: true): it => [
      #let nlines = it.lines.len()
      #table(
        columns: (auto, auto), 
        align: (right, left), 
        inset: 0.0em, 
        gutter: 0.5em, 
        stroke: none,
        ..it.lines.enumerate().map(((i, line)) => (math.mono(text(gray)[#(i + 1)]), line)).flatten()
      )
    ]
    body
  }

}