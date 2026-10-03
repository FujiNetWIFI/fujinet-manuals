#!/usr/bin/env python3
"""build_wxr.py -- build/<platform>.json -> wordpress/ (for fujinet.online).

usage: build_wxr.py [--media-base URL] [--site https://fujinet.online]

Writes
  wordpress/mule-players-guide.wxr   WordPress eXtended RSS 1.2: a parent page
                                     ("M.U.L.E. Player's Guide") and a child page
                                     per edition, in Gutenberg block HTML, plus an
                                     attachment item for every picture
  wordpress/images.zip               the pictures, flat names
  wordpress/images/                  the same, unzipped

Tools > Import > WordPress, with "Download and import file attachments"
ticked, fetches each picture from --media-base and rewrites the pages to
point at the copy in the Media Library. So before importing, the pictures
must be reachable at --media-base: unzip images.zip there (any web host),
or upload them to the Media Library first and pass its folder as
--media-base (then untick the attachment download). README.md has the steps.
"""
import argparse
import html
import os
import shutil
import zipfile
from datetime import datetime, timezone

from common import (ROOT, GUIDE, GUIDE_SLUG, editions, chapters, images, flat_name,
                    md_inline_html as mi, page_title, slug, alt_text)

OUT = os.path.join(ROOT, "wordpress")
PARENT_ID = 9100


def blk(name, inner, attrs=None):
    a = "" if not attrs else " " + attrs
    return f"<!-- wp:{name}{a} -->\n{inner}\n<!-- /wp:{name} -->"


def para(s):
    return blk("paragraph", f"<p>{mi(s)}</p>")


def heading(s, level=2):
    return blk("heading", f'<h{level} class="wp-block-heading">{mi(s)}</h{level}>',
               None if level == 2 else f'{{"level":{level}}}')


def lst(items, ordered=False):
    tag = "ol" if ordered else "ul"
    lis = "".join(blk("list-item", f"<li>{mi(x)}</li>") for x in items)
    return blk("list", f'<{tag} class="wp-block-list">{lis}</{tag}>', '{"ordered":true}' if ordered else None)


class Page:
    def __init__(self, base):
        self.base = base

    def url(self, path):
        return self.base + flat_name(path)

    def image(self, path, caption="", alt=None):
        cap = f'<figcaption class="wp-element-caption">{mi(caption)}</figcaption>' if caption else ""
        return blk("image", f'<figure class="wp-block-image size-full"><img src="{self.url(path)}" '
                            f'alt="{html.escape(alt or alt_text(path))}"/>{cap}</figure>',
                   '{"sizeSlug":"full","linkDestination":"none"}')

    def cell(self, c, th=False):
        tag = "th" if th else "td"
        if isinstance(c, dict):
            return f'<{tag}><img src="{self.url(c["img"])}" alt="{alt_text(c["img"])}" width="48"/></{tag}>'
        return f"<{tag}>{mi(c)}</{tag}>"

    def table(self, b):
        head = "" if b.get("kv") else (
            "<thead><tr>" + "".join(self.cell(h, True) for h in b["head"]) + "</tr></thead>")
        body = "<tbody>" + "".join("<tr>" + "".join(self.cell(c) for c in r) + "</tr>" for r in b["rows"]) + "</tbody>"
        return blk("table", f'<figure class="wp-block-table"><table>{head}{body}</table></figure>')

    def render(self, b):
        t = b["t"]
        if t == "p":
            return para(b["text"])
        if t == "h":
            return heading(b["text"], 3)
        if t == "list":
            return lst(b["items"], b["ordered"])
        if t == "note":
            return blk("quote", f'<blockquote class="wp-block-quote">{para(b["text"])}</blockquote>')
        if t == "step":
            out = [heading(f"{b['n']}. {b['title']}", 4)]
            if b.get("img"):
                out.append(self.image(b["img"]))
            if b.get("alt"):
                out.append(self.image(b["alt"]["img"], f"{b['alt']['label']} screen"))
            if b.get("lead"):
                out.append(para(f"**{b['lead']}**"))
            if b.get("text"):
                out.append(para(b["text"]))
            return "\n\n".join(out)
        if t == "shot":
            out = [self.image(b["img"], b.get("caption", ""))]
            if b.get("alt"):
                out.append(self.image(b["alt"]["img"], f"{b['alt']['label']} screen"))
            return "\n\n".join(out)
        if t == "shots":
            out = [self.image(i["img"]) for i in b["imgs"]]
            out.append(para(f"*{b['caption']}*"))
            return "\n\n".join(out)
        if t == "tips":
            return heading("Tips on the Tournament Game", 3) + "\n\n" + lst(b["items"])
        if t == "qa":
            return "\n\n".join(para(f"**Q: {x['q']}**") + "\n\n" + para(f"A: {x['a']}") for x in b["items"])
        if t == "table":
            return self.table(b)
        if t == "event":
            return "\n\n".join([heading(b["name"], 4),
                                para(f"*Can happen up to {b['times']} times a game.*"),
                                blk("quote", f'<blockquote class="wp-block-quote">{para("“" + b["text"] + "”")}</blockquote>'),
                                para(b["effect"])])
        raise SystemExit(f"unknown block {t}")

    def content(self, ed):
        out = []
        if ed.get("cover"):
            out.append(self.image(ed["cover"], alt="M.U.L.E. title screen"))
        out.append(para(f"*How to load and play The FujiNet Multiplayer M.U.L.E. on the {ed['long']}.*"))
        chs = chapters(ed)
        out.append(heading("Contents", 2))
        out.append(lst([c["title"] for c in chs], ordered=True))
        for c in chs:
            out.append(heading(c["title"], 2))
            out += [self.render(b) for b in c["blocks"]]
        out.append(para("*M.U.L.E. was designed by Ozark Softscape and published by Electronic Arts in 1983. "
                        "The FujiNet Multiplayer Edition is a network version made by the FujiNet community; "
                        "its pictures are converted from the 1983 Atari disk and remain the property of their owners.*"))
        return "\n\n".join(out)


def cdata(s):
    return "<![CDATA[" + s.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def item(title, pid, name, ptype, content="", parent=0, order=0, link="", attach_url=None, date=""):
    x = [
        "\t<item>",
        f"\t\t<title>{cdata(title)}</title>",
        f"\t\t<link>{html.escape(link)}</link>",
        "\t\t<dc:creator><![CDATA[fujinet]]></dc:creator>",
        f'\t\t<guid isPermaLink="false">{html.escape(attach_url or link)}</guid>',
        "\t\t<description></description>",
        f"\t\t<content:encoded>{cdata(content)}</content:encoded>",
        "\t\t<excerpt:encoded><![CDATA[]]></excerpt:encoded>",
        f"\t\t<wp:post_id>{pid}</wp:post_id>",
        f"\t\t<wp:post_date>{cdata(date)}</wp:post_date>",
        f"\t\t<wp:post_date_gmt>{cdata(date)}</wp:post_date_gmt>",
        "\t\t<wp:comment_status><![CDATA[closed]]></wp:comment_status>",
        "\t\t<wp:ping_status><![CDATA[closed]]></wp:ping_status>",
        f"\t\t<wp:post_name>{cdata(name)}</wp:post_name>",
        f"\t\t<wp:status>{cdata('inherit' if ptype == 'attachment' else 'publish')}</wp:status>",
        f"\t\t<wp:post_parent>{parent}</wp:post_parent>",
        f"\t\t<wp:menu_order>{order}</wp:menu_order>",
        f"\t\t<wp:post_type>{cdata(ptype)}</wp:post_type>",
        "\t\t<wp:post_password><![CDATA[]]></wp:post_password>",
        "\t\t<wp:is_sticky>0</wp:is_sticky>",
    ]
    if attach_url:
        x.append(f"\t\t<wp:attachment_url>{cdata(attach_url)}</wp:attachment_url>")
    x.append("\t</item>")
    return "\n".join(x)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--site", default="https://fujinet.online")
    ap.add_argument("--media-base", default="https://apps.irata.online/mule/manual/images/")
    a = ap.parse_args()
    base = a.media_base if a.media_base.endswith("/") else a.media_base + "/"
    site = a.site.rstrip("/")

    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(os.path.join(OUT, "images"))
    date = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
    pg = Page(base)
    eds = editions()

    items, attach = [], []
    pid_att = 9500
    parent_link = f"{site}/{GUIDE_SLUG}/"
    intro = [para("*The player's guide to The FujiNet Multiplayer M.U.L.E., in an edition for each machine it runs on.*"),
             para("M.U.L.E. is played over the Internet with FujiNet. Up to four colonists share a room. "
                  "Right now there is one room, **Planet IRATA**, and more will be added. Each guide below covers "
                  "the same game, with its own machine's pictures, controls and loading steps."),
             blk("list", '<ul class="wp-block-list">' + "".join(
                 blk("list-item", f'<li><a href="/{GUIDE_SLUG}/{slug(ed)}/">{html.escape(ed["name"])}</a> '
                                  f'({html.escape(ed["long"])})</li>') for ed in eds) + "</ul>")]
    items.append(item(GUIDE, PARENT_ID, GUIDE_SLUG, "page", "\n\n".join(intro), link=parent_link, date=date))

    seen = {}
    for i, ed in enumerate(eds):
        pid = PARENT_ID + 1 + i
        link = f"{parent_link}{slug(ed)}/"
        items.append(item(page_title(ed), pid, slug(ed), "page", pg.content(ed), parent=PARENT_ID,
                          order=i + 1, link=link, date=date))
        for p in images(ed):
            fn = flat_name(p)
            if fn in seen:
                continue
            seen[fn] = True
            shutil.copy(os.path.join(ROOT, p), os.path.join(OUT, "images", fn))
            pid_att += 1
            attach.append(item(fn[:-4], pid_att, fn[:-4], "attachment", parent=pid,
                               link=base + fn, attach_url=base + fn, date=date))

    head = f"""<?xml version="1.0" encoding="UTF-8" ?>
<!-- WordPress eXtended RSS for the M.U.L.E. Player's Guide. Import with Tools > Import > WordPress. -->
<rss version="2.0"
	xmlns:excerpt="http://wordpress.org/export/1.2/excerpt/"
	xmlns:content="http://purl.org/rss/1.0/modules/content/"
	xmlns:wfw="http://wellformedweb.org/CommentAPI/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:wp="http://wordpress.org/export/1.2/"
>
<channel>
	<title>FujiNet</title>
	<link>{site}</link>
	<description>{html.escape(GUIDE)}</description>
	<pubDate>{datetime.now(timezone.utc).strftime('%a, %d %b %Y %H:%M:%S +0000')}</pubDate>
	<language>en-US</language>
	<wp:wxr_version>1.2</wp:wxr_version>
	<wp:base_site_url>{site}</wp:base_site_url>
	<wp:base_blog_url>{site}</wp:base_blog_url>
	<wp:author><wp:author_id>1</wp:author_id><wp:author_login><![CDATA[fujinet]]></wp:author_login><wp:author_email><![CDATA[]]></wp:author_email><wp:author_display_name><![CDATA[FujiNet]]></wp:author_display_name><wp:author_first_name><![CDATA[]]></wp:author_first_name><wp:author_last_name><![CDATA[]]></wp:author_last_name></wp:author>
"""
    with open(os.path.join(OUT, "mule-players-guide.wxr"), "w") as f:
        f.write(head)
        f.write("\n".join(items + attach))   # the importer rewrites image URLs once all are in
        f.write("\n</channel>\n</rss>\n")
    with zipfile.ZipFile(os.path.join(OUT, "images.zip"), "w", zipfile.ZIP_DEFLATED) as z:
        for fn in sorted(seen):
            z.write(os.path.join(OUT, "images", fn), fn)
    print(f"wordpress: {len(eds) + 1} pages, {len(seen)} attachments, media base {base}")


if __name__ == "__main__":
    main()
