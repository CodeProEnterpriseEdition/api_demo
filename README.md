# api_demo

Harjoituksen kolmas testirepo. Siinä on kevyitä API-testejä Tampereen
kaupungin avoimia rajapintoja vasten. Raskaat testit ovat repoissa
`oma_runner` (kuorma- ja resurssitestit) ja `robot_demo` (selaintestit).
Kolmella repolla nähdään, miten eri repojen ja eri painoiset ajot jakavat
saman testikoneen (win-agent-15).

| | |
|---|---|
| Runner | `runner-api-demo` (koneen vaihe 4, testirepo) |
| Label | `api-demo` |
| Testikuva | `localhost:5000/robot-tests:current` (koneen paikallinen rekisteri) |

## Työnkulku

**API tests: Tampere open data** (Actions-välilehti): testit 1–3 kertaa
yhtä aikaa, jokainen ajo omassa kontissaan koneen rajoilla. Summary-sivulla
on jokaisen testin tulos ja lopuksi ajojen vertailutaulukko.

## Testit (`tests/`)

| Tiedosto | Rajapinta | Mitä testataan |
|---|---|---|
| `public_transport.robot` | Nyssen Journeys API (`data.itsfactory.fi`) | Linjat löytyvät, linja 3 kulkee Hervannasta, linjan 3 bussit ovat juuri nyt Tampereen seudulla ja niiden sijainti on tuore. Yöllä, kun busseja ei ole, viimeinen testi ohitetaan. |
| `open_data_portal.robot` | Dataportaalin CKAN API (`data.tampere.fi`) | Portaali vastaa, haku löytää uimahallit, uimahallit taulukkokyselynä (DataStore) ja suodatus postinumerolla. |
| `drinking_water.robot` | Vellamo API (`vellamo.tampere.fi`) | Mittaussuureet (kloori, kovuus, pH, lämpötila) ja talousveden pH kaikilla alueilla laatusuosituksen rajoissa 6,5–9,5. Arvot ovat laskennallisia arvioita. |
| `news_feed.robot` | Kaupungin uutisten RSS-syöte | Syöte on kelvollista RSS:ää, uutisia on vähintään viisi, ja jokaisella on otsikko, päiväys ja tampere.fi-linkki. |

Yhteiset osoitteet ja avainsanat: `tests/resources/tampere.resource`.

## RSS vai API?

Molemmat haetaan samalla HTTP GET -pyynnöllä, joten ne testataan samalla
tavalla: tilakoodi, sisällön tyyppi ja rakenne. Ero on vastauksessa.
RSS-syöte on kiinteä XML-lista uusimmista kohteista, eikä siltä voi kysyä
mitään. API ottaa vastaan parametreja (esim. linja, hakusana, suodatin) ja
palauttaa yleensä JSONia.

## Data ja lisenssi

Tampereen kaupungin ja ITS Factoryn avoin data, lisenssi CC BY 4.0
(https://data.tampere.fi). Rajapinnat eivät vaadi avainta. Testit kutsuvat
oikeita palveluja, joten epäonnistuminen voi johtua myös siitä, että palvelu
oli hetkellisesti alhaalla tai hidas.

## Ajo omalla koneella

```
pip install robotframework robotframework-requests
robot --outputdir results tests
```
