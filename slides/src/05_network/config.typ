#import "common.typ": *

#slide[
  = Connecting to the Internet #text(size: 10pt, weight: "regular")[\ _what a computer needs_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.5 - _The Default Gateway_
      - Section 9.14 - _Resolving Hostnames_
  + #tanenbaum
    - Section 7.1 - _DNS, the Domain Name System_
  + #uso-book
    - Section 11.2.2 - _Nume în Internet. DNS_
    - Section 11.5 - _Configurări de rețea_
]

#let need-card(e, title, body) = box(
  width: 140pt,
  height: 120pt,
  radius: 5pt,
  stroke: 1pt + accent,
  inset: 8pt,
  align(center, stack(spacing: 6pt, icon(e, size: 26pt), text(size: 11pt, weight: "bold", fill: accent, title), text(
    size: 9.5pt,
    body,
  ))),
)

#slide[
  == What Does a Computer Need?

  #align(center, grid(
    columns: 3,
    gutter: 14pt,
    need-card("🏠", [IP address + mask])[`192.168.1.105/24` \ talk to the devices of the *local network*],
    uncover("2-", need-card("🚪", [default gateway])[`192.168.1.1` \ talk to *other networks*: the Internet]),
    uncover("3-", need-card("📖", [DNS server])[`192.168.1.1` \ use *names* (`upb.ro`) instead of IP addresses]),
  ))

  #uncover("4-")[
    #note-box[💡 usually all of them come *automatically*, from the DHCP server of the home router]
  ]
]

#slide[
  == IP Address and Mask

  #reveal-terminal(before: none, lines: (3, 6), full: false)[```terminal
  $ ip -4 addr show wlp2s0 | grep -A1 inet
      inet 192.168.1.105/24 brd 192.168.1.255 scope global dynamic noprefixroute wlp2s0
         valid_lft 85934sec preferred_lft 85934sec
  $ ip -br -4 addr
  lo               UNKNOWN        127.0.0.1/8
  wlp2s0           UP             192.168.1.105/24
  ```]

  #uncover("2-")[
    #block[- `inet 192.168.1.105/24` - the IP address and the mask (`/24`)]
    #block[- `brd 192.168.1.255` - the broadcast address of the network]
    #block[- `dynamic`, `valid_lft` - received from DHCP, valid for 85934 more seconds]
  ]
]

#slide[
  == Default Gateway

  #reveal-terminal(before: none, lines: (2, 5), full: false)[```terminal
  $ ip route | grep default
  default via 192.168.1.1 dev wlp2s0 proto dhcp src 192.168.1.105 metric 600
  $ ping -c 1 8.8.8.8
  PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
  64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=12.4 ms
  ```]

  #uncover("2-")[
    #block[- `default via 192.168.1.1` - packets for other networks go to the router `192.168.1.1`]
  ]
]

#slide[
  == Without a Gateway

  #reveal-terminal(before: none, lines: (2, 5, 7), full: false)[```terminal
  $ ip route
  192.168.1.0/24 dev wlp2s0 proto kernel scope link src 192.168.1.105 metric 600
  $ ping -c 1 192.168.1.20
  PING 192.168.1.20 (192.168.1.20) 56(84) bytes of data.
  64 bytes from 192.168.1.20: icmp_seq=1 ttl=64 time=3.11 ms
  $ ping -c 1 8.8.8.8
  ping: connect: Network is unreachable
  ```]

  #uncover("4-")[
    #note-box[💡 without a gateway only the *local network* works]
  ]
]

// ---------------------------------------------------------------------------
// DNS
// ---------------------------------------------------------------------------

#slide[
  == DNS
  _Domain Name System_, the phone book of the Internet

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1em)[
    #drawing(width: 300pt, height: 195pt)[
      #let pc = (40pt, 120pt)
      #let dns = (250pt, 40pt)
      #let web = (250pt, 160pt)
      #host(..pc, "my PC", addr: "192.168.1.105", size: 30pt)
      #host(..dns, "DNS server", kind: "dns-server", addr: "192.168.1.1", size: 30pt, below: false)
      #host(..web, "upb.ro", kind: "server", addr: "141.85.220.33", size: 30pt)
      #uncover("2-")[
        #draw-arrow((70pt, 100pt), (215pt, 40pt), color: hl)
        #tag(120pt, 55pt, [what is the IP of `upb.ro`?], stroke: 0.8pt + hl, size: 7pt)
      ]
      #uncover("3-")[
        #draw-arrow((222pt, 58pt), (78pt, 116pt), color: ok-color)
        #tag(175pt, 100pt, [`141.85.220.33`], stroke: 0.8pt + ok-color, size: 7pt)
      ]
      #uncover("4-")[
        #draw-arrow((75pt, 135pt), (215pt, 160pt), color: accent)
        #tag(140pt, 165pt, [HTTP to `141.85.220.33`], size: 7pt)
      ]
    ]
  ][
    #set text(size: 11pt)
    - computers use *IP addresses*, people use *names*
    #uncover("2-")[#block[- the computer asks a *DNS server* for the address of a name]]
    #uncover("4-")[#block[- then it connects to the *IP address*]]
    #uncover("5-")[
      #block[- names are hierarchical, read from right to left: `www.upb.ro` is `www` in `upb` in `ro`]
    ]
  ]
]

#slide[
  == DNS in Linux

  #reveal-terminal(before: none, lines: (3, 6), full: false)[```terminal
  $ host upb.ro
  upb.ro has address 141.85.220.33
  upb.ro mail is handled by 0 ironport.upb.ro.
  $ resolvectl dns
  Global:
  Link 3 (wlp2s0): 192.168.1.1
  ```]

  #uncover("1-")[#block[- `host` asks the DNS server for the address of a name]]
  #uncover("2-")[#block[- the DNS server comes from DHCP, Fedora keeps it in `systemd-resolved`]]
]

#slide[
  == Where Do Names Come From?

  #reveal-terminal(before: none, lines: (4, 7), full: false)[```terminal
  $ grep -v '^#' /etc/resolv.conf
  nameserver 127.0.0.53
  options edns0 trust-ad
  search .
  $ grep -v '^#' /etc/hosts
  127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
  ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
  ```]

  #block[- programs ask `127.0.0.53`, the local `systemd-resolved`, which asks the real DNS server]
  #uncover("2-")[#block[- `/etc/hosts` is checked *before* DNS: add your own names here]]
]

#slide[
  == Without DNS?

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #text(fill: ok-color, weight: "bold")[✅ works: everything that uses an IP address]
    #set text(size: 10.5pt)
    - `ping 8.8.8.8`
    - `ssh student@192.168.1.20`
    - the local network, printers, shared folders by IP
    - names written in `/etc/hosts`
    - connections that were already open
  ][
    #uncover("2-")[
      #text(fill: bad-color, weight: "bold")[❌ fails: everything that uses a name]
      #set text(size: 10.5pt)
      - opening `upb.ro` in the browser
      - `ping google.com`, e-mail, `dnf upgrade`
      - websites opened by IP may not work: one server hosts many sites, HTTPS certificates are for *names*
    ]
  ]

  #uncover("3-")[
    ```terminal
    $ ping -c 1 8.8.8.8
    PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
    64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=12.4 ms
    $ ping -c 1 google.com
    ping: google.com: Temporary failure in name resolution
    ```
  ]
]

#let check-step(n, cmd, question) = uncover(str(n) + "-", block(below: 0.5em, grid(
  columns: (24pt, 150pt, 1fr),
  gutter: 6pt,
  align: horizon,
  box(width: 20pt, height: 20pt, radius: 50%, fill: accent, align(center + horizon, text(
    fill: white,
    weight: "bold",
    str(n),
  ))),
  raw(cmd),
  question,
)))

#slide[
  == No Internet?
  check from the bottom up

  #check-step(1, "ip -br addr", [do I have an *IP address*? (`169.254.x.x` or none: DHCP failed)])
  #check-step(2, "ip route", [do I have a *default gateway*?])
  #check-step(3, "ping 192.168.1.1", [can I reach the *gateway*? (the local network works)])
  #check-step(4, "ping 8.8.8.8", [can I reach the *Internet*? (routing works)])
  #check-step(5, "host upb.ro", [does *DNS* work?])

  #uncover("6-")[
    #note-box[💡 "Wi-Fi connected, but no Internet" is very often a *DNS* problem]
  ]
]
