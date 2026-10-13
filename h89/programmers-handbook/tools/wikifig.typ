// One picture from the book, alone on a page sized to it, for the wiki:
//   typst compile --root . --input kind=crt --input name=netcat-hdos tools/wikifig.typ out.png
// kind: crt (a captured screen), card (a command card with its examples)
#import "../lib.typ": *
#import "../prog.typ": *
#set page(width: auto, height: auto, margin: 0.12in, fill: white)
#set text(font: f-body, size: 9.6pt, fill: ink)
#set par(justify: true, leading: 0.52em, spacing: 0.95em)
#let kind = sys.inputs.at("kind", default: "crt")
#let name = sys.inputs.at("name", default: "netcat-hdos")
#{
  if kind == "crt" { block(width: 6.2in, crt(name, width: 6.2in)) }
  else if kind == "card" {
    block(width: 3.4in, {
      cmdcard("Get WiFi Status", dev: 0x70, cmd: 0xFA, tags: ("Stand-in WiFi",),
        lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [1 byte: 3, connected; 6, not])))
      [Whether the FujiNet is on its network.]
      examples("fuji.get_wifistatus")
    })
  }
}
