# PYRP
PYRP- Project Y RP - MTA SK/CZ Server

🧱 CORE SYSTÉMY
🔐 Account systém
Registrácia / login cez GUI

Viacero postáv na účet

Whitelist a IP logy

Token / heslo login (s kryptovaním)

Bezpečnostné prvky (dvojfaktor, HWID hashovanie)

📋 Admin systém
GUI panel, rozdelenie práv

Správa hráčov, reporty, logovanie

Live nástroje (teleport, mute, heal, ban)

Databázové logy každého zásahu

👤 HRÁČ A RP STAV
🌟 VIP systém
Výhody: XP bonus, vzhľady, rýchlejšie výplaty, efekty

Úroveň VIP sa ukladajú v DB, viditeľné v GUI

🎓 Skill systém
Každý job má XP, levely, výhody

TOP 10 hráčov získava bonus XP

XP sa zapisujú po každej zákazke

⚕️ Zdravotníctvo
HP systém + zranenia (pad, zbraň, nehoda)

Respawn alebo ošetrenie v nemocnici

Medici ako RP frakcia s výplatou

💼 PRÁCA A EKONOMIKA
🧾 Úrad práce
GUI pre výber zamestnania

Podmienky: licencia, level, whitelist

Prehľad jobov a história zamestnania

👷 Job systém
Joby: Taxikár, pilot, kamionista, upratovač, IT technik, farmár, mechanik

Každý job má XP, zákazky, GUI panel

Výplaty podľa levelu a zákazky

Job cooldowny a grind protection

Rebríčky + GUI s bonusmi

📦 Trhovisko
Predaj/nákup z inventára

GUI panel s kartami: Nákup, Predaj, Moje ponuky

Server-side validácia

Ukladanie v DB (vlastník, cena, čas)

🏘️ REALITA A MAJETOK
🏠 Reality
Kúpa/prenájom domov/bytu

GUI panel, mapa, ceny, dane

Interiéry a zámky

Viac vlastníkov, spolubývajúci

🚗 Vozidlá
Kúpa, STK, poistenie

Vozidlové zámky, GPS, servis

Spotreba, technický stav

🧾 STK / Poistenie
Overenie vozidiel políciou

RP poistenie pri nehodách

📈 EKONOMIKA A ŠTÁT
📊 Finančný systém
Bankový účet pre každého

Výplaty z jobu/frakcie

Dane, pokuty, prehľad cez web

Firemné účty + daňový systém

🗳️ Politika a voľby
Starosta: práva na dane, eventy

Hlasovanie cez GUI/web

Kandidáti, história volieb

📁 INVENTÁR A INTERAKCIE
📁 Inventár
Fyzické predmety

Tašky na nosnosť

Kľúče od domov/áut

RP predmety od adminov (/vytvorpredmet)

📞 Telefónny systém
GUI telefón s aplikáciami

Hovory, SMS

GPS navigácia

Trhovisko, Mestský web

Slabé signálové zóny

🛡️ FRAKCIE A RP ORGANIZÁCIE
👮‍♂️ Polícia / väzenie
GUI zatýkanie, tresty, väzenie

História zločinov hráča

Role RP dôkazy a zásahy

🏢 Frakcie
Tvorba a správa frakcie

Členovia, výplaty, práva (checkboxy)

Logy: pozvánky, výplaty, zmeny

Frakčný účet

📅 SPOLOČENSKÉ SYSTÉMY
🎯 RP udalosti
Kalendár udalostí

Oficiálne, hráčske, frakčné

Účasť, teleport, oznámenia

Databázový záznam účastníkov

📊 Rebríčky
TOP joby, najbohatší, RP skóre

Aktualizované denne / týždenne

Prístupné cez GUI + mestský web

🌐 Mestský web
HTML frontend + login systém

Zobrazenie pokút, volieb, oznamov

Prepojenie s databázou

Dostupné aj cez telefón (RP)

🗃️ DATABÁZA A STRUKTÚRA
Každý systém má vlastnú SQL tabuľku

Prepojenie pomocou user_id a character_id

Všetky RP akcie sa logujú (aj reporty, admin zásahy)

Možnosť exportovať štatistiky (aktivita, výplaty, ekonomika)
