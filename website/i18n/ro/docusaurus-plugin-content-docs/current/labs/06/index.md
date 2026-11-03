import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# 06. Prelucrarea textului

În laboratorul 5 ați aflat ce utilizator rulează fiecare program și cine poate citi și scrie fiecare fișier. În acest
laborator lucrați cu ce se află **în interiorul** celor mai multe dintre aceste fișiere: **text**. Vă întâlniți cu
**filtrele**, comenzi mici care citesc linii și scriu linii: `cat`, `head`, `tail` și `sort` lucrează cu linii întregi,
`grep` găsește liniile care se potrivesc cu o **expresie regulată**, `cut`, `tr` și `sed` schimbă interiorul fiecărei
linii, iar `wc` și `awk` numără și calculează. Le legați în **pipeline-uri** care răspund la o întrebare într-o singură
linie, aflați dintr-un **cod de ieșire** dacă o comandă a mers și înlănțuiți comenzi cu `&&` și `||`. La final editați
fișiere text în terminal, cu `nano` și `vim`.

Ideea cea mai importantă a laboratorului este că textul este **limba comună** a comenzilor. Fiecare filtru citește
linii de text, face **un singur** lucru mic cu ele și scrie linii de text, așa că ieșirea oricărui filtru poate fi
intrarea oricărui alt filtru. Un pipe le leagă într-un **pipeline**, în care fiecare comandă schimbă puțin textul, până
când ultima afișează răspunsul. Fiecare comandă se termină și cu un număr, **codul de ieșire**, care îi spune shell-ului
dacă a mers.

## Obiective {/* #objectives */}

- Să înțelegeți ce este un **filtru** și să construiți un **pipeline** de filtre care răspunde la o întrebare
- Să afișați, să inversați și să decupați linii cu `cat`, `tac`, `head` și `tail`
- Să sortați linii cu `sort`, ca text, ca numere și după un câmp, și să numărați liniile repetate cu `uniq`
- Să scrieți **expresii regulate**, de bază și extinse, și să căutați cu ele cu `grep`
- Să decupați **câmpuri** și caractere din fiecare linie cu `cut` și să inversați sau să numerotați liniile cu `rev` și
  `nl`
- Să schimbați, să ștergeți și să comprimați caractere cu `tr` și să înlocuiți text cu `sed`
- Să numărați linii, cuvinte și caractere cu `wc` și să calculați sume și medii cu `awk`
- Să aflați dacă o comandă a mers din **codul de ieșire** al ei și să înlănțuiți comenzi cu `&&` și `||`
- Să editați un fișier text în terminal cu `nano` și cu `vim`

## Resurse {/* #resources */}

1. _[Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici, Utilizarea Sistemelor de
   Operare, Printech 2021](https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf)_
   - Capitolul 4 - _Procese_, secțiunile 4.5.3 și 4.5.4
   - Capitolul 6 - _Dezvoltarea aplicațiilor_, secțiunile 6.6.1 și 6.6.2
   - Capitolul 7 - _Interfața în linia de comandă_, secțiunile 7.4 și 7.5
   - Capitolul 13 - _Automatizarea sarcinilor_, secțiunea 13.3.2
2. _Brian Ward, How LINUX Works, 3rd Edition, No Starch Press, 2021_
   - Capitolul 2 - _Basic Commands and Directory Hierarchy_, secțiunile 2.2.2, 2.5 și 2.14
   - Capitolul 11 - _Introduction to Shell Scripts_, secțiunile 11.4 și 11.5
3. _[The GNU Awk User's Guide](https://www.gnu.org/software/gawk/manual/gawk.html)_ și `vimtutor`, tutorialul de 30 de
   minute al lui `vim`
4. Slide-urile cursului: [06. Prelucrarea textului](/docs/lectures/06)
5. Paginile de manual: `man cat`, `man tac`, `man head`, `man tail`, `man sort`, `man uniq`, `man grep`, `man 7 regex`,
   `man cut`, `man tr`, `man sed`, `man rev`, `man nl`, `man wc`, `man awk`, `man nano`, `man vim` și `man bash`
   (căutați `Pipelines` și `Lists`)

## Fedora și Ubuntu {/* #fedora-and-ubuntu */}

Calculatoarele din laborator rulează **Fedora** cu **Sway**, iar exemplele provin de pe ele. Acasă puteți folosi și
**Ubuntu**: comenzile din acest laborator sunt aceleași, cu câteva diferențe:

|                                 | Fedora                                        | Ubuntu                                                   |
| ------------------------------- | --------------------------------------------- | -------------------------------------------------------- |
| promptul                        | `[student@fedora ~]$`                         | `student@ubuntu:~$`, colorat                             |
| programul din spatele lui `awk` | GNU `awk` (`gawk`)                            | `mawk`, un `awk` mai mic: laboratorul merge la fel pe el |
| `vim` și `vimtutor`             | dacă lipsesc: `sudo dnf install vim-enhanced` | dacă lipsesc: `sudo apt install vim`                     |

## Filtre {/* #filters */}

Un **filtru** este o comandă care citește text, din fișierele primite ca parametri sau de la intrarea standard când nu
primește niciunul, schimbă textul și scrie rezultatul la ieșirea standard. În
[Pipe-uri](/docs/labs/03#pipes-) din laboratorul 03 ați legat câteva dintre ele cu `|`: `sort fruits.txt | uniq -c`. Un
lanț de comenzi legate prin pipe-uri este un **pipeline**.

Gândiți-vă la o linie de asamblare dintr-o fabrică: fiecare muncitor face **o singură** treabă mică pe piesă și o dă
mai departe. Un filtru nu știe ce este înaintea lui sau după el: doar intrarea și ieșirea lui.

Filtrele din acest laborator fac patru feluri de treburi, iar un pipeline obișnuit le folosește în această ordine:

| Fel                      | Decide                            | Comenzi                                      |
| ------------------------ | --------------------------------- | -------------------------------------------- |
| **filtre de linii**      | ce linii și în ce ordine          | `cat`, `tac`, `head`, `tail`, `sort`, `uniq` |
| **căutare**              | ce linii se potrivesc cu un tipar | `grep`                                       |
| **modificarea textului** | ce părți din fiecare linie        | `cut`, `tr`, `sed`, `rev`, `nl`              |
| **calcul**               | un număr, o sumă, o medie         | `wc`, `uniq -c`, `awk`                       |

![Un pipeline obișnuit](./images/pipeline.svg)

```shell-session
[student@fedora lab06]$ grep ' 404$' access.log | cut -d' ' -f1 | sort | uniq -c
      2 10.0.0.3
      3 10.0.0.9
```

- `grep` a păstrat liniile care se termină cu `404`, cererile pentru pagini care nu există; `cut` a păstrat doar primul
  câmp, adresa; `sort | uniq -c` a numărat fiecare adresă. Fiecare comandă este explicată în secțiunile de mai jos.

:::tip

**Construiți un pipeline câte o comandă pe rând**

Rulați prima comandă și uitați-vă la ieșirea ei; apoi apăsați <kbd>↑</kbd>, adăugați `|` și comanda următoare și
uitați-vă din nou. Când ieșirea este lungă, adăugați `| head` la final cât timp lucrați.

:::

:::info

_"Write programs that do one thing and do it well. Write programs to work together. Write programs to handle text
streams, because that is a universal interface."_ (Doug McIlroy, inventatorul pipe-ului din Unix)

:::

Toate comenzile unui pipeline rulează **în același timp**, fiecare în procesul ei, iar textul curge între ele cât timp
rulează. Exercițiile de acasă și provocările au nevoie de detalii: sunt în
[Cum rulează un pipeline](#how-a-pipeline-runs).

## Filtre de linii {/* #line-filters */}

Filtrele de linii lucrează cu **linii întregi**: aleg ce linii păstrează și în ce ordine, dar nu le schimbă. Exemplele
folosesc fișierele pe care [exercițiul 2](#first-steps) le creează în `~/lab06`; `fruits.txt` are 7 linii: `banana`,
`apple`, `cherry`, `apple`, `kiwi`, `banana` și `apple`.

### Afișarea unui fișier: `cat` și `tac` {/* #showing-a-file-cat-and-tac */}

Ați întâlnit `cat` în [laboratorul 02](/docs/labs/02#cat). Opțiunile lui arată ce nu se vede în text:

| Comandă         | Ce face                                                                                |
| --------------- | -------------------------------------------------------------------------------------- |
| `cat <FILE>...` | afișează fișierele, unul după altul (_concatenate_)                                    |
| `cat`           | fără fișier, afișează ce citește de la tastatură, până la <kbd>Ctrl</kbd>+<kbd>D</kbd> |
| `cat -n <FILE>` | numerotează fiecare linie                                                              |
| `cat -A <FILE>` | arată caracterele invizibile: un tab ca `^I`, sfârșitul fiecărei linii ca `$`          |
| `tac <FILE>`    | afișează liniile în ordine **inversă**, ultima prima                                   |

```shell-session
[student@fedora lab06]$ tac fruits.txt
apple
banana
kiwi
apple
cherry
apple
banana
[student@fedora lab06]$ printf 'a\tb \n' | cat -A
a^Ib $
```

- `tac` a afișat aceleași 7 linii, de la ultima la prima.
- `cat -A` a arătat tab-ul dintre `a` și `b` și spațiul de la sfârșitul liniei, înainte de `$`.

### Primele și ultimele linii: `head` și `tail` {/* #the-first-and-the-last-lines-head-and-tail */}

| Comandă               | Ce afișează                                                                                               |
| --------------------- | --------------------------------------------------------------------------------------------------------- |
| `head -n <N> <FILE>`  | primele `N` linii; fără `-n`, primele 10                                                                  |
| `tail -n <N> <FILE>`  | ultimele `N` linii; fără `-n`, ultimele 10                                                                |
| `tail -n +<N> <FILE>` | totul **de la** linia `N` până la sfârșit                                                                 |
| `tail -f <FILE>`      | ultimele linii, apoi fiecare linie nouă scrisă în fișier, până la <kbd>Ctrl</kbd>+<kbd>C</kbd> (_follow_) |

```shell-session
[student@fedora lab06]$ head -n 3 fruits.txt
banana
apple
cherry
[student@fedora lab06]$ head -n 5 fruits.txt | tail -n 1
kiwi
[student@fedora lab06]$ tail -n +2 students.csv
Alice,30,Paris
Bob,25,London
Carol,22,Bucharest
```

- `head -n 5 | tail -n 1` a păstrat primele 5 linii, apoi ultima dintre ele: linia a 5-a.
- `tail -n +2` a sărit peste prima linie din `students.csv`, **antetul** cu numele coloanelor.

:::tip

`tail -f` este felul în care administratorii urmăresc un **log**, un fișier în care un program adaugă o linie pentru
tot ce face. Lăsați-l să ruleze într-un terminal și vedeți fiecare linie nouă în clipa în care este scrisă.

:::

### Sortarea: `sort` {/* #sorting-sort */}

`sort` afișează liniile în ordine alfabetică. Opțiunile schimbă ce compară:

| Opțiune      | Ce face                                                                     |
| ------------ | --------------------------------------------------------------------------- |
| `-r`         | în ordine **inversă**                                                       |
| `-n`         | compară liniile ca **numere**: `9` înainte de `10`                          |
| `-u`         | afișează fiecare linie o **singură** dată (_unique_)                        |
| `-t <C>`     | câmpurile sunt separate de caracterul `C` (implicit: spații)                |
| `-k <N>,<N>` | sortează doar după câmpul `N`; `-k 2,2n` sortează după câmpul `2`, ca număr |

```shell-session
[student@fedora lab06]$ sort numbers.txt
10
100
2
9
[student@fedora lab06]$ sort -n numbers.txt
2
9
10
100
[student@fedora lab06]$ sort -t, -k 2,2n students.csv
name,age,city
Carol,22,Bucharest
Bob,25,London
Alice,30,Paris
```

- Fără `-n`, `sort` a comparat numerele ca text, caracter cu caracter: `100` a venit înainte de `2`, pentru că `1` este
  înainte de `2`.
- `-t, -k 2,2n` a sortat liniile din `students.csv` după al doilea câmp, vârsta, ca număr. Antetul nu are un număr în
  acel câmp, așa că valorează `0` și rămâne primul.

:::caution

Fără `-n`, numerele sunt sortate ca **text**: `100` înainte de `2`. Folosiți `-n` ori de câte ori liniile încep cu un
număr, sau `-k` cu `n` când numărul este în alt câmp.

:::

### Numărarea liniilor repetate: `uniq` {/* #counting-repeated-lines-uniq */}

Ați întâlnit `uniq` în [Linii repetate](/docs/labs/03#repeated-lines-uniq) din laboratorul 03: compară o linie doar cu
linia **imediat de deasupra**, așa că vine după `sort`. Împreună cu `sort -nr` și `head`, găsește liniile cele mai
frecvente:

```shell-session
[student@fedora lab06]$ sort fruits.txt | uniq -c | sort -nr | head -n 2
      3 apple
      2 banana
```

- `sort | uniq -c` a numărat fiecare fruct, `sort -nr` a pus primul cel mai mare număr, iar `head -n 2` le-a păstrat pe
  primele două.

| Opțiune   | Ce afișează                                |
| --------- | ------------------------------------------ |
| `uniq -c` | fiecare linie o dată, cu de câte ori apare |
| `uniq -d` | doar liniile care apar de mai multe ori    |
| `uniq -u` | doar liniile care apar exact o dată        |

## Expresii regulate {/* #regular-expressions */}

O **expresie regulată** (_regex_) este un tipar care descrie un text: „un `c`, apoi orice caracter, apoi un `l`” este
`c.l`. Majoritatea programelor care caută în text le înțeleg: `grep`, `sed`, `awk`, căutarea cu <kbd>/</kbd> din
`less`, `man` și `vim` și fiecare limbaj de programare.

Gândiți-vă la descrierea unei persoane pe care i-o dați unui prieten la gară: nu știți numele, dar „înalt, cu o pălărie
roșie” găsește persoana potrivită în mulțime. Un regex găsește liniile care se potrivesc cu descrierea.

`grep '<REGEX>' <FILE>` afișează liniile care conțin o potrivire a regex-ului. Exemplele folosesc `words.txt`:

```text
color
colour
cat
category
concatenate
dog
banana
bat
orange
gal
goal
gooooal
notes.txt
2026-10-04
call 0722 123 456
```

:::caution

**Un regex nu este un glob**

`*` dintr-un glob (vedeți [Globbing](/docs/labs/04#globbing) din laboratorul 04) înseamnă „orice caractere”; într-un
regex, `*` înseamnă „elementul de dinainte, de oricâte ori”, iar „orice caractere” este `.*`. Puneți mereu regex-ul
între **ghilimele simple**: fără ele, shell-ul îl poate expanda ca pe un glob, înainte să pornească `grep`. Dacă
directorul curent are un fișier `banana.txt`, `grep ba* fruits.txt` devine `grep banana.txt fruits.txt`.

:::

### Expresii regulate de bază {/* #basic-regular-expressions */}

| Regex    | Se potrivește cu                                             | Exemplu  | Potriviri în `words.txt`            |
| -------- | ------------------------------------------------------------ | -------- | ----------------------------------- |
| `abc`    | textul `abc`, oriunde în linie                               | `cat`    | `cat`, `category`, `concatenate`    |
| `.`      | **orice** caracter, unul singur                              | `c.l`    | `color`, `colour`, `call ...`       |
| `^`      | **începutul** liniei                                         | `^ca`    | `cat`, `category`, `call ...`       |
| `$`      | **sfârșitul** liniei                                         | `r$`     | `color`, `colour`                   |
| `[abc]`  | **unul** dintre caracterele dinăuntru (o **clasă**)          | `[0-9]`  | `2026-10-04`, `call ...`            |
| `[^abc]` | un caracter care **nu** este înăuntru                        | `^[^c]`  | fiecare linie care nu începe cu `c` |
| `*`      | elementul **de dinainte**, de **0 sau mai multe** ori        | `go*al`  | `gal`, `goal`, `gooooal`            |
| `.*`     | orice caractere, sau niciunul                                | `^c.*e$` | `concatenate`                       |
| `\`      | caracterul următor este text simplu: `\.` este un punct real | `\.`     | `notes.txt`                         |

```shell-session
[student@fedora lab06]$ grep 'go*al' words.txt
gal
goal
gooooal
[student@fedora lab06]$ grep '^[a-z]*$' words.txt | wc -l
12
[student@fedora lab06]$ grep '.' words.txt | wc -l
15
[student@fedora lab06]$ grep '\.' words.txt
notes.txt
```

- `go*al` s-a potrivit cu un `g`, oricâți `o`, chiar niciunul, apoi `al`.
- `^[a-z]*$` s-a potrivit cu liniile care au doar litere mici, de la început până la sfârșit: 12 linii.
- `.` singur s-a potrivit cu **fiecare** linie care nu este goală; `\.` doar cu linia care are un punct real.

### Expresii regulate extinse {/* #extended-regular-expressions */}

Cu `grep -E`, încă cinci caractere sunt speciale și fac regex-ul mai scurt:

| Regex | Se potrivește cu                                                   | Exemplu    | Potriviri în `words.txt`                |
| ----- | ------------------------------------------------------------------ | ---------- | --------------------------------------- |
| `+`   | elementul de dinainte, de **1 sau mai multe** ori                  | `[0-9]+`   | `2026-10-04`, `call ...`                |
| `?`   | elementul de dinainte, de **0 sau 1** dată: este opțional          | `colou?r`  | `color`, `colour`                       |
| `{n}` | elementul de dinainte, de exact `n` ori; `{n,m}`: de la `n` la `m` | `[0-9]{4}` | `2026-10-04`, `call 0722 ...`           |
| `( )` | un **grup**, repetat ca un singur element                          | `b(an)*a`  | `banana`, `bat`                         |
| `\|`  | una dintre variante (_sau_)                                        | `cat\|dog` | `cat`, `category`, `concatenate`, `dog` |
| `\b`  | o **margine de cuvânt**: începutul sau sfârșitul unui cuvânt       | `\bcat\b`  | doar `cat`                              |

```shell-session
[student@fedora lab06]$ grep -E 'colou?r' words.txt
color
colour
[student@fedora lab06]$ grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' words.txt
2026-10-04
[student@fedora lab06]$ grep -E '\b[0-9]{3}\b' words.txt
call 0722 123 456
```

- `^[0-9]{4}-[0-9]{2}-[0-9]{2}$` s-a potrivit cu o linie care este **doar** o dată calendaristică: 4 cifre, `-`, 2
  cifre, `-`, 2 cifre.
- `\b[0-9]{3}\b` s-a potrivit cu un număr de exact 3 cifre, `123`; fără `\b`, s-ar fi potrivit și în interiorul lui
  `0722` și al lui `2026`.

:::info

Fără `-E`, `grep` folosește expresiile regulate **de bază**, în care `+`, `?`, `{`, `(` și `|` sunt caractere simple
(în schimb, `\+`, `\?`, ... sunt speciale). Folosiți `-E` ori de câte ori aveți nevoie de unul dintre ele. Lista
completă este în `man 7 regex`.

:::

### Opțiunile lui `grep` {/* #grep-options */}

| Opțiune | Ce face                                                                                                 |
| ------- | ------------------------------------------------------------------------------------------------------- |
| `-E`    | folosește expresiile regulate **extinse**                                                               |
| `-i`    | ignoră diferența dintre literele mari și mici                                                           |
| `-v`    | afișează liniile care **nu** se potrivesc                                                               |
| `-n`    | afișează numărul fiecărei linii în fața ei                                                              |
| `-c`    | afișează doar câte linii se potrivesc                                                                   |
| `-o`    | afișează doar **partea care se potrivește**, fiecare potrivire pe linia ei                              |
| `-w`    | se potrivește doar cu **cuvinte** întregi, ca `\b...\b`                                                 |
| `-q`    | nu afișează nimic (_quiet_): răspunsul este în codul de ieșire (vedeți [Coduri de ieșire](#exit-codes)) |
| `-r`    | caută în toate fișierele unui director și ale subdirectoarelor lui                                      |

```shell-session
[student@fedora lab06]$ grep -n 'an' fruits.txt
1:banana
6:banana
[student@fedora lab06]$ grep -o -E '[0-9]+' words.txt
2026
10
04
0722
123
456
[student@fedora lab06]$ grep -v -c 'apple' fruits.txt
4
```

- `-n` a arătat că `banana` este pe liniile `1` și `6`.
- `-o` a afișat fiecare număr din `words.txt` pe linia lui, fără restul liniei.
- `-v -c` a numărat liniile care **nu** conțin `apple`.

## Modificarea textului {/* #change-text */}

### Câmpuri și delimitatori {/* #fields-and-delimiters */}

Multe fișiere text sunt **tabele**: fiecare linie este un rând, iar un caracter, **delimitatorul**, o împarte în
**câmpuri**, coloanele. Câmpurile sunt numerotate de la `1`.

| Fișier                                       | O linie                                               | Delimitatorul |
| -------------------------------------------- | ----------------------------------------------------- | ------------- |
| un fișier **CSV** (_comma-separated values_) | `Alice,30,Paris`                                      | `,`           |
| `/etc/passwd` (laboratorul 05)               | `student:x:1000:1000:Student:/home/student:/bin/bash` | `:`           |
| un fișier log, `access.log`                  | `10.0.0.9 GET /logo.png 404`                          | un spațiu     |
| multe programe                               | câmpurile sunt aliniate în coloane                    | un **tab**    |

![Câmpuri și delimitatori](./images/fields.svg)

:::caution

**Fiecare** delimitator desparte. În `Bob   25 London`, cu trei spații după `Bob`, sunt două câmpuri **goale** între
spații, iar `25` este câmpul `4`, nu `2`.

:::

### Tăierea coloanelor: `cut` {/* #cutting-columns-cut */}

| Comandă                   | Ce afișează                                                             |
| ------------------------- | ----------------------------------------------------------------------- |
| `cut -d<C> -f<N> <FILE>`  | câmpul `N` al fiecărei linii; câmpurile sunt separate de caracterul `C` |
| `cut -d<C> -f1,3`         | câmpurile 1 și 3, separate de același `C`                               |
| `cut -d<C> -f2-4`, `-f2-` | câmpurile 2 până la 4; de la câmpul 2 până la sfârșit                   |
| `cut -f<N>`               | fără `-d`, delimitatorul este **tab**-ul                                |
| `cut -c<N>-<M> <FILE>`    | caracterele `N` până la `M` ale fiecărei linii, numărate de la `1`      |

```shell-session
[student@fedora lab06]$ cut -d, -f1 students.csv
name
Alice
Bob
Carol
[student@fedora lab06]$ cut -d, -f2- students.csv
age,city
30,Paris
25,London
22,Bucharest
[student@fedora lab06]$ cut -d' ' -f2 people.txt
30

```

- `-d, -f1` a afișat primul câmp, numele; `-f2-` a afișat tot ce urmează începând cu al doilea câmp.
- `people.txt` conține `Alice 30 Paris` și `Bob   25 London`: pentru `Bob`, câmpul `2` este câmpul gol dintre primele
  două spații, așa că `cut` a afișat o linie goală. `tr`, din secțiunea următoare, rezolvă asta.

### Schimbarea caracterelor: `tr` {/* #changing-characters-tr */}

`tr` (_translate_) schimbă **caractere** individuale, nu cuvinte. Citește **doar** de la intrarea standard: dați-i un
fișier cu `<` sau printr-un pipe.

| Comandă            | Ce face                                                                                |
| ------------------ | -------------------------------------------------------------------------------------- |
| `tr <SET1> <SET2>` | schimbă fiecare caracter din `SET1` în caracterul de pe **aceeași poziție** din `SET2` |
| `tr -d <SET>`      | **șterge** caracterele din `SET`                                                       |
| `tr -s <SET>`      | **comprimă** o succesiune de caractere identice din `SET` într-unul singur (_squeeze_) |

Un set este o listă de caractere, `aeiou`, sau un interval, `a-z`, `0-9`; `'\n'` este sfârșitul unei linii, iar `'\t'`
un tab.

```shell-session
[student@fedora lab06]$ tr a-z A-Z < fruits.txt | head -n 2
BANANA
APPLE
[student@fedora lab06]$ echo 'call 0722 123 456' | tr -d 0-9
call
[student@fedora lab06]$ tr -s ' ' < people.txt | cut -d' ' -f2
30
25
[student@fedora lab06]$ echo "$PATH" | tr : '\n'
/home/student/.local/bin
/home/student/bin
/usr/local/bin
/usr/bin
...
```

- `a-z` și `A-Z` au aceeași lungime: `a` a devenit `A`, `b` a devenit `B` și așa mai departe.
- `-d 0-9` a șters cifrele; spațiile au rămas.
- `tr -s ' '` a lăsat un singur spațiu între câmpurile din `people.txt`, așa că `cut` a găsit vârsta lui `Bob` în
  câmpul `2`.
- `tr : '\n'` a pus fiecare director din `PATH` (laboratorul 04) pe linia lui.

### Înlocuirea textului: `sed` {/* #replacing-text-sed */}

`sed` (_stream editor_) schimbă textul fiecărei linii. Comanda lui cea mai folosită este `s` (_substitute_):

```text
sed 's/<REGEX>/<NEW TEXT>/<FLAGS>' <FILE>
```

| Scris ca           | Ce face                                                           |
| ------------------ | ----------------------------------------------------------------- |
| `s/apple/pear/`    | înlocuiește **prima** potrivire din fiecare linie                 |
| `s/apple/pear/g`   | înlocuiește **fiecare** potrivire din linie (_global_)            |
| `s/apple/pear/gi`  | la fel, ignorând diferența dintre literele mari și mici           |
| `sed -E 's/...//'` | regex-ul este unul **extins**, ca la `grep -E`                    |
| `s/apple//g`       | textul nou este gol: șterge potrivirile                           |
| `s\|/usr\|/opt\|`  | orice caracter poate separa părțile: util când textul conține `/` |

```shell-session
[student@fedora lab06]$ echo 'apple and apple pie' | sed 's/apple/pear/'
pear and apple pie
[student@fedora lab06]$ echo 'apple and apple pie' | sed 's/apple/pear/g'
pear and pear pie
[student@fedora lab06]$ echo 'call 0722 123 456' | sed -E 's/[0-9]+/N/g'
call N N N
[student@fedora lab06]$ sed 's/,/ /g' students.csv
name age city
Alice 30 Paris
Bob 25 London
Carol 22 Bucharest
```

- Fără `g`, doar primul `apple` s-a schimbat.
- `[0-9]+` s-a potrivit cu fiecare număr, iar fiecare potrivire a devenit `N`.
- `sed` a afișat textul schimbat; `students.csv` însuși **nu** s-a schimbat.

:::danger

`sed -i` scrie rezultatul **înapoi în fișier**, în loc să-l afișeze. Nu există undo: rulați întâi comanda fără `-i` și
uitați-vă la ieșire.

:::

### Inversarea și numerotarea: `rev` și `nl` {/* #reversing-and-numbering-rev-and-nl */}

| Comandă      | Ce face                                                                              |
| ------------ | ------------------------------------------------------------------------------------ |
| `rev <FILE>` | inversează **caracterele** fiecărei linii; ordinea liniilor rămâne (asta face `tac`) |
| `nl <FILE>`  | adaugă o primă coloană cu numărul liniei și un tab; liniile goale nu primesc număr   |

```shell-session
[student@fedora lab06]$ rev fruits.txt | head -n 2
ananab
elppa
[student@fedora lab06]$ echo /usr/share/doc/bash | rev | cut -d/ -f1 | rev
bash
```

- `cut` nu poate număra câmpurile de la sfârșit. `rev` a pus ultimul câmp primul, `cut -f1` l-a luat, iar al doilea
  `rev` l-a întors la loc.

## Numărare și calcule {/* #counting-and-computing */}

### Numărarea: `wc` {/* #counting-wc */}

`wc` (_word count_) numără liniile, cuvintele și octeții:

| Opțiune | Ce numără                                                            |
| ------- | -------------------------------------------------------------------- |
| `-l`    | **liniile**                                                          |
| `-w`    | **cuvintele**: grupurile de caractere separate prin spații           |
| `-c`    | **octeții**                                                          |
| `-m`    | **caracterele**: o literă ca `ș` ocupă 2 octeți, dar este 1 caracter |

```shell-session
[student@fedora lab06]$ wc fruits.txt
 7  7 44 fruits.txt
[student@fedora lab06]$ wc -l < fruits.txt
7
[student@fedora lab06]$ echo 'mașină' | wc -c -m
      7       9
```

- Fără opțiuni, `wc` a afișat liniile, cuvintele și octeții, apoi numele fișierului.
- Cu `<`, `wc` nu a știut numele fișierului (vedeți [Intrarea](/docs/labs/03#input-) din laboratorul 03): a afișat doar
  numărul.
- `mașină` și sfârșitul liniei sunt 7 caractere, dar 9 octeți: `ș` și `ă` ocupă câte doi octeți.

### Calcule: `awk` {/* #computing-awk */}

`awk` este un mic limbaj de programare pentru tabele. Un program `awk` este o listă de **condiții**, fiecare cu o
**acțiune** între `{ }`: pentru fiecare linie, `awk` o împarte în câmpuri și rulează acțiunea fiecărei condiții care
este adevărată pentru linie. O condiție este opțională; `END` este o condiție adevărată o singură dată, după ultima
linie.

![Un program awk](./images/awk.svg)

| Scris ca                   | Ce este                                                                        |
| -------------------------- | ------------------------------------------------------------------------------ |
| `-F,`                      | delimitatorul este `,`; fără `-F`, orice succesiune de spații și tab-uri       |
| `$1`, `$2`, ..., `$NF`     | câmpurile; `$NF` este ultimul; `$0` este linia întreagă                        |
| `NF`, `NR`                 | numărul de câmpuri al liniei; numărul liniei                                   |
| `==`, `!=`, `<`, `>=`, ... | compară două valori: numerele ca numere, textul ca text                        |
| `~ /regex/`, `!~ /regex/`  | se potrivește, nu se potrivește cu un regex                                    |
| `&&`, `\|\|`, `!`          | și, sau, nu                                                                    |
| `{ print $1, $3 }`         | afișează câmpurile 1 și 3, separate de un spațiu                               |
| `{ s += $3; n++ }`         | adună câmpul 3 la variabila `s` și adună 1 la `n`; variabilele încep de la `0` |

Exemplele folosesc `orders.csv`, un antet și 6 comenzi:

```text
name,fruit,count
alice,apple,3
bob,kiwi,1
carol,apple,2
alice,banana,5
dan,apple,1
alice,apple,2
```

```shell-session
[student@fedora lab06]$ awk -F, '{ s += $3 } END { print s }' orders.csv
14
[student@fedora lab06]$ awk -F, 'NR > 1 { s += $3; n++ } END { print s / n }' orders.csv
2.33333
[student@fedora lab06]$ awk -F, '$2 == "apple" { s += $3 } END { print s }' orders.csv
8
[student@fedora lab06]$ awk -F, '$2 ~ /an/ { print $1, $2 }' orders.csv
alice banana
[student@fedora lab06]$ awk '{ print NF, $NF }' people.txt
3 Paris
3 London
```

- Primul program a adunat câmpul 3 al fiecărei linii și a afișat suma la final; antetul `count` nu este un număr, așa
  că a adunat `0`.
- `NR > 1` a sărit peste antet, iar `n` a numărat comenzile: 14 / 6 = 2.33333.
- `$2 == "apple"` a adunat doar merele; `$2 ~ /an/` a afișat comenzile al căror fruct conține `an`.
- Fără `-F`, `awk` a împărțit `Bob   25 London` la **succesiunea** de spații: 3 câmpuri, niciunul gol.

:::tip

Puneți programul `awk` între **ghilimele simple**: `$1` și `$3` sunt pentru `awk`, nu pentru shell.

:::

## Un pipeline, pas cu pas {/* #a-pipeline-step-by-step */}

Câți clienți au comandat mere? Construiți pipeline-ul câte o comandă pe rând și uitați-vă la text după fiecare pas:

```shell-session
[student@fedora lab06]$ tail -n +2 orders.csv | grep ',apple,'
alice,apple,3
carol,apple,2
dan,apple,1
alice,apple,2
[student@fedora lab06]$ tail -n +2 orders.csv | grep ',apple,' | cut -d, -f1
alice
carol
dan
alice
[student@fedora lab06]$ tail -n +2 orders.csv | grep ',apple,' | cut -d, -f1 | sort -u
alice
carol
dan
[student@fedora lab06]$ tail -n +2 orders.csv | grep ',apple,' | cut -d, -f1 | sort -u | wc -l
3
```

- `tail -n +2` a sărit peste antet, iar `grep ',apple,'` a păstrat comenzile de mere; virgulele din jurul lui `apple`
  sar peste un fruct ca `pineapple`.
- `cut` a păstrat numele; `alice` a comandat mere de două ori, așa că `sort -u` a păstrat fiecare nume o singură dată;
  `wc -l` le-a numărat.

## Coduri de ieșire {/* #exit-codes */}

Fiecare comandă se termină cu un număr între `0` și `255`, **codul ei de ieșire**: `0` înseamnă **succes**, orice alt
număr o eroare. Shell-ul păstrează codul de ieșire al ultimei comenzi în `$?` (vedeți
[Parametri speciali](/docs/labs/04#special-parameters---and-) din laboratorul 04). Pagina de manual a unei comenzi spune
ce înseamnă numerele ei, în secțiunea `EXIT STATUS`:

| `grep` se termină cu | Când                                     |
| -------------------- | ---------------------------------------- |
| `0`                  | a găsit cel puțin o linie                |
| `1`                  | nu a găsit nimic                         |
| `2`                  | o eroare: de exemplu, fișierul nu există |

```shell-session
[student@fedora lab06]$ grep -q kiwi fruits.txt
[student@fedora lab06]$ echo $?
0
[student@fedora lab06]$ grep -q mango fruits.txt
[student@fedora lab06]$ echo $?
1
[student@fedora lab06]$ grep kiwi nope.txt
grep: nope.txt: No such file or directory
[student@fedora lab06]$ echo $?
2
```

- `grep -q` nu a afișat nimic; codul lui de ieșire a spus dacă a găsit `kiwi`, `0`, sau nu, `1`.

| Comandă    | Ce face                                                 |
| ---------- | ------------------------------------------------------- |
| `true`     | nimic; se termină cu `0`                                |
| `false`    | nimic; se termină cu `1`                                |
| `exit <N>` | termină shell-ul, sau un script, cu codul de ieșire `N` |

O comandă oprită de un semnal (laboratorul 04) se termină cu `128` plus numărul semnalului: <kbd>Ctrl</kbd>+<kbd>C</kbd>
(`SIGINT`, `2`) dă `130`.

### Înlănțuirea comenzilor: `&&` și `||` {/* #chaining-commands--and- */}

| Scris ca   | Ce face                                                                     |
| ---------- | --------------------------------------------------------------------------- |
| `a ; b`    | rulează `a`, apoi `b`, orice s-ar fi întâmplat                              |
| `a && b`   | rulează `b` doar dacă `a` s-a terminat cu `0`: „`a`, **și apoi** `b`”       |
| `a \|\| b` | rulează `b` doar dacă `a` **nu** s-a terminat cu `0`: „`a`, **altfel** `b`” |

```shell-session
[student@fedora lab06]$ grep -q kiwi fruits.txt && echo 'kiwi found'
kiwi found
[student@fedora lab06]$ grep -q mango fruits.txt && echo 'mango found'
[student@fedora lab06]$ grep -q mango fruits.txt || echo 'no mango'
no mango
[student@fedora lab06]$ mkdir -p backup && cp fruits.txt backup/ && echo 'saved'
saved
```

- `&&` a sărit peste `echo 'mango found'`, pentru că `grep` s-a terminat cu `1`; `||` a rulat `echo 'no mango'` din
  același motiv.
- `cp` a rulat doar după ce `mkdir` a mers, iar `echo` doar după ce `cp` a mers.

:::caution

`a && b || c` **nu** înseamnă „dacă `a`, atunci `b`, altfel `c`”: shell-ul îl citește de la stânga la dreapta, așa că
`c` rulează și când `a` merge, dar `b` eșuează. Este sigur când `b` nu poate eșua, ca `echo`.

:::

### Codul de ieșire al unui pipeline {/* #the-exit-code-of-a-pipeline */}

Codul de ieșire al unui pipeline este codul de ieșire al **ultimei** lui comenzi:

```shell-session
[student@fedora lab06]$ cut -d, -f2 orders.csv | grep -q kiwi && echo 'kiwi ordered' || echo 'no kiwi'
kiwi ordered
[student@fedora lab06]$ cut -d, -f2 nope.csv | sort
cut: nope.csv: No such file or directory
[student@fedora lab06]$ echo $?
0
```

- În prima linie, `grep -q` a găsit `kiwi` în coloana fructelor: pipeline-ul s-a terminat cu `0`.
- În a doua, `cut` a eșuat, dar `sort`, ultima comandă, a mers: pipeline-ul s-a terminat cu `0`, iar eroarea a fost
  ascunsă. [Cum rulează un pipeline](#how-a-pipeline-runs) arată cum o vedeți.

## Editoare de text {/* #text-editors */}

Editați fișiere text tot timpul: setări din `/etc` și din `~/.config`, programe, notițe. Pe un server, prin rețea, sau
pe un terminal virtual (laboratorul 04), nu există ferestre: aveți nevoie de un editor care rulează **în terminal**.

| Editor              | Cum este                                                                                                         |
| ------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `nano`              | simplu: scrieți, iar tastele sunt afișate în partea de jos a ecranului; editorul implicit pe Fedora și pe Ubuntu |
| `vi`, `vim`, `nvim` | **modal**: tastele sunt comenzi până când începeți să scrieți; instalat pe orice sistem Unix                     |
| `emacs`             | fiecare comandă este o combinație cu <kbd>Ctrl</kbd> sau <kbd>Alt</kbd>; poate fi extins fără sfârșit            |
| `helix` (`hx`)      | modal ca `vim`, mai nou, și înțelege limbajele de programare fără setări                                         |

### `nano` {/* #nano */}

Ați întâlnit `nano` în [laboratorul 02](/docs/labs/02#nano). Partea de jos a ecranului îi listează tastele: `^`
înseamnă <kbd>Ctrl</kbd>, iar `M-` înseamnă <kbd>Alt</kbd>.

| Tastă                         | Acțiune                                       |
| ----------------------------- | --------------------------------------------- |
| <kbd>Ctrl</kbd>+<kbd>O</kbd>  | salvează (_write out_), apoi <kbd>Enter</kbd> |
| <kbd>Ctrl</kbd>+<kbd>X</kbd>  | ieșire                                        |
| <kbd>Ctrl</kbd>+<kbd>K</kbd>  | taie linia                                    |
| <kbd>Ctrl</kbd>+<kbd>U</kbd>  | lipește liniile tăiate                        |
| <kbd>Alt</kbd>+<kbd>U</kbd>   | undo                                          |
| <kbd>Ctrl</kbd>+<kbd>W</kbd>  | caută (_where is_)                            |
| <kbd>Ctrl</kbd>+<kbd>\\</kbd> | caută și înlocuiește                          |
| <kbd>Ctrl</kbd>+<kbd>\_</kbd> | mergi la o linie, după numărul ei             |

### `vim` {/* #vim */}

`vim` (_Vi IMproved_) este **modal**: aceeași tastă face lucruri diferite în **moduri** diferite. Pornește în modul
**Normal**, în care tastele sunt **comenzi**: <kbd>d</kbd> nu scrie un `d`, ci șterge. Scrieți text doar în modul
**Insert**.

![Modurile lui vim](./images/vim-modes.svg)

| Mod          | Ce fac tastele                                | Intrați în el cu                               | Ultima linie arată |
| ------------ | --------------------------------------------- | ---------------------------------------------- | ------------------ |
| Normal       | mutare, ștergere, copiere, lipire             | <kbd>Esc</kbd>, din orice alt mod              | nimic              |
| Insert       | scrierea textului                             | <kbd>i</kbd>, <kbd>a</kbd>, <kbd>o</kbd>       | `-- INSERT --`     |
| Command line | rulează o comandă: salvare, ieșire, înlocuire | <kbd>:</kbd> (sau <kbd>/</kbd> pentru căutare) | `:` și comanda     |
| Visual       | selectarea textului                           | <kbd>v</kbd> (caractere), <kbd>V</kbd> (linii) | `-- VISUAL --`     |

| În modul Normal                                                   | Acțiune                                                             |
| ----------------------------------------------------------------- | ------------------------------------------------------------------- |
| <kbd>h</kbd> <kbd>j</kbd> <kbd>k</kbd> <kbd>l</kbd>, sau săgețile | stânga, jos, sus, dreapta                                           |
| <kbd>w</kbd>, <kbd>b</kbd>                                        | cuvântul următor, cuvântul anterior                                 |
| <kbd>0</kbd>, <kbd>$</kbd>                                        | începutul, sfârșitul liniei                                         |
| <kbd>g</kbd><kbd>g</kbd>, <kbd>G</kbd>                            | prima linie, ultima linie                                           |
| <kbd>i</kbd>, <kbd>a</kbd>                                        | modul Insert, înainte, după cursor                                  |
| <kbd>o</kbd>, <kbd>O</kbd>                                        | o linie nouă dedesubt, deasupra, în modul Insert                    |
| <kbd>x</kbd>, <kbd>d</kbd><kbd>d</kbd>                            | șterge un caracter, șterge linia                                    |
| <kbd>y</kbd><kbd>y</kbd>, <kbd>p</kbd>                            | copiază (_yank_) linia, o lipește dedesubt                          |
| <kbd>u</kbd>, <kbd>Ctrl</kbd>+<kbd>R</kbd>                        | undo, redo                                                          |
| <kbd>/</kbd>`text`, <kbd>n</kbd>                                  | caută înainte, mergi la potrivirea următoare                        |
| `:w`, `:q`, `:wq`, `:q!`                                          | salvează, ieșire, salvează și ieșire, ieșire **fără** salvare       |
| `:%s/old/new/g`                                                   | înlocuiește în fiecare linie, ca `sed` (`%` înseamnă toate liniile) |

Un număr în fața unei comenzi o repetă: <kbd>5</kbd><kbd>j</kbd> coboară 5 linii,
<kbd>3</kbd><kbd>d</kbd><kbd>d</kbd> șterge 3 linii. Tastele <kbd>h</kbd> <kbd>j</kbd> <kbd>k</kbd> <kbd>l</kbd>
sunt cele din Sway, din [laboratorul 01](/docs/labs/01).

:::tip

**V-ați pierdut în `vim`?**

Uitați-vă la ultima linie ca să aflați modul. Apăsați <kbd>Esc</kbd> de câteva ori ca să reveniți în modul Normal,
apoi scrieți `:q!` și <kbd>Enter</kbd> ca să ieșiți fără să salvați. `vimtutor` vă învață restul în 30 de minute.

:::

## Cum rulează un pipeline {/* #how-a-pipeline-runs */}

:::note

**Pentru cine vrea să afle mai mult**

Nu aveți nevoie de această secțiune pentru exercițiile din laborator, 🧪 Primii pași. Citiți-o acasă: exercițiile
🏠 Mai departe și 📝 Provocări o folosesc.

:::

Pentru un pipeline, shell-ul pornește **toate** comenzile în același timp, fiecare ca proces copil, și le leagă prin
**pipe-uri**. Un pipe este un mic buffer în kernel: ieșirea (`1`) unei comenzi scrie în el, iar intrarea (`0`) comenzii
următoare citește din el. Gândiți-vă la un tub între doi muncitori: primul aruncă piese la un capăt, al doilea le scoate
la celălalt.

![Cum rulează un pipeline](./images/pipeline-processes.svg)

| Ce se întâmplă                                               | Rezultatul                                                                             |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| pipe-ul este **gol**, iar comanda următoare vrea să citească | așteaptă până apare text                                                               |
| pipe-ul este **plin** (64 KiB)                               | cel care scrie așteaptă până când cel care citește scoate o parte din text             |
| cel care scrie **se termină**                                | cel care citește primește _end of file_ și poate termina                               |
| cel care citește **se termină** înaintea celui care scrie    | la următoarea scriere, cel care scrie primește semnalul `SIGPIPE` (`13`) și se termină |
| <kbd>Ctrl</kbd>+<kbd>C</kbd>, <kbd>Ctrl</kbd>+<kbd>Z</kbd>   | ajung la **toate** comenzile: pipeline-ul este **un singur** job (laboratorul 04)      |

```shell-session
[student@fedora lab06]$ yes | head -n 3
y
y
y
[student@fedora lab06]$ echo "${PIPESTATUS[@]}"
141 0
```

- `yes` afișează `y` fără sfârșit; `head` s-a terminat după 3 linii, iar `yes` a primit `SIGPIPE` la următoarea
  scriere: `128 + 13 = 141`.
- `PIPESTATUS` este o variabilă a lui `bash` cu codurile de ieșire ale **fiecărei** comenzi din ultimul pipeline; `$?`
  îl are doar pe ultimul.

Pipe-urile unui proces sunt în directorul lui din `/proc` (vedeți
[Sistemul de fișiere `/proc`](/docs/labs/03#the-proc-file-system) din laboratorul 03): `readlink /proc/<PID>/fd/1`
afișează `pipe:[48211]` când ieșirea `1` merge într-un pipe; ambele capete ale aceluiași pipe au același număr.

| Setare                 | Ce face                                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `set -o pipefail`      | codul de ieșire al unui pipeline este cel al **ultimei comenzi care a eșuat**, sau `0`; `set +o pipefail` îl dezactivează |
| `grep --line-buffered` | `grep` scrie fiecare linie imediat; fără el, când ieșirea lui este un pipe, așteaptă până are 4 KiB de text               |

```shell-session
[student@fedora lab06]$ set -o pipefail
[student@fedora lab06]$ cut -d, -f2 nope.csv | sort
cut: nope.csv: No such file or directory
[student@fedora lab06]$ echo $?
1
[student@fedora lab06]$ set +o pipefail
```

- Cu `pipefail`, eșecul lui `cut` nu a mai fost ascuns: pipeline-ul s-a terminat cu `1`.

## Depanare {/* #troubleshooting */}

| Problemă                                                      | Soluție                                                                                                                    |
| ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| O comandă așteaptă, iar promptul nu revine                    | Citește de la tastatură: ați uitat fișierul sau `<`. Apăsați <kbd>Ctrl</kbd>+<kbd>D</kbd> sau <kbd>Ctrl</kbd>+<kbd>C</kbd> |
| `tr: extra operand ‘fruits.txt’`                              | `tr` citește doar de la intrare: `tr a-z A-Z < fruits.txt`                                                                 |
| `sort` pune `100` înainte de `2`                              | Sortează ca text: adăugați `-n`, sau `n` după `-k`                                                                         |
| `uniq` lasă linii repetate                                    | Nu sunt una lângă alta: întâi `sort`                                                                                       |
| `cut` afișează linii goale sau câmpul greșit                  | Sunt mai mulți delimitatori la rând: comprimați-i cu `tr -s` sau folosiți `awk`                                            |
| `cut -f2` afișează toată linia                                | Fără `-d`, delimitatorul este tab-ul, iar linia nu are niciunul: dați delimitatorul cu `-d`                                |
| `cut: the delimiter must be a single character`               | `-d` primește un singur caracter: `-d,`, `-d' '`, `-d:`                                                                    |
| `grep` găsește linii la care nu vă așteptați                  | `.` și `*` sunt speciale într-un regex: scrieți `\.` pentru un punct real, `\*` pentru o stea reală                        |
| `grep: warning: stray \ before d`                             | `\d` nu este o cifră în `grep`: folosiți `[0-9]`                                                                           |
| `grep -E 'a+'` merge, dar `grep 'a+'` nu găsește nimic        | În regex-urile de bază, `+` este un caracter simplu: folosiți `-E`                                                         |
| `grep` cu `*` găsește rezultate ciudate sau fișierele greșite | Regex-ul nu este între ghilimele simple, iar shell-ul l-a expandat ca pe un glob                                           |
| ``sed: -e expression #1, char 8: unknown option to `s'``      | Textul conține `/`: folosiți alt separator, `s\|/usr\|/opt\|`                                                              |
| `awk -F, '{ print $2 }'` afișează linii goale                 | Delimitatorul este greșit: uitați-vă la o linie cu `cat -A` și dați-l pe cel corect cu `-F`                                |
| `awk "{ print $1 }"` afișează linii întregi                   | Între ghilimele duble, shell-ul a înlocuit `$1` cu nimic: folosiți ghilimele simple                                        |
| `vim` scrie litere în locuri ciudate sau nu scrie deloc       | Sunteți în modul greșit: apăsați <kbd>Esc</kbd>, apoi <kbd>i</kbd> ca să scrieți                                           |
| `E37: No write since last change (add ! to override)`         | `vim` nu iese fără să salveze: `:wq` salvează, `:q!` aruncă modificările                                                   |
| `vim: command not found`                                      | Folosiți `vi` sau instalați `vim-enhanced` (Ubuntu: `vim`)                                                                 |

## Exerciții {/* #exercises */}

- 🧪 [Primii pași](#first-steps) (exercițiile 1 - 15): câte o idee pe rând, în ordinea laboratorului, de făcut în
  laborator;
- 🏠 [Mai departe](#going-further) (exercițiile 16 - 34): exerciții mai lungi, de făcut acasă; unele dintre ele se uită
  la felul în care rulează împreună comenzile unui pipeline, explicat în
  [Cum rulează un pipeline](#how-a-pipeline-runs);
- 📝 [Provocări](#challenges) (exercițiile 35 - 40): cele mai grele, ca cele de la examen.

:::danger

Filtrele doar afișează: fișierele se schimbă doar cu `>`, `sed -i` sau un editor. Înainte să scrieți rezultatul peste
un fișier, uitați-vă la el pe ecran și nu redirectați niciodată ieșirea unei comenzi în propriul ei fișier de intrare
(`sort f.txt > f.txt` lasă `f.txt` gol).

:::

### 🧪 Primii pași {/* #first-steps */}

Faceți aceste exerciții în ordine, în timpul laboratorului. Fiecare începe cu ce trebuie să obțineți și încearcă **o**
idee din laborator: dacă vă blocați, citiți secțiunea indicată la finalul exercițiului. Rulați comenzile în `~/lab06`,
dacă exercițiul nu spune altfel.

1. **Editorul vostru**: Alegeți `vim`, `nvim` (Neovim), `hx` (Helix) sau `emacs` și începeți să-l învățați cu
    propriul lui tutorial, timp de 20 de minute. Continuați tutorialul acasă, în [exercițiul 16](#going-further).

    1. alegeți unul dintre cele patru editoare și instalați-l dacă lipsește:

       | Editor  | Pe Fedora                       | Pe Ubuntu                           | Tutorialul                        |
       | ------- | ------------------------------- | ----------------------------------- | --------------------------------- |
       | `vim`   | `sudo dnf install vim-enhanced` | `sudo apt install vim`              | `vimtutor`                        |
       | `nvim`  | `sudo dnf install neovim`       | `sudo apt install neovim`           | `nvim +Tutor`                     |
       | `hx`    | `sudo dnf install helix`        | `sudo snap install --classic helix` | `hx --tutor`                      |
       | `emacs` | `sudo dnf install emacs`        | `sudo apt install emacs`            | `emacs -nw -f help-with-tutorial` |

    2. porniți-i tutorialul și urmați-l timp de 20 de minute: este un fișier text pe care îl modificați în timp ce îl
       citiți;
    3. rețineți lecția la care v-ați oprit și ieșiți din tutorial fără să salvați.

    💡 Fiecare tutorial începe cu felul în care vă mutați și ieșiți. Helix selectează întâi, apoi acționează:
    <kbd>x</kbd> selectează o linie, <kbd>d</kbd> o șterge. În Emacs,
    <kbd>Ctrl</kbd>+<kbd>X</kbd> <kbd>Ctrl</kbd>+<kbd>C</kbd> iese; `-nw` îl păstrează în terminal.

    **Verificare:** tutorialul se deschide în editor, la prima lecție; după 20 de minute vă puteți muta, puteți
    insera, șterge și ieși fără să vă uitați în el. <small>→ [Editoare de text](#text-editors)</small>

2. **Arborele de exerciții**: Creați fișierele folosite de celelalte exerciții, în `~/lab06`.

    1. rulați aceste comenzi (copiați-le din browser cu <kbd>Ctrl</kbd>+<kbd>C</kbd> și lipiți-le în terminal cu
       <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>V</kbd>):

       ```bash
       mkdir -p ~/lab06
       cd ~/lab06
       printf '%s\n' banana apple cherry apple kiwi banana apple > fruits.txt
       printf '%s\n' 10 9 100 2 > numbers.txt
       printf '%s\n' color colour cat category concatenate dog banana bat orange \
           gal goal gooooal notes.txt 2026-10-04 'call 0722 123 456' > words.txt
       printf '%s\n' name,age,city Alice,30,Paris Bob,25,London Carol,22,Bucharest > students.csv
       printf '%s\n' 'Alice 30 Paris' 'Bob   25 London' > people.txt
       printf '%s\n' name,fruit,count alice,apple,3 bob,kiwi,1 carol,apple,2 \
           alice,banana,5 dan,apple,1 alice,apple,2 > orders.csv
       cat > access.log << 'END'
       10.0.0.7 GET /index.html 200
       10.0.0.9 GET /logo.png 404
       10.0.0.7 GET /about.html 200
       10.0.0.3 GET /old.html 404
       10.0.0.9 GET /favicon.ico 404
       10.0.0.5 GET /index.html 200
       10.0.0.9 GET /admin 404
       10.0.0.3 GET /old.html 404
       END
       ```

    2. listați fișierele din `~/lab06` și numărați liniile fiecăruia cu **o singură** comandă.

    **Verificare:** `~/lab06` are 7 fișiere: `access.log` (8 linii), `fruits.txt` (7), `numbers.txt` (4),
    `orders.csv` (7), `people.txt` (2), `students.csv` (4) și `words.txt` (15). <small>→ [Numărarea: `wc`](#counting-wc)</small>

**Filtre de linii**

3. **Cele două capete ale unui fișier**: Uitați-vă la părți dintr-un fișier, fără să-l afișați pe tot.

    1. afișați `fruits.txt` cu numărul fiecărei linii; apoi afișați-l de la ultima linie la prima;
    2. afișați primele 3 linii din `/etc/passwd`, apoi doar ultima lui linie;
    3. afișați doar linia a 5-a din `fruits.txt`;
    4. afișați `students.csv` fără antet;
    5. creați fișierul gol `live.log`; într-un al doilea terminal, urmăriți-l; în primul terminal, adăugați-i liniile
       `first` și `second`, pe rând; opriți urmărirea.

    💡 `man cat`: căutați `number`; `man tail`: căutați `+NUM` și `follow`; adăugați o linie cu `echo` și `>>`
    (laboratorul 03).

    **Verificare:** liniile sunt numerotate de la `1` la `7`, iar `tac` începe cu `apple`; prima linie din
    `/etc/passwd` este linia lui `root`; al 5-lea fruct este `kiwi`; fără antet, `students.csv` începe cu
    `Alice,30,Paris`. Fiecare linie apare în al doilea terminal în clipa în care o adăugați. <small>→ [Afișarea unui fișier](#showing-a-file-cat-and-tac) · [Primele și ultimele linii](#the-first-and-the-last-lines-head-and-tail)</small>

4. **Sortați și numărați**: Puneți liniile în ordinea potrivită și găsiți liniile care se repetă.

    1. sortați `numbers.txt` ca text, apoi ca numere, apoi ca numere de la cel mai mare;
    2. afișați studenții din `students.csv`, fără antet, de la cel mai în vârstă la cel mai tânăr; apoi sortați-i după
       oraș;
    3. afișați fiecare fruct din `fruits.txt` o singură dată, apoi doar fructele care apar exact o dată;
    4. afișați fructul cel mai frecvent, cu de câte ori apare, cu **un singur** pipeline.

    💡 `man sort`: căutați `field-separator` și `KEYDEF`; `man uniq`: căutați `unique`.

    **Verificare:** `10 100 2 9`, apoi `2 9 10 100`, apoi `100 10 9 2`. După vârstă: `Alice`, `Bob`, `Carol`; după
    oraș: `Carol` (`Bucharest`), `Bob` (`London`), `Alice` (`Paris`). Fructele sunt `apple`, `banana`, `cherry` și
    `kiwi`; doar `cherry` și `kiwi` apar o dată. Cel mai frecvent este `3 apple`. <small>→ [Sortarea: `sort`](#sorting-sort) · [Numărarea liniilor repetate](#counting-repeated-lines-uniq)</small>

**Expresii regulate**

5. **Expresii regulate de bază**: Descrieți linii cu un tipar și găsiți-le în `words.txt` cu `grep`.

    Pentru fiecare, scrieți **întâi** regex-ul pe hârtie, apoi verificați-l. Găsiți liniile care:

    1. se termină cu `l`;
    2. încep cu o cifră;
    3. au un `o`, iar mai târziu în linie un `e`;
    4. au exact trei caractere, toate litere mici;
    5. au cel puțin un caracter care nu este nici literă mică, nici cifră.

    💡 Tabelul din [Expresii regulate de bază](#basic-regular-expressions). La pasul 4, gândiți-vă la `^` și `$`.

    **Verificare:** `gal`, `goal`, `gooooal`; `2026-10-04`; `concatenate`, `orange`, `notes.txt`; `cat`, `dog`, `bat`,
    `gal`; `notes.txt` (`.`), `2026-10-04` (`-`) și `call 0722 123 456` (spațiile). <small>→ [Expresii regulate de bază](#basic-regular-expressions)</small>

6. **Expresii regulate extinse**: Scrieți tipare mai scurte cu `grep -E` și vedeți de ce un regex are nevoie de
    ghilimele.

    1. găsiți liniile care au un `g`, **unul** sau mai mulți `o`, apoi `al`;
    2. găsiți liniile care sunt exact `cat` sau exact `dog`;
    3. găsiți liniile cu un număr de telefon: 4 cifre, un spațiu, 3 cifre, un spațiu, 3 cifre;
    4. creați fișierul gol `banana.txt`; ghiciți **întâi** ce afișează `grep ba* words.txt` și `grep 'ba*' words.txt`,
       apoi rulați-le; ștergeți `banana.txt`.

    💡 Tabelul din [Expresii regulate extinse](#extended-regular-expressions); la pasul 4, afișați cuvintele pe care le
    primește `grep` cu `echo grep ba* words.txt`.

    **Verificare:** `goal` și `gooooal`, dar nu `gal`; `cat` și `dog`, dar nu `category`; `call 0722 123 456`. Fără
    ghilimele, shell-ul a transformat `ba*` în `banana.txt`, iar `grep` a căutat textul `banana.txt`: nimic. Cu
    ghilimele, `grep` a primit `ba*`, un `b` și oricâți `a`: `banana` și `bat`. <small>→ [Expresii regulate extinse](#extended-regular-expressions) · [Expresii regulate](#regular-expressions)</small>

7. **Opțiunile lui `grep`**: Faceți-l pe `grep` să afișeze exact ce vă trebuie: alte linii, doar o parte din ele sau
    doar un număr.

    1. afișați setările din `/etc/login.defs` (laboratorul 05), fără comentarii (liniile care încep cu `#`) și fără
       liniile goale; apoi numărați-le;
    2. afișați linia setării `UMASK`, cu numărul ei de linie;
    3. afișați doar shell-ul fiecărui utilizator (textul de după ultimul `:`), din baza de date a utilizatorilor;
       numărați câți utilizatori au fiecare shell;
    4. numărați liniile din `words.txt` care conțin `cat`, apoi afișați-le doar pe cele în care `cat` este un cuvânt
       întreg.

    💡 `man grep`: căutați `invert`, `line-number`, `only-matching` și `word-regexp`; o linie goală este `^$`. Căutați
    utilizatorii cu `getent passwd` (laboratorul 05).

    **Verificare:** setările sunt linii ca `UID_MIN 1000`, câteva zeci; `UMASK` este `022`. Cei mai mulți utilizatori
    au `/usr/sbin/nologin` și doar câțiva au `/bin/bash`. `cat` apare în 3 linii, dar este un cuvânt întreg doar în
    `cat`. <small>→ [Opțiunile lui `grep`](#grep-options)</small>

**Modificarea textului**

8. **Tăiați coloane**: Păstrați doar unele câmpuri, sau unele caractere, din fiecare linie.

    1. afișați numele și orașele din `students.csv`, fără antet;
    2. afișați numele și shell-ul fiecărui utilizator, din baza de date a utilizatorilor;
    3. afișați primele 3 caractere ale fiecărui fruct;
    4. afișați doar numele directorului curent, cu `pwd`, `rev` și `cut`.

    💡 `man cut`: căutați `delimiter`, `fields` și `characters`; `/etc/passwd` are 7 câmpuri, separate de `:`.

    **Verificare:** `Alice,Paris`, `Bob,London`, `Carol,Bucharest`; linii ca `student:/bin/bash`; `ban`, `app`, `che`,
    ...; `lab06`. <small>→ [Tăierea coloanelor: `cut`](#cutting-columns-cut) · [Inversarea și numerotarea](#reversing-and-numbering-rev-and-nl)</small>

9. **Schimbați caractere**: Schimbați, ștergeți și comprimați caractere cu `tr`.

    1. afișați `fruits.txt` cu litere mari;
    2. afișați fructele fără vocale;
    3. afișați cuvintele din `the quick brown fox` câte unul pe linie;
    4. afișați vârsta fiecărei persoane din `people.txt`, cu `tr` și `cut`;
    5. afișați directoarele din `PATH` câte unul pe linie și numărați-le.

    💡 `man tr`: căutați `delete` și `squeeze`; `tr` citește doar de la intrare.

    **Verificare:** `BANANA`, ...; `bnn`, `ppl`, `chrry`, `ppl`, `kw`, `bnn`, `ppl`; 4 linii; `30` și `25`; câte un
    director pe linie, printre ele `/usr/bin`. <small>→ [Schimbarea caracterelor: `tr`](#changing-characters-tr)</small>

10. **Înlocuiți text**: Schimbați cuvinte și părți din linii cu `sed`, fără să schimbați fișierele.

    1. înlocuiți `apple` cu `pear` în `fruits.txt`; apoi verificați că `fruits.txt` nu s-a schimbat;
    2. afișați linia cu telefonul din `words.txt`, cu fiecare cifră înlocuită de `#`;
    3. afișați `students.csv` cu tab-uri în loc de virgule, apoi tăiați a doua coloană **fără** `-d`;
    4. afișați linia `notes.txt` din `words.txt` fără extensie;
    5. afișați-vă directorul home cu `/home` înlocuit de `/users`.

    💡 [Înlocuirea textului: `sed`](#replacing-text-sed); `\t` este un tab; la pasul 5, folosiți alt separator decât
    `/`.

    **Verificare:** `pear` de trei ori, iar `fruits.txt` are tot `apple`; `call #### ### ###`; `age`, `30`, `25`,
    `22`; `notes`; `/users/student`. <small>→ [Înlocuirea textului: `sed`](#replacing-text-sed)</small>

**Numărare și calcule**

11. **Numărați**: Numărați liniile, cuvintele și caracterele unui text.

    1. numărați liniile, cuvintele și octeții din `words.txt`; apoi doar liniile, fără numele fișierului;
    2. numărați utilizatorii sistemului;
    3. numărați caracterele și octeții din `Iași`.

    💡 `man wc`: căutați `chars`.

    **Verificare:** `15 18 116 words.txt`, apoi `15`; câteva zeci de utilizatori; `Iași` și sfârșitul liniei sunt 5
    caractere, dar 6 octeți: `ș` ocupă 2 octeți. <small>→ [Numărarea: `wc`](#counting-wc)</small>

12. **Calcule cu `awk`**: Răspundeți cu `awk` la întrebări despre comenzile din `orders.csv`.

    1. afișați numele și cantitatea fiecărei comenzi, fără antet;
    2. calculați câte fructe a comandat `alice` în total;
    3. calculați cantitatea medie a comenzilor de mere;
    4. afișați comenzile de cel puțin 2 fructe, apoi numărați-le;
    5. afișați numele și UID-ul utilizatorilor al căror UID este cel puțin `1000`, din baza de date a utilizatorilor.

    💡 [Calcule: `awk`](#computing-awk) are tot ce vă trebuie; UID-ul este câmpul 3 din baza de date a utilizatorilor.

    **Verificare:** `alice 3`, `bob 1`, ...; `10`; `2`; 4 comenzi; `student 1000` și, în plus, `nobody 65534`. <small>→ [Calcule: `awk`](#computing-awk)</small>

**Un pipeline**

13. **Citiți un log**: Răspundeți la întrebări despre cererile din `access.log`, cu pipeline-uri pe care le construiți
    câte o comandă pe rând.

    1. afișați pagina fiecărei cereri (al treilea câmp);
    2. afișați de câte ori a fost cerută fiecare pagină, cea mai cerută prima;
    3. afișați adresele care au cerut o pagină care nu există (starea `404`), fiecare o singură dată;
    4. numărați cererile care s-au terminat cu `404`.

    💡 [Un pipeline, pas cu pas](#a-pipeline-step-by-step); uitați-vă la ieșire după fiecare comandă.

    **Verificare:** 8 pagini; `/index.html` și `/old.html` au fost cerute de două ori, celelalte o dată; `10.0.0.3` și
    `10.0.0.9`; `5`. <small>→ [Un pipeline, pas cu pas](#a-pipeline-step-by-step) · [Filtre](#filters)</small>

**Coduri de ieșire**

14. **A mers?**: Citiți codul de ieșire al unei comenzi și rulați o comandă doar dacă alta a mers sau a eșuat.

    1. ghiciți **întâi** codul de ieșire al fiecărei comenzi, apoi verificați-l: `grep -q apple fruits.txt`,
       `grep -q mango fruits.txt`, `grep apple nope.txt`, `ls /nope`, `true` și `false`;
    2. porniți `sleep 100`, opriți-l cu <kbd>Ctrl</kbd>+<kbd>C</kbd> și afișați-i codul de ieșire;
    3. afișați `found` doar dacă `cherry` este în `fruits.txt`; apoi afișați `missing` doar dacă `mango` **nu** este în
       el;
    4. creați directorul `save` și, doar dacă a mers, copiați `orders.csv` în el, cu **o singură** linie; rulați din
       nou aceeași linie.

    💡 [Coduri de ieșire](#exit-codes) și [Înlănțuirea comenzilor](#chaining-commands--and-); `man ls`: căutați
    `Exit status`.

    **Verificare:** `0`, `1`, `2`, `2`, `0`, `1`; `sleep` se termină cu `130`: `128 + 2`, pentru `SIGINT`. `found`,
    apoi `missing`. A doua oară, `mkdir` eșuează cu `File exists`, iar `cp` nu rulează. <small>→ [Coduri de ieșire](#exit-codes) · [Înlănțuirea comenzilor](#chaining-commands--and-)</small>

**Editoare de text**

15. **Două editoare**: Scrieți un fișier cu `nano`, apoi schimbați-l cu `vim`.

    1. cu `nano`, creați `todo.txt` cu trei linii: `buy milk`, `learn vim` și `call bob`; tăiați ultima linie și
       lipiți-o deasupra primei; salvați și ieșiți;
    2. deschideți `todo.txt` cu `vim`; ștergeți linia `learn vim`, apoi dați undo; adăugați linia `practice awk` la
       final; înlocuiți `milk` cu `bread`, cu o comandă; salvați și ieșiți;
    3. deschideți-l din nou, ștergeți o linie și ieșiți **fără** să salvați;
    4. afișați `todo.txt`.

    💡 Tabelele din [`nano`](#nano) și [`vim`](#vim); în `vim`, uitați-vă mereu la ultima linie ca să aflați modul.

    **Verificare:** `todo.txt` are 4 linii: `call bob`, `buy bread`, `learn vim` și `practice awk`. <small>→ [`nano`](#nano) · [`vim`](#vim)</small>

### 🏠 Mai departe {/* #going-further */}

Fiecare exercițiu începe cu **scopul** lui; comenzile le alegeți voi. La final, verificați scopul, nu doar că fiecare
comandă a mers. Exercițiile folosesc fișierele din `~/lab06` din Primii pași.

16. **Editorul vostru, esențialul**: Continuați tutorialul editorului ales în exercițiul 1, până știți destul cât să-l
    folosiți în fiecare zi, apoi folosiți-l pe un fișier adevărat.

    1. instalați editorul dacă lipsește de pe calculatorul vostru:

       | Editor  | Pe Fedora                       | Pe Ubuntu                           | Tutorialul                        |
       | ------- | ------------------------------- | ----------------------------------- | --------------------------------- |
       | `vim`   | `sudo dnf install vim-enhanced` | `sudo apt install vim`              | `vimtutor`                        |
       | `nvim`  | `sudo dnf install neovim`       | `sudo apt install neovim`           | `nvim +Tutor`                     |
       | `hx`    | `sudo dnf install helix`        | `sudo snap install --classic helix` | `hx --tutor`                      |
       | `emacs` | `sudo dnf install emacs`        | `sudo apt install emacs`            | `emacs -nw -f help-with-tutorial` |

    2. porniți din nou tutorialul, mergeți la lecția la care v-ați oprit în laborator și urmați-l până la finalul
       acestor lecții; restul tutorialului nu vă trebuie încă:
       - `vim`, `nvim`: lecțiile 1 - 6, până știți `o`, `y` și `p` (lecția 7 este despre ajutor și setări);
       - `hx`: capitolele 1 - 6, până știți comanda de înlocuire, <kbd>r</kbd>;
       - `emacs`: secțiunile până la _Searching_, inclusiv;
    3. ieșiți din tutorial fără să salvați;
    4. deschideți `todo.txt` din exercițiul 15 cu editorul vostru, adăugați la final linia `use vim` (sau `use nvim`,
       `use hx`, `use emacs`), salvați și ieșiți; afișați `todo.txt`.

    💡 Fiecare tutorial începe cu felul în care vă mutați și ieșiți. Helix selectează întâi, apoi acționează:
    <kbd>x</kbd> selectează o linie, <kbd>d</kbd> o șterge. În Emacs,
    <kbd>Ctrl</kbd>+<kbd>X</kbd> <kbd>Ctrl</kbd>+<kbd>C</kbd> iese; `-nw` îl păstrează în terminal.

    **Verificare:** ați făcut lecțiile editorului vostru și vă puteți muta, puteți insera, șterge, copia, lipi, da
    undo, căuta, salva și ieși fără să vă uitați în tutorial. `todo.txt` se termină cu linia editorului vostru, după `practice awk`.
    <small>→ [Editoare de text](#text-editors)</small>

**Filtre de linii și căutare**

17. **Comenzile voastre preferate**: Folosiți terminalul de șase săptămâni. Aflați ce 5 comenzi rulați cel mai des.

    1. afișați istoricul shell-ului și găsiți câmpul care conține numele comenzii;
    2. afișați cele mai folosite 5 comenzi, fiecare cu de câte ori ați rulat-o, cea mai folosită prima.

    💡 `help history`; fiecare linie din `history` începe cu un număr.

    **Verificare:** 5 linii ca `   42 ls`, cu numerele în scădere; `ls` și `cd` sunt de obicei pe primele locuri.
    Fiecare terminal își adaugă comenzile în `~/.bash_history` când este închis, așa că un terminal nou nu știe
    comenzile celor încă deschise. <small>→ [Numărarea liniilor repetate](#counting-repeated-lines-uniq) · [Calcule: `awk`](#computing-awk)</small>

18. **Cele mai mari programe**: Discul calculatorului este aproape plin. Găsiți cele mai mari 5 fișiere din `/usr/bin`,
    cu dimensiuni ușor de citit.

    1. listați `/usr/bin` în format lung și sortați liniile după dimensiune, câmpul 5, ca număr; păstrați cele mai mari
       5;
    2. afișați doar dimensiunea și numele lor;
    3. refaceți totul cu dimensiunile scrise ca `2.1M` și sortați-le corect.

    💡 `man sort`: căutați `KEYDEF` și `human`; `man ls`: căutați `human`.

    **Verificare:** aceleași 5 fișiere la pașii 1 și 3, în aceeași ordine; la pasul 3, `sort -n` singur ar pune `900K`
    după `2.1M`, pentru că citește doar numărul. <small>→ [Sortarea: `sort`](#sorting-sort) · [Calcule: `awk`](#computing-awk)</small>

19. **Un formular de înscriere**: Un formular a salvat tot ce au scris oamenii, fără să verifice. Păstrați doar numerele
    de telefon și adresele de e-mail valide.

    Creați `contacts.txt`:

    ```bash
    cat > ~/lab06/contacts.txt << 'END'
    0722123456
    0722 123 456
    +40722123456
    072212345
    07221234567
    0312345678
    ana.pop@upb.ro
    bob@gmail
    carol@@yahoo.com
    dave_99@stud.upb.ro
    erin@example.com
    END
    ```

    1. afișați numerele de mobil: `07` și încă 8 cifre, nimic altceva pe linie;
    2. acceptați și numerele scrise cu `+4` în față;
    3. afișați adresele de e-mail: litere mici, cifre, `.` sau `_`, apoi **un singur** `@`, apoi un domeniu din litere
       mici și puncte, care se termină cu un `.` și câteva litere;
    4. numărați liniile care nu sunt nici număr de telefon, nici adresă de e-mail, cu **un singur** `grep`.

    💡 [Expresii regulate extinse](#extended-regular-expressions); un `+` care este caracter simplu se scrie `\+`.

    **Verificare:** `0722123456`; apoi și `+40722123456`; `ana.pop@upb.ro`, `dave_99@stud.upb.ro` și
    `erin@example.com`; `6` linii nu sunt nici una, nici alta. <small>→ [Expresii regulate extinse](#extended-regular-expressions) · [Opțiunile lui `grep`](#grep-options)</small>

**Coloane și calcule**

20. **Numele de la secretariat**: Secretariatul a exportat numele ca `Popescu, Ana`, dar sistemul nou vrea
    `Ana Popescu` și o adresă pentru fiecare student.

    Creați `names.txt` cu `printf '%s\n' 'Popescu, Ana' 'Ionescu, Mihai' 'Georgescu, Ioana' > names.txt`:

    1. afișați fiecare nume ca `Ana Popescu`, cu **un singur** `sed`;
    2. sortați rezultatul după prenume;
    3. afișați o adresă de e-mail pentru fiecare student, ca `ana.popescu@upb.ro`, toată cu litere mici.

    💡 `man sed`: căutați `\1`; într-un regex extins, `( )` păstrează ce s-a potrivit, iar `\1`, `\2` îl pun înapoi în
    textul nou.

    **Verificare:** `Ana Popescu`, `Mihai Ionescu`, `Ioana Georgescu`; sortate: `Ana`, `Ioana`, `Mihai`;
    `ana.popescu@upb.ro`, `mihai.ionescu@upb.ro`, `ioana.georgescu@upb.ro`. <small>→ [Înlocuirea textului: `sed`](#replacing-text-sed) · [Schimbarea caracterelor: `tr`](#changing-characters-tr)</small>

21. **Cuvintele manualului**: Ce cuvinte folosește cel mai des manualul lui `bash` și câte cuvinte diferite are?

    1. afișați textul din `man bash`, câte un cuvânt pe linie: fiecare succesiune de caractere care nu sunt litere
       devine un sfârșit de linie;
    2. faceți toate cuvintele cu litere mici și afișați cele mai frecvente 10, cu numărul lor;
    3. numărați cuvintele diferite.

    💡 `man tr`: căutați `complement`; pagina de manual, trimisă într-un pipe, este text simplu.

    **Verificare:** `the` este primul, la mare distanță; urmează cuvinte mici ca `a`, `is`, `to` și `of`. Sunt câteva
    mii de cuvinte diferite. <small>→ [Schimbarea caracterelor: `tr`](#changing-characters-tr) · [Numărarea liniilor repetate](#counting-repeated-lines-uniq)</small>

22. **Memoria browserului**: Calculatorul merge greu și îl bănuiți pe Firefox. Aflați câtă memorie folosesc împreună
    toate procesele lui.

    Deschideți Firefox cu câteva tab-uri, apoi:

    1. listați memoria (`RSS`) și linia de comandă întreagă a fiecărui proces și păstrați-le doar pe cele ale lui
       Firefox; numărați-le;
    2. adunați-le memoria și afișați-o în MiB;
    3. afișați cele 3 procese din sistem care folosesc cea mai multă memorie.

    💡 `man ps`: căutați `rss` (unitatea este KiB) și `args`; un tab din Firefox este și el un proces, al cărui nume nu
    este `firefox`, dar a cărui linie de comandă îl conține.

    **Verificare:** Firefox are mai multe procese, câte unul pentru câteva tab-uri; împreună folosesc câteva sute de
    MiB. Firefox este de obicei printre cele mai mari 3 procese. <small>→ [Calcule: `awk`](#computing-awk) · [Listarea proceselor](/docs/labs/03#listing-processes-ps)</small>

23. **Notele de la examen**: Asistentul are nevoie de un raport al examenului, dintr-un fișier cu note.

    Creați `grades.csv` cu
    `printf '%s\n' name,grade ana,9 bob,4 carol,7 dave,10 erin,3 grace,5 mallory,6 > grades.csv`, apoi calculați, cu
    `awk`:

    1. câți studenți au promovat (o notă de cel puțin `5`);
    2. media tuturor notelor și media studenților care au promovat;
    3. cea mai mare notă și studentul care a luat-o;
    4. numele studenților care nu au promovat, în ordine alfabetică.

    💡 O variabilă poate ține minte cea mai mare valoare de până acum: `$2 > max { max = $2 }`.

    **Verificare:** `5`; `6.28571` și `7.4`; `dave 10`; `bob` și `erin`. <small>→ [Calcule: `awk`](#computing-awk)</small>

24. **Un audit al utilizatorilor**: Scrieți raportul utilizatorilor sistemului, așa cum l-ar face un administrator în
    fiecare lună.

    Din baza de date a utilizatorilor:

    1. afișați fiecare shell și câți utilizatori îl au, cel mai folosit primul;
    2. numărați utilizatorii de sistem (un UID de la `1` la `999`);
    3. afișați numele și directorul home al utilizatorilor obișnuiți (un UID de la `1000` la `60000`).

    💡 `man login.defs`: căutați `UID_MAX`; condițiile din `awk` pot folosi `&&`.

    **Verificare:** `/usr/sbin/nologin` este shell-ul cel mai folosit; sunt câteva zeci de utilizatori de sistem;
    utilizatorii obișnuiți sunt `student` și fiecare utilizator din laboratorul 05 care mai există, cu un director în
    `/home`. `nobody` (`65534`) nu este un utilizator obișnuit. <small>→ [Calcule: `awk`](#computing-awk) · [Tăierea coloanelor: `cut`](#cutting-columns-cut)</small>

**Coduri de ieșire**

25. **Ghiciți lanțul**: Învățați să citiți `&&` și `||` fără să rulați comenzile.

    Scrieți **întâi** pe hârtie ce afișează fiecare linie, apoi verificați:

    1. `true && echo A || echo B`
    2. `false && echo A || echo B`
    3. `true || echo A && echo B`
    4. `false || false && echo C; echo $?`
    5. `true && false || echo D`

    **Verificare:** `A`; `B`; `B`; nimic, apoi `1`; `D`. Shell-ul citește de la stânga la dreapta, iar fiecare `&&` sau
    `||` se uită doar la codul de ieșire al celor dinaintea lui: la linia 5, `D` este afișat deși prima comandă a mers.
    <small>→ [Înlănțuirea comenzilor](#chaining-commands--and-)</small>

26. **Ce înseamnă numerele**: Aflați ce spun codurile de ieșire, pe lângă „succes” și „eroare”.

    1. găsiți în manual ce înseamnă `1` și `2` pentru `ls` și obțineți-le pe fiecare;
    2. porniți `sleep 100`, opriți-l cu `kill` dintr-un alt terminal și afișați-i codul de ieșire; refaceți totul cu
       `kill -9`;
    3. rulați `bash -c 'exit 42'` și afișați-i codul de ieșire; apoi `bash -c 'exit 300'`.

    💡 `man ls`: căutați `Exit status`; `kill -l 15` afișează numele semnalului `15`; un cod de ieșire este un octet.

    **Verificare:** `ls /nope` se termină cu `2`; `ls -R /etc` se termină cu `1`, pentru că unele directoare din el nu
    pot fi citite. `kill` dă `143` (`128 + 15`, `SIGTERM`), `kill -9` dă `137` (`128 + 9`, `SIGKILL`). `42`, apoi `44`:
    `300` nu încape într-un octet și se păstrează doar `300 - 256`. <small>→ [Coduri de ieșire](#exit-codes) · [Semnale](/docs/labs/04#signals)</small>

27. **O schimbare atentă**: Trebuie să schimbați `kiwi` în `mango` în `orders.csv`, direct în fișier. Faceți-o așa
    încât să puteți reveni oricând.

    1. cu **o singură** linie: copiați `orders.csv` în `orders.bak`; doar dacă copierea a mers, schimbați fișierul cu
       `sed -i`; afișați `changed` dacă amândouă au mers, sau `not changed` altfel;
    2. verificați conținutul ambelor fișiere;
    3. rulați din nou aceeași linie, dar copiați în `/nope/orders.bak`;
    4. puneți la loc `orders.csv` original, din `orders.bak`.

    💡 [Înlocuirea textului: `sed`](#replacing-text-sed) și [Înlănțuirea comenzilor](#chaining-commands--and-).

    **Verificare:** după pasul 1, `orders.csv` are `bob,mango,1`, iar `orders.bak` are `bob,kiwi,1`. La pasul 3, `cp`
    eșuează, `sed` nu rulează și se afișează `not changed`. La final, `grep -c kiwi orders.csv` afișează `1`.
    <small>→ [Înlănțuirea comenzilor](#chaining-commands--and-) · [Înlocuirea textului: `sed`](#replacing-text-sed)</small>

**Cum rulează un pipeline**

28. **Procesele unui pipeline**: Vedeți că, într-un pipeline, comenzile rulează împreună, ca un singur job.

    1. în al doilea terminal, afișați PID-ul shell-ului, apoi rulați `sleep 300 | sleep 301 | cat`;
    2. în primul terminal, afișați arborele de procese al celui de-al doilea shell, cu PID-urile; listați aceste
       procese cu PID-ul, PPID-ul, grupul de procese, starea și numele lor;
    3. opriți pipeline-ul cu <kbd>Ctrl</kbd>+<kbd>Z</kbd> și listați-le din nou; continuați-l cu `fg` și terminați-l
       cu <kbd>Ctrl</kbd>+<kbd>C</kbd>.

    💡 `man pstree`: căutați `pid`; `man ps`: căutați `pgid` și `state`.

    **Verificare:** cele trei comenzi sunt copiii aceluiași `bash`, pornite în același timp, și au același grup de
    procese: PID-ul primului `sleep`. Toate sunt `S` (așteaptă); după <kbd>Ctrl</kbd>+<kbd>Z</kbd>, toate sunt `T`
    (oprite); <kbd>Ctrl</kbd>+<kbd>C</kbd> le termină pe toate trei. <small>→ [Cum rulează un pipeline](#how-a-pipeline-runs) · [Foreground și background](/docs/labs/04#foreground-and-background)</small>

29. **Urmăriți pipe-ul**: Găsiți în `/proc` pipe-ul dintre două comenzi.

    1. în al doilea terminal, rulați `sleep 300 | cat`;
    2. în primul terminal, găsiți PID-urile lui `sleep` și `cat` și afișați unde duc intrările (`0`) și ieșirile (`1`)
       ale amândurora;
    3. terminați pipeline-ul.

    💡 `man pgrep`; `man readlink`; descriptorii de fișier ai unui proces sunt în `/proc/<PID>/fd` (laboratorul 03).

    **Verificare:** ieșirea lui `sleep` și intrarea lui `cat` sunt același `pipe:[...]`, cu același număr; intrarea lui
    `sleep` și ieșirea lui `cat` sunt terminalul, `/dev/pts/...`. <small>→ [Cum rulează un pipeline](#how-a-pipeline-runs) · [Sistemul de fișiere `/proc`](/docs/labs/03#the-proc-file-system)</small>

30. **Cine termină primul**: Aflați ce se întâmplă cu o comandă al cărei cititor s-a oprit din citit.

    Pentru fiecare linie, ghiciți **întâi** codurile de ieșire ale celor două comenzi, apoi afișați-le cu `PIPESTATUS`:

    1. `yes | head -n 3`;
    2. `seq 5 | sleep 2`;
    3. `seq 100000 | sleep 2`.

    💡 `kill -l 13`; `seq 100000 | wc -c` arată cât text scrie `seq`; pipe-ul ține 64 KiB.

    **Verificare:** `141 0`: `yes` a primit `SIGPIPE`. `0 0`: cele 5 linii scurte încap în pipe, iar `seq` s-a terminat
    înaintea lui `sleep`. `141 0`: aproximativ 575 KiB nu încap, așa că `seq` a așteptat un cititor; când `sleep` s-a
    terminat fără să citească, `seq` a primit `SIGPIPE`. <small>→ [Cum rulează un pipeline](#how-a-pipeline-runs)</small>

31. **Un eșec la mijloc**: În fiecare noapte, un pipeline numără clienții magazinului. Într-o noapte fișierul lipsea,
    iar raportul a spus `0`, fără nicio eroare. Faceți pipeline-ul să spună adevărul.

    1. rulați `cut -d, -f1 nope.csv | sort -u | wc -l`, apoi afișați-i codul de ieșire și codurile de ieșire ale
       fiecărei comenzi;
    2. adăugați `&& echo ok || echo failed` după pipeline;
    3. activați `pipefail` și rulați din nou pasul 2; apoi dezactivați-l.

    💡 [Cum rulează un pipeline](#how-a-pipeline-runs).

    **Verificare:** pipeline-ul afișează `0` și se termină cu `0`, dar `PIPESTATUS` este `1 0 0`; fără `pipefail`
    spune `ok`, cu `pipefail` spune `failed`. <small>→ [Cum rulează un pipeline](#how-a-pipeline-runs) · [Codul de ieșire al unui pipeline](#the-exit-code-of-a-pipeline)</small>

32. **Urmăriți un log în timp real**: Urmăriți cererile care se termină cu `404` pe măsură ce sosesc și doar adresele
    lor.

    1. în al doilea terminal, urmăriți `live.log` și păstrați doar liniile care conțin `404`;
    2. în primul terminal, adăugați linia `10.0.0.9 GET /x 404` în `live.log`, apoi linia `10.0.0.7 GET / 200`;
    3. în al doilea terminal, adăugați `cut` la final, ca să păstrați doar adresa; adăugați încă o linie cu `404`;
    4. reparați pipeline-ul de la pasul 3, astfel încât adresa să apară imediat.

    💡 [Cum rulează un pipeline](#how-a-pipeline-runs); `man grep`: căutați `line-buffered`.

    **Verificare:** la pasul 2 apare doar linia cu `404`, imediat. La pasul 3 nu apare nimic: ieșirea lui `grep` merge
    acum într-un pipe, iar `grep` așteaptă până are 4 KiB de text. Cu `grep --line-buffered`, adresa apare imediat.
    <small>→ [Cum rulează un pipeline](#how-a-pipeline-runs) · [Primele și ultimele linii](#the-first-and-the-last-lines-head-and-tail)</small>

**Editoare de text**

33. **Editorul vostru pe un fișier adevărat**: Schimbați un fișier cu editorul învățat în exercițiile 1 și 16, fără
    să rescrieți liniile care rămân.

    1. copiați `students.csv` în `class.csv` și deschideți-l cu editorul vostru;
    2. adăugați linia `Dave,27,Cluj` la final;
    3. copiați linia lui `Bob` și lipiți copia sub ea; schimbați copia în `Erin,24,Iasi`;
    4. înlocuiți fiecare `,` cu `;`, cu **o singură** comandă; salvați, ieșiți și afișați fișierul.

    💡 Alegeți editorul vostru:

    <Tabs groupId="editor">
    <TabItem value="vim" label="vim">

    | Pas | Taste |
    | --- | --- |
    | deschideți fișierul | `vim class.csv` |
    | adăugați o linie la final | <kbd>G</kbd> merge la ultima linie, <kbd>o</kbd> deschide o linie nouă dedesubt; scrieți-o, <kbd>Esc</kbd> |
    | copiați o linie și lipiți-o dedesubt | pe `Bob`: <kbd>y</kbd><kbd>y</kbd> copiază linia, <kbd>p</kbd> o lipește dedesubt |
    | schimbați o linie întreagă | pe copie: <kbd>c</kbd><kbd>c</kbd> șterge textul liniei; scrieți-l pe cel nou, <kbd>Esc</kbd> |
    | înlocuiți în tot fișierul | `:%s/,/;/g`; `:s` fără `%` schimbă doar linia curentă |
    | salvați și ieșiți | `:wq` |

    </TabItem>
    <TabItem value="nvim" label="nvim">

    Neovim are tastele lui `vim`.

    | Pas | Taste |
    | --- | --- |
    | deschideți fișierul | `nvim class.csv` |
    | adăugați o linie la final | <kbd>G</kbd> merge la ultima linie, <kbd>o</kbd> deschide o linie nouă dedesubt; scrieți-o, <kbd>Esc</kbd> |
    | copiați o linie și lipiți-o dedesubt | pe `Bob`: <kbd>y</kbd><kbd>y</kbd> copiază linia, <kbd>p</kbd> o lipește dedesubt |
    | schimbați o linie întreagă | pe copie: <kbd>c</kbd><kbd>c</kbd> șterge textul liniei; scrieți-l pe cel nou, <kbd>Esc</kbd> |
    | înlocuiți în tot fișierul | `:%s/,/;/g`; `:s` fără `%` schimbă doar linia curentă |
    | salvați și ieșiți | `:wq` |

    </TabItem>
    <TabItem value="hx" label="hx">

    | Pas | Taste |
    | --- | --- |
    | deschideți fișierul | `hx class.csv` |
    | adăugați o linie la final | <kbd>g</kbd><kbd>e</kbd> merge la ultima linie, <kbd>o</kbd> deschide o linie nouă dedesubt; scrieți-o, <kbd>Esc</kbd> |
    | copiați o linie și lipiți-o dedesubt | pe `Bob`: <kbd>x</kbd> selectează linia, <kbd>y</kbd> o copiază, <kbd>p</kbd> o lipește dedesubt |
    | schimbați o linie întreagă | pe copie: <kbd>x</kbd> selectează linia, <kbd>_</kbd> lasă deoparte sfârșitul ei, <kbd>c</kbd> o șterge; scrieți-o pe cea nouă, <kbd>Esc</kbd> |
    | înlocuiți în tot fișierul | <kbd>%</kbd> selectează tot fișierul, <kbd>s</kbd> `,` <kbd>Enter</kbd> selectează fiecare `,` din el, <kbd>r</kbd><kbd>;</kbd> le înlocuiește pe toate |
    | salvați și ieșiți | `:wq` |

    </TabItem>
    <TabItem value="emacs" label="emacs">

    | Pas | Taste |
    | --- | --- |
    | deschideți fișierul | `emacs -nw class.csv` |
    | adăugați o linie la final | <kbd>Alt</kbd>+<kbd>&gt;</kbd> merge la finalul fișierului; scrieți-o |
    | copiați o linie și lipiți-o dedesubt | la începutul lui `Bob` (<kbd>Ctrl</kbd>+<kbd>A</kbd>): <kbd>Ctrl</kbd>+<kbd>K</kbd> de două ori taie linia, <kbd>Ctrl</kbd>+<kbd>Y</kbd> de două ori o lipește la loc, plus o copie |
    | schimbați o linie întreagă | pe copie (<kbd>Ctrl</kbd>+<kbd>P</kbd> urcă), la începutul ei: <kbd>Ctrl</kbd>+<kbd>K</kbd> taie textul; scrieți-l pe cel nou |
    | înlocuiți în tot fișierul | <kbd>Alt</kbd>+<kbd>&lt;</kbd> merge la început, <kbd>Alt</kbd>+<kbd>%</kbd> `,` <kbd>Enter</kbd> `;` <kbd>Enter</kbd> întreabă la fiecare potrivire; <kbd>!</kbd> le înlocuiește pe toate |
    | salvați și ieșiți | <kbd>Ctrl</kbd>+<kbd>X</kbd> <kbd>Ctrl</kbd>+<kbd>S</kbd>, apoi <kbd>Ctrl</kbd>+<kbd>X</kbd> <kbd>Ctrl</kbd>+<kbd>C</kbd> |

    </TabItem>
    </Tabs>

    **Verificare:** `class.csv` are 6 linii: `name;age;city`, `Alice;30;Paris`, `Bob;25;London`, `Erin;24;Iasi`,
    `Carol;22;Bucharest` și `Dave;27;Cluj`. <small>→ [Editoare de text](#text-editors)</small>

**Curățenie**

34. **Curățenie**: Lăsați directorul home așa cum era înainte de laborator.

    1. ștergeți `~/lab06`;
    2. dacă `set -o pipefail` este încă activ într-un shell, închideți acel terminal.

    **Verificare:** `ls ~` nu mai arată `lab06`; `set -o | grep pipefail` afișează `pipefail off` într-un terminal nou.
    <small>→ [Cum rulează un pipeline](#how-a-pipeline-runs)</small>

### 📝 Provocări {/* #challenges */}

Aceste exerciții seamănă cu cele de la examen. Fiecare vă dă un **rezultat** de atins, dar nu și pașii: comenzile le
alegeți voi. Fiecare se termină cu **Verificarea** după care va fi notat. Unele dintre ele au nevoie de
[Cum rulează un pipeline](#how-a-pipeline-runs).

Toate provocările pornesc de la aceeași configurație, cea pe care o veți găsi la examen: directorul `~/exam` cu patru
fișiere. `web.log` are câte o cerere pe linie, cu 7 câmpuri separate de un spațiu: adresa, data, ora, metoda, pagina,
starea și numărul de octeți trimiși. Copiați și rulați aceste comenzi înainte de prima provocare; rulați-le din nou ca
să recăpătați fișierele originale:

```bash
mkdir -p ~/exam
cd ~/exam
cat > web.log << 'END'
10.0.0.7 2026-11-02 10:15:01 GET /index.html 200 5120
10.0.0.9 2026-11-02 10:15:04 GET /logo.png 404 0
10.0.0.7 2026-11-02 10:15:09 GET /about.html 200 2048
10.0.0.3 2026-11-02 10:16:12 GET /old.html 404 0
10.0.0.9 2026-11-02 10:16:30 GET /favicon.ico 404 0
10.0.0.5 2026-11-02 10:17:45 POST /login 200 512
10.0.0.9 2026-11-02 10:18:02 GET /admin 403 0
10.0.0.3 2026-11-02 10:18:40 GET /old.html 404 0
10.0.0.12 2026-11-02 11:02:11 GET /index.html 200 5120
10.0.0.5 2026-11-02 11:03:27 GET /exam.pdf 200 734003
10.0.0.9 2026-11-02 11:04:51 POST /login 401 0
10.0.0.9 2026-11-02 11:04:53 POST /login 401 0
10.0.0.9 2026-11-02 11:04:55 POST /login 401 0
10.0.0.7 2026-11-02 11:20:00 GET /index.html 200 5120
10.0.0.12 2026-11-02 12:01:10 GET /exam.pdf 200 734003
10.0.0.7 2026-11-02 12:30:44 GET /contact.html 200 1024
10.0.0.5 2026-11-02 12:31:02 POST /login 401 0
END
printf '%s\n' 'B 123 ABC' 'B 12 XYZ' 'IF 07 UPB' 'CJ 123 ABC' 'IS 99 ab' 'b 100 USO' \
    'TM 05 LNX' 'B1 23 ABC' 'AG 7 OOO' > plates.txt
printf '%s\n' name,lab,exam ana,4.5,3.5 bob,2,1.5 carol,3,4 dave,5,4.5 erin,1.5,2 \
    grace,3.5,1 mallory,4,2.5 > grades.csv
printf '%s\n' '# the settings of the exam server' port=8080 '# host=localhost' \
    host=0.0.0.0 debug=true users=ana,bob,carol > settings.conf
```

Când terminați toate provocările, ștergeți totul cu `rm -rf ~/exam`.

35. **Cele mai active adrese**: Aflați cine folosește cel mai mult serverul și cât trimite acesta.

    Cu **un singur** pipeline pentru fiecare:

    1. afișați cele 3 adrese cu cele mai multe cereri, fiecare cu numărul ei de cereri, cea mai activă prima;
    2. afișați numărul total de octeți trimiși de server;
    3. afișați numărul de octeți trimiși către `10.0.0.12`.

    **Verificare:** cele trei ieșiri sunt exact:

    ```text
          6 10.0.0.9
          4 10.0.0.7
          3 10.0.0.5
    ```

    apoi `1486950`, apoi `739123`. <small>→ [Filtre](#filters) · [Calcule: `awk`](#computing-awk)</small>

36. **Cine ghicește parole**: O autentificare eșuată este o cerere `POST` pentru `/login` care se termină cu `401`.
    Găsiți adresele care au eșuat la autentificare de cel puțin 3 ori și cât de ocupat a fost serverul în fiecare oră.

    1. afișați fiecare adresă cu cel puțin 3 autentificări eșuate, cu numărul ei de eșecuri;
    2. afișați numărul de cereri din fiecare oră, în ordinea orelor.

    **Verificare:** pasul 1 afișează exact `      3 10.0.0.9` (`10.0.0.5` a eșuat o singură dată); pasul 2 afișează
    exact:

    ```text
          8 10
          6 11
          3 12
    ```

    <small>→ [Calcule: `awk`](#computing-awk) · [Tăierea coloanelor: `cut`](#cutting-columns-cut)</small>

37. **Numere de înmatriculare**: Păstrați doar numerele de înmatriculare valide din `plates.txt`, cu **un singur**
    `grep` și **o singură** expresie regulată.

    Un număr valid are, separate prin câte un spațiu:

    - județul: `B` (București) sau două litere mari;
    - un număr: 2 sau 3 cifre pentru `B`, exact 2 cifre pentru celelalte județe;
    - trei litere mari.

    Nimic altceva nu poate fi pe linie.

    **Verificare:** comanda afișează exact `B 123 ABC`, `B 12 XYZ`, `IF 07 UPB` și `TM 05 LNX`, iar aceeași comandă cu
    `-c` afișează `4`. <small>→ [Expresii regulate extinse](#extended-regular-expressions)</small>

38. **Notele finale**: `grades.csv` are, pentru fiecare student, nota de la laborator și nota de la examen. Nota finală
    este suma lor. Un student promovează cu o notă finală de cel puțin `5` **și** o notă la examen de cel puțin `2.5`.

    Cu **un singur** pipeline, afișați numele și nota finală ale fiecărui student care a promovat, cea mai mare notă
    prima.

    **Verificare:** ieșirea este exact `dave 9.5`, `ana 8`, `carol 7` și `mallory 6.5`; `grace` are `4.5`, iar `bob`,
    `erin` au mai puțin, așa că nu sunt afișați. <small>→ [Calcule: `awk`](#computing-awk) · [Sortarea: `sort`](#sorting-sort)</small>

39. **Ghiciți codurile de ieșire**: Ghiciți ce afișează fiecare linie și codurile ei de ieșire, apoi dovediți fiecare
    răspuns.

    În `~/exam`, completați **întâi** tabelul pe hârtie; apoi rulați fiecare linie, urmată de `echo $?`, sau de
    `echo "${PIPESTATUS[@]}"` pentru liniile 4 și 6:

    | Linia                                                                      | Afișează | Cod(uri) de ieșire |
    | -------------------------------------------------------------------------- | -------- | ------------------ |
    | 1. `grep -c ' 404 ' web.log`                                               |          |                    |
    | 2. `grep -c ' 500 ' web.log`                                               |          |                    |
    | 3. `grep -q ' 500 ' web.log && echo yes \|\| echo no`                      |          |                    |
    | 4. `cut -d' ' -f1 web.log nope.log \| sort -u \| wc -l`                    |          |                    |
    | 5. aceeași linie, după `set -o pipefail`                                   |          |                    |
    | 6. `yes \| head -n 1 > /dev/null`                                          |          |                    |
    | 7. `mkdir -p backup && cp nope.log backup/ && echo saved \|\| echo failed` |          |                    |

    Dezactivați `pipefail` după linia 5.

    **Verificare:**

    |     | Afișează                           | Cod(uri) de ieșire                                         |
    | --- | ---------------------------------- | ---------------------------------------------------------- |
    | 1.  | `4`                                | `0`                                                        |
    | 2.  | `0`                                | `1`: `grep` nu a găsit nimic, chiar dacă a afișat un număr |
    | 3.  | `no`                               | `0`, codul de ieșire al lui `echo no`                      |
    | 4.  | o eroare a lui `cut`, apoi `5`     | `1 0 0`: `cut` a eșuat, dar a citit `web.log`              |
    | 5.  | o eroare a lui `cut`, apoi `5`     | `1`                                                        |
    | 6.  | nimic                              | `141 0`: `yes` a primit `SIGPIPE`                          |
    | 7.  | o eroare a lui `cp`, apoi `failed` | `0`, codul de ieșire al lui `echo failed`                  |

    <small>→ [Coduri de ieșire](#exit-codes) · [Înlănțuirea comenzilor](#chaining-commands--and-) · [Cum rulează un pipeline](#how-a-pipeline-runs)</small>

40. **Configurați cu `vim`**: Schimbați `settings.conf` doar cu `vim`, fără să rescrieți liniile care rămân.

    La final, fișierul trebuie să aibă exact aceste linii, în această ordine:

    ```text
    port=80
    host=0.0.0.0
    debug=false
    users=ana,bob,carol,dave
    timeout=30
    ```

    💡 În `vim`, `:help :g` explică cum rulați o comandă, ca `d`, pe fiecare linie care se potrivește cu un regex;
    `:help A` explică cum adăugați text la sfârșitul unei linii.

    **Verificare:** `cat -A settings.conf` afișează cele 5 linii, fiecare terminată cu `$`, fără spații înainte de `$`
    și fără linii goale. <small>→ [`vim`](#vim)</small>

## Întrebări de recapitulare {/* #wrap-up-questions */}

Folosiți **ultimele 5 minute** ale laboratorului ca să răspundeți la aceste întrebări împreună cu colegii și cu
asistentul. La ultimele două nu există răspunsuri greșite.

1. Ce este un **filtru**? De ce poate fi ieșirea oricărui filtru intrarea oricărui alt filtru?
2. De ce are nevoie `uniq` de `sort` înaintea lui? De ce pune `sort` `100` înainte de `2` și cum rezolvați asta?
3. Care este diferența dintre `*` într-un **glob** și `*` într-o **expresie regulată**? De ce puneți un regex între
   ghilimele simple?
4. Când folosiți `cut` și când `awk`? Ce se întâmplă cu `cut` când câmpurile sunt separate de mai multe spații?
5. Care este diferența dintre `tr` și `sed`?
6. Ce înseamnă **codul de ieșire** `0`? Ce fac `&&` și `||` cu el?
7. Ce cod de ieșire are un pipeline? Ce poate ascunde?
8. Cum ieșiți din `vim` fără să salvați?
9. Ce filtru v-a surprins cel mai mult astăzi?
10. Ce editor veți folosi de acum înainte și de ce?

## Extra {/* #extra */}

1. **`column`**: `column -t -s, students.csv` aliniază un fișier CSV ca pe un tabel, ca să fie ușor de citit.
   <small>→ `man column`</small>
2. **`jq`**: multe programe și servicii web scriu **JSON** în loc de linii; `jq` este filtrul pentru el, cu propriul lui
   mic limbaj. Instalați-l cu `sudo dnf install jq` (Ubuntu: `sudo apt install jq`). <small>→ `man jq`</small>
3. **Alte editoare**: `helix` (`hx --tutor`) și `emacs` (<kbd>Ctrl</kbd>+<kbd>H</kbd>, apoi <kbd>T</kbd>) au propriile
   tutoriale, ca `vimtutor`; Visual Studio Code și Zed pot folosi tastele lui `vim`.
