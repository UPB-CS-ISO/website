# 05. Utilizatori și permisiuni

În laboratorul 4 ați aflat ce face shell-ul cu o linie de comandă și cum pornește programele și le trimite semnale. În
acest laborator aflați **sub ce utilizator** rulează aceste programe. Vă întâlniți cu **utilizatorii** și cu
**grupurile** sistemului, aflați unde sunt păstrați, `/etc/passwd`, `/etc/group` și `/etc/shadow`, și cum îi căutați cu
`getent`. Rulați comenzi ca `root` cu `sudo`, vedeți cum verifică sistemul o **parolă** fără să o păstreze vreodată și
creați utilizatori noi. Apoi decideți cine vă poate citi, modifica și rula fișierele, cu `chmod`, `chown` și `umask`. La
final întâlniți **permisiunile speciale**: bitul `setuid`, datorită căruia `passwd` vă poate schimba parola, bitul
`setgid` pentru directoarele partajate și **bitul sticky** al lui `/tmp`.

Ideea cea mai importantă a laboratorului este că kernelul nu cunoaște niciun nume, ci doar **numere**. Fiecare proces
poartă numărul utilizatorului său (**UID**-ul) și numerele grupurilor sale (**GID**-urile): **eticheta procesului**.
Fiecare fișier păstrează numărul **proprietarului**, numărul **grupului** și trei seturi de **permisiuni**: pentru
proprietar, pentru grup și pentru toți ceilalți. De fiecare dată când un proces deschide un fișier, kernelul compară
eticheta procesului cu proprietarul și cu grupul fișierului, alege **unul** dintre cele trei seturi și verifică dacă
permite ce cere procesul.

## Obiective {/* #objectives */}

- Să înțelegeți ce sunt un **utilizator** și un **grup**, pentru oameni și pentru kernel: un **UID** și un **GID**
- Să aflați cine sunteți cu `whoami`, `id` și `groups` și sub ce utilizator rulează fiecare proces cu `ps`
- Să aflați unde se păstrează utilizatorii și grupurile: `/etc/passwd`, `/etc/group` și `/etc/shadow`
- Să căutați utilizatori și grupuri cu `getent`
- Să rulați comenzi ca `root` sau ca alt utilizator, cu `sudo` și `su`, și să evitați **capcana redirectării** cu `tee`
- Să înțelegeți cum păstrează `/etc/shadow` parolele sub formă de **hash-uri** cu **salt** și cum se verifică o parolă
- Să creați, să modificați și să ștergeți utilizatori și grupuri cu `useradd`, `passwd`, `usermod`, `groupadd`, `gpasswd`
  și `userdel`
- Să înțelegeți ce se întâmplă când vă **autentificați** și de ce un grup nou cere o nouă autentificare
- Să citiți **permisiunile** unui fișier cu `ls -l` și `stat` și să înțelegeți ce înseamnă `r`, `w` și `x` pentru
  fișiere și pentru directoare
- Să schimbați permisiunile cu `chmod` (cu litere și cu numere), proprietarul cu `chown` și `chgrp`, iar permisiunile
  implicite cu `umask`
- Să folosiți **permisiunile speciale**: `setuid`, `setgid` și **bitul sticky**
- Să înțelegeți de ce nu vă puteți baza pe **prompt** ca să aflați cine sunteți

## Resurse {/* #resources */}

1. _[Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici, Utilizarea Sistemelor de
   Operare, Printech 2021](https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf)_
   - Capitolul 5 - _Utilizatori_
   - Capitolul 9 - _Pornirea sistemului_, secțiunea 9.6.1
2. _Brian Ward, How LINUX Works, 3rd Edition, No Starch Press, 2021_
   - Capitolul 2 - _Basic Commands and Directory Hierarchy_, secțiunile 2.17 și 2.20
   - Capitolul 7 - _System Configuration: Logging, System Time, Batch Jobs, and Users_, secțiunile 7.3, 7.4, 7.9 și 7.10
3. Slide-urile cursului: [05. Utilizatori](/docs/lectures/05)
4. Paginile de manual: `man 5 passwd`, `man 5 shadow`, `man 5 group`, `man id`, `man getent`,
   `man sudo`, `man su`, `man useradd`, `man usermod`, `man userdel`, `man gpasswd`, `man chage`, `man chmod`,
   `man chown`, `man chgrp`, `man stat`, `man login.defs`, `man openssl-passwd`, `man 5 proc` și `man bash` (căutați
   `umask` și `PROMPTING`)

## Fedora și Ubuntu {/* #fedora-and-ubuntu */}

Calculatoarele din laborator rulează **Fedora**, cu managerul de ferestre **Sway**, și toate exemplele din acest
laborator provin de pe ele. Acasă puteți folosi Fedora sau **Ubuntu**: toate comenzile din laborator merg pe amândouă,
însă unele nume, valori implicite și rezultate diferă. Când un exemplu sau o verificare nu se potrivește cu ce vedeți
pe Ubuntu, căutați întâi în acest tabel:

|                                                                 | Fedora                               | Ubuntu                                                 |
| --------------------------------------------------------------- | ------------------------------------ | ------------------------------------------------------ |
| promptul                                                        | `[student@fedora ~]$`                | `student@ubuntu:~$`, colorat                           |
| grupul **administratorilor**, cei care pot folosi `sudo`        | `wheel`, GID `10`                    | `sudo`, GID `27` (sunteți și în `adm`, `cdrom`, ...)   |
| `.` de după permisiuni în `ls -l`, `context=` în `id`           | afișate: ignorați-le în laborator    | nu apar                                                |
| shell-ul unui utilizator nou creat cu `useradd`                 | `/bin/bash`                          | `/bin/sh`, dacă nu dați `-s /bin/bash`                 |
| un director nou al utilizatorului                               | `drwx------` (`700`)                 | `drwxr-x---` (`750`)                                   |
| `/etc/shadow`                                                   | `---------- root root`               | `-rw-r----- root shadow`                               |
| `/usr/bin/sudo`                                                 | `---s--x--x` (`4111`)                | `-rwsr-xr-x` (`4755`)                                  |
| o parolă încă nesetată sau blocată cu `passwd -l`               | `!!` în fața hash-ului sau singur    | `!` în fața hash-ului sau singur                       |
| `umask`-ul unui utilizator obișnuit                             | `0022`                               | `0002`                                                 |
| instalarea unui pachet                                          | `sudo dnf install <PACKAGE>`         | `sudo apt install <PACKAGE>`                           |

Ubuntu 25.10 și versiunile mai noi folosesc `sudo-rs`, o versiune nouă a lui `sudo`: unele dintre mesajele lui diferă
de cele din acest laborator. Utilizatorul vostru poate avea și alt nume decât `student`: folosiți numele vostru oriunde
laboratorul scrie `student`.

## Utilizatori {/* #users */}

Un **utilizator** este un **cont** pe calculator: un nume, de exemplu `student`, o parolă, un director pentru fișierele
lui și programul care pornește când se autentifică, de obicei un shell. Utilizatorii țin separată munca oamenilor
diferiți: fișierele lui `bob` nu sunt fișierele lui `carol`, iar un program pornit de `bob` nu le poate atinge decât dacă
ea îi permite.

Utilizatorii nu sunt doar oameni. Multe servicii ale sistemului rulează sub un utilizator propriu: dacă unul dintre ele
are un bug sau este atacat, poate atinge doar propriile fișiere, nu și pe ale celorlalte servicii sau ale oamenilor.

Pentru voi, un utilizator este un **nume**. Pentru kernel, un utilizator este doar un **număr**, **UID**-ul
(_User ID_). Numele se păstrează într-un fișier, iar programele le traduc în numere, și înapoi, când vorbesc cu voi.

### Cine sunt eu: `whoami` și `id` {/* #who-am-i-whoami-and-id */}

| Comandă                      | Ce afișează                                                                                     |
| ---------------------------- | ----------------------------------------------------------------------------------------------- |
| `whoami`                     | numele utilizatorului care rulează comanda                                                      |
| `id`                         | eticheta procesului: UID-ul, grupul primar (GID-ul) și toate grupurile                          |
| `id -u`, `id -g`             | doar UID-ul, doar GID-ul grupului primar                                                        |
| `id -un`                     | doar numele utilizatorului, ca `whoami`                                                         |
| `id -nG`                     | doar numele grupurilor                                                                          |
| `groups`                     | numele grupurilor voastre, ca `id -nG`                                                          |
| `id <USER>`, `groups <USER>` | ce spun despre un utilizator bazele de date: eticheta pe care o primește când se autentifică    |

```shell-session
[student@fedora ~]$ whoami
student
[student@fedora ~]$ id
uid=1000(student) gid=1000(student) groups=1000(student),10(wheel) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
[student@fedora ~]$ id root
uid=0(root) gid=0(root) groups=0(root)
```

- `whoami` a afișat numele utilizatorului vostru, `student`.
- `id` a afișat eticheta procesului shell-ului vostru (vedeți [Utilizatorul unui proces](#the-user-of-a-process)):
  UID-ul `1000`, grupul primar `student`, cu GID-ul `1000`, și grupurile `student` și `wheel`. Pe Fedora, membrii lui
  `wheel` sunt **administratorii**, cei care pot folosi `sudo` (vedeți [`sudo`](#sudo)). Ignorați `context=...`: nu
  aveți nevoie de el în acest laborator, iar Ubuntu nu îl afișează.
- `id root` a afișat ce știe sistemul despre utilizatorul `root`, administratorul: UID-ul `0`.

### Intervale de UID-uri {/* #uid-ranges */}

| UID          | Tip                           | Folosit pentru                                                                          | Exemple pe Fedora                 |
| ------------ | ----------------------------- | --------------------------------------------------------------------------------------- | --------------------------------- |
| `0`          | `root`                        | administratorul; kernelul sare pentru el peste majoritatea verificărilor                | `root`                            |
| `1` - `999`  | **utilizatori de sistem**     | servicii; majoritatea nu se pot autentifica, pentru că au ca shell `nologin`            | `bin`, `daemon`, `dbus`, `chrony` |
| `1000` - ... | **utilizatori obișnuiți**     | oameni                                                                                  | `student`                         |
| `65534`      | `nobody`                      | fișierele al căror proprietar real nu se cunoaște și procesele care nu trebuie să aibă niciun drept | `nobody`              |

Aceste intervale sunt doar o **convenție**: pentru kernel, toate UID-urile în afară de `0` sunt la fel. Ele se
stabilesc în `/etc/login.defs`, fișierul de setări al lui `useradd` și al celorlalte comenzi care creează utilizatori,
iar aceste comenzi iau următorul UID liber din intervalul potrivit:

```shell-session
[student@fedora ~]$ grep -E '^(UID|SYS_UID)_(MIN|MAX)' /etc/login.defs
UID_MIN                  1000
UID_MAX                 60000
SYS_UID_MIN               201
SYS_UID_MAX               999
```

### Utilizatorul unui proces {/* #the-user-of-a-process */}

Fiecare **proces** poartă UID-ul utilizatorului care l-a pornit și GID-urile grupurilor sale: aceasta este **eticheta
procesului**. Gândiți-vă la o ecusoană pe care procesul o poartă toată viața: kernelul se uită la ea de fiecare dată
când procesul cere ceva, să deschidă un fișier sau să trimită un semnal, și decide dacă are **voie**. Un proces copil
**moștenește** eticheta părintelui: tot ce porniți din shell-ul vostru rulează ca voi.

![Eticheta unui proces](./images/user-label.svg)

`ps` afișează utilizatorul fiecărui proces în coloana `USER` (sau `UID`, ca număr):

```shell-session
[student@fedora ~]$ ps -o user,uid,pid,ppid,comm
USER       UID     PID    PPID COMMAND
student   1000    2817    2805 bash
student   1000    3104    2817 ps
[student@fedora ~]$ ps -eo user | sort | uniq -c
      4 chrony
      2 dbus
      ...
    156 root
     51 student
```

- `ps -o user,uid,pid,ppid,comm` a arătat că `bash` și `ps` rulează ca `student`: `ps` este copilul lui `bash` și i-a
  moștenit eticheta.
- `ps -eo user` a afișat utilizatorul **fiecărui** proces, iar `sort | uniq -c` le-a numărat (vedeți
  [Pipe-uri](/docs/labs/03#pipes-) în laboratorul 03). Majoritatea proceselor din sistem rulează ca `root`.

:::info

`ps` primește de la kernel doar UID-urile. Ca să afișeze un nume, caută fiecare UID în baza de date a utilizatorilor;
dacă UID-ul nu există acolo, de exemplu pentru că utilizatorul a fost șters, afișează numărul. `ls -l`, `id` și
promptul fac la fel.

:::

:::note

Eticheta unui proces are câteva părți în plus față de un UID și o listă de grupuri: un program ca `passwd` poate rula
cu două UID-uri diferite în același timp. Exercițiile din laborator nu au nevoie de aceste detalii, dar exercițiile de
acasă și provocările au: le găsiți în [Credențialele unui proces](#the-credentials-of-a-process), la finalul
laboratorului.

:::

## Grupuri {/* #groups */}

Un **grup** este o mulțime de utilizatori, cu un nume și un număr, **GID**-ul (_Group ID_). Grupurile vă permit să
partajați: un fișier își poate da permisiunile unui grup, de exemplu studenților unui proiect, fără să fie deschis
tuturor. Un grup nu are niciun drept prin el însuși: când un fișier sau `sudo` dă drepturi unui grup, le primește
fiecare membru.

Fiecare utilizator are:

- **un singur grup primar**: fișierele noi ale utilizatorului primesc acest grup. Pe Fedora și Ubuntu, `useradd`
  creează un grup cu același nume ca utilizatorul, doar pentru el, așa că `student` are grupul primar `student`;
- oricâte **grupuri suplimentare**, de exemplu `wheel`, grupul administratorilor.

`id` și `groups` le afișează pe amândouă, așa cum ați văzut mai sus: `groups=1000(student),10(wheel)`.

## Bazele de date ale utilizatorilor și grupurilor {/* #the-users-and-groups-databases */}

### `/etc/passwd` {/* #etcpasswd */}

Utilizatorii locali se păstrează în `/etc/passwd`, un fișier text cu **câte un utilizator pe fiecare linie** și
câmpurile separate prin `:`. **Oricine** îl poate citi, pentru că orice program care afișează un nume de utilizator, cum
sunt `ls` sau `ps`, rulează ca utilizatorul care l-a pornit și trebuie să-l poată citi.

```shell-session
[student@fedora ~]$ ls -l /etc/passwd
-rw-r--r--. 1 root root 2245 Oct 20 09:12 /etc/passwd
[student@fedora ~]$ head -3 /etc/passwd
root:x:0:0:Super User:/root:/bin/bash
bin:x:1:1:bin:/bin:/usr/sbin/nologin
daemon:x:2:2:daemon:/sbin:/usr/sbin/nologin
```

- `ls -l` a arătat că doar `root` poate modifica fișierul, dar oricine îl poate citi. Pe Fedora, ignorați `.` de după
  permisiuni: nu aveți nevoie de el în acest laborator, iar Ubuntu nu îl afișează.
- `head -3` a afișat primele 3 linii, ca să arate formatul. Ca să **căutați** un utilizator, nu citiți fișierul:
  folosiți [`getent`](#getent), cum face restul laboratorului.

```shell-session
[student@fedora ~]$ getent passwd student
student:x:1000:1000:Student:/home/student:/bin/bash
```

![Câmpurile din /etc/passwd](./images/passwd-fields.svg)

| Câmp | În exemplu      | Ce este                                                                                                        |
| ---- | --------------- | -------------------------------------------------------------------------------------------------------------- |
| 1    | `student`       | **numele de utilizator**, cel cu care vă autentificați                                                         |
| 2    | `x`             | parola: `x` înseamnă că se păstrează în `/etc/shadow` (vedeți [Parole](#passwords))                            |
| 3    | `1000`          | **UID**-ul                                                                                                     |
| 4    | `1000`          | **GID**-ul **grupului primar**                                                                                 |
| 5    | `Student`       | câmpul **GECOS**: numele complet, uneori urmat de numărul camerei și de numerele de telefon, separate prin `,` |
| 6    | `/home/student` | **directorul utilizatorului** (_home_): directorul curent după autentificare, `~` și `$HOME`                   |
| 7    | `/bin/bash`     | **shell-ul**, programul pornit după autentificare; `/usr/sbin/nologin` refuză autentificarea                   |

### `/etc/group` {/* #etcgroup */}

Grupurile locale se păstrează în `/etc/group`, câte un grup pe linie, cu 4 câmpuri. Și acesta poate fi citit de
oricine.

```shell-session
[student@fedora ~]$ getent group wheel
wheel:x:10:student
[student@fedora ~]$ getent group student
student:x:1000:
```

| Câmp | În exemplu | Ce este                                                                                  |
| ---- | ---------- | ---------------------------------------------------------------------------------------- |
| 1    | `wheel`    | numele grupului                                                                          |
| 2    | `x`        | nu este folosit în acest laborator                                                       |
| 3    | `10`       | **GID**-ul                                                                               |
| 4    | `student`  | **membrii**, separați prin `,`: utilizatorii care au grupul ca grup **suplimentar**      |

:::caution

Utilizatorii care au un grup ca grup **primar** **nu** apar în ultimul lui câmp: `student` este singurul membru al
grupului `student`, dar lista este goală. Grupul primar este al 4-lea câmp din `/etc/passwd`. Ca să vedeți toate
grupurile unui utilizator, folosiți `id <USER>`.

:::

:::danger

Nu modificați `/etc/passwd`, `/etc/group` sau `/etc/shadow` cu un editor de text. Un singur `:` greșit poate împiedica
orice utilizator, inclusiv pe `root`, să se autentifice. Modificați-le doar cu comenzile din
[Gestionarea utilizatorilor și a grupurilor](#managing-users-and-groups).

:::

### `getent` {/* #getent */}

Utilizatorii și grupurile nu se păstrează mereu în aceste fișiere: într-o universitate sau într-o firmă, se află de
obicei pe un **server** din rețea (LDAP, Active Directory, ...), iar `systemd` poate crea și el utilizatori, pentru
serviciile lui. De aceea, `ls`, `ps` și `id` nu deschid singure `/etc/passwd`: îi cer utilizatorul **bibliotecii C**
(codul pe care îl folosește orice program ca să vorbească cu sistemul), care caută în toate aceste locuri, în ordinea
scrisă în `/etc/nsswitch.conf`. Toate aceste locuri împreună formează **baza de date a utilizatorilor** și **baza de
date a grupurilor**.

`getent` (_get entries_) întreabă biblioteca C în același fel, așa că găsește un utilizator oriunde ar fi păstrat și
îl afișează în același format ca fișierele:

| Comandă                            | Găsește                                                    |
| ---------------------------------- | ---------------------------------------------------------- |
| `getent passwd <NAME>` sau `<UID>` | utilizatorul cu acest **nume** sau cu acest **UID**        |
| `getent passwd`                    | toți utilizatorii                                          |
| `getent group <NAME>` sau `<GID>`  | grupul cu acest nume sau cu acest GID                      |
| `getent group`                     | toate grupurile                                            |
| `sudo getent shadow <NAME>`        | linia utilizatorului din `/etc/shadow`, doar pentru `root` |

```shell-session
[student@fedora ~]$ getent passwd 0
root:x:0:0:Super User:/root:/bin/bash
[student@fedora ~]$ getent passwd nobody
nobody:x:65534:65534:Kernel Overflow User:/:/usr/sbin/nologin
[student@fedora ~]$ getent passwd alice
[student@fedora ~]$
```

- `getent passwd 0` a găsit utilizatorul cu UID-ul `0`, `root`, iar `getent passwd nobody` utilizatorul `nobody`.
- `getent passwd alice` nu a afișat **nimic**, fără nicio eroare: nu există un astfel de utilizator.

`getent` se uită și la **câmpuri**, nu la textul liniilor. `grep` doar găsește un text, oriunde într-o linie:

```shell-session
[student@fedora ~]$ grep root /etc/passwd
root:x:0:0:Super User:/root:/bin/bash
operator:x:11:0:operator:/root:/usr/sbin/nologin
[student@fedora ~]$ getent passwd root
root:x:0:0:Super User:/root:/bin/bash
```

- `grep root` l-a afișat și pe `operator`, al cărui director este `/root`.
- `getent passwd root` l-a afișat doar pe utilizatorul al cărui **nume** este `root`.

:::caution

**Căutați mereu utilizatorii și grupurile cu `getent`**

Folosiți `getent passwd` pentru utilizatori și `getent group` pentru grupuri, nu `cat` sau `grep` pe `/etc/passwd` și
`/etc/group`: fișierele conțin doar conturile locale, iar `grep` se potrivește cu orice câmp. În acest laborator, **baza
de date a utilizatorilor** înseamnă `getent passwd`, iar **baza de date a grupurilor** înseamnă `getent group`.

:::

## Utilizatorul `root` {/* #the-root-user */}

`root` este utilizatorul cu UID-ul `0`, administratorul. Pentru un proces cu UID-ul `0`, kernelul **sare peste**
majoritatea verificărilor: procesul poate citi și scrie orice fișier, poate trimite semnale oricărui proces, poate
monta discuri și poate schimba setările rețelei. Instalarea de programe și adăugarea de utilizatori cer `root` din
același motiv: scriu fișiere care îi aparțin lui `root`, în `/usr` și în `/etc`. Directorul lui `root` este `/root`, nu
`/home/root`, ca `root` să se poată autentifica și atunci când `/home` se află pe un alt disc, care nu funcționează.

Kernelul se uită doar la **număr**: `root` este doar numele UID-ului `0`, aflat de obicei pe prima linie din
`/etc/passwd`. Două nume de utilizator cu același UID sunt, pentru kernel, **același utilizator**: așa își poate
ascunde un atacator un al doilea `root`.

:::danger

O greșeală făcută ca `root` poate distruge tot sistemul: pe `root` nu îl oprește niciun `Permission denied`. Lucrați ca
utilizator obișnuit și deveniți `root` doar pentru comenzile care au nevoie de asta.

:::

## Cum devenim `root`: `sudo` și `su` {/* #becoming-root-sudo-and-su */}

### `sudo` {/* #sudo */}

`sudo` rulează **o comandă** ca `root`. Cere parola **voastră**, nu pe cea a lui `root`, și vă lasă să rulați comanda
doar dacă sunteți **administrator**. Un utilizator este administrator dacă face parte dintr-un anumit grup, al cărui
nume depinde de distribuție:

| Distribuție                | Grupul administratorilor |
| -------------------------- | ------------------------ |
| Fedora, Red Hat, CentOS    | `wheel`                  |
| Ubuntu, Debian, Linux Mint | `sudo`                   |

Ca să faceți dintr-un utilizator un administrator, adăugați-l în acest grup; ca să-i luați dreptul, scoateți-l din grup
(vedeți [Gestionarea utilizatorilor și a grupurilor](#managing-users-and-groups)). `student` este în `wheel`, deci poate
folosi `sudo`:

```shell-session
[student@fedora ~]$ cat /etc/shadow
cat: /etc/shadow: Permission denied
[student@fedora ~]$ sudo whoami
[sudo] password for student:
root
[student@fedora ~]$ sudo whoami
root
```

- `cat /etc/shadow` a eșuat: doar `root` poate citi acest fișier (vedeți [Parole](#passwords)).
- `sudo whoami` a cerut parola lui `student`, apoi a pornit `whoami` ca `root`, care a afișat `root`.
- Al doilea `sudo whoami` nu a mai cerut parola: `sudo` o ține minte câteva minute (**5** pe Fedora), în acest
  terminal.
- Un utilizator care nu este administrator primește `bob is not in the sudoers file.`, iar comanda nu mai pornește.

`sudo` scrie **fiecare** comandă în jurnalul sistemului: cine a rulat ce, ca cine și din ce director.

```shell-session
[student@fedora ~]$ sudo journalctl -t sudo | tail -2
Oct 27 10:02:11 fedora sudo[3311]:  student : TTY=pts/0 ; PWD=/home/student ; USER=root ; COMMAND=/usr/bin/whoami
Oct 27 10:02:20 fedora sudo[3315]:  student : TTY=pts/0 ; PWD=/home/student ; USER=root ; COMMAND=/usr/bin/journalctl -t sudo
```

| Comandă                    | Ce face                                                                                                    |
| -------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `sudo <COMMAND>`           | rulează comanda ca `root`                                                                                  |
| `sudo -u <USER> <COMMAND>` | rulează comanda ca alt utilizator; cere parola **voastră**, nu pe a lui                                    |
| `sudo -i`                  | pornește un **shell de autentificare** al lui `root`, în `/root`, cu variabilele lui `root`                |
| `sudo -k`                  | uită parola: următorul `sudo` o cere din nou                                                               |
| `sudo !!`                  | rulează din nou comanda **anterioară**, cu `sudo`: `bash` înlocuiește `!!` înainte să pornească `sudo`     |

Cât timp rulează comanda, `sudo` nu dispare: așteaptă să se termine comanda și îi transmite semnalele pe care le
primește. Pe Fedora, `sudo` rulează comanda și într-un **pseudoterminal nou**, doar al lui (vedeți
[Emulatoare de terminal](/docs/labs/04#terminal-emulators) în laboratorul 04), așa că există **două** procese `sudo`. Cu
`sudo sleep 300` rulând într-un shell cu PID-ul `2817`:

```shell-session
[student@fedora ~]$ pstree -pu 2817
bash(2817)───sudo(3320,root)───sudo(3321)───sleep(3322)
[student@fedora ~]$ ps -o pid,ppid,tty,comm -p 3320,3321,3322
    PID    PPID TT       COMMAND
   3320    2817 pts/0    sudo
   3321    3320 pts/2    sudo
   3322    3321 pts/2    sleep
```

- `pstree -p` a afișat PID-urile, iar `-u` utilizatorul, acolo unde se schimbă: `sudo` rulează ca `root`, la fel ca tot
  ce se află sub el.
- `ps` a arătat că al doilea `sudo` și `sleep` sunt pe `pts/2`, nu pe `pts/0`: `ps -t pts/0` **nu** afișează comanda
  pornită cu `sudo`. Găsiți-o în schimb cu `pstree`, cu `pgrep` sau după PPID.

:::info

Noul pseudoterminal vă protejează: un program pornit cu `sudo` nu mai poate scrie comenzi în terminalul vostru după ce
se termină. `sudo` 1.9.14 și versiunile mai noi îl folosesc implicit; pe sistemele mai vechi, `pstree` afișează un
singur `sudo`.

:::

### `su` {/* #su */}

`su` (_switch user_) pornește un **shell** ca alt utilizator și cere parola **acelui** utilizator:

| Comandă       | Ce face                                                                                         |
| ------------- | ----------------------------------------------------------------------------------------------- |
| `su - <USER>` | pornește un **shell de autentificare** al utilizatorului: cu directorul, variabilele și grupurile lui |
| `su -`        | același lucru, pentru `root`; cere parola lui `root`                                            |
| `exit`        | iese din shell și revine în al vostru                                                           |

```shell-session
[student@fedora ~]$ su -
Password:
su: Authentication failure
[student@fedora ~]$ sudo -i
[root@fedora ~]# whoami
root
[root@fedora ~]# exit
logout
[student@fedora ~]$
```

- `su -` a eșuat: pe Fedora și pe Ubuntu, `root` nu are de obicei **nicio parolă** (contul este blocat, vedeți
  [`/etc/shadow`](#etcshadow)), dacă nu i-ați setat una la instalarea sistemului.
- `sudo -i` a pornit un shell de `root` cu parola **voastră**; `exit` a ieșit din el.

Cu `su`, toți cei care devin `root` trebuie să știe aceeași parolă și nu îi puteți lua dreptul unuia dintre ei fără să
o schimbați pentru toți; cu `sudo`, fiecare își folosește propria parolă, iar fiecare comandă este scrisă în jurnal.
`su` rămâne util ca să deveniți **alt utilizator obișnuit**, cu parola lui.

:::tip

Într-un shell de `root`, promptul afișează `#` în loc de `$`. Ieșiți din el cu `exit` imediat ce ați terminat.

:::

### Capcana redirectării {/* #the-redirect-trap */}

`sudo` rulează **comanda**, nu toată linia. **Redirectările** le face shell-ul vostru, care rulează ca voi, **înainte**
să pornească `sudo`:

```shell-session
[student@fedora ~]$ sudo echo "192.168.1.20 printer" >> /etc/hosts
bash: /etc/hosts: Permission denied
[student@fedora ~]$ echo "192.168.1.20 printer" | sudo tee -a /etc/hosts
192.168.1.20 printer
```

![Capcana redirectării](./images/redirect-trap.svg)

- Pe prima linie, `bash` a încercat să deschidă `/etc/hosts` pentru `>>`, ca `student`, și a eșuat: `sudo echo` nu a
  mai pornit deloc.
- Pe a doua linie, `tee` a rulat ca `root`: a citit textul din pipe și l-a scris în fișier **și** pe ecran. `-a`
  (_append_) îl adaugă la sfârșit, ca `>>`; fără această opțiune, `tee` înlocuiește conținutul fișierului, ca `>`.

:::tip

Ca să ascundeți textul pe care îl afișează `tee`, trimiteți-i ieșirea în `/dev/null`:
`echo "192.168.1.20 printer" | sudo tee -a /etc/hosts > /dev/null`. Și această redirectare o face shell-ul vostru, ca
voi, dar merge: `/dev/null` este `rw-rw-rw-`, deci orice utilizator are voie să scrie în el.

:::

## Parole {/* #passwords */}

### `/etc/shadow` {/* #etcshadow */}

`/etc/passwd` trebuie să poată fi citit de oricine, așa că parolele nu pot sta acolo. Ele se păstrează în `/etc/shadow`,
pe care doar `root` îl poate citi:

```shell-session
[student@fedora ~]$ ls -l /etc/shadow
----------. 1 root root 1207 Oct 20 09:12 /etc/shadow
[student@fedora ~]$ getent shadow student
[student@fedora ~]$ sudo getent shadow student
student:$y$j9T$Xr3aB7tPq2LkV9sD1fGh0J$9mQeT4bW1sZxH8cDr5Ny2kLpA7uVq3oEw6iFj0gHt1M:20737:0:99999:7:::
```

- `ls -l` a arătat că pe Fedora `/etc/shadow` nu are **nicio** permisiune, `----------`: doar `root` îl poate citi,
  pentru că pentru `root` kernelul sare peste verificări. Pe Ubuntu este `-rw-r----- root shadow`: îl poate citi și
  grupul `shadow`, ca anumite programe să poată verifica parole fără să fie `root`.
- `getent shadow student`, rulat ca `student`, nu a afișat nimic: nu a putut citi fișierul.
- `sudo getent shadow student` a afișat linia lui `student`.

Fiecare linie are 9 câmpuri, separate prin `:`:

| Câmp | În exemplu       | Ce este                                                                                                         |
| ---- | ---------------- | --------------------------------------------------------------------------------------------------------------- |
| 1    | `student`        | numele de utilizator, același ca în `/etc/passwd`                                                               |
| 2    | `$y$j9T$Xr3a...` | **hash**-ul parolei; `!`, `!!` sau `*` la început înseamnă că parola este **blocată**: nu merge nicio parolă     |
| 3    | `20737`          | ziua ultimei schimbări a parolei, numărată de la 1 ianuarie 1970                                                |
| 4    | `0`              | numărul minim de zile între două schimbări de parolă                                                            |
| 5    | `99999`          | numărul maxim de zile după care parola **trebuie** schimbată; `99999` înseamnă niciodată                        |
| 6    | `7`              | cu câte zile înainte de expirare este avertizat utilizatorul                                                    |
| 7    | _gol_            | câte zile după expirare mai poate fi folosit contul                                                             |
| 8    | _gol_            | ziua în care expiră **contul**; gol înseamnă niciodată                                                          |
| 9    | _gol_            | rezervat                                                                                                        |

`chage -l` (_change age_) afișează câmpurile 3 - 8 ca date calendaristice:

```shell-session
[student@fedora ~]$ sudo chage -l student
Last password change                                    : Oct 11, 2026
Password expires                                        : never
Password inactive                                       : never
Account expires                                         : never
Minimum number of days between password change          : 0
Maximum number of days between password change          : 99999
Number of days of warning before password expires       : 7
[student@fedora ~]$ date -d '1970-01-01 + 20737 days'
Sun Oct 11 12:00:00 AM EEST 2026
```

:::note

O parolă blocată (câmpul 2) oprește doar autentificările **cu parolă**: un utilizator care se autentifică cu `ssh` și o
cheie tot intră. Ca să opriți **orice** autentificare, faceți contul să expire (câmpul 8, `chage -E`).

:::

### Hash-uri și salt {/* #hashes-and-salt */}

Parola în sine **nu** se păstrează niciodată, ci doar **hash**-ul ei: rezultatul unei funcții **într-un singur sens**
(_one-way_). Hash-ul unei parole se calculează ușor, dar din hash nu există nicio cale de a calcula parola: singurul drum
înapoi este să **ghiciți** o parolă, să-i calculați hash-ul și să comparați. Al doilea câmp din `/etc/shadow` este format
din părți separate prin `$`:

| Parte       | În exemplu               | Ce este                                                                                             |
| ----------- | ------------------------ | --------------------------------------------------------------------------------------------------- |
| algoritmul  | `y`                      | funcția de hash: `y` este _yescrypt_, `6` este _SHA-512_, `1` este vechiul _MD5_                    |
| parametrii  | `j9T`                    | costul algoritmului: câtă muncă cere un hash                                                        |
| **salt**-ul | `Xr3aB7tPq2LkV9sD1fGh0J` | un text aleator, diferit pentru fiecare utilizator, adăugat la parolă înainte de calculul hash-ului |
| hash-ul     | `9mQeT4bW1sZx...`        | hash-ul salt-ului și al parolei                                                                     |

Ca să **verifice** o parolă, `login` (sau `sudo`, sau `passwd`) citește din `/etc/shadow` algoritmul, parametrii și
salt-ul, calculează cu ele hash-ul parolei tastate și compară rezultatul cu hash-ul păstrat. Dacă sunt egale, parola
este corectă.

![Verificarea unei parole](./images/password-check.svg)

`openssl passwd` calculează un hash în același fel (`-6` înseamnă _SHA-512_):

```shell-session
[student@fedora ~]$ openssl passwd -6 -salt Xr3aB7tP pass123
$6$Xr3aB7tP$Z1hKbIRkawX63bJfb3tDz.QpCpVlFdOHOBw1ZdK7Oe/6P0K3E0OUwMhyG7PXhsJPPu.ZobCXoTYNxvAQ3HExk0
[student@fedora ~]$ openssl passwd -6 -salt Xr3aB7tP pass123
$6$Xr3aB7tP$Z1hKbIRkawX63bJfb3tDz.QpCpVlFdOHOBw1ZdK7Oe/6P0K3E0OUwMhyG7PXhsJPPu.ZobCXoTYNxvAQ3HExk0
[student@fedora ~]$ openssl passwd -6 -salt Xr3aB7tP pass124
$6$Xr3aB7tP$msVqpr1xVM/DA2zRy9MVn8yIL5iisMXZpqd3XHD5Ix0aQ5QqD8D3Q91LXVy0w9hPqQLzRYsUVEH5g5oBfNp9//
[student@fedora ~]$ openssl passwd -6 -salt Lp0wQ2zM pass123
$6$Lp0wQ2zM$Uo9XUE/86KtNuRc.TcZpxeM0kWUejWZuFOaRQSujvsfACi8WRK55XpaV3Z3WE8TLEWQBF9Jgn4ByzOvO43Ukw0
```

- Aceeași parolă cu același salt a dat întotdeauna **același** hash: așa se verifică parola.
- O singură literă diferită, `pass124`, a dat un hash complet diferit.
- Aceeași parolă cu alt salt a dat alt hash: doi utilizatori cu aceeași parolă au linii diferite în `/etc/shadow`.

:::info

De ce nu stă hash-ul în `/etc/passwd`, pe care îl poate citi oricine? Pentru că verificarea merge și pentru un atacator:
cu o copie a hash-ului, poate calcula pe propriul calculator hash-ul unei parole după alta, până când una dintre ele dă
același hash. Nimeni nu vede aceste încercări și nimic nu le încetinește, spre deosebire de `login`, care așteaptă după
o parolă greșită și o scrie în jurnal. Un algoritm lent, cum este _yescrypt_, face ca fiecare încercare să coste mai
mult, iar salt-ul îl obligă pe atacator să o ia de la capăt pentru fiecare utilizator, dar o parolă simplă tot se
găsește repede. De aceea doar `root` poate citi `/etc/shadow`: programele care verifică parole, `login`, `sudo` și
`passwd`, rulează ca `root`, deci îl pot citi.

:::

### Schimbarea parolei: `passwd` {/* #changing-a-password-passwd */}

| Comandă                 | Ce face                                                                                             |
| ----------------------- | --------------------------------------------------------------------------------------------------- |
| `passwd`                | schimbă parola **voastră**; o cere întâi pe cea veche                                               |
| `sudo passwd <USER>`    | schimbă parola altui utilizator (doar `root` are voie)                                              |
| `sudo passwd -l <USER>` | **blochează** parola: adaugă `!!` (Ubuntu: `!`) în fața hash-ului, așa că nu mai merge nicio parolă |
| `sudo passwd -u <USER>` | o deblochează: elimină `!`, iar parola **veche** merge din nou                                      |
| `sudo passwd -S <USER>` | afișează starea parolei: setată, blocată sau goală                                                  |

:::caution

Când tastați o parolă în terminal, pe ecran nu apare **nimic**. Tastați-o oricum și apăsați <kbd>Enter</kbd>. Fedora
refuză parolele prea scurte sau prea simple, dacă nu sunteți `root`.

:::

## Gestionarea utilizatorilor și a grupurilor {/* #managing-users-and-groups */}

Comenzile de mai jos modifică în locul vostru `/etc/passwd`, `/etc/shadow` și `/etc/group`, așa că au nevoie de `sudo`:

| Comandă                           | Ce face                                                                                                                                  |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `sudo useradd -m <USER>`          | creează un utilizator, cu un grup cu același nume; `-m` creează directorul utilizatorului, `-c` setează numele complet, iar `-s` shell-ul |
| `sudo passwd <USER>`              | setează parola utilizatorului                                                                                                            |
| `sudo groupadd <GROUP>`           | creează un grup                                                                                                                          |
| `sudo usermod -aG <GROUP> <USER>` | **adaugă** utilizatorul într-un grup suplimentar                                                                                         |
| `sudo usermod <OPTIONS> <USER>`   | **modifică** un utilizator existent; acceptă majoritatea opțiunilor lui `useradd`: `-c` numele complet, `-s` shell-ul, ...               |
| `sudo gpasswd -a <USER> <GROUP>`  | adaugă și el utilizatorul în grup                                                                                                        |
| `sudo gpasswd -d <USER> <GROUP>`  | scoate utilizatorul din grup                                                                                                             |
| `sudo userdel -r <USER>`          | șterge utilizatorul și grupul lui; `-r` îi șterge și directorul                                                                          |
| `sudo groupdel <GROUP>`           | șterge un grup; refuză dacă grupul este grupul primar al unui utilizator                                                                 |

```shell-session
[student@fedora ~]$ sudo useradd -m -c "Dave Brown" dave
[student@fedora ~]$ sudo passwd dave
New password:
Retype new password:
passwd: password updated successfully
[student@fedora ~]$ sudo usermod -aG students dave
[student@fedora ~]$ id dave
uid=1003(dave) gid=1004(dave) groups=1004(dave),1003(students)
[student@fedora ~]$ ls -ld /home/dave
drwx------. 3 dave dave 80 Oct 27 10:15 /home/dave
```

- `useradd` l-a creat pe `dave`, cu următorul UID liber, un grup `dave` doar al lui și `/home/dave`.
- `passwd dave` i-a setat parola; până atunci, nimeni nu se putea autentifica ca `dave`.
- `usermod -aG` l-a adăugat în grupul `students` (grupul trebuie să existe deja, creat cu `groupadd`).
- `id dave` și `ls -ld` au afișat rezultatul. Numerele pot fi diferite pe calculatorul vostru.

Un utilizator nou **nu** este administrator. `sudo` merge pentru `student` pentru că `student` este în `wheel`; `dave`
nu este, așa că `sudo` îl refuză, chiar dacă își dă parola corectă:

```shell-session
[student@fedora ~]$ su - dave
Password:
[dave@fedora ~]$ sudo whoami
[sudo] password for dave:
dave is not in the sudoers file.
[dave@fedora ~]$ exit
logout
[student@fedora ~]$ sudo usermod -aG wheel dave
[student@fedora ~]$ su - dave
Password:
[dave@fedora ~]$ sudo whoami
[sudo] password for dave:
root
[dave@fedora ~]$ exit
logout
[student@fedora ~]$ sudo gpasswd -d dave wheel
Removing user dave from group wheel
```

- Primul `sudo whoami` a eșuat: `dave` nu este în `wheel`. Încercarea s-a scris totuși în jurnal.
- După `usermod -aG wheel`, o **nouă autentificare** (`su - dave`) a avut noul grup, iar `sudo` a mers, cu parola
  **lui**.
- `gpasswd -d` i-a luat din nou dreptul.

:::danger

Nu uitați niciodată `-a` din `usermod -aG`. `usermod -G students dave` **înlocuiește** toate grupurile suplimentare ale
lui `dave` cu `students`. Dacă o rulați pe voi înșivă, pierdeți `wheel` și, odată cu el, `sudo`.

:::

`usermod` modifică în locul vostru câmpurile din `/etc/passwd`, iar `userdel` șterge utilizatorul, împreună cu grupul
lui și, cu `-r`, cu directorul lui:

```shell-session
[student@fedora ~]$ sudo usermod -c "David Brown" dave
[student@fedora ~]$ getent passwd dave
dave:x:1003:1004:David Brown:/home/dave:/bin/bash
[student@fedora ~]$ sudo userdel -r dave
[student@fedora ~]$ id dave
id: 'dave': no such user
[student@fedora ~]$ ls -d /home/dave
ls: cannot access '/home/dave': No such file or directory
```

`userdel` refuză să șteargă un utilizator care este încă autentificat sau care are procese în rulare și afișează
`userdel: user dave is currently used by process 4321`. Închideți mai întâi sesiunea utilizatorului.

## Autentificarea {/* #logging-in */}

Când vă autentificați, un proces primește UID-ul și grupurile utilizatorului vostru ca etichetă. Pe un terminal text, de
exemplu `/dev/tty3`:

1. `systemd` pornește `agetty` pe terminal, ca `root`; `agetty` afișează `login:` și citește numele de utilizator;
2. `agetty` **devine** `login` (rulează `exec`), tot ca `root`, și cere parola;
3. `login` găsește utilizatorul în baza de date a utilizatorilor și verifică parola cu hash-ul din `/etc/shadow`;
4. un copil al lui `login` își setează grupurile și, la final, UID-ul la cele ale utilizatorului; după aceea nu mai
   poate reveni **niciodată** la `root`;
5. copilul intră în **directorul utilizatorului** și rulează (`exec`) **shell-ul** din `/etc/passwd`.

![Autentificarea](./images/login.svg)

```shell-session
[student@fedora ~]$ ps -t tty3 -o user,pid,ppid,comm
USER         PID    PPID COMMAND
root        5120       1 login
student     5191    5120 bash
```

`login` rulează în continuare ca `root` și așteaptă să se termine shell-ul, iar shell-ul rulează ca `student`. Orice
program pe care îl porniți din el moștenește această etichetă. O autentificare grafică, `ssh` și `su` parcurg aceiași
pași.

:::info

**Un grup nou cere o nouă autentificare**

Grupurile se copiază din baza de date a grupurilor în eticheta unui proces doar la autentificare și prin `su` și `sudo`.
Dacă sunteți adăugați într-un grup nou, procesele care rulează deja nu îl au, și nici copiii lor: o fereastră nouă de
terminal este un copil al lui Sway, care și-a primit grupurile când v-ați autentificat. Ca să primiți noul grup,
**ieșiți din sesiune și autentificați-vă din nou** sau, doar pentru un shell, porniți un shell de autentificare cu
`su - student`. `id student` citește baza de date, așa că afișează imediat noul grup; `id` singur afișează eticheta
procesului shell-ului vostru, fără el.

:::

## Permisiunile fișierelor {/* #file-permissions */}

### Proprietar, grup și permisiuni {/* #owner-group-and-permissions */}

Fiecare fișier și director are **un singur proprietar** (un utilizator), **un singur grup** și trei seturi de
**permisiuni**: pentru **proprietar** (`u`, _user_), pentru **grup** (`g`) și pentru toți **ceilalți** (`o`, _others_).
Proprietarul și grupul se păstrează ca numere, un UID și un GID, și sunt independente: proprietarul nu trebuie să fie
membru al grupului. `ls -l` le afișează:

```shell-session
[student@fedora lab05]$ ls -l notes.txt
-rw-r-----. 1 student students 9 Oct 27 10:20 notes.txt
```

![Permisiunile unui fișier](./images/permissions.svg)

| Parte        | În exemplu | Ce este                                                                  |
| ------------ | ---------- | ------------------------------------------------------------------------ |
| tipul        | `-`        | `-` fișier, `d` director, `l` legătură simbolică, `c` și `b` dispozitive |
| `u`          | `rw-`      | proprietarul, `student`, poate **citi** și **scrie** fișierul            |
| `g`          | `r--`      | membrii grupului `students` îl pot doar **citi**                         |
| `o`          | `---`      | toți ceilalți nu pot face **nimic**                                      |
| proprietarul | `student`  | utilizatorul căruia îi aparține fișierul, de obicei cel care l-a creat   |
| grupul       | `students` | grupul fișierului, de obicei grupul primar al celui care l-a creat       |

`stat` afișează aceleași informații, în formatul pe care îl cereți:

```shell-session
[student@fedora lab05]$ stat -c '%A %a %U %G %n' notes.txt /etc/passwd /etc/shadow
-rw-r----- 640 student students notes.txt
-rw-r--r-- 644 root root /etc/passwd
---------- 0 root root /etc/shadow
```

`%A` înseamnă permisiunile sub formă de litere, `%a` sub formă de număr (vedeți [`chmod`](#chmod)), `%U` proprietarul,
`%G` grupul, iar `%n` numele.

### `r`, `w` și `x` {/* #r-w-and-x */}

Aceleași litere au alt înțeles pentru fișiere și pentru directoare:

| Permisiune   | Valoare | Pentru un fișier                     | Pentru un director                                                                     |
| ------------ | ------- | ------------------------------------ | -------------------------------------------------------------------------------------- |
| `r` citire   | `4`     | citirea conținutului (`cat`, `less`) | **listarea** numelor fișierelor din el (`ls`)                                          |
| `w` scriere  | `2`     | modificarea conținutului             | **crearea**, **ștergerea** și **redenumirea** fișierelor din el; merge doar cu `x`     |
| `x` execuție | `1`     | rularea lui ca program               | **intrarea** în el (`cd`) și accesul la fișierele din el, dacă le știți numele         |

![Un director este o listă de nume](./images/directory-list.svg)

Un director este un fișier al cărui conținut este o **listă de nume**, fiecare indicând către un fișier. `r` citește
această listă, `w` o modifică, iar `x` o folosește ca să ajungă la un fișier. De aici rezultă trei lucruri:

- crearea, redenumirea sau **ștergerea** unui fișier înseamnă modificarea **directorului**, nu a fișierului: cu `w` pe
  un director puteți șterge un fișier pe care nici măcar nu îl puteți citi;
- ca să ajungeți la un fișier, aveți nevoie de `x` pe **fiecare** director din calea lui:
  `cat /home/student/lab05/notes.txt` are nevoie de `x` pe `/`, `/home`, `/home/student` și `/home/student/lab05`;
- `ls -l` are nevoie și de `x`, nu doar de `r`: ajunge la fiecare fișier ca să-i citească detaliile.

```shell-session
[student@fedora lab05]$ ls -ld noread noenter
d--x------. 2 student student 60 Oct 27 10:20 noread
dr--------. 2 student student 60 Oct 27 10:20 noenter
[student@fedora lab05]$ ls noread
ls: cannot open directory 'noread': Permission denied
[student@fedora lab05]$ cat noread/secret.txt
top secret
[student@fedora lab05]$ ls noenter
ls: cannot access 'noenter/secret.txt': Permission denied
secret.txt
[student@fedora lab05]$ cd noenter
bash: cd: noenter: Permission denied
```

- `noread` are `x`, dar nu are `r`: `ls` nu l-a putut lista, dar `cat` a deschis un fișier al cărui nume îl **știa**.
- `noenter` are `r`, dar nu are `x`: `ls` a citit numele `secret.txt`, dar nu a putut ajunge la fișier ca să-i aleagă
  culoarea, așa că a afișat și o eroare; `cd` nu a putut intra în el.

:::info

Pe Fedora, directoarele utilizatorilor sunt `drwx------`: ceilalți utilizatori nici măcar nu pot intra în al vostru,
deci nu pot ajunge la fișierele voastre, oricare ar fi permisiunile acestora. Pe Ubuntu sunt `drwxr-x---`: membrii
grupului vostru primar îl pot și lista și pot intra în el, dar de obicei acest grup nu are alți membri. Un Ubuntu mai
vechi, sau unul actualizat de la o versiune mai veche, poate avea încă `drwxr-xr-x`, deschis tuturor: verificați-l pe
al vostru cu `ls -ld ~`.

:::

### Ce permisiuni se aplică? {/* #which-permissions-apply */}

Kernelul verifică eticheta procesului în această **ordine**, iar prima potrivire decide:

1. dacă utilizatorul procesului este `root`, UID-ul `0`: totul este permis (în afară de rularea unui fișier care nu are
   niciun `x`);
2. dacă utilizatorul procesului este **proprietarul** fișierului: se folosesc permisiunile `u`;
3. dacă unul dintre grupurile procesului este **grupul** fișierului: se folosesc permisiunile `g`;
4. altfel: se folosesc permisiunile `o`.

![Ce permisiuni se aplică](./images/permission-check.svg)

Pentru `notes.txt` de mai sus, `-rw-r----- student students`:

| Proces rulat de | Grupurile lui      | Folosește | Citire | Scriere |
| --------------- | ------------------ | --------- | ------ | ------- |
| `root`          | `root`             | -         | da     | da      |
| `student`       | `student`, `wheel` | `u`       | da     | da      |
| `bob`           | `bob`, `students`  | `g`       | da     | nu      |
| `carol`         | `carol`            | `o`       | nu     | nu      |

:::caution

Se folosește **un singur** set. Cu `----rw----`, proprietarul nu poate face **nimic**, chiar dacă este în grup:
proprietarul s-a potrivit deja la pasul 2, așa că permisiunile `g` nici nu mai sunt verificate.

:::

### `chmod` {/* #chmod */}

`chmod` (_change mode_) schimbă permisiunile. Doar **proprietarul** fișierului (sau `root`) îl poate rula. Permisiunile
se pot scrie cu **litere**:

| Parte | Litere                                                                                                        |
| ----- | ------------------------------------------------------------------------------------------------------------- |
| cine  | `u` proprietarul, `g` grupul, `o` ceilalți (**nici** proprietarul, **nici** membrii grupului), `a` toate trei |
| cum   | `+` adaugă, `-` elimină, `=` setează exact acestea                                                            |
| ce    | `r`, `w`, `x`                                                                                                 |

| Comandă                     | Ce face                                                                                                                              |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `chmod u+x script.sh`       | adaugă `x` pentru proprietar                                                                                                         |
| `chmod g+w,o-r notes.txt`   | adaugă `w` pentru grup și elimină `r` pentru ceilalți                                                                                |
| `chmod go-rwx notes.txt`    | elimină tot pentru grup și pentru ceilalți                                                                                           |
| `chmod a=r readme.txt`      | setează `r--` pentru toți                                                                                                            |
| `chmod u=rw,go=r notes.txt` | setează exact `rw-r--r--`: `=` înlocuiește permisiunile vechi în loc să le adauge la ele                                             |
| `chmod -R g+rX project`     | pentru grup, adaugă `r` lui `project` și tuturor celor din el, iar `x` doar directoarelor și fișierelor care au deja un `x`          |

sau cu **numere**, în octal: `r` este `4`, `w` este `2`, iar `x` este `1`. Adunați-le pentru fiecare dintre `u`, `g` și
`o`:

| Litere      | `u`             | `g`         | `o`         | Număr |
| ----------- | --------------- | ----------- | ----------- | ----- |
| `rw-r-----` | 4 + 2 = `6`     | 4 = `4`     | `0`         | `640` |
| `rwxr-xr-x` | 4 + 2 + 1 = `7` | 4 + 1 = `5` | 4 + 1 = `5` | `755` |
| `rw-r--r--` | `6`             | `4`         | `4`         | `644` |
| `rw-------` | `6`             | `0`         | `0`         | `600` |

```shell-session
[student@fedora lab05]$ ls -l myid.sh
-rw-r--r--. 1 student student 18 Oct 27 10:20 myid.sh
[student@fedora lab05]$ ./myid.sh
bash: ./myid.sh: Permission denied
[student@fedora lab05]$ chmod u+x myid.sh
[student@fedora lab05]$ ./myid.sh
student
[student@fedora lab05]$ chmod 600 myid.sh
[student@fedora lab05]$ ls -l myid.sh
-rw-------. 1 student student 18 Oct 27 10:20 myid.sh
```

- `./myid.sh` a eșuat: scriptul nu avea `x`.
- `chmod u+x` a adăugat `x` pentru proprietar, iar scriptul a rulat.
- `chmod 600` a setat toate permisiunile deodată: `rw-------`.

:::tip

Folosiți literele ca să **schimbați** câteva permisiuni și să le păstrați pe celelalte (`chmod g+w`), iar numerele ca să
le **setați** pe toate deodată (`chmod 640`). Cu `-R`, folosiți literele: `chmod -R 644 box` elimină și `x`-ul
directoarelor, iar apoi nimeni nu mai poate intra în ele, nici măcar `chmod`; `chmod -R u=rwX,go=rX box` le dă
fișierelor `rw-r--r--`, iar directoarelor `rwxr-xr-x`.

:::

### `umask` {/* #umask */}

Fișierele noi nu primesc toate permisiunile: programul care le creează cere `rw-rw-rw-` (`666`) pentru un fișier și
`rwxrwxrwx` (`777`) pentru un director, iar kernelul **elimină** biții din **`umask`**-ul procesului. `umask` este o
comandă internă a shell-ului (`help umask`), iar fiecare proces își moștenește `umask`-ul de la părinte.

```shell-session
[student@fedora lab05]$ umask
0022
[student@fedora lab05]$ touch new.txt
[student@fedora lab05]$ mkdir newdir
[student@fedora lab05]$ ls -ld new.txt newdir
-rw-r--r--. 1 student student  0 Oct 27 10:25 new.txt
drwxr-xr-x. 2 student student 40 Oct 27 10:25 newdir
```

|                     | Fișier            | Director          |
| ------------------- | ----------------- | ----------------- |
| programul cere      | `666` `rw-rw-rw-` | `777` `rwxrwxrwx` |
| `umask 022` elimină | `022` `----w--w-` | `022` `----w--w-` |
| rezultatul          | `644` `rw-r--r--` | `755` `rwxr-xr-x` |

- `022` elimină `w` pentru grup și pentru ceilalți.
- Un fișier nou nu este niciodată executabil: `umask` poate doar să **elimine** biți, iar programele nu cer `x` pentru
  fișiere.
- `umask 077` face privat orice fișier nou: `600` pentru fișiere și `700` pentru directoare. Setarea rămâne până la
  închiderea shell-ului.

:::info

Unele sisteme folosesc `umask 002` pentru utilizatorii obișnuiți: atunci fișierele noi sunt `rw-rw-r--`. Nu este
periculos, pentru că fiecare utilizator are un grup primar propriu, fără alți membri.

:::

### `chown` și `chgrp` {/* #chown-and-chgrp */}

| Comandă                             | Ce face                                                                    |
| ----------------------------------- | -------------------------------------------------------------------------- |
| `sudo chown bob notes.txt`          | proprietarul devine `bob`                                                  |
| `sudo chown bob:students notes.txt` | proprietarul devine `bob`, iar grupul `students`                           |
| `chown :students notes.txt`         | doar grupul, ca `chgrp`                                                    |
| `chgrp students notes.txt`          | doar grupul                                                                |
| `chown -R`, `chgrp -R`              | directorul și tot ce se află în el                                         |
| `sudo chown 1005 notes.txt`         | proprietarul devine UID-ul `1005`, chiar dacă nu există niciun utilizator cu el |

- Doar `root` poate da un fișier altui utilizator: altfel, oricine ar putea umple discul altui utilizator sau și-ar
  putea ascunde urmele.
- Proprietarul poate schimba grupul unui fișier, dar doar într-unul dintre grupurile **procesului** său.

```shell-session
[student@fedora lab05]$ chown carol notes.txt
chown: changing ownership of 'notes.txt': Operation not permitted
[student@fedora lab05]$ sudo chown carol notes.txt
[student@fedora lab05]$ ls -l notes.txt
-rw-r-----. 1 carol students 9 Oct 27 10:20 notes.txt
```

## Permisiuni speciale {/* #special-permissions */}

Mai există trei biți, pe care `ls -l` îi afișează în locul unui `x`:

| Bit        | Număr  | `ls -l` afișează           | Pe un program                                   | Pe un director                                                                                              |
| ---------- | ------ | -------------------------- | ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **setuid** | `4000` | `-rwsr-xr-x`               | rulează ca **proprietarul** fișierului          | ignorat                                                                                                     |
| **setgid** | `2000` | `-rwxr-sr-x`, `drwxrwsr-x` | rulează cu **grupul** fișierului                | fișierele noi primesc **grupul directorului**; directoarele noi primesc și ele bitul                        |
| **sticky** | `1000` | `drwxrwxrwt`               | ignorat                                         | un fișier poate fi șters sau redenumit doar de proprietarul lui, de proprietarul directorului și de `root`  |

Cu litere, aceștia sunt `u+s`, `g+s` și `+t`; cu numere, a 4-a cifră, pusă în față: `chmod 2775 project` înseamnă
`rwxrwsr-x`. Un `S` sau un `T` **mare** înseamnă că bitul este setat, dar `x`-ul de sub el nu.

### `setuid` {/* #setuid */}

`passwd` trebuie să scrie noul hash în `/etc/shadow`, pe care doar `root` îl poate modifica. `/usr/bin/passwd` îi
aparține lui `root` și are bitul **setuid**: oricine l-ar porni, procesul rulează ca `root`.

```shell-session
[student@fedora ~]$ ls -l /usr/bin/passwd /usr/bin/sudo /usr/bin/su
-rwsr-xr-x. 1 root root  32648 Jul 24 03:00 /usr/bin/passwd
-rwsr-xr-x. 1 root root  56920 Jul 24 03:00 /usr/bin/su
---s--x--x. 1 root root 262536 Jul 24 03:00 /usr/bin/sudo
```

`sudo` și `su` sunt și ele programe setuid: așa pot deveni `root`. Porniți `passwd` într-un terminal (nu tastați nimic)
și uitați-vă la el dintr-un alt terminal:

```shell-session
[student@fedora ~]$ ps -o pid,ruser,user,comm -C passwd
    PID RUSER    USER     COMMAND
   6011 student  root     passwd
```

![Bitul setuid](./images/setuid.svg)

`passwd` rulează ca `root` (coloana `USER`), așa că kernelul îl lasă să scrie în `/etc/shadow`. Dar kernelul ține minte
și cine l-a **pornit** (coloana `RUSER`, _utilizatorul real_), așa că `passwd` schimbă doar parola **voastră**.
[Credențialele unui proces](#the-credentials-of-a-process) explică în detaliu acești doi utilizatori.

:::danger

Nu adăugați niciodată `+s` unui program care îi aparține lui `root`: va rula ca `root` pentru **oricine**, iar un singur
bug din el îl poate face `root` pe oricine. O copie setuid a lui `bash` le dă tuturor utilizatorilor un shell de
`root`. Lăsați bitul setuid programelor făcute pentru el: `passwd`, `su`, `sudo`.

:::

:::info

Kernelul ignoră biții setuid și setgid pe **scripturi**, cum este `myid.sh`. Un script nu rulează singur: kernelul
pornește programul de pe prima lui linie, `/bin/bash`, iar apoi `bash` deschide scriptul după nume. Între acești doi
pași, un utilizator ar putea pune alt fișier sub același nume, iar `bash` l-ar rula ca `root`. De aceea, biții
funcționează doar pentru programe compilate, cum este `passwd`.

:::

### `setgid` pe un director {/* #setgid-on-a-directory */}

Când mai mulți utilizatori lucrează în același director, fișierele noi ar trebui să aparțină grupului proiectului, nu
grupului primar al fiecărui utilizator. Bitul **setgid** pus pe un director face exact acest lucru:

```shell-session
[student@fedora ~]$ sudo mkdir /srv/project
[student@fedora ~]$ sudo chgrp students /srv/project
[student@fedora ~]$ sudo chmod 2775 /srv/project
[student@fedora ~]$ ls -ld /srv/project
drwxrwsr-x. 2 root students 40 Oct 27 10:40 /srv/project
[student@fedora ~]$ sudo -u bob touch /srv/project/bob.txt
[student@fedora ~]$ ls -l /srv/project
total 0
-rw-r--r--. 1 bob students 0 Oct 27 10:41 bob.txt
```

`bob.txt` îi aparține lui `bob`, dar grupul lui este `students`, grupul directorului, nu `bob`.

:::caution

Setați bitul `setgid` ca `root`, ca mai sus, atunci când nu sunteți membri ai grupului directorului. Dacă proprietarul
îl setează, dar nu este în grup, kernelul elimină bitul **fără** nicio eroare, iar `ls -ld` afișează `rwxrwxr-x`.

:::

### Bitul sticky {/* #the-sticky-bit */}

`/tmp` trebuie să poată fi scris de oricine, așa că toată lumea are `w` pe el. Fără nimic altceva, oricine ar putea
șterge fișierele celorlalți. Bitul **sticky**, `t`, permite ștergerea sau redenumirea unui fișier din director doar
**proprietarului fișierului**, proprietarului directorului și lui `root`:

```shell-session
[student@fedora ~]$ ls -ld /tmp
drwxrwxrwt. 21 root root 520 Oct 27 10:00 /tmp
```

:::tip

`find` poate căuta biții speciali: `find /usr -perm -4000` afișează fișierele care au **cel puțin** bitul setuid.

:::

## Promptul {/* #the-prompt */}

Promptul lui `bash` se construiește din variabila de shell `PS1` (vedeți
[Variabile de shell și `export`](/docs/labs/04#shell-variables-and-export) din laboratorul 04). Pe Fedora este
`[\u@\h \W]\$ ` (pe Ubuntu, `\u@\h:\w\$ `, cu culori):

| Secvență | Înseamnă                                              | Pentru `student` | Pentru `root` |
| -------- | ----------------------------------------------------- | ---------------- | ------------- |
| `\u`     | **utilizatorul**                                      | `student`        | `root`        |
| `\h`     | numele **calculatorului** (_host_)                    | `fedora`         | `fedora`      |
| `\W`     | numele directorului curent (`\w` este calea completă) | `lab05`          | `~`           |
| `\$`     | `$` pentru utilizatori, `#` pentru UID-ul `0`         | `$`              | `#`           |

Promptul este doar **text**, iar orice utilizator îl poate schimba:

```shell-session
[student@fedora ~]$ PS1='[root@fedora \W]# '
[root@fedora ~]# whoami
student
[root@fedora ~]# cat /etc/shadow
cat: /etc/shadow: Permission denied
```

:::caution

Nu vă bazați pe prompt ca să aflați cine sunteți. `whoami` și `id` îi cer **kernelului** eticheta procesului.

:::

### Schimbarea promptului {/* #changing-the-prompt */}

`PS1` poate conține orice text, plus aceste secvențe speciale (`man bash`, secțiunea `PROMPTING`):

| Secvență   | Se înlocuiește cu                                                                                 |
| ---------- | ------------------------------------------------------------------------------------------------- |
| `\u`, `\h` | utilizatorul; numele calculatorului, până la primul `.`                                           |
| `\w`, `\W` | calea completă a directorului curent, cu `~` pentru directorul vostru; doar ultimul nume din cale |
| `\$`       | `$` sau, dacă UID-ul este `0`, `#`                                                                |
| `\t`, `\A` | ora, ca `HH:MM:SS` și ca `HH:MM`                                                                  |
| `\d`       | data, de exemplu `Tue Oct 27`                                                                     |
| `\j`       | numărul de job-uri ale shell-ului (laboratorul 04)                                                |
| `\n`       | o linie nouă                                                                                      |

```shell-session
[student@fedora lab05]$ PS1='\A \u in \w \$ '
10:52 student in ~/lab05 $ PS1='[\u@\h \W]\$ '
[student@fedora lab05]$
```

:::tip

O schimbare a lui `PS1` durează până la închiderea shell-ului. Ca s-o păstrați, adăugați linia `PS1='...'` la sfârșitul
lui `~/.bashrc`; `bash` îl citește când pornește (`source ~/.bashrc` îl citește imediat). `root` are propriul
`/root/.bashrc`.

:::

## Credențialele unui proces {/* #the-credentials-of-a-process */}

:::note

**Pentru cine vrea să afle mai mult**

Nu aveți nevoie de această secțiune pentru exercițiile din laborator, 🧪 Primii pași. Citiți-o acasă: exercițiile
🏠 Mai departe și 📝 Provocări o folosesc.

:::

Eticheta unui proces înseamnă mai mult decât un UID și o listă de grupuri. Pentru fiecare proces, kernelul păstrează o
mică înregistrare, **credențialele** procesului (_credentials_): **patru** UID-uri, **patru** GID-uri și lista
**grupurilor suplimentare**. Această înregistrare o ține **kernelul**, nu procesul: procesul nu o poate modifica după
bunul plac.

![Credențialele unui proces](./images/credentials.svg)

| Credențial                                 | Ce este                                                                                                                                                         |
| ------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| UID-ul și GID-ul **real**                  | utilizatorul care a **pornit** procesul și grupul său primar; programele le citesc ca să afle cine sunteți                                                      |
| UID-ul și GID-ul **efectiv**               | cele pe care kernelul le **verifică** atunci când procesul deschide un fișier; `ps` arată utilizatorul efectiv în coloana `USER`                                |
| UID-ul și GID-ul **salvat**                | o copie de rezervă a celor efective, făcută la pornirea programului, ca acesta să-și poată lăsa deoparte drepturile o vreme și apoi să le **ia înapoi**         |
| UID-ul și GID-ul **sistemului de fișiere** | folosite doar pentru fișiere; pe Linux urmează mereu valorile efective, așa că le puteți ignora                                                                 |
| **grupurile suplimentare**                 | celelalte grupuri ale procesului, verificate împreună cu GID-ul efectiv; se copiază din baza de date a grupurilor la autentificare, precum și de `su` și `sudo` |

Pentru shell-ul vostru, cele patru UID-uri sunt toate `1000`, iar cele patru GID-uri sunt toate `1000`. De ce păstrează
kernelul patru copii ale aceluiași număr? Pentru că **nu sunt mereu** egale: un program cu bitul `setuid`, cum este
`passwd`, schimbă UID-ul efectiv și pe cel salvat, dar îl păstrează pe cel real. `login`, `su` și `sudo` fac altceva:
le schimbă pe **toate**, pentru shell-ul sau comanda pe care o pornesc.

### Ce credențiale se verifică {/* #which-credentials-are-checked */}

Kernelul nu se uită de fiecare dată la toate credențialele. Depinde de ce cere procesul:

![Ce credențiale se verifică](./images/credentials-check.svg)

- **deschiderea unui fișier**: UID-ul efectiv se compară cu **proprietarul** fișierului, iar GID-ul efectiv și
  grupurile suplimentare cu **grupul** fișierului (vedeți [Ce permisiuni se aplică?](#which-permissions-apply));
- **trimiterea unui semnal**, cu `kill`: UID-ul real sau cel efectiv al expeditorului trebuie să fie UID-ul real sau cel
  salvat al țintei. Puteți opri un `passwd` pornit de **voi**, chiar dacă rulează ca `root`, pentru că UID-ul lui real
  este al vostru; `bob` nu poate;
- **schimbarea propriilor UID-uri**: un proces care nu este `root` poate lua doar un UID pe care îl are **deja**:
  UID-ul real, cel efectiv sau cel salvat. Un proces **nu** se poate face singur `root`. Doar un proces cu UID-ul
  efectiv `0` poate lua orice UID.

### Cum se schimbă credențialele {/* #how-the-credentials-change */}

Un proces își primește credențialele de la părinte. Tabelul de mai jos arată ce se întâmplă cu ele la fiecare pas din
viața unui proces:

![Cum se schimbă credențialele](./images/credentials-change.svg)

| Când                                                                              | Ce se întâmplă cu UID-urile                                                                                                                                                                                                    |
| --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `fork`, un copil nou                                                              | copilul primește o **copie** a credențialelor părintelui                                                                                                                                                                       |
| `exec` al unui program obișnuit                                                   | **nu** se schimbă nimic                                                                                                                                                                                                        |
| `exec` al unui program cu bitul `setuid`                                          | UID-ul efectiv și cel salvat devin **proprietarul** fișierului; UID-ul real nu se schimbă; bitul `setgid` face la fel pentru GID-uri, cu **grupul** fișierului                                                                 |
| un proces cu UID-ul efectiv `0` apelează `setgid()`, `initgroups()` și `setuid()` | se schimbă **toate** GID-urile, grupurile suplimentare și **toate** UID-urile, în această ordine: așa îi dau `login`, `su` și `sudo` unui proces eticheta unui utilizator (vedeți [Autentificarea](#logging-in) și [`sudo`](#sudo)) |

### Cum vedem credențialele {/* #seeing-the-credentials */}

Există două moduri de a vedea credențialele unui proces:

```shell-session
[student@fedora ~]$ ps -o pid,ruser,euser,suser,comm -p $$
    PID RUSER    EUSER    SUSER    COMMAND
   2817 student  student  student  bash
[student@fedora ~]$ grep -E '^(Uid|Gid|Groups):' /proc/$$/status
Uid:	1000	1000	1000	1000
Gid:	1000	1000	1000	1000
Groups:	10 1000
```

- `ps -o` a primit numele coloanelor: `ruser` este utilizatorul real, `euser` cel efectiv, iar `suser` cel salvat.
  `man ps` le listează pe toate, pentru UID-uri, GID-uri și grupuri, în secțiunea `STANDARD FORMAT SPECIFIERS`.
- Liniile `Uid:` și `Gid:` din `/proc/<PID>/status` au câte 4 numere: real, efectiv, salvat și cel al sistemului de
  fișiere; linia `Groups:` conține grupurile suplimentare (`man 5 proc`). Oricine poate citi fișierul `status` al
  oricărui proces.

Încercați să faceți un proces `root` fără niciun ajutor. `python3` îi poate cere kernelului UID-urile, cu
`os.getresuid()` (_get real, effective and saved UID_), și le poate schimba, cu `os.setuid()`:

```shell-session
[student@fedora ~]$ python3 -c 'import os; print(os.getresuid()); os.setuid(0)'
(1000, 1000, 1000)
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import os; print(os.getresuid()); os.setuid(0)
                                      ~~~~~~~~~^^^
PermissionError: [Errno 1] Operation not permitted
```

Kernelul a refuzat: `0` nu este niciunul dintre cele trei UID-uri ale procesului. Singurul mod de a obține `root` este
să porniți un program **setuid** al lui `root`, cum sunt `sudo`, `su` sau `passwd`, sau să fiți pornit de un proces
care rulează deja ca `root`, cum este `login`.

### UID-ul salvat {/* #the-saved-uid */}

Un program setuid scris cu grijă nu lucrează tot timpul ca `root`: lucrează ca **voi** și folosește `root` doar pentru
puținii pași care au nevoie de el, astfel încât un bug în restul programului să poată face doar ce ați fi putut face
oricum. UID-ul **salvat** face acest lucru posibil. După `exec`, linia `Uid:` a programului este `1000 0 0 0`:

1. programul își setează UID-ul **efectiv** la cel real, `1000` (`Uid: 1000 1000 0 1000`): `root` rămâne doar în
   UID-ul salvat;
2. când are din nou nevoie de `root`, își setează UID-ul efectiv înapoi la `0` (`Uid: 1000 0 0 0`): are voie, pentru că
   `0` este UID-ul său salvat;
3. când nu mai are nevoie de `root`, își setează **toate trei** UID-urile la `1000` (`Uid: 1000 1000 1000 1000`): acum
   `0` nu mai este niciunul dintre UID-urile sale, deci nu mai poate reveni niciodată.

![UID-ul salvat](./images/saved-uid.svg)

## Depanare {/* #troubleshooting */}

| Problemă                                                            | Soluție                                                                                                                                                          |
| ------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Un utilizator afișat de `ps` sau `ls` nu este în `/etc/passwd`      | Nu este un utilizator local: căutați mereu utilizatorii cu `getent passwd` și grupurile cu `getent group`                                                        |
| `Permission denied` la un fișier                                    | Rulați `ls -l` pe fișier și `id`: aflați ce set vi se aplică (proprietar, grup sau ceilalți) și ce permite                                                       |
| `Permission denied` la un fișier care are `r` pentru voi            | Unul dintre directoarele din cale nu are `x` pentru voi: rulați `ls -ld` pe fiecare                                                                              |
| `./script.sh: Permission denied`                                    | Fișierul nu are `x`: `chmod u+x script.sh`                                                                                                                       |
| `Operation not permitted` la `chmod` sau `chown`                    | Doar proprietarul poate rula `chmod` și doar `root` poate schimba proprietarul: folosiți `sudo`                                                                  |
| `student is not in the sudoers file.`                               | Utilizatorul nu este administrator: nu este în `wheel` (Fedora) sau în `sudo` (Ubuntu); un administrator trebuie să ruleze `sudo usermod -aG wheel student`, apoi utilizatorul se autentifică din nou |
| `sudo echo ... > file`: `Permission denied`                         | Redirectarea o face shell-ul vostru, înainte de `sudo`: folosiți `echo ... \| sudo tee file`                                                                     |
| `su: Authentication failure` la `su -`                              | Pe Fedora și pe Ubuntu, `root` nu are parolă: folosiți `sudo -i`                                                                                                 |
| Un grup nou nu apare în `id`                                        | Grupurile se citesc la autentificare: autentificați-vă din nou sau porniți un shell de autentificare nou cu `su - <USER>`                                        |
| `usermod -G` mi-a șters grupurile                                   | Ați uitat `-a`; adăugați-le la loc cu `sudo usermod -aG <GROUP> <USER>`                                                                                          |
| `passwd`: `BAD PASSWORD: The password is shorter than 8 characters` | Alegeți o parolă mai lungă și mai puțin simplă; ca `root`, o puteți seta oricum                                                                                  |
| `useradd: user 'bob' already exists`                                | Utilizatorul există deja: verificați cu `id bob`                                                                                                                 |
| `userdel: user bob is currently used by process 1234`               | `bob` are încă procese: opriți-le sau închideți mai întâi sesiunea lui `bob`                                                                                     |
| `rm: remove write-protected regular file?`                          | Nu aveți `w` pe fișier, dar îl aveți pe director: răspundeți `y` ca să-l ștergeți oricum                                                                         |
| `rm: cannot remove ... Operation not permitted` în `/tmp`           | Bitul sticky: doar proprietarul fișierului îl poate șterge                                                                                                       |
| Un fișier afișează în `ls -l` un număr în loc de proprietar         | Utilizatorul a fost șters, dar fișierul are încă UID-ul lui                                                                                                      |

## Exerciții {/* #exercises */}

- 🧪 [Primii pași](#first-steps) (exercițiile 1 - 14): câte o idee pe rând, în ordinea laboratorului, de făcut în
  laborator;
- 🏠 [Mai departe](#going-further) (exercițiile 15 - 32): exerciții mai lungi, de făcut acasă; multe dintre ele se uită
  la **eticheta** unui proces, explicată în [Credențialele unui proces](#the-credentials-of-a-process);
- 📝 [Provocări](#challenges) (exercițiile 33 - 39): cele mai grele, ca cele de la examen.

:::danger

Folosiți `sudo` doar acolo unde vă cere exercițiul și niciodată pe directoarele sistemului. Nu vă scoateți niciodată pe
voi (`student`) din grupul administratorilor, `wheel` pe Fedora și `sudo` pe Ubuntu, altfel pierdeți `sudo`.

:::

### 🧪 Primii pași {/* #first-steps */}

Faceți aceste exerciții în ordine, în timpul laboratorului. Fiecare începe cu ce trebuie să obțineți și încearcă **o**
idee din laborator: dacă vă blocați, citiți secțiunea indicată la finalul exercițiului. Rulați comenzile în `~/lab05`,
dacă exercițiul nu spune altfel.

**Utilizatori și grupuri**

1. **Arborele de exerciții**: Creați fișierele și directoarele folosite de celelalte exerciții, în `~/lab05`.

    1. rulați aceste comenzi (copiați-le din browser cu <kbd>Ctrl</kbd>+<kbd>C</kbd> și lipiți-le în terminal cu
       <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>V</kbd>):

       ```bash
       mkdir -p ~/lab05/noread ~/lab05/noenter
       cd ~/lab05
       printf 'buy milk\n' > notes.txt
       printf 'top secret\n' > noread/secret.txt
       printf 'top secret\n' > noenter/secret.txt
       printf '#!/bin/bash\nid -un\n' > myid.sh
       ```

    2. afișați arborele lui `~/lab05`.

    **Verificare:** `~/lab05` conține directoarele `noread` și `noenter`, fiecare cu un `secret.txt`, și fișierele
    `myid.sh` și `notes.txt`. <small>→ [Navigare](/docs/labs/02#navigation)</small>

2. **Cine sunt eu**: Aflați-vă numele de utilizator, UID-ul și grupurile, și ce utilizator rulează comenzile pe care le
    porniți.

    1. afișați-vă numele de utilizator, cu două comenzi diferite;
    2. afișați-vă UID-ul, grupul primar și toate grupurile cu **o singură** comandă; apoi doar UID-ul, apoi doar
       **numele** grupurilor;
    3. afișați ce știe sistemul despre utilizatorul `root`, fără să deveniți `root`;
    4. listați procesele terminalului vostru, cu utilizatorul care rulează fiecare dintre ele.

    💡 `man id`: căutați `name`, `user` și `groups`; `man ps`: căutați `-o` și `user`.

    **Verificare:** numele este `student`, iar UID-ul `1000`; grupul vostru primar este `student` (`1000`), iar
    grupurile voastre sunt `student` și `wheel` (Ubuntu: `sudo` și încă câteva); `root` are UID-ul `0` și doar grupul
    `root`. `bash` și `ps` rulează ca `student`: `ps` a fost pornit din shell-ul vostru și rulează ca același
    utilizator. <small>→ [Cine sunt eu](#who-am-i-whoami-and-id) · [Grupuri](#groups) · [Utilizatorul unui proces](#the-user-of-a-process)</small>

**Bazele de date ale utilizatorilor și ale grupurilor**

3. **Contul vostru în bazele de date**: Găsiți-vă contul în baza de date a utilizatorilor și în cea a grupurilor și
    citiți fiecare câmp al lui.

    1. afișați permisiunile lui `/etc/passwd` și ale lui `/etc/group`;
    2. afișați-vă linia din baza de date a utilizatorilor și spuneți ce este fiecare dintre cele 7 câmpuri ale ei;
    3. afișați liniile grupurilor `wheel` (Ubuntu: `sudo`) și `student` din baza de date a grupurilor; apoi afișați
       grupurile utilizatorului `student` cu `id`;
    4. găsiți utilizatorul cu UID-ul `0` și grupul cu GID-ul `10` (Ubuntu: `27`), după **numerele** lor;
    5. căutați utilizatorul `root` în două feluri: cu `grep` în `/etc/passwd` și în baza de date a utilizatorilor;
       comparați;
    6. afișați utilizatorii al căror shell **nu** este `nologin`.

    💡 `man getent`: bazele de date (`DATABASES`) sunt `passwd`, `group`, `shadow`, ...; `man 5 passwd` și
    `man 5 group` explică câmpurile; `man grep`: căutați `invert`.

    **Verificare:** ambele fișiere sunt `-rw-r--r-- root root`: oricine le poate citi. Linia voastră este
    `student:x:1000:1000:Student:/home/student:/bin/bash`: numele, `x` (parola este în altă parte), UID-ul, GID-ul
    grupului primar, numele complet, directorul propriu și shell-ul. `wheel` este `wheel:x:10:student`, dar `student`
    este `student:x:1000:`, fără membri, deși `id` arată că `student` este în el: membrii unui grup **primar** nu sunt
    listați. UID-ul `0` este `root`, iar GID-ul `10` este `wheel` (Ubuntu: `27` este `sudo`). Pe Fedora, `grep` afișează
    două linii, `root` și `operator` (al cărui director propriu este `/root`; Ubuntu îl are doar pe `root`); baza de
    date a utilizatorilor îl dă doar pe `root`. În afară de `root` și `student`, doar câțiva utilizatori de sistem au
    alt program decât `nologin`, de exemplu `/bin/sync` (Ubuntu mai are câțiva cu `/bin/false`): niciunul nu dă un
    shell. <small>→ [`/etc/passwd`](#etcpasswd) · [`/etc/group`](#etcgroup) · [`getent`](#getent)</small>

**Cum devenim `root`**

4. **`sudo`**: Rulați comenzi ca `root`, vedeți cum ține minte `sudo` parola, scrieți într-un fișier al lui `root` și
    porniți un shell al lui `root`.

    1. afișați-vă utilizatorul ca `root`; repetați și observați că parola nu mai este cerută;
    2. faceți-l pe `sudo` să uite parola și afișați-vă din nou utilizatorul ca `root`;
    3. încercați să afișați prima linie din `/etc/shadow` ca voi înșivă; apoi rulați **aceeași** comandă ca `root`,
       fără să o tastați din nou;
    4. creați ca `root` directorul `/srv/lab05` și fișierul gol `/srv/lab05/root.txt`; încercați să adăugați linia
       `hello` la sfârșitul fișierului cu `sudo echo` și `>>`; apoi faceți-o cu o comandă care scrie într-un fișier
       **și** pe ecran și afișați fișierul;
    5. porniți un shell de autentificare al lui `root`, afișați utilizatorul și directorul curent și ieșiți din el.

    💡 `man sudo`: căutați `invalidate` și `login`; `man bash`: căutați `HISTORY EXPANSION`, apoi `!!`; `man tee`:
    căutați `append`.

    **Verificare:** utilizatorul este `root`; după ce parola a fost uitată, este cerută din nou. Ca voi înșivă,
    `/etc/shadow` dă `Permission denied`; cu `!!`, `bash` afișează comanda în care s-a transformat `!!`, apoi o rulează,
    și vedeți linia lui `root`. `sudo echo` cu `>>` eșuează cu `Permission denied`, pentru că fișierul îl deschide
    shell-ul vostru, nu `sudo`; la final, fișierul conține `hello`. Shell-ul lui `root` pornește în `/root`, cu `#` în
    prompt. <small>→ [`sudo`](#sudo) · [Capcana redirectării](#the-redirect-trap)</small>

**Gestionarea utilizatorilor și a grupurilor**

5. **Doi utilizatori noi și un grup**: Creați-i pe `bob` și pe `carol`, care joacă în restul laboratorului rolul unui
    membru al grupului vostru și pe al unui străin, precum și grupul `students`, cu `bob` ca singur membru.

    1. verificați că `bob` și `carol` nu există încă;
    2. creați utilizatorul `bob`, cu director propriu, shell-ul `/bin/bash` și numele complet `Bob Jones`, și
       utilizatorul `carol`, la fel, cu numele complet `Carol White`;
    3. setați-le amândurora parola `uso2026`;
    4. creați grupul `students` și adăugați-l pe `bob` în el, fără să-i eliminați celelalte grupuri;
    5. afișați grupurile lui `bob` și ale lui `carol`, linia lui `students` din baza de date a grupurilor și
       proprietarii directoarelor din `/home`.

    💡 `man useradd`: căutați `home`, `shell` și `comment` (numele complet); `man -k group` găsește comanda care creează
    un grup; `man usermod`: căutați `-G`, apoi `append`.

    **Verificare:** înainte, `id` spune `no such user`; după, `bob` și `carol` au UID-urile `1001` și `1002` și câte un
    grup propriu, iar `/home/bob` și `/home/carol` le aparțin; `students` este `students:x:1003:bob`. Setarea parolei
    poate afișa avertismentul `BAD PASSWORD: The password is shorter than 8 characters`, dar `root` o poate seta
    oricum. <small>→ [Gestionarea utilizatorilor și a grupurilor](#managing-users-and-groups)</small>

6. **Un utilizator temporar**: Creați contul `dave`, modificați-l, puneți-l într-un grup și scoateți-l din el, apoi
    ștergeți-l fără să lăsați nimic în urmă.

    1. creați-l pe `dave`, cu director propriu, shell-ul `/bin/bash` și numele complet `Dave Brown`, **fără** parolă;
       afișați-i linia din baza de date a utilizatorilor și din `/etc/shadow` (cu `getent`, ca `root`);
    2. schimbați-i numele complet în `David Brown` și afișați-i din nou linia;
    3. adăugați-l în `students` cu `gpasswd` și afișați-i grupurile; apoi scoateți-l din `students` și afișați-le din
       nou;
    4. ștergeți-l pe `dave` împreună cu directorul lui și verificați că utilizatorul, grupul lui și `/home/dave` au
       dispărut.

    💡 `man usermod`: căutați `comment`; `man gpasswd`: căutați `add` și `delete`; `man userdel`: căutați `home`.

    **Verificare:** câmpul parolei lui `dave` este `!!` (Ubuntu: `!`): nimeni nu se poate autentifica încă drept el.
    După pasul 2, s-a schimbat doar al 5-lea câmp. Grupurile lui sunt `dave students`, apoi doar `dave`. La final,
    `id dave` afișează `no such user`, `getent group dave` nu afișează nimic, iar `ls -d /home/dave` spune
    `No such file or directory`. <small>→ [Gestionarea utilizatorilor și a grupurilor](#managing-users-and-groups) · [`/etc/shadow`](#etcshadow)</small>

**Autentificarea**

7. **Deveniți alt utilizator**: Autentificați-vă ca `bob` pe un terminal text și deveniți `carol` cu `su`.

    1. treceți pe al treilea terminal virtual și autentificați-vă ca `bob`; afișați utilizatorul, directorul curent și
       grupurile; încercați să vă afișați utilizatorul ca `root` cu `sudo`; ieșiți din sesiune și reveniți în Sway
       (acasă, în mediul vostru grafic);
    2. într-un terminal, deveniți `carol` cu un shell de **autentificare**; afișați utilizatorul și directorul curent;
       ieșiți cu `exit` și afișați din nou utilizatorul.

    💡 <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F3</kbd> (<kbd>Host</kbd>+<kbd>F3</kbd> în VirtualBox), iar înapoi cu
    <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F1</kbd> sau <kbd>F2</kbd>; `man su`: căutați `login`.

    **Verificare:** shell-ul lui `bob` rulează în `/home/bob`, cu grupurile `bob` și `students`; `sudo` îl refuză:
    `bob is not in the sudoers file.`. `su` cere parola lui `carol`, nu pe a voastră; shell-ul ei pornește în
    `/home/carol`; după `exit` sunteți din nou `student`. <small>→ [Autentificarea](#logging-in) · [`su`](#su) · [Terminale virtuale](/docs/labs/04#virtual-terminals)</small>

**Permisiunile fișierelor**

8. **Citiți permisiunile**: Învățați să citiți cui îi aparține un fișier și ce poate face fiecare utilizator cu el și
    prevedeți permisiunile unui fișier nou.

    1. afișați permisiunile, proprietarul și grupul lui `notes.txt`, `/etc/passwd`, `/etc/shadow` și ale directorului
       `~` însuși (nu ale conținutului lui);
    2. afișați aceleași informații cu `stat`, sub formă de litere **și** de numere, cu proprietarul, grupul și numele;
    3. afișați-vă `umask`-ul; **ghiciți** permisiunile unui fișier nou și ale unui director nou, apoi creați `new.txt`
       și `newdir` și verificați;
    4. setați `umask`-ul la `077`, creați `private.txt` și afișați-i permisiunile; apoi readuceți `umask`-ul la
       valoarea de la pasul 3, pentru că exercițiile următoare au nevoie de ea.

    💡 `man ls`: căutați `directories themselves`; `man stat`: căutați `%a`, `%A`, `%U`, `%G` și `--format`.

    **Verificare:** `notes.txt` este `-rw-r--r-- student student` (`644`; Ubuntu: `-rw-rw-r--`, `664`); `~` este
    `drwx------` (`700`) pe Fedora și `drwxr-x---` (`750`) pe Ubuntu. Cu `umask`-ul `0022`, `new.txt` este `rw-r--r--`,
    iar `newdir` este `rwxr-xr-x` (Ubuntu, `0002`: `rw-rw-r--` și `rwxrwxr-x`); cu `077`, `private.txt` este
    `rw-------`. <small>→ [Proprietar, grup și permisiuni](#owner-group-and-permissions) · [`umask`](#umask)</small>

9. **`chmod`**: Schimbați permisiunile pe rând, cu litere, sau pe toate deodată, cu un număr, și vedeți că un program
    are nevoie de `x` ca să ruleze.

    1. pe `notes.txt`, eliminați `r` pentru grup și pentru ceilalți;
    2. eliminați `w` pentru voi și încercați să adăugați o linie în fișier; adăugați `w` la loc și adăugați linia;
    3. readuceți permisiunile lui `notes.txt` la `rw-r--r--` cu **o singură** comandă, cu litere;
    4. rulați `./myid.sh`; dați-i `rwxr-xr-x`, cu un număr, și rulați-l din nou.

    **Verificare:** după pasul 1, `notes.txt` este `-rw-------`; la pasul 2 primiți `Permission denied`, chiar dacă
    fișierul este al vostru; după pasul 3 este din nou `-rw-r--r--`. Fără `x`, `./myid.sh` dă `Permission denied`; cu
    `755`, afișează `student`. <small>→ [`chmod`](#chmod)</small>

10. **`r`, `w` și `x` pentru directoare**: Vedeți ce permite fiecare permisiune pe un director și cine poate șterge un
    fișier.

    1. dați-i lui `noread` doar `x` pentru voi (`--x------`), iar lui `noenter` doar `r` (`r--------`);
    2. încercați să le listați, să intrați în ele și să afișați `secret.txt` din fiecare; apoi dați-le amândurora înapoi
       `rwxr-xr-x`;
    3. copiați `notes.txt` în `ro.txt` și faceți-l doar de citire pentru toată lumea; încercați să adăugați o linie în
       el, apoi ștergeți-l.

    **Verificare:** `noread` nu poate fi listat, dar `noread/secret.txt` poate fi afișat; `noenter` își listează numele
    (cu o eroare), dar nu se poate intra în el, iar fișierul din el nu poate fi afișat. Nu puteți scrie în `ro.txt`, dar
    `rm` întreabă `remove write-protected regular file 'ro.txt'?`, iar după `y` fișierul dispare: ștergerea unui fișier
    schimbă **directorul**, iar voi aveți `w` pe `~/lab05`. <small>→ [`r`, `w` și `x`](#r-w-and-x)</small>

11. **Un director partajat**: Partajați fișiere cu grupul `students` în `/srv/lab05` și vedeți care set de permisiuni
    se aplică proprietarului, unui membru al grupului și celorlalți.

    1. faceți-vă proprietarul lui `/srv/lab05` și dați-i grupul `students`, cu **o singură** comandă;
    2. creați în el, ca voi înșivă, `plan.txt`, cu textul `the plan`, și `report.txt`, cu textul `the report`;
    3. dați-i lui `report.txt` grupul `students` și permisiunile `rw-r-----`; listați directorul însuși, apoi
       conținutul lui;
    4. afișați ambele fișiere ca `bob` și ca `carol`; încercați să adăugați o linie în `report.txt` ca `bob`.

    ![Directorul partajat](./images/ex-shared-dir.svg)

    💡 `man chown`: căutați `OWNER:GROUP`. Nu sunteți membri ai grupului `students`, așa că și ca să dați unui fișier
    acest grup aveți nevoie de `root`. `man sudo`: căutați `-u user`; ca să scrieți ca `bob`, folosiți trucul din
    [Capcana redirectării](#the-redirect-trap).

    **Verificare:** `/srv/lab05` este `drwxr-xr-x student students`; `report.txt` este `-rw-r----- student students`,
    iar `plan.txt` este `-rw-r--r--` (Ubuntu: `-rw-rw-r--`), cu grupul vostru. `bob` citește ambele fișiere: pentru
    `report.txt` primește setul `g`, `r--`, așa că nu poate scrie în el (`Permission denied`). `carol` citește
    `plan.txt`, dar nu și `report.txt`: ea este una dintre **ceilalți**, care nu au nimic. <small>→ [Ce permisiuni se aplică?](#which-permissions-apply) · [`chown` și `chgrp`](#chown-and-chgrp)</small>

**Permisiuni speciale**

12. **Biții speciali**: Vedeți biții speciali ai sistemului, un director în care nimeni nu poate șterge fișierele
    celorlalți și un director care își dă grupul fiecărui fișier nou.

    1. afișați permisiunile lui `/usr/bin/passwd` și ale lui `/tmp`, sub formă de litere și de numere;
    2. creați `/tmp/student.txt`, dați-i **tuturor** `w` pe el și încercați să-l ștergeți ca `bob`;
    3. creați directorul `/srv/lab05/team`, dați-i grupul `students` și permisiunile `rwxrwsr-x`; creați
       `team/bob.txt` ca `bob` și listați-l.

    💡 [Permisiuni speciale](#special-permissions) are numerele biților. Nu sunteți membri ai grupului `students`, așa
    că schimbați grupul **și** permisiunile lui `team` ca `root` (vedeți
    [`setgid` pe un director](#setgid-on-a-directory)).

    **Verificare:** `/usr/bin/passwd` este `-rwsr-xr-x` (`4755`): `s`-ul proprietarului îl face să ruleze ca `root`,
    oricine l-ar porni; `/tmp` este `drwxrwxrwt` (`1777`). `bob` nu poate șterge `/tmp/student.txt`
    (`Operation not permitted`), deși are `w` pe el: `t`-ul lui `/tmp`. `team` este `drwxrwsr-x student students`, iar
    `bob.txt` este `-rw-r--r-- bob students`: a primit grupul directorului, nu grupul `bob`. <small>→ [`setuid`](#setuid) · [`setgid` pe un director](#setgid-on-a-directory) · [Bitul sticky](#the-sticky-bit)</small>

**Promptul**

13. **Promptul**: Schimbați ce afișează promptul lui `bash` și vedeți că este doar text, la care kernelul nu se uită.

    1. afișați valoarea lui `PS1`; schimbați promptul în `student in ~/lab05 $`, cu utilizatorul, calea **completă** și
       `$`-ul utilizatorului;
    2. schimbați promptul astfel încât să arate ca promptul lui `root`; afișați-vă utilizatorul și încercați să afișați
       `/etc/shadow`;
    3. reveniți la promptul inițial.

    💡 `man bash`: căutați `PROMPTING`.

    **Verificare:** promptul inițial este `[\u@\h \W]\$ ` pe Fedora (`\u@\h:\w\$ ` cu culori pe Ubuntu). Cu promptul
    fals de `root`, utilizatorul este tot `student`, iar `/etc/shadow` este refuzat în continuare: `whoami` întreabă
    kernelul, iar promptul este doar text. <small>→ [Promptul](#the-prompt) · [Schimbarea promptului](#changing-the-prompt)</small>

**Schimbarea unei parole**

14. **`bob` își schimbă parola**: Vedeți ce se schimbă în `/etc/shadow` când un utilizator își schimbă singur parola și
    cum poate face asta deși nu poate citi fișierul.

    1. afișați linia lui `bob` din `/etc/shadow`, ca `root`;
    2. deveniți `bob` cu un shell de autentificare și încercați să afișați linia lui din `/etc/shadow`;
    3. tot ca `bob`, schimbați-i parola: încercați întâi `bob123`, apoi `Lab05-k7Qx-2026`; ieșiți din shell-ul lui `bob`;
    4. afișați din nou linia lui, ca `root`, și comparați salt-ul, hash-ul și al 3-lea câmp cu cele de la pasul 1;
    5. readuceți parola lui `bob` la `uso2026`, ca `root`: exercițiile de acasă au nevoie de ea.

    💡 [Schimbarea parolei](#changing-a-password-passwd); uitați-vă la permisiunile lui `/usr/bin/passwd`.

    **Verificare:** ca `bob`, `getent shadow bob` nu afișează nimic: nu poate citi fișierul. `passwd` îi cere întâi
    parola curentă, `uso2026`, și refuză `bob123`, cu un mesaj care spune de ce (pe Fedora, `BAD PASSWORD: ...`). După
    schimbare, salt-ul și hash-ul sunt altele, iar al 3-lea câmp este ziua de azi, numărată de la 1 ianuarie 1970. `bob`
    a putut modifica `/etc/shadow` fără să-l poată citi, pentru că `/usr/bin/passwd` are `s`-ul proprietarului: rulează
    ca `root`, oricine l-ar porni. <small>→ [Schimbarea parolei](#changing-a-password-passwd) · [Hash-uri și salt](#hashes-and-salt) · [`setuid`](#setuid)</small>

### 🏠 Mai departe {/* #going-further */}

Fiecare exercițiu începe cu **obiectivul** lui: ce trebuie să fie adevărat la final sau ce trebuie să aflați. Pașii vă
duc până acolo, dar comenzile le alegeți voi. La final, verificați obiectivul în sine, nu doar că fiecare comandă a
mers. Exercițiile folosesc `bob`, `carol`, `students` și `/srv/lab05` din Primii pași.

**Eticheta unui proces**

15. **Credențialele shell-ului și ale lui `passwd`**: Vedeți toate credențialele pe care le păstrează kernelul pentru
    shell-ul vostru și aflați pe care dintre ele le schimbă bitul `setuid` al lui `passwd`.

    1. afișați PID-ul shell-ului; afișați-i utilizatorul real, utilizatorul efectiv, utilizatorul salvat și grupurile
       suplimentare, cu **o singură** comandă `ps`;
    2. afișați liniile `Uid:`, `Gid:` și `Groups:` din fișierul lui `status` din `/proc` și aflați din manual ce
       înseamnă fiecare dintre cele 4 numere din `Uid:`;
    3. în al doilea terminal, porniți `passwd` și **nu** tastați nimic; în primul terminal, afișați aceleași coloane și
       aceleași linii pentru `passwd`;
    4. opriți `passwd` cu <kbd>Ctrl</kbd>+<kbd>C</kbd>.

    ![Două terminale](./images/ex-two-terminals.svg)

    💡 `$$` este PID-ul shell-ului (laboratorul 04); `man ps`, secțiunea `STANDARD FORMAT SPECIFIERS`: căutați
    `real user`, `effective user`, `saved user` și `supplementary`; `man ps`: căutați `command name`; `man 5 proc`:
    căutați `Uid`.

    **Verificare:** pentru shell-ul vostru, cei trei utilizatori sunt `student`, `Uid:` conține de 4 ori `1000` (UID-ul
    real, cel efectiv, cel salvat și cel al sistemului de fișiere), iar `Groups:` conține `10` și `1000`, GID-urile lui
    `wheel` și `student` (Ubuntu: `27` pentru `sudo` și încă câteva). Pentru `passwd`, utilizatorul real este `student`,
    iar cel efectiv și cel salvat sunt `root`: `Uid:` este `1000 0 0 0`. `s`-ul lui `/usr/bin/passwd` a schimbat UID-ul
    efectiv și pe cel salvat, dar nu și pe cel real: `passwd` știe în continuare cine l-a pornit. <small>→ [Credențialele unui proces](#the-credentials-of-a-process) · [`setuid`](#setuid)</small>

16. **Cine poate opri un proces**: Aflați cum schimbă `sudo` credențialele comenzii pe care o pornește și cine poate
    opri apoi comanda cu `kill`.

    Pentru pașii 3 - 6, notați-vă **întâi** presupunerea, apoi verificați-o:

    1. în al doilea terminal, afișați PID-ul shell-ului, apoi rulați `sleep 300` ca `root`; în primul terminal, afișați
       arborele de procese al celui de-al doilea shell, cu PID-urile, și listați aceste procese cu PID-ul, PPID-ul,
       terminalul, utilizatorul real și cel efectiv;
    2. afișați linia `Uid:` a primului `sudo` (cel al cărui părinte este al doilea shell) și a lui `sleep`; care dintre
       ele are aceeași linie ca `passwd` din exercițiul 15 și de ce?
    3. puteți opri `sleep` cu `kill` și PID-ul lui?
    4. trimiteți semnalul primului `sudo`; ce se întâmplă cu `sleep`?
    5. în al doilea terminal, rulați `sleep 300` ca `bob`; afișați-i liniile `Uid:` și `Groups:`; îl puteți opri? Îl
       poate opri `bob` (rulați `kill` ca `bob`, cu `sudo`)?
    6. în al doilea terminal, porniți `passwd`; îl puteți opri din primul terminal? Dar `bob`?

    💡 `man pstree`: căutați `pid`; `ps -p` primește mai multe PID-uri, separate prin `,`; `man pgrep` găsește PID-ul
    unui proces după nume. `sudo` își rulează comanda pe un pseudoterminal nou (vedeți [`sudo`](#sudo)), așa că
    `ps -t` cu terminalul celui de-al doilea shell nu îl găsește pe `sleep`. Pentru `kill`, folosiți regula din
    [Ce credențiale se verifică](#which-credentials-are-checked).

    **Verificare:** arborele este `bash───sudo───sudo───sleep`. Primul `sudo` seamănă cu `passwd`, `1000 0 0 0`,
    pentru că este un program setuid; `sleep` este `0 0 0 0`: `sudo`, ca `root`, a setat **toate** UID-urile copilului
    său. Așadar nu puteți opri `sleep` (`Operation not permitted`), dar **puteți** opri primul `sudo`, al cărui UID real
    este al vostru, iar `sudo` transmite semnalul mai departe: se oprește și `sleep`. `sleep`-ul lui `bob` are de 4 ori
    UID-ul lui `bob` și GID-urile lui `bob` și `students`, ca după o autentificare: `bob` îl poate opri, voi nu. Puteți
    opri `passwd`-ul vostru, `bob` nu poate. <small>→ [Ce credențiale se verifică](#which-credentials-are-checked) · [`sudo`](#sudo)</small>

17. **Jucați rolul unui program setuid**: Vedeți cum îi permite UID-ul salvat unui program setuid să lase `root`
    deoparte și să-l ia înapoi, comportându-vă chiar voi ca un astfel de program, ca în [UID-ul salvat](#the-saved-uid).

    După fiecare pas, afișați din al doilea terminal linia `Uid:` a procesului `python3` și încercați să citiți din
    `python3` prima linie din `/etc/shadow`:

    1. în primul terminal, porniți `python3` ca `root`; afișați-i UID-ul real, cel efectiv și cel salvat;
    2. deveniți `student` în UID-ul real și în cel efectiv, dar păstrați `root` în UID-ul salvat;
    3. luați înapoi `root`, doar în UID-ul efectiv;
    4. setați toate cele trei UID-uri la `1000` și încercați încă o dată să luați înapoi `root`.

    ![Jucați rolul unui program setuid](./images/ex-saved-uid.svg)

    💡 În `python3`, rulați întâi `import os`, apoi `help(os.getresuid)`, `help(os.setresuid)` și `help(os.seteuid)`;
    `open('/etc/shadow').readline()` citește prima linie a unui fișier; `exit()` iese din `python3`.

    **Verificare:** `Uid:` este `0 0 0 0`, apoi `1000 1000 0 1000` și `/etc/shadow` este refuzat, apoi `1000 0 0 0` și
    fișierul poate fi citit din nou, pentru că `0` era UID-ul salvat; după ultimul pas, `Uid:` este
    `1000 1000 1000 1000`, iar `seteuid(0)` eșuează cu `Operation not permitted`. Al 4-lea număr, UID-ul sistemului de
    fișiere, îl urmează mereu pe al 2-lea. <small>→ [UID-ul salvat](#the-saved-uid) · [Ce credențiale se verifică](#which-credentials-are-checked)</small>

18. **O colegă nouă, de la prima până la ultima zi**: `erin` intră în echipă, devine administrator și pleacă după o
    vreme. Gestionați-i contul de la prima până la ultima zi și aflați de ce vechiul ei shell nu primește noile
    drepturi.

    Verificați fiecare pas înainte să treceți la următorul:

    1. creați-i contul, cu **două** comenzi: director propriu, shell-ul `/bin/bash`, numele complet `Erin Gray`,
       grupul suplimentar `students` și o parolă;
    2. autentificați-vă ca `erin` pe al treilea terminal virtual; verificați că pornește în `/home/erin`, că este în
       `students` și că `sudo` o refuză;
    3. devine administrator: cât timp este încă autentificată pe `tty3`, faceți-o administrator. În **același shell**
       al lui `erin`, afișați `id erin`, apoi `id`, apoi linia `Groups:` din `/proc/$$/status` și încercați din nou
       `sudo`; apoi ieșiți din sesiune, autentificați-vă din nou și încercați încă o dată;
    4. își schimbă numele: setați-i numele complet `Erin Black`;
    5. pleacă: închideți-i sesiunea și ștergeți-i contul, grupul și directorul.

    💡 `man useradd`: căutați `shell`, `comment` și `groups`; `man usermod`; `man userdel`; grupul administratorilor
    se află în tabelul din [`sudo`](#sudo).

    **Verificare:** după pasul 1, `id erin` arată `students`, iar linia ei conține `Erin Gray` și `/bin/bash`. La pasul
    3, `id erin` arată `wheel`, pentru că citește baza de date, dar `id` și `Groups:` nu îl au (nu apare `10`): eticheta
    vechiului shell a fost setată la autentificare, iar `sudo` o refuză în continuare. După o nouă autentificare, `sudo`
    merge, cu parola lui `erin`. După pasul 4 s-a schimbat doar câmpul 5. La final, `id erin`, `getent group erin` și
    `ls -d /home/erin` nu găsesc nimic. <small>→ [Autentificarea](#logging-in) · [Gestionarea utilizatorilor și a grupurilor](#managing-users-and-groups)</small>

**Utilizatori și parole**

19. **Intrarea parolei voastre**: Citiți-vă linia din `/etc/shadow`, găsiți părțile hash-ului ei și aflați când v-ați
    schimbat ultima dată parola.

    1. afișați permisiunile lui `/etc/shadow`, apoi încercați să vă afișați linia din el cu `getent`, ca voi înșivă și
       ca `root`;
    2. găsiți algoritmul și salt-ul hash-ului vostru;
    3. afișați datele parolei contului vostru; transformați al 3-lea câmp al liniei voastre într-o dată.

    💡 `man 5 shadow` explică câmpurile; `man 5 crypt`: căutați `yescrypt`; `man chage`: căutați `list`; `man date`:
    căutați `--date` (data poate fi `1970-01-01 + N days`).

    **Verificare:** `/etc/shadow` este `----------` (Ubuntu: `-rw-r----- root shadow`); ca voi înșivă, `getent shadow`
    nu afișează nimic; ca `root`, afișează o linie al cărei hash începe cu `$y$`, _yescrypt_; salt-ul este partea dintre
    al 3-lea și al 4-lea `$`. Cele două date de la pasul 3 sunt aceeași zi. <small>→ [`/etc/shadow`](#etcshadow) · [Hash-uri și salt](#hashes-and-salt)</small>

20. **Auditați baza de date a utilizatorilor**: Un atacator care devine `root` adaugă adesea un al doilea utilizator cu
    UID-ul `0`: un `root` ascuns, cu un nume nevinovat. Verificați că sistemul vostru nu are un astfel de utilizator
    și aflați ce utilizatori se pot autentifica cu un shell.

    1. găsiți toți utilizatorii cu UID-ul `0`;
    2. găsiți utilizatorii al căror shell este `/bin/bash`;
    3. găsiți utilizatorii al căror director se află în `/home` și numărați-i.

    💡 Citiți utilizatorii cu `getent passwd`; UID-ul este câmpul 3, directorul utilizatorului câmpul 6, iar shell-ul
    câmpul 7. Filtrați liniile cu `grep` (laboratorul 03): `[^:]*:` se potrivește cu un câmp și cu `:`-ul lui, iar `^`
    cu începutul liniei. Afișați doar numele cu `cut` (`man cut`: căutați `delimiter` și `fields`). De ce nu ajunge
    `grep 0`? De ce nu ajunge nici `grep ':0:'`?

    **Verificare:** doar `root` are UID-ul `0`. `grep 0` găsește și orice linie care conține un `0` oriunde, de exemplu
    UID-ul `1000`; `grep ':0:'` găsește și utilizatorii al căror **GID** este `0`. `/bin/bash` este shell-ul lui
    `root`, `student`, `bob` și `carol`; utilizatorii din `/home` sunt `student`, `bob` și `carol`: `3`. <small>→ [`/etc/passwd`](#etcpasswd) · [`getent`](#getent)</small>

21. **Conturi suspendate**: `bob` și `carol` au aceeași parolă. `bob` pleacă în concediu, iar stagiul de practică al
    lui `carol` s-a încheiat pe 1 ianuarie 2020. Aflați dacă `/etc/shadow` arată că au aceeași parolă, apoi opriți
    ambele conturi fără să ștergeți nimic și fără să le schimbați parolele, apoi lăsați-i din nou să intre: trebuie să
    se autentifice cu parolele **vechi**.

    1. afișați liniile lui `bob` și `carol` din `/etc/shadow` și comparați-le salt-urile și hash-urile;
    2. blocați parola lui `bob` și afișați-i linia; încercați să deveniți `bob` cu `su`, cu parola corectă; deblocați-o
       și încercați din nou;
    3. faceți contul lui `carol` să expire pe 1 ianuarie 2020 și afișați-i datele parolei și linia; încercați să
       deveniți `carol`; apoi eliminați data de expirare.

    💡 `man passwd`: căutați `lock`; `man chage`: căutați `expiredate` și `-1`.

    **Verificare:** salt-urile sunt diferite, deci și hash-urile sunt diferite: nimeni nu poate afla din `/etc/shadow`
    că parolele sunt aceleași. Hash-ul lui `bob` primește `!!` în față (Ubuntu: `!`), iar `su` eșuează cu
    `Authentication failure`; după deblocare, semnele `!` dispar și `su` merge. Câmpul 8 al lui `carol` devine `18262`,
    ziua de 1 ianuarie 2020, iar `su` o refuză cu un mesaj că contul a expirat; la final, câmpul este din nou gol. <small>→ [`/etc/shadow`](#etcshadow) · [Hash-uri și salt](#hashes-and-salt) · [Schimbarea parolei](#changing-a-password-passwd)</small>

22. **Sunt de vină permisiunile?**: Învățați să vă dați seama din eroare când ajută `sudo` și când nu.

    Rulați fiecare comandă fără `sudo`, decideți dacă eroarea ține de **permisiuni** (atunci `sudo` o rezolvă) sau de
    altceva (atunci `sudo` nu ajută) și verificați cu `sudo`:

    1. `cat /var/log/kill/them/all.log`;
    2. `userdel hariseldon`;
    3. `chown $USER /home/search/and/destroy`;
    4. `cat /root/missing.txt`;
    5. `dnf install sports-illustrated` (pe Ubuntu, `apt install sports-illustrated`).

    **Verificare:** când eroarea ținea de permisiuni (2, 4 și 5), `sudo` o face să dispară, iar comanda eșuează apoi cu
    eroarea **reală**: utilizatorul, fișierul sau pachetul nu există. Când eroarea ținea de altceva (1 și 3,
    `No such file or directory`), `sudo` dă aceeași eroare. <small>→ [`sudo`](#sudo) · [`r`, `w` și `x`](#r-w-and-x)</small>

**Permisiuni**

23. **`x` pe fiecare director**: `bob` trebuie să vă citească `notes.txt`. Găsiți schimbarea **minimă** care îi permite
    asta, fără să-l lăsați să vadă numele celorlalte fișiere ale voastre.

    1. ca `bob`, afișați `notes.txt` din `~/lab05`-ul vostru, cu calea lui absolută;
    2. aflați de ce eșuează, uitându-vă la permisiunile fiecărui director din cale;
    3. dați-le celorlalți **doar** `x` pe directorul vostru și încercați din nou; apoi încercați să vă listați
       directorul ca `bob`;
    4. luați `x`-ul înapoi.

    **Verificare:** `/home/student` este `drwx------` (Ubuntu: `drwxr-x---`), iar `bob` face parte dintre ceilalți, așa
    că nu poate trece prin el; cu `x` pentru ceilalți, `bob` citește `notes.txt` (care este `rw-r--r--`), dar nu vă
    poate lista directorul: nu are `r` pe el. <small>→ [`r`, `w` și `x`](#r-w-and-x)</small>

24. **Proprietarul se verifică primul**: Arătați că kernelul folosește **un singur** set de permisiuni, chiar și atunci
    când alt set ar permite mai mult.

    1. copiați `notes.txt` în `/srv/lab05/first.txt` și dați-i grupul `students` (nu sunteți membri: folosiți
       `root`);
    2. dați-i `----rw-r--`;
    3. încercați să-l citiți voi înșivă, ca `bob` și ca `carol`; apoi încercați să adăugați o linie în el ca `bob`.

    **Verificare:** voi, proprietarul, nu îl puteți citi (`Permission denied`); `bob` îl poate citi și scrie (setul
    `g`), iar `carol` îl poate citi (setul `o`). <small>→ [Ce permisiuni se aplică?](#which-permissions-apply)</small>

25. **Octal de mână**: Învățați să treceți de la literele permisiunilor la numere și invers, fără ajutor.

    Fără calculator:

    1. scrieți ca numere: `rwxr-x---`, `rw-rw-r--`, `r--------`, `rwx--x--x`, `rw-r--r--`;
    2. scrieți cu litere: `751`, `664`, `400`, `700`, `555`;
    3. verificați-vă răspunsurile pe un fișier `test.txt`.

    **Verificare:** setați fiecare valoare pe `test.txt` în forma de la care ați pornit și afișați cealaltă formă cu
    `stat`: trebuie să fie cea pe care ați scris-o. <small>→ [`chmod`](#chmod)</small>

26. **Un `umask` privat**: Faceți private toate fișierele noi ale shell-ului și aflați pentru ce procese și cât timp
    rămâne setarea.

    Într-un terminal nou:

    1. setați `umask`-ul astfel încât fișierele și directoarele noi să fie private, apoi creați `private2.txt` și
       `privdir`;
    2. afișați `umask`-ul unui `bash` copil;
    3. afișați linia `Umask:` din fișierul `status` al shell-ului;
    4. închideți terminalul, deschideți unul nou și afișați `umask`-ul.

    💡 `man 5 proc`: căutați `Umask`.

    **Verificare:** `private2.txt` este `rw-------`, iar `privdir` este `rwx------`; copilul afișează același `umask` ca
    părintele: kernelul păstrează un `umask` pentru fiecare proces, iar un copil îl moștenește, la fel ca pe etichetă;
    noul terminal are din nou vechiul `umask`. <small>→ [`umask`](#umask)</small>

**Puzzle-uri cu permisiuni**: În fiecare exercițiu, setați permisiunile (și grupul, dacă e nevoie) astfel încât
**exact** utilizatorii indicați să poată face lucrurile indicate și nimic în plus. Nu sunteți membri ai grupului
`students`, așa că pentru a da unui fișier acest grup aveți nevoie de `root`. Apoi testați fiecare utilizator
(`student`, `bob` și `carol`), citind, listând, scriind sau rulând fișierele.

27. **Un director public**: Publicați fișiere pe care le poate citi oricine, dar pe care doar voi le puteți modifica.

    `/srv/lab05/public`, cu două fișiere, `a.txt` și `b.txt`:

    - oricine poate lista directorul și citi fișierele;
    - doar `student` poate crea, șterge sau modifica fișiere în el;
    - folosiți **un singur** `chmod` cu litere pentru director și pentru toate fișierele.

    ![Un director public](./images/ex-public.svg)

    Începeți prin a închide `public` și tot ce conține pentru grup și pentru ceilalți, cu **o singură** comandă, și
    verificați că `carol` nu poate citi `a.txt`; apoi deschideți-l așa cum se cere.

    💡 `man chmod`: căutați `recursive` și `X`-ul mare.

    **Verificare:** cât timp este închis, `public` este `drwx------`, iar `a.txt` este `-rw-------`; la final, `carol`
    listează `public` și citește `a.txt`, dar nu poate crea `public/c.txt` și nici modifica `a.txt`; fișierele nu au
    primit `x`. <small>→ [`chmod`](#chmod)</small>

28. **Un script pentru grup**: Lăsați grupul să ruleze un script, fără să-l lăsați să-l modifice.

    `/srv/lab05/tool.sh`, o copie a lui `myid.sh`:

    - membrii grupului `students` îl pot rula, dar nu îl pot modifica;
    - nimeni altcineva nu îl poate citi sau rula.

    ![Un script pentru grup](./images/ex-tool.svg)

    Încercați întâi să-i dați grupului doar `x` și să-l rulați ca `bob`; apoi găsiți permisiunile corecte.

    **Verificare:** cu doar `x` pentru grup, `bob` primește `Permission denied`: gândiți-vă ce trebuie să facă `bash`
    cu fișierul ca să ruleze comenzile din el. Cu permisiunile corecte, `bob` îl rulează, iar scriptul afișează `bob`;
    `carol` nu îl poate nici citi, nici rula. <small>→ [`r`, `w` și `x`](#r-w-and-x)</small>

29. **Doar pentru cine știe numele**: Ascundeți un fișier într-un director, astfel încât să-l poată citi doar cei care
    îi știu numele.

    `/srv/lab05/hidden`, cu fișierul `key.txt`:

    - membrii grupului `students` pot citi `key.txt` dacă îi știu numele, dar nu pot lista directorul;
    - nimeni altcineva nu poate face nimic.

    ![Doar pentru cine știe numele](./images/ex-hidden.svg)

    **Verificare:** `bob` poate afișa `hidden/key.txt`, dar `ls hidden` este refuzat; `carol` nu poate ajunge la
    `key.txt`, nici măcar știindu-i numele. <small>→ [`r`, `w` și `x`](#r-w-and-x)</small>

30. **O listă privată**: Ajutați-l pe `bob` să partajeze un fișier din directorul lui cu grupul lui și cu nimeni
    altcineva.

    Ca `bob`:

    ![O listă privată](./images/ex-private.svg)

    1. închideți `/home/bob` pentru toată lumea în afară de `bob` (pe Fedora este deja așa, pe Ubuntu nu); creați
       `/home/bob/todo.txt` cu textul `Bob's TODO list`, pe care **doar** `bob` îl poate citi și scrie; verificați că
       `carol` nu îl poate citi;
    2. schimbați-l astfel încât să-l poată citi și membrii grupului `bob`, iar nimeni altcineva să nu poată face nimic;
    3. ieșiți, adăugați-vă (`student`) în grupul `bob` și încercați să citiți fișierul dintr-un **shell de
       autentificare nou**;
    4. aflați de ce tot eșuează și lăsați-l pe `bob` să modifice directorul potrivit ca să meargă, fără să o lase pe
       `carol` să intre;
    5. scoateți-vă din grupul `bob`.

    **Verificare:** la pasul 3 accesul este tot refuzat, deși sunteți în grupul `bob`, iar fișierul îi dă grupului său
    `r`: uitați-vă la **fiecare** director din cale. După corectură puteți citi fișierul, dar nu puteți lista
    `/home/bob`, iar `carol` tot nu are acces la nimic. <small>→ [Ce permisiuni se aplică?](#which-permissions-apply) · [`r`, `w` și `x`](#r-w-and-x)</small>

**Promptul**

31. **Un prompt care spune adevărul și rămâne**: Spre deosebire de `root`-ul fals din Primii pași, faceți un prompt care
    afișează UID-ul shell-ului, astfel încât să se schimbe singur, și păstrați-l pentru orice terminal nou.

    1. faceți un prompt care vă afișează UID-ul, dintr-o variabilă a lui `bash`, și `$`-ul sau `#`-ul;
    2. porniți un shell de autentificare al lui `root`, setați în el **același** `PS1` și uitați-vă la prompt; ieșiți
       din el;
    3. adăugați `PS1`-ul vostru la sfârșitul lui `~/.bashrc`, deschideți un terminal nou și verificați promptul;
    4. porniți un shell de autentificare al lui `root` și uitați-vă la promptul lui.

    💡 `man bash`: căutați `EUID`; scrieți `PS1` între ghilimele **simple**, ca variabila să fie înlocuită de fiecare
    dată când se afișează promptul, nu o singură dată, când îl setați.

    **Verificare:** promptul vostru afișează `1000` și `$`; shell-ul lui `root` afișează `0` și `#`: `\$` și `$EUID`
    vin din eticheta shell-ului, nu dintr-un text tastat de voi. Noul terminal are promptul vostru; shell-ul lui `root`
    nu îl are: citește `/root/.bashrc`, nu fișierul vostru. <small>→ [Schimbarea promptului](#changing-the-prompt)</small>

**Curățenie**

32. **Curățenie**: Lăsați sistemul așa cum era înainte de laborator.

    1. ștergeți utilizatorii `bob` și `carol`, cu directoarele lor, precum și grupul `students`;
    2. ștergeți `/srv/lab05` și `/tmp/student.txt`;
    3. ștergeți `~/lab05` (dacă eșuează, aflați ce director nu are `w` sau `x` pentru voi);
    4. eliminați `PS1`-ul vostru din `~/.bashrc`.

    **Verificare:** `id bob`, `id carol` și `getent group students` nu găsesc nimic; `/srv` nu mai conține `lab05`. <small>→ [Gestionarea utilizatorilor și a grupurilor](#managing-users-and-groups)</small>

### 📝 Provocări {/* #challenges */}

Aceste exerciții seamănă cu cele de la examen. Fiecare vă dă un **rezultat** de atins și **regulile** pe care trebuie
să le respectați, dar nu și pașii: comenzile le alegeți voi. Fiecare se termină cu **Verificarea** după care va fi
notat. Multe dintre ele au nevoie de [Credențialele unui proces](#the-credentials-of-a-process).

Toate provocările pornesc de la aceeași configurație, cea pe care o veți găsi la examen: utilizatorii `bob`, `carol` și
`dave`, grupul `students`, cu `bob` și `dave` ca membri, și directorul gol `/srv/exam`, al lui `root`. Copiați și
rulați aceste comenzi o singură dată, înainte de prima provocare (nu schimbă utilizatorii și grupurile care există
deja):

```bash
sudo groupadd -f students
for u in bob carol dave; do id "$u" &> /dev/null || sudo useradd -m -s /bin/bash "$u"; done
sudo usermod -aG students bob
sudo usermod -aG students dave
sudo mkdir -p /srv/exam
```

Utilizatorii nu au parole: rulați comenzi ca ei cu `sudo -u <USER>`. Când terminați toate provocările, ștergeți totul
cu:

```bash
sudo rm -rf /srv/exam
for u in bob carol dave grace; do id "$u" &> /dev/null && sudo userdel -r "$u"; done
sudo groupdel students
```

33. **Un atac offline**: Vedeți cum depinde un hash de parolă și de salt, apoi găsiți o parolă pornind de la hash-ul
    ei, așa cum ar face un atacator care are o copie a lui `/etc/shadow`.

    1. calculați hash-ul parolei `pass123` cu _SHA-512_ și salt-ul `abc`, de două ori; apoi cu salt-ul `xyz`; apoi
       calculați hash-ul lui `pass124` cu salt-ul `abc`;
    2. un utilizator are această linie într-o copie furată a lui `/etc/shadow`:

       ```text
       mallory:$6$uso2026$YT5ail.RilPFhAJ4Zo6bXZ6qayzFgl959rpxQZDutFYsI3F/Yq4zt5BFc04bFuFJN7PE9Scof6J8VZUPjp7Y20:20737:0:99999:7:::
       ```

       știți că parola este una dintre `123456`, `password`, `qwerty`, `dragon` și `letmein`; aflați care, cu **o
       singură** linie de comandă.

    💡 `man openssl-passwd`: căutați `SHA512` și `salt`; o singură comandă poate calcula hash-urile mai multor parole.
    Găsiți algoritmul și salt-ul în hash-ul lui `mallory`; `man grep`: căutați `line-number`.

    **Verificare:** la pasul 1, primele două hash-uri sunt identice; cu alt salt sau cu o singură literă diferită,
    hash-ul este complet diferit. La pasul 2, linia voastră de comandă afișează exact un hash, cel al lui `mallory`, cu
    numărul liniei lui; numărul liniei vă spune parola. Explicați de ce `/etc/shadow` nu trebuie să poată fi citit de
    oricine. <small>→ [Hash-uri și salt](#hashes-and-salt)</small>

34. **Prevedeți credențialele**: Prevedeți toate UID-urile și GID-urile a trei procese, verificați-le cu o singură
    comandă și găsiți toate procesele care au puterea lui `root` și au fost pornite dintr-un terminal.

    Cele trei procese: shell-ul vostru, un `sleep 300` pornit ca `bob` cu `sudo` și un `passwd` care așteaptă o parolă.

    1. **întâi** completați pe hârtie tabelul de mai jos, pornind de la
       [Cum se schimbă credențialele](#how-the-credentials-change);
    2. porniți cele două procese în alte terminale; afișați, cu **o singură** comandă `ps`, câte o coloană pentru
       fiecare: UID-ul real, cel efectiv, cel salvat și cel al sistemului de fișiere, precum și GID-ul real și cel
       efectiv, pentru cele trei procese; comparați;
    3. găsiți toate procesele care rulează cu utilizatorul efectiv `root`, dar au un terminal, și afișați pentru fiecare
       terminalul, utilizatorul real și cel efectiv și comanda.

    ![Credențialele de aflat](./images/ex-credentials.svg)

    💡 `man ps`, `STANDARD FORMAT SPECIFIERS`: căutați `saved` și `filesystem`; `-p` primește mai multe PID-uri,
    separate prin `,`; procesele fără terminal au `?` în coloana `TTY`.

    **Verificare:** shell-ul are `1000` peste tot; `sleep` are UID-ul lui `bob` peste tot și GID-ul lui `bob`; `passwd`
    are UID-ul real `1000`, celelalte trei `0`, și GID-urile `1000`: are doar bitul setuid, nu și pe cel setgid. La
    pasul 3 vedeți `agetty`-ul terminalelor virtuale pe care le-ați deschis, dar pe care nu este autentificat nimeni,
    `login`-ul fiecăruia pe care este autentificat cineva, procesele `sudo`, `su` și `passwd` care încă rulează și
    shell-urile lui `root`; utilizatorul real vă spune cine l-a pornit pe fiecare. <small>→ [Credențialele unui proces](#the-credentials-of-a-process)</small>

35. **Cine ce poate face**: Prevedeți ce utilizatori pot deschide ce fișiere și cine poate opri ce proces, apoi
    demonstrați fiecare răspuns cu o singură comandă.

    Creați două fișiere cu aceste comenzi:

    ```bash
    printf 'file a\n' | sudo tee /srv/exam/a.txt > /dev/null
    printf 'file b\n' | sudo tee /srv/exam/b.txt > /dev/null
    sudo chown root:students /srv/exam/a.txt
    sudo chmod 640 /srv/exam/a.txt
    sudo chown bob:students /srv/exam/b.txt
    sudo chmod 064 /srv/exam/b.txt
    ```

    Apoi porniți aceste procese; rulați `passwd` într-un al doilea terminal și nu tastați nimic:

    ```bash
    sudo -b -u bob sleep 601
    sudo -b sleep 602
    ```

    1. **întâi**, pe hârtie: pentru `student`, `bob`, `carol` și `dave`, pot citi `a.txt`? Pot citi `b.txt`? Pot scrie
       în `b.txt`?
    2. **întâi**, pe hârtie: pentru `student`, `bob` și `carol`, pot opri `sleep 601`? `sleep 602`? `passwd`?
    3. demonstrați fiecare răspuns din cele două tabele cu **o singură** comandă, ca utilizatorul potrivit;
    4. opriți cele trei procese.

    💡 `man sudo`: căutați `background`; `man pgrep`: căutați `full`, ca să găsiți un proces după toată linia lui de
    comandă; `man 2 kill`: căutați `If sig is 0`, ca să testați dacă aveți voie să trimiteți un semnal, fără să-l
    trimiteți.

    **Verificare:** fișierele:

    |           | citește `a.txt` | citește `b.txt` | scrie în `b.txt` |
    | --------- | --------------- | --------------- | ---------------- |
    | `student` | nu              | da              | nu               |
    | `bob`     | da              | **nu**          | **nu**           |
    | `carol`   | nu              | da              | nu               |
    | `dave`    | da              | da              | da               |

    `bob` este proprietarul lui `b.txt`, așa că primește setul `u`, `---`, chiar dacă grupul lui poate scrie în el.
    Procesele: `student` poate opri doar `passwd`, al cărui UID real este al lui; `bob` poate opri doar `sleep 601`,
    care rulează cu toate UID-urile lui; `carol` nu poate opri niciunul; nimeni în afară de `root` nu poate opri
    `sleep 602`. Fiecare răspuns trebuie să vină dintr-o comandă care afișează conținutul sau o eroare
    (`Permission denied`, `Operation not permitted`). <small>→ [Ce permisiuni se aplică?](#which-permissions-apply) · [Ce credențiale se verifică](#which-credentials-are-checked)</small>

36. **Un proiect pentru grup**: Construiți un director de proiect pentru un grup, în care fișierele aparțin grupului și
    nimeni nu poate șterge munca celorlalți.

    Faceți `/srv/exam/project` astfel încât:

    - `root` să fie proprietarul lui și doar membrii grupului `students` să poată intra în el, să-l poată lista și să
      poată crea fișiere în el;
    - orice fișier nou din el să aparțină grupului `students`, indiferent cine îl creează;
    - un membru să nu poată șterge sau redenumi fișierele altui membru.

    ![Un proiect pentru grup](./images/ex-project.svg)

    **Verificare:** `stat -c '%A %U %G' /srv/exam/project` afișează `drwxrws--T root students`: ați avut nevoie de
    **doi** biți speciali. Un fișier creat de `bob` și unul creat de `dave` au amândouă grupul `students`, deși
    grupurile lor primare sunt `bob` și `dave`; `bob` primește `Operation not permitted` când șterge fișierul lui
    `dave`; `carol` primește `Permission denied` când listează directorul. <small>→ [`setgid` pe un director](#setgid-on-a-directory) · [Bitul sticky](#the-sticky-bit)</small>

37. **O cutie pentru teme**: Construiți o cutie în care studenții își predau temele fără să vadă numele fișierelor
    celorlalți și fără să le modifice, dar pe care profesorul o poate totuși curăța.

    Faceți `/srv/exam/homework` astfel încât:

    - `student`, profesorul, să fie proprietarul lui și să poată face orice în el;
    - membrii grupului `students` să poată preda fișiere (să le creeze), dar să nu poată lista directorul, deci să nu
      poată vedea numele celorlalți;
    - să nu poată șterge sau înlocui fișierele celorlalți, chiar dacă le ghicesc numele;
    - `carol` să nu poată face nimic.

    ![O cutie pentru teme](./images/ex-homework.svg)

    Predați `bob.txt` ca `bob` și `dave.txt` ca `dave`; ca `bob`, încercați să listați directorul, să ștergeți
    `dave.txt` și să-l afișați; apoi, ca profesor, ștergeți `dave.txt`.

    **Verificare:** `stat -c '%A %U %G' /srv/exam/homework` afișează `drwx-wx--T student students`. `bob` poate crea
    fișiere, dar nu poate lista directorul și nici șterge `dave.txt` (`Operation not permitted`); **poate** însă afișa
    `dave.txt`, pentru că i-a ghicit numele: este `rw-r--r--`, iar `bob` are `x` pe director. Ascunderea numelor nu
    protejează conținutul; doar permisiunile fișierului o fac. Profesorul **poate** șterge `dave.txt`: **proprietarul
    directorului** poate șterge orice fișier din el, chiar și cu bitul sticky; `carol` primește `Permission denied` la
    orice. <small>→ [`r`, `w` și `x`](#r-w-and-x) · [Bitul sticky](#the-sticky-bit)</small>

38. **Programe setuid și scripturi**: Găsiți programele sistemului care rulează ca proprietarul lor și arătați de ce
    bitul setuid merge pentru programe, dar nu și pentru scripturi.

    1. listați toate fișierele setuid din `/usr`, în formatul lui `ls -l`, fără erori, și numărați-le;
    2. ca `root`, copiați `/usr/bin/id` în `/srv/exam/rootid` și dați-i bitul setuid și `rwxr-xr-x`; rulați-l ca voi
       înșivă și ca `bob`;
    3. ca `root`, creați scriptul `/srv/exam/rootid.sh`, cu cele două linii `#!/bin/bash` și `id`, cu aceleași
       permisiuni; rulați-l ca voi înșivă;
    4. creați `/tmp/cap.txt` și dați-i bitul setuid **fără** `x` pentru proprietar; creați directorul `/tmp/capdir` cu
       `rwxrwx---` și bitul sticky, cu **un singur** număr; afișați permisiunile amândurora, cu litere și ca numere;
    5. explicați de ce `/usr/bin/sudo` este `---s--x--x` pe Fedora și ce permite în plus `-rwsr-xr-x` pe Ubuntu;
    6. ștergeți `rootid`, `rootid.sh`, `cap.txt` și `capdir`.

    💡 `man find`: căutați `-perm` și `-ls`.

    **Verificare:** există câteva zeci de programe setuid, toate ale lui `root`. `rootid` afișează
    `uid=1000(student) gid=1000(student) euid=0(root) ...` (iar pentru `bob`, `uid=` al lui `bob`): `id` afișează
    `euid` când UID-ul efectiv nu este cel real. Scriptul afișează doar `uid=1000(student) ...`, fără `euid`: kernelul
    ignoră bitul setuid pe scripturi. `cap.txt` este `-rwSr--r--` (`4644`), iar `capdir` este `drwxrwx--T` (`1770`): o
    literă mare înseamnă că bitul este setat, dar `x`-ul de sub el nu. Pe Fedora, oricine poate rula `sudo`, ca `root`,
    dar nimeni nu poate citi fișierul; pe Ubuntu, oricine îl poate și citi, deci și copia. <small>→ [`setuid`](#setuid) · [Permisiuni speciale](#special-permissions)</small>

39. **Contează UID-ul**: Arătați că un fișier îi aparține unui UID, nu unui nume, și ce se întâmplă când un UID este
    refolosit.

    1. aflați UID-ul lui `carol`, apoi ștergeți-o **fără** directorul ei;
    2. listați `/home` cu nume, apoi cu numere;
    3. creați utilizatorul `grace`, fără director propriu, cu UID-ul pe care îl avea `carol`;
    4. listați din nou `/home`, apoi ștergeți-o pe `grace` și ștergeți `/home/carol`.

    💡 `man ls`: căutați `numeric`; `man useradd`: căutați `uid` și `no-create-home`.

    **Verificare:** după ce `carol` a fost ștearsă, `/home/carol` afișează numere în locul proprietarului și al
    grupului: fișierele păstrează doar UID-ul și GID-ul. Când `grace` primește acest UID, `ls -l` o arată drept
    proprietara tuturor fișierelor lui `carol`, iar ea le poate citi și modifica. Înainte ca un UID să fie refolosit,
    fișierele vechiului utilizator trebuie șterse sau date altcuiva. <small>→ [Utilizatori](#users) · [`chown` și `chgrp`](#chown-and-chgrp)</small>

## Întrebări de recapitulare {/* #wrap-up-questions */}

Folosiți **ultimele 5 minute** ale laboratorului ca să răspundeți la aceste întrebări împreună cu colegii și cu
asistentul. La ultimele două nu există răspunsuri greșite.

1. Ce este un **utilizator** pentru kernel? Dar un **grup**?
2. Unde se păstrează utilizatorii, grupurile și parolele locale? Ce comandă folosiți ca să căutați un utilizator?
3. De ce poate oricine să citească `/etc/passwd`, dar doar `root` poate citi `/etc/shadow`? Cum verifică `login` o
   parolă, dacă parola nu este păstrată nicăieri?
4. Ce set de permisiuni, **unul singur**, folosește kernelul pentru voi când deschideți un fișier? De ce nu poate
   proprietarul unui fișier `----rw----` să-l citească?
5. Care este diferența dintre `sudo` și `su`? De ce merge `sudo` pentru `student`, dar nu și pentru un utilizator nou?
6. De ce eșuează `sudo echo text > /etc/hosts`?
7. Ce înseamnă `r`, `w` și `x` pentru un director? De ce puteți șterge un fișier în care nu puteți scrie?
8. De ce nu vă puteți baza pe prompt ca să aflați cine sunteți?
9. Ce v-a surprins cel mai mult astăzi la permisiuni?
10. Ce permisiuni le veți da de acum înainte propriilor fișiere?
