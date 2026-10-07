#import "common.typ": *

#section-cover([Network Configuration], [temporary and permanent, static and dynamic], layers: ("network",), note: [IP, mask, \ gateway])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.10 - _Introduction to Network Interface Configuration_
      - Section 9.11 - _Boot-Activated Network Configuration_
      - Section 9.13 - _Network Configuration Managers_
  + #uso-book
    - Section 11.6 - _Configurarea rețelei în Linux_
]

// the logos of the distributions (the images of lecture 01)
#let fedora-logo(height: 1em, baseline: 25%) = box(baseline: baseline, image("/src/01_intro/img/distributions/fedora.png", height: height))
#let ubuntu-logo(height: 1em) = box(baseline: 20%, image("/src/01_intro/img/distributions/ubuntu.png", height: height))
#let redhat-logo(height: 1em) = box(baseline: 20%, image("/src/01_intro/img/distributions/red-hat.svg", height: height))

// ---------------------------------------------------------------------------
// The four ways
// ---------------------------------------------------------------------------

#let way-c = (
  temp: (fill: rgb("fff3bf"), stroke: rgb("f08c00")),
  perm: (fill: ok-color.lighten(88%), stroke: ok-color),
)
#let way-head(e, title, sub) = align(center, stack(
  spacing: 3pt,
  text(size: 12pt, weight: "bold")[#icon(e, size: 13pt) #title],
  text(size: 8.5pt, fill: luma(90), sub),
))
#let way-card(c, body) = block(
  width: 100%,
  height: 54pt,
  inset: (x: 8pt, y: 6pt),
  radius: 5pt,
  fill: c.fill,
  stroke: 1pt + c.stroke,
  align(horizon, text(size: 9.5pt, body)),
)

#slide[
  == Four Ways to Configure
  the IP address, the mask and the gateway

  #grid(
    columns: (92pt, 1fr, 1fr),
    column-gutter: 8pt,
    row-gutter: 8pt,
    align: (right + horizon, center, center),
    [],
    way-head("⏳", [temporary], [until reboot or reconnect]),
    way-head("💾", [permanent], [saved, used at every boot]),
    text(size: 11pt)[*static* ✍️ \ #text(size: 8.5pt, fill: luma(90))[written by hand]],
    uncover("2-", way-card(way-c.temp)[`ip address add` \ `ip route add default via`]),
    uncover("3-", way-card(way-c.perm)[#fedora-logo(height: 1.6em) `nmcli connection modify` or a file \ #ubuntu-logo(height: 1.2em) _netplan_: `addresses`]),
    text(size: 11pt)[*dynamic* 🔄 \ #text(size: 8.5pt, fill: luma(90))[from a DHCP server]],
    uncover("4-", way-card(way-c.temp)[a DHCP client: \ `dhclient`]),
    uncover("5-", way-card(way-c.perm)[#fedora-logo(height: 1.6em) `ipv4.method auto` \ #ubuntu-logo(height: 1.2em) _netplan_: `dhcp4: true`]),
  )
  #v(0pt)
]

// ---------------------------------------------------------------------------
// The tools
// ---------------------------------------------------------------------------

// a box of the tools drawing: a name and a short explanation
#let tool(x, y, w, name, sub, c: (fill: luma(246), stroke: luma(150)), h: 34pt) = at(x, y, box(
  width: w,
  height: h,
  radius: 4pt,
  fill: c.fill,
  stroke: 1pt + c.stroke,
  align(center + horizon, stack(spacing: 2pt, text(size: 9pt, weight: "bold", name), text(size: 7pt, fill: luma(70), sub))),
))
#let down(x, y1, y2) = draw-arrow((x, y1), (x, y2), color: luma(110))

#let who-configures(permanent: false) = slide[
  == Who Configures the Network?

  #let app = layer-colors.application
  #let daemon = (fill: hl-bg, stroke: hl)
  #let file-c = (fill: rgb("fff3bf"), stroke: rgb("f08c00"))
  #v(10pt)
  #drawing(width: 470pt, height: 204pt)[
    // the kernel, at the bottom: it really sends and receives
    #tool(0pt, 168pt, 470pt, [Linux kernel], [the network cards, the IP addresses, the routes], c: (fill: luma(235), stroke: luma(110)), h: 30pt)

    // 1: ip, straight to the kernel
    #label(45pt, -6pt, text(size: 9pt, weight: "bold", fill: luma(90))[⏳ temporary])
    #tool(0pt, 20pt, 92pt, [`ip`], [talks directly to the kernel], c: app)
    #down(12pt, 56pt, 166pt)
    #tool(24pt, 76pt, 70pt, [`dhclient`], [asks a DHCP server], c: app)
    #down(59pt, 112pt, 166pt)
    // temporary | permanent
    #if permanent [#label(286pt, -6pt, text(size: 9pt, weight: "bold", fill: luma(90))[💾 permanent])]
    #place(top + left, line(start: (102pt, -10pt), end: (102pt, 160pt), stroke: (paint: luma(140), thickness: 1.2pt, dash: "dotted")))

    // 2: NetworkManager
    #if permanent [
      #label(205pt, 9pt, text(size: 8pt, weight: "bold", fill: luma(90))[#fedora-logo(height: 1.4em) #redhat-logo(height: 1.2em) #h(4pt) · #h(4pt) #ubuntu-logo(height: 1.1em) Desktop])
      #tool(115pt, 20pt, 85pt, [`nmcli`], [command line], c: app)
      #tool(210pt, 20pt, 85pt, [Settings], [graphical], c: app)
      #down(157pt, 56pt, 74pt)
      #down(252pt, 56pt, 74pt)
      #tool(115pt, 76pt, 180pt, [NetworkManager], [a service, always running: connects, asks DHCP], c: daemon)
      #tool(115pt, 120pt, 155pt, text(size: 7.5pt)[`/etc/NetworkManager/` \ `system-connections/`], [the saved connections], c: file-c, h: 36pt)
      #draw-arrow((192pt, 112pt), (192pt, 118pt), color: luma(110))
      #draw-arrow((284pt, 112pt), (284pt, 166pt), color: luma(110))
      // older RHEL versions keep the connections in another format
      #label(205pt, 207pt, text(size: 7.5pt, fill: luma(80))[RHEL 8 and older: `ifcfg-*` files in `/etc/sysconfig/network-scripts/`])
    ]

    // 3: netplan
    #if permanent [
      #label(400pt, 9pt, text(size: 8pt, weight: "bold", fill: luma(90))[#ubuntu-logo(height: 1.1em) Server])
      #tool(330pt, 20pt, 140pt, [`/etc/netplan/*.yaml`], [what we want], c: file-c)
      #down(400pt, 56pt, 74pt)
      #tool(330pt, 76pt, 140pt, [`netplan apply`], [translates the YAML file], c: app)
      #down(400pt, 112pt, 120pt)
      #tool(330pt, 122pt, 140pt, [systemd-networkd], [a service, or NetworkManager], c: daemon, h: 30pt)
      #down(400pt, 152pt, 166pt)
    ]
  ]
  #v(0pt)
]

#who-configures()

// ---------------------------------------------------------------------------
// Temporary
// ---------------------------------------------------------------------------

#let tmp-static = (
  "$ ip -br link",
  tab((17, 15, 18), (none, "lo"), (none, "UNKNOWN"), (none, "00:00:00:00:00:00")) + ((none, "<LOOPBACK,UP,LOWER_UP>"),),
  tab((17, 15, 18), ("dev", "enp0s31f6"), ("down", "DOWN"), (none, "8c:16:45:a2:3b:91")) + ((none, "<BROADCAST,MULTICAST>"),),
  tab((17, 15, 18), (none, "wlp2s0"), (none, "UP"), (none, "3c:a9:f4:5e:21:7b")) + ((none, "<BROADCAST,MULTICAST,UP,LOWER_UP>"),),
  "$ sudo ip -4 address flush dev enp0s31f6",
  "$ sudo ip address add 192.168.1.50/24 dev enp0s31f6",
  "$ sudo ip link set enp0s31f6 up",
  "$ sudo ip route add default via 192.168.1.1",
)
#let tmp-static-2 = (
  "$ ip -br address show enp0s31f6",
  tab((17, 15), (none, "enp0s31f6"), (none, "UP")) + (("addr", "192.168.1.50/24"),),
  "$ ip route",
  ((none, "default via "), ("gw", "192.168.1.1"), (none, " dev enp0s31f6")),
  ((none, "192.168.1.0/24 dev enp0s31f6 proto kernel scope link "), ("net", "src 192.168.1.50")),
)

// the steps of a shell: (lines shown, highlighted parts, explanation)
#let shell-steps(lines, steps, size: 0.9em) = for (i, (n, keys, body)) in steps.enumerate() {
  only(i + 1)[
    #parts-terminal(lines.slice(0, n), hl: ((keys, ip-peach),), size: size)
    #body
  ]
}

#slide[
  == Temporary, Static
  with the `ip` command: the IP address, the mask and the gateway

  #shell-steps(tmp-static, (
    (4, ("dev", "down"), explain[`ip -br link`: the network cards; we configure `enp0s31f6`, it is `DOWN`]),
    (5, (), explain(
      [`address flush`: delete the old addresses of the card, each `add` adds *one more* address],
      ([`-4`], [only the IPv4 addresses, the IPv6 ones (like the automatic `fe80::...`) stay]),
    )),
    (6, (), explain[`address add`: the *IP address* and the *mask*, `192.168.1.50/24` (`address del` deletes one)]),
    (7, (), explain[`link set ... up`: turn the card on]),
    (8, (), explain[`route add default via`: the *gateway* `192.168.1.1`, for all the other networks]),
  ))
]

#slide[
  == Temporary, Static
  check the configuration

  #shell-steps(tmp-static-2, (
    (2, ("addr",), explain[`ip -br address show`: check the IP address and the mask of the card]),
    (5, ("gw",), explain[`ip route`: check the routes: `default via` the gateway, the local network directly]),
    (5, (), explain(
      [⏳ *temporary*: it is only in the kernel, nothing is saved],
      ([reboot], [the configuration is lost]),
      ([NetworkManager], [may change it back when the card reconnects]),
    )),

    (5, (), explain(
      [🧰 older systems (and macOS, BSD) have *no* `ip`: the older `ifconfig` and `route` (Linux: the _net-tools_ package)],
      ([`ifconfig`], [`sudo ifconfig enp0s31f6 192.168.1.50 netmask 255.255.255.0 up`]),
      ([`route`], [`sudo route add default gw 192.168.1.1`]),
      ([check], [`ifconfig` shows the cards and their addresses, `route -n` shows the routes]),
    )),
  ))
]

#let tmp-dhcp = (
  "$ sudo dhclient -v enp0s31f6",
  ((none, "DHCP"), ("msg", "DISCOVER"), (none, " on enp0s31f6 to 255.255.255.255 port 67 interval 3"),),
  ((none, "DHCP"), ("msg", "OFFER"), (none, " of 192.168.1.105 from 192.168.1.1"),),
  ((none, "DHCP"), ("msg", "REQUEST"), (none, " for 192.168.1.105 on enp0s31f6 to 255.255.255.255 port 67"),),
  ((none, "DHCP"), ("msg", "ACK"), (none, " of 192.168.1.105 from 192.168.1.1"),),
  ((none, "bound to "), ("addr", "192.168.1.105"), (none, " -- renewal in "), ("lease", "41853 seconds"), (none, "."),),
  "$ ip -4 address show enp0s31f6",
  ((none, "2: enp0s31f6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP"),),
  ((none, "    inet 192.168.1.105/24 brd 192.168.1.255 scope global "), ("dyn", "dynamic"), (none, " enp0s31f6"),),
  ((none, "       "), ("lft", "valid_lft 86394sec"), (none, " preferred_lft 86394sec"),),
  "$ sudo dhclient -r enp0s31f6    # give the address back",
)

#slide[
  == Temporary, Dynamic
  ask a DHCP server, with a DHCP client

  #shell-steps(tmp-dhcp, (
    (6, ("msg",), explain[the four *DHCP messages*: discover, offer, request, acknowledge]),
    (6, ("addr", "lease"), explain(
      [the card *got* its configuration: IP address, mask, gateway, DNS],
      ([`192.168.1.105`], [the IP address, *leased* from the server]),
      ([`41853 seconds`], [when the client asks again, to keep it]),
    )),
    (10, ("dyn", "lft"), explain(
      [`ip` shows the lease too],
      ([`dynamic`], [the address came from DHCP]),
      ([`valid_lft`], [how long the address is still valid: the *lease* (here 24 hours); \ the client renews it at about half of the time]),
    )),
    (11, (), explain(
      [⏳ *temporary*: nothing is saved, the next boot does not ask again],
      ([`dhclient -r`], [give the address back to the server]),
      ([`dhclient`], [an older DHCP client, it may have to be installed; NetworkManager has its own]),
    )),
  ), size: 0.88em)
]

// ---------------------------------------------------------------------------
// Permanent
// ---------------------------------------------------------------------------

#let perm-static = (
  "$ sudo nmcli connection modify \"Wired connection 1\" \\",
  "    ipv4.method manual \\",
  "    ipv4.addresses 192.168.1.50/24 \\",
  "    ipv4.gateway 192.168.1.1 \\",
  "    ipv4.dns 1.1.1.1",
  "$ sudo nmcli connection up \"Wired connection 1\"",
)
#let perm-dhcp = (
  "$ sudo nmcli connection modify \"Wired connection 1\" \\",
  "    ipv4.method auto \\",
  "    ipv4.addresses \"\" \\",
  "    ipv4.gateway \"\" \\",
  "    ipv4.dns \"\"",
  "$ sudo nmcli connection up \"Wired connection 1\"",
)

#who-configures(permanent: true)

#slide[
  == Permanent on Fedora
  #place(top + right, dy: -12pt, fedora-logo(height: 22pt))
  NetworkManager saves the configuration in the *connection*

  #only(1)[
    #parts-terminal(perm-static, size: 1em)
    #explain(
      [✍️ *static*: `ipv4.method manual`],
      ([`ipv4.addresses`], [the IP address and the mask]),
      ([`ipv4.gateway`], [the gateway]),
      ([`ipv4.dns`], [the DNS server]),
    )
  ]
  #only(2)[
    #parts-terminal(perm-dhcp, size: 1em)
    #explain(
      [🔄 *dynamic*: `ipv4.method auto`, ask a DHCP server],
      ([`""`], [delete the static values]),
      ([`connection up`], [use the new configuration now]),
    )
  ]
  #place(bottom + left, text(size: 10pt)[💾 saved in `/etc/NetworkManager/system-connections/`, used at every boot])
]

#let nm-file = ```ini
[connection]
id=lab
type=ethernet
interface-name=enp0s31f6

[ipv4]
method=manual
address1=192.168.1.50/24
gateway=192.168.1.1
dns=1.1.1.1;
```
#let nm-file-lines = (
  "$ cd /etc/NetworkManager/system-connections/",
  "$ sudo nano lab.nmconnection",
  "$ sudo chmod 600 lab.nmconnection",
  "$ sudo nmcli connection reload",
  "$ nmcli -f NAME,TYPE,DEVICE connection show",
  tab((20, 10), (none, "NAME"), (none, "TYPE")) + ((none, "DEVICE"),),
  tab((20, 10), (none, "Wired connection 1"), (none, "ethernet")) + ((none, "enp0s31f6"),),
  tab((20, 10), ("new", "lab"), (none, "ethernet")) + ((none, "--"),),
  "$ sudo nmcli connection up lab",
)

#slide[
  == A New Connection, with a File
  on Fedora: write the connection by hand
  #place(top + right, dy: -12pt, fedora-logo(height: 22pt))

  // each step shows more of the shell
  #let steps = (
    (2, (), [📝 write the file: any name that ends in `.nmconnection`, `id` is the name of the connection]),
    (3, (), [🔒 only root may read it, NetworkManager *ignores* the file otherwise (it may hold a Wi-Fi password)]),
    (8, ("new",), [🔄 `reload`: NetworkManager reads the files again, the new connection `lab` is in the list]),
    (9, (), [▶️ use it now and at every boot; for DHCP: `method=auto`, without `address1`, `gateway` and `dns`]),
  )
  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1em)[
    #align(center, text(size: 9pt, weight: "bold")[`lab.nmconnection`])
    #v(-4pt)
    #text(size: 0.85em, nm-file)
  ][
    #for (i, (n, keys, body)) in steps.enumerate() {
      only(i + 1, parts-terminal(nm-file-lines.slice(0, n), hl: ((keys, ip-peach),), size: 0.8em))
    }
  ]
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #for (i, (n, keys, body)) in steps.enumerate() { only(i + 1, explain(body)) }
  ]))
]

#let netplan-static = ```yaml
network:
  version: 2
  ethernets:
    enp0s31f6:
      dhcp4: false
      addresses: [192.168.1.50/24]
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [1.1.1.1]
```
#let netplan-dhcp = ```yaml
network:
  version: 2
  ethernets:
    enp0s31f6:
      dhcp4: true
```

#slide[
  == Permanent on Ubuntu
  #place(top + right, dy: -10pt, ubuntu-logo(height: 20pt))
  _netplan_: a YAML file in `/etc/netplan/`

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #align(center, text(weight: "bold")[✍️ static])
    #netplan-static
  ][
    #uncover("2-")[
      #align(center, text(weight: "bold")[🔄 dynamic (DHCP)])
      #netplan-dhcp
    ]
    #uncover("3-")[
      ```terminal
      $ sudo netplan apply
      ```
      #text(size: 10pt)[- 💾 used now *and* at every boot]
      #text(size: 10pt)[- Ubuntu Desktop uses NetworkManager too: the `nmcli` commands work]
    ]
  ]
]
