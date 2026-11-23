# Lab 09 (Network Infrastructure): checklist for the lab room

The First Steps of lab 09 fit in 100 minutes only if the lab computers are ready **before** the students arrive:
no package to install and no image to build. Everything below is for the lab admin and the teaching assistants.

## 1. One day before (admin, on every lab computer)

- [ ] **Packages installed**:

  ```bash
  sudo dnf install -y podman tcpdump traceroute bind-utils ipcalc curl
  podman --version; tcpdump --version; traceroute --version; host 2>&1 | head -1; ipcalc --version
  ```

- [ ] **The image `lab09` is in the storage of `root`** (the students run `sudo podman`). Pull from Docker Hub **once**,
  on a single computer, then copy the archive to the others: Docker Hub allows 100 anonymous pulls every 6 hours for
  each public address, and the whole lab goes out through one address (NAT).

  On one computer:

  ```bash
  mkdir -p /tmp/lab09 && cd /tmp/lab09
  cat > Containerfile << 'END'
  FROM docker.io/library/debian:trixie-slim
  RUN apt-get update && apt-get install -y --no-install-recommends iproute2 iputils-ping bind9-host traceroute \
          curl ca-certificates python3 isc-dhcp-client dnsmasq-base && rm -rf /var/lib/apt/lists/*
  END
  sudo podman build -t lab09 .
  sudo podman save -m -o /tmp/lab09.tar localhost/lab09:latest docker.io/library/debian:trixie-slim
  ```

  On every other computer (copy `/tmp/lab09.tar` there first):

  ```bash
  sudo podman load -i /tmp/lab09.tar
  ```

- [ ] `sudo podman images` lists `localhost/lab09` (`latest`) and `docker.io/library/debian` (`trixie-slim`) on
  **every** computer (this is the Check of exercise 1).
- [ ] The `student` account can run `sudo` (the lab uses `sudo podman`, `sudo ss -p` and `sudo tcpdump`).
- [ ] The containers of the lab are not left over from a test: `sudo podman ps -a` prints only its header.

## 2. One day before (admin, the network of the room)

Run these on two lab computers, as `student`. Each line names the exercise that needs it.

- [ ] The card is up and gets its address from **DHCP**: `nmcli -f DHCP4 device show <IF>` prints
  `dhcp_lease_time` and `dhcp_server_identifier` (exercise 8; with static addresses, tell the TAs: the Check differs).
- [ ] `ping -c 2 8.8.8.8` gets replies: ICMP goes out of the faculty (exercises 4, 9, 12, 13).
- [ ] Two lab computers ping each other, and `ip neigh` shows the MAC address of the other one (exercise 4).
- [ ] `traceroute -n 8.8.8.8` shows at least line `1`, the gateway (exercise 6; `* * *` after it is fine).
- [ ] `host upb.ro` and `host 8.8.8.8` answer (exercise 7).
- [ ] `curl -s https://ifconfig.me` prints the public address (exercises 3 and 9).
- [ ] `curl -I https://upb.ro` prints a line that starts with `HTTP` (exercise 13 and the No Internet? checks).
- [ ] **Rehearsal of the containers** (exercises 9 - 12), on one computer, then clean up:

  ```bash
  sudo podman run -d --name pc1 --hostname pc1 --ip 10.88.0.11 lab09 sleep infinity
  sudo podman exec pc1 ping -c 1 8.8.8.8
  sudo podman exec pc1 curl -s https://ifconfig.me; echo
  sudo podman run -d --name dhcp --hostname dhcp --ip 10.88.0.10 --cap-add NET_ADMIN,NET_RAW lab09 \
      dnsmasq -d --conf-file=/dev/null --user=root --no-ping --dhcp-range=10.88.0.200,10.88.0.209,10m \
      --dhcp-option=option:router,10.88.0.1
  sudo podman run -d --name client --hostname client --ip 10.88.0.12 --cap-add NET_ADMIN,NET_RAW lab09 sleep infinity
  sudo podman exec client timeout 30 dhclient -v eth0      # must end with "bound to 10.88.0.20x"
  sudo timeout 10 tcpdump -i podman0 -n -c 2 icmp & sleep 1; sudo podman exec pc1 ping -c 1 8.8.8.8; wait
  sudo podman rm -f -t 0 pc1 dhcp client
  ```

- [ ] **Write down the real values of the room** for the TAs, since the lab text uses `10.41.1.0/24` as an example:
  the name of the card, the network and the mask, the gateway, the DNS server, the lease time and the public address.

  | Value          | Example in the lab | This room |
  | -------------- | ------------------ | --------- |
  | card           | `enp3s0`           |           |
  | address / mask | `10.41.1.27/24`    |           |
  | gateway        | `10.41.1.1`        |           |
  | DNS server     | `10.41.1.1`        |           |
  | lease time     | `86400`            |           |
  | public address | `141.85.227.12`    |           |

## 3. At the start of the lab (TA, 5 minutes)

- [ ] Write the real values of the room (the table above) on the board.
- [ ] Tell the students to work in **pairs** for exercise 4 (each one pings the other), and to keep **two terminals**
  open from exercise 11 on.
- [ ] Remind the rule: only **look** at the network settings of the computer; no `nmcli` changes, no `dhclient` on the
  computer itself, `dhclient` only in the container `client`.

## 4. During the lab (TA): the time budget

About 85 - 90 minutes of exercises, plus 5 minutes of wrap-up questions. Exercise 11 (DHCP) varies most.

| Exercise                | Minutes | A group on time is here at |
| ----------------------- | ------- | -------------------------- |
| 1. The practice tree    | 4       | minute 4                   |
| 2. Your network cards   | 6       | minute 10                  |
| 3. Your address         | 9       | minute 19                  |
| 4. Is anybody there?    | 7       | minute 26                  |
| 5. Which way?           | 6       | minute 32                  |
| 6. The routers          | 4       | minute 36                  |
| 7. Names and addresses  | 5       | minute 41                  |
| 8. What DHCP gave you   | 5       | minute 46                  |
| 9. Containers           | 10      | minute 56                  |
| 10. Who is listening?   | 8       | minute 64                  |
| 11. DHCP in a container | 12      | minute 76                  |
| 12. Watch the packets   | 7       | minute 83                  |
| 13. Recap               | 6       | minute 89                  |
| Wrap-up questions       | 5       | minute 94                  |

- [ ] At **minute 50**, a group that has not started exercise 9 skips exercise 6 (`traceroute`; exercises 19 and 20 at
  home cover it), and does only step 1 of exercise 12.
- [ ] If the image is missing on a computer, do **not** build it during the lab: the student pairs with a colleague.

## 5. After each group (TA, before the next group)

- [ ] Delete the containers of the students on every computer (keep the image):

  ```bash
  sudo podman rm -f -t 0 pc1 web dhcp client lost 2> /dev/null
  sudo rm -f /tmp/*.pcap
  sudo podman images      # lab09 must still be there
  ```

  Otherwise the next group gets `the container name "pc1" is already in use`.
