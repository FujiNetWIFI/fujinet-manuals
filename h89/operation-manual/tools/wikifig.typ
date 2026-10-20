// One picture from the book, alone on a page sized to it, for the wiki:
//   typst compile --root . --input kind=crt --input name=hosts tools/wikifig.typ out.png
// kind: crt (a captured screen), fig (a drawing from figs.typ)
#import "../lib.typ": *
#import "../figs.typ": card, jumpers, sockets, portmap, blocks
#set page(width: auto, height: auto, margin: 0.12in, fill: white)
#set text(font: f-body, size: 9.6pt, fill: ink)
#let kind = sys.inputs.at("kind", default: "crt")
#let name = sys.inputs.at("name", default: "hosts")
#{
  if kind == "crt" { block(width: 6.2in, crt(name, width: 6.2in)) }
  else if name == "card" { card(s: 0.0083in) }
  else if name == "jumpers" { jumpers() }
  else if name == "sockets" { sockets() }
  else if name == "portmap" { portmap() }
  else if name == "blocks" { blocks() }
}
