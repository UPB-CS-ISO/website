#import "common.typ": *

#section-cover([Extra], [how Linux finds the address of a name], layers: ("application",), note: [`nsswitch.conf`, \ `resolv.conf`])

#slide[
  == Bibliography
  for this section

  + #link("https://man7.org/linux/man-pages/man5/nsswitch.conf.5.html")[`man nsswitch.conf`]
  + #link("https://man7.org/linux/man-pages/man8/systemd-resolved.8.html")[`man systemd-resolved`]
  + #link("https://man7.org/linux/man-pages/man5/resolv.conf.5.html")[`man resolv.conf`]
]

// /etc/nsswitch.conf: where the C library looks for each kind of name
#let nss-lines = (
  "$ grep -E '^(passwd|group|hosts|services):' /etc/nsswitch.conf",
  (("db", "passwd:"), (none, "     files systemd")),
  (("db", "group:"), (none, "      files [SUCCESS=merge] systemd")),
  (
    ("db", "hosts:"), (none, "      "), ("files", "files"), (none, " "), ("me", "myhostname"), (none, " "), ("mdns", "mdns4_minimal"),
    (none, " "), ("nf", "[NOTFOUND=return]"), (none, " "), ("resolve", "resolve"), (none, " "), ("ua", "[!UNAVAIL=return]"), (none, " "),
    ("dns", "dns"),
  ),
  (("db", "services:"), (none, "   files")),
)

#slide[
  == `/etc/nsswitch.conf`
  the _Name Service Switch_: where to look for each kind of name

  #let steps = (
    (("db",), explain(
      [one line for each kind of name: *where* the C library looks, *in order*],
      ([`passwd:`], [the users: `/etc/passwd` (`files`), then `systemd`]),
      ([`group:`], [the groups of users, the same way]),
      ([`hosts:`], [the names of computers: the line used for `upb.ro`]),
      ([`services:`], [the names of the ports (`https` is `443`): `/etc/services`]),
    )),
    (("files", "me", "mdns", "resolve", "dns"), explain(
      [`hosts:` the places to ask, from left to right],
      ([`files`], [`/etc/hosts`]),
      ([`myhostname`], [the name of this computer, always known]),
      ([`mdns4_minimal`], [names that end in `.local`: asked in the local network (_multicast DNS_)]),
      ([`resolve`], [`systemd-resolved`]),
      ([`dns`], [the DNS server written in `/etc/resolv.conf`]),
    )),
    (("nf", "ua"), explain(
      [`[...]`: when to *stop* before the end of the line],
      ([`[NOTFOUND=return]`], [a `.local` name not found in the local network: stop, do not ask DNS]),
      ([`[!UNAVAIL=return]`], [`systemd-resolved` is running: trust its answer, stop; `dns` is used only if it is not running]),
    )),
  )
  #for (i, (keys, body)) in steps.enumerate() {
    only(i + 1)[
      #parts-terminal(nss-lines, hl: ((keys, ip-peach),), size: 0.85em)
      #body
    ]
  }
]

// who answers a name: the program, /etc/hosts, systemd-resolved, the DNS
// server; each one asks the next, and the file that configures it is shown
#let resolve-drawing(n, fork: false) = drawing(width: 470pt, height: if fork { 68pt } else if n >= 4 { 66pt } else { 46pt })[
  #let xs = (0pt, 123pt, 246pt, 369pt)
  #let boxes = (
    ("🦊", [program], [`ping`, Firefox, `ssh`]),
    ("📒", [`/etc/hosts`], [names written by hand]),
    ("🧭", [`systemd-resolved`], [`127.0.0.53`, remembers answers]),
    ("📖", [DNS server], if fork { [`1.1.1.1`, Cloudflare] } else { [`192.168.1.1`, the router] }),
  )
  // the boxes used on this step: on the fork, `systemd-resolved` is skipped
  #let used = if fork { (0, 1, 3) } else { range(n) }
  #let last = used.last()
  #for (i, (e, name, sub)) in boxes.enumerate() {
    let c = layer-colors.application
    let lit = i in used
    at(xs.at(i), 0pt, box(width: 100pt, height: 40pt, radius: 5pt, fill: if lit { c.fill } else { luma(248) }, stroke: if i == last { 1.8pt + hl } else { 1pt + if lit { c.stroke } else { luma(200) } }, align(center + horizon, stack(
      spacing: 3pt,
      text(size: 9pt, weight: "bold", fill: if lit { black } else { luma(170) })[#icon(e, size: 11pt) #name],
      text(size: 7.5pt, fill: if lit { black } else { luma(170) }, sub),
    ))))
    if i > 0 and lit and (i - 1) in used { draw-arrow((xs.at(i) - 21pt, 20pt), (xs.at(i) - 2pt, 20pt), color: hl, thickness: 1.4pt) }
  }
  // the fork: `/etc/resolv.conf` sends the programs straight to the DNS server
  #if fork {
    let st = 1.4pt + hl
    wire((173pt, 40pt), (173pt, 52pt), stroke: st)
    wire((173pt, 52pt), (419pt, 52pt), stroke: st)
    draw-arrow((419pt, 52pt), (419pt, 42pt), color: hl, thickness: 1.4pt)
    label(296pt, 61pt, box(fill: white, inset: (x: 2pt), text(size: 7.5pt, fill: hl)[or straight to the DNS server: `nameserver 1.1.1.1`, no `systemd-resolved`]))
  }
  #if n >= 4 and not fork {
    draw-arrow((419pt, 50pt), (50pt, 50pt), color: ok-color, thickness: 1.4pt)
    label(235pt, 60pt, text(size: 8pt, fill: ok-color)[`141.85.220.33` comes back to the program])
  }
]

#let nss = (
  "$ grep hosts /etc/nsswitch.conf",
  ((none, "hosts:      "), ("files", "files"), (none, " myhostname mdns4_minimal [NOTFOUND=return] "), ("resolve", "resolve"), (none, " [!UNAVAIL=return] "), ("dns", "dns")),
)
#let hosts-file = (
  "$ cat /etc/hosts",
  "# Loopback entries; do not change.",
  (("host", "127.0.0.1"), (none, "   localhost localhost.localdomain localhost4 localhost4.localdomain4")),
  (("host", "::1"), (none, "         localhost localhost.localdomain localhost6 localhost6.localdomain6")),
  "# 192.168.1.10 foo.example.org foo",
)
#let resolv-file = (
  "$ cat /etc/resolv.conf",
  "# This is /run/systemd/resolve/stub-resolv.conf managed by man:systemd-resolved(8).",
  "# Do not edit.",
  ((none, "nameserver "), ("ns", "127.0.0.53")),
)
// /etc/resolv.conf when NetworkManager writes it (no systemd-resolved)
#let resolv-direct = (
  "$ cat /etc/resolv.conf",
  "# Generated by NetworkManager",
  ((none, "nameserver "), ("ns2", "1.1.1.1")),
)
#slide[
  == Who Answers a Name?
  four places: each one asks the next, until one knows the answer

  #let steps = (
    (1, false, nss, ("files", "resolve", "dns"), explain(
      [a program does not talk to DNS itself: it asks the C library (`getaddrinfo()`), in this *order*],
      ([`files`], [`/etc/hosts`]),
      ([`resolve`], [`systemd-resolved`, the local service]),
      ([`dns`], [the DNS server in `/etc/resolv.conf`, if `systemd-resolved` is not running]),
    )),
    (2, false, hosts-file, ("host",), explain(
      [`/etc/hosts`: names written by hand, checked *first*],
      ([add], [a line `192.168.1.20 printer` (with `sudo`), then `ping printer` works]),
      ([💡], [a name written here never reaches DNS]),
    )),
    (4, false, resolv-file, ("ns",), explain(
      [`/etc/resolv.conf`: the DNS server the programs ask (written by `systemd-resolved`)],
      ([`127.0.0.53`], [the local `systemd-resolved`: it remembers the answers, and asks the DNS server of the card, the router (from *DHCP*)]),
    )),
    (3, true, resolv-direct, ("ns2",), explain(
      [🔀 *or*: no `systemd-resolved` (some systems, containers)],
      ([`1.1.1.1`], [a DNS server on the Internet (Cloudflare), written in `/etc/resolv.conf`: the programs ask it *directly*]),
    )),
  )
  #for (i, (n, fork, lines, keys, body)) in steps.enumerate() {
    only(i + 1)[
      #resolve-drawing(n, fork: fork)
      #parts-terminal(lines, hl: ((keys, ip-peach),), size: 0.85em)
      #body
    ]
  }
]
