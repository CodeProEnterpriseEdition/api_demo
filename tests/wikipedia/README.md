# Wikipedia-testit

Oikeat Robot Framework -selaintestit Wikipediaa vasten: artikkelien
lukeminen, haku, linkit, etusivu ja isot sivut. 20 testiä viidessä
tiedostossa. Sama testisarja on kaikissa kolmessa testirepossa (oma_runner,
robot_demo, api_demo), joten ajoja voi verrata yksin ja yhtä aikaa.

Työnkulku: **Actions › Test: Wikipedia**. Summary näyttää jokaisen
tiedoston ja testin keston, CPU-ajan, muistihuipun ja epäonnistuneiden
testien viestit.

| Tiedosto | Tagi | Testit |
|---|---|---|
| `articles.robot` | `articles` | Otsikko ja johdanto, pääluvut, tietolaatikko, suomenkielisen artikkelin pääluvut |
| `search.robot` | `search` | Hakukenttä, kokotekstihaku, haku ilman tuloksia, uudelleenohjaus |
| `navigation.robot` | `navigation` | Linkki ja takaisin, kieliversio, luokkasivu, satunnainen artikkeli |
| `main_page.robot` | `main-page` | Etusivun osiot, uutiset, päivän suositeltu artikkeli, suomenkielinen etusivu |
| `media.robot` | `media` | Kuva latautuu, kuvat latautuvat vierittäessä, pitkä artikkeli, iso taulukko |

Muut tagit:

| Tagi | Testit | Käyttö |
|---|---|---|
| `smoke` | 5 (yksi nopea per tiedosto) | Nopea tarkistus, että kaikki osa-alueet toimivat |
| `heavy` | 3 (isot sivut) | Raskaimmat testit; jätä pois nopeaa ajoa varten |
| `finnish` | 3 | Suomenkielinen Wikipedia |

Esimerkkejä työnkulun kenttiin (Robotin tagilausekkeet):

| include | exclude | Ajaa |
|---|---|---|
| (tyhjä) | (tyhjä) | Kaikki 20 |
| `smoke` | | 5 nopeaa |
| `search` | | Hakutestit (4) |
| `searchORnavigation` | | Haku ja navigointi (8) |
| `articlesANDfinnish` | | Suomenkieliset artikkelitestit (1) |
| | `heavy` | Kaikki paitsi isot sivut (17) |

Omalla koneella: `robot --outputdir results --include smoke tests/wikipedia`
(vaatii Robot Frameworkin ja Browser-kirjaston).

Huomioita:

- Testit käyttävät oikeaa Wikipediaa, joten tulokseen vaikuttavat myös verkko
  ja Wikipedian sisältö. Etusivun suositeltu artikkeli ja satunnainen
  artikkeli vaihtuvat joka ajossa.
- Yksi täysi ajo lataa noin 25 sivua, mikä vastaa yhden käyttäjän selailua.
  Älä aja testejä silmukassa.
