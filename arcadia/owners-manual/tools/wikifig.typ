// Render one picture of the book on its own, for the wiki edition.
//   typst compile --root . --font-path fonts --ignore-system-fonts \
//     --input name=back tools/wikifig.typ out.png
#import "../lib.typ": *
#import "../figs.typ": *
#let name = sys.inputs.at("name", default: "back")
#set page(width: 6.2in, height: auto, margin: 8pt, fill: white)
#set text(font: f-body, size: 10pt, fill: ink)
#set par(justify: false)
#wiki.update(true)
#{
  let ov(n, jobs, head) = fig(overlay(n, jobs, head: head))
  let figs = (back: fig-back, top: fig-top, inside: fig-inside,
    insert: fig-insert, rear: fig-rear, panel: fig-panel,
    controller: fig-controller,
    overlay: ov("FujiNet Config", ("Rename · Up a folder", "Select", "Info",
      "Page back", "Copy", "Page on", "WiFi · Filter", "Down", "Lobby",
      "Back · Delete", "Skip · Esc", "OK"), [Action: select]),
    window: align(center, {
      window-strip
      v(12pt)
      flow(
        nodebox([YOUR ARCADIA], sub: [reads], w: 1.15in), biarrow(w: 0.42in),
        nodebox([GAME CHIP], sub: [listens], w: 1.15in), biarrow(w: 0.42in),
        nodebox([NETWORK CHIP], sub: [fetches], w: 1.2in), biarrow(w: 0.42in),
        nodebox([THE WORLD], sub: [WiFi], w: 1.05in))
    }))
  figs.at(name)
}
