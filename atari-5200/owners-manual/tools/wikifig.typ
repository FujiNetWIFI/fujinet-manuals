// Render one picture of the book on its own, for the wiki edition.
//   typst compile --root . --font-path fonts --ignore-system-fonts \
//     --input name=face tools/wikifig.typ out.png
#import "../lib.typ": *
#import "../figs.typ": *
#let name = sys.inputs.at("name", default: "face")
#set page(width: 4.6in, height: auto, margin: 8pt, fill: white)
#set text(font: f-body, size: 9pt, fill: ink)
#set par(justify: false)
#{
  let figs = (face: fig-face, top: fig-top, inside: fig-inside,
    insert: fig-insert, jacks: fig-jacks, controller: fig-controller,
    side: fig-side, overlay: () => align(center, overlay-card),
    window: () => align(center, {
      window-strip
      v(10pt)
      flow(
        nodebox([YOUR 5200], sub: [reads], w: 0.8in), biarrow(w: 0.32in),
        nodebox([GAME CHIP], sub: [listens], w: 0.8in), biarrow(w: 0.32in),
        nodebox([NETWORK CHIP], sub: [fetches], w: 0.85in), biarrow(w: 0.32in),
        nodebox([THE WORLD], sub: [WiFi], w: 0.75in))
    }))
  (figs.at(name))()
}
