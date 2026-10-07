// Render one picture of the book on its own, for the wiki edition.
//   typst compile --root . --font-path fonts --ignore-system-fonts \
//     --input kind=fig --input name=hero tools/wikifig.typ out.png
// kind=fig: a labelled figure from figs.typ; kind=tv: screens/<name>.txt;
// kind=chain: How It Works' chain, name = 1..4.
#import "../lib.typ": *
#import "../figs.typ": *
#let kind = sys.inputs.at("kind", default: "fig")
#let name = sys.inputs.at("name", default: "hero")
#set page(width: if kind == "tv" { auto } else { 5in }, height: auto,
  margin: 8pt, fill: white)
#set text(font: f-body, size: 9.2pt, fill: ink)
#set par(justify: false)
#band-col.update(orange)
#{
  if kind == "tv" { tvfile(name, size: 7pt) } else if kind == "chain" {
    let n = int(name)
    fig-chain(calc.min(n - 1, 2), back: n == 4, all: n == 4)
  } else {
    let figs = (hero: fig-hero, rear: fig-rear, top: fig-top, side: fig-side,
      inside: fig-inside, insert: fig-insert, jacks: fig-jacks,
      panel: fig-panel, memory: fig-memory)
    (figs.at(name))()
  }
}
