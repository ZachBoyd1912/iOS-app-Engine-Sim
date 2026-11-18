# Cars, tyres, differentials, drive modes and engine pairings: gap-fill research (pass 2)

Research date: 2026-11-18. Status: PARTIAL. Builds on `gearboxes-and-cars.md` (first pass, not edited).

## Tag legend

- `[SRC]` = page fetched and read in this pass. URL given in the section source list.
- `[SRC-1P]` = figure taken from the first-pass file, which fetched that page. Not re-read in this pass. Treat as sourced but re-check before shipping.
- `[UNVERIFIED]` = search-result snippet only, forum or retailer claim, derived by hand, or no source. Placeholder for game tuning only, not data.
- Derived values (hand calculation from a sourced formula) are marked `[SRC] (computed)`. Re-check them numerically before use.

Nothing in this file was invented. Where a page was fetched and did not contain the number, the gap is stated.

---

## 0. Coverage at a glance

| Area | Result |
|---|---|
| 1. Body types (19 requested) | Kerb mass sourced for about 12 types. Wheelbase sourced for about 10. Track: 0 sourced. Frontal area: 0 sourced (CdA/drag area only for 5 cars). Cd sourced for about 15 types. Weight distribution: 1 car. Engine-bay dimensions: 0 sourced. |
| 2. Tyres | Dry/wet mu sourced for generic road and gravel/snow (Wong 1993, Bosch 1996 via hpwizard, Engineering ToolBox). Class-specific mu for semi-slick, slick, drag radial, drag slick, winter, rally gravel: not sourced. Rolling resistance: generic car/truck sourced. Pacejka longitudinal parameter sets (B,C,D,E) sourced for dry/wet/snow/ice from a tutorial. Lateral Pacejka: structure only, no numbers. |
| 3. Diffs and driveline | Torsen bias sourced (T-1 type description, illustrative 3:1). T-2 2.5:1 standard is snippet-only (UNVERIFIED). Quaife ATB: no official bias ratio (manufacturer says it does not publish one). Clutch LSD preload and slip torque: snippet only. Final-drive examples sourced for 3 cars. Drivetrain loss: government figure is a share of fuel energy, not crank-to-wheel. Weight transfer longitudinal formula sourced; lateral formula not on the source page. |
| 4. Drive modes and control | MegaSquirt MShift shift table structure and example speed bins sourced (SRC). Haltech launch control structure and ignition-retard values sourced (SRC). Wikipedia rev limiter and anti-lag mechanics sourced (SRC). Per-mode shift rpm, throttle exponent, shift time by mode, TC slip target: NOT sourced. |
| 5. Engine/car pairings | 48 entries listed (two candidate cars, Toyota Supra and Dodge Challenger, were dropped: no sourced data). Most have engine, gearbox and power from SRC pages. Mass is sourced for about half. Entry 47 (RX-7 FD) and a few power/mass cells are UNVERIFIED (noted inline). |

---

## 1. Body types

Source list for this section:
- Wikipedia, Kei car: https://en.wikipedia.org/wiki/Kei_car [SRC]
- Wikipedia, Suzuki Alto: https://en.wikipedia.org/wiki/Suzuki_Alto [SRC]
- Wikipedia, Honda Civic Type R: https://en.wikipedia.org/wiki/Honda_Civic_Type_R [SRC]
- Wikipedia, Mazda MX-5: https://en.wikipedia.org/wiki/Mazda_MX-5 [SRC]
- Wikipedia, Porsche 911 (992): https://en.wikipedia.org/wiki/Porsche_911_(992) [SRC]
- Wikipedia, Bugatti Chiron: https://en.wikipedia.org/wiki/Bugatti_Chiron [SRC]
- Wikipedia, Caterham Seven: https://en.wikipedia.org/wiki/Caterham_Seven [SRC]
- Wikipedia, Ariel Atom: https://en.wikipedia.org/wiki/Ariel_Atom [SRC]
- Wikipedia, Ford Mustang (seventh generation): https://en.wikipedia.org/wiki/Ford_Mustang_(seventh_generation) [SRC]
- Wikipedia, Toyota GR86: https://en.wikipedia.org/wiki/Toyota_GR86 [SRC]
- Wikipedia, Subaru Impreza WRX STI (page covers VA and VB): https://en.wikipedia.org/wiki/Subaru_Impreza_WRX_STI [SRC]
- Wikipedia, Lamborghini Huracan: https://en.wikipedia.org/wiki/Lamborghini_Hurac%C3%A1n [SRC]
- Wikipedia, Koenigsegg Jesko: https://en.wikipedia.org/wiki/Koenigsegg_Jesko [SRC]
- Wikipedia, Land Rover Defender (L663): https://en.wikipedia.org/wiki/Land_Rover_Defender_(L663) [SRC]
- Wikipedia, Ford Transit: https://en.wikipedia.org/wiki/Ford_Transit [SRC]
- Wikipedia, Ford F-Series: https://en.wikipedia.org/wiki/Ford_F-Series [SRC]
- Wikipedia, Lancia Delta S4: https://en.wikipedia.org/wiki/Lancia_Delta_S4 [SRC]
- Wikipedia, Toyota Sprinter Trueno (AE86 generation): https://en.wikipedia.org/wiki/Toyota_Sprinter_Trueno [SRC]
- Wikipedia, List of automobile drag coefficients: https://en.wikipedia.org/wiki/List_of_automobile_drag_coefficients [SRC]
- Wikipedia, Rolling resistance (see section 2)
- Wikipedia, Automotive aerodynamics: https://en.wikipedia.org/wiki/Automotive_aerodynamics [SRC]. No Cd, frontal area or body-type numbers on the page; only mirror drag shares.
- Wikipedia, Weight transfer: https://en.wikipedia.org/wiki/Weight_transfer [SRC]

Failed or not usable in this pass: Mini F56 (Wikipedia page returned 404), Toyota Land Cruiser 300 (404), Nissan Skyline R34 (page too long; R34 section not reached in the first 100,000 characters), Ford Focus RS (page gave no mass, track or Cd), Mazda MX-5 NC/ND (no mass, track or Cd on page).

### 1.1 Summary by body type

Units: mass kg (kerb unless stated), wheelbase mm, track mm, frontal area m2, Cd, weight distribution front/rear. "NS" = not sourced.

| Body type | Kerb mass (kg) | Wheelbase (mm) | Track (mm) | Frontal area (m2) | Cd | Weight dist. F/R | Engine bay L x W x H (mm) |
|---|---|---|---|---|---|---|---|
| Kei car | 720 to 810 (Alto HA24, 2004-09) [SRC] | 2360 (HA24) [SRC] | NS | NS | NS (no kei Cd on any fetched page) | NS | NS |
| Hatchback | 1380 to 1390 (Civic Type R FK8) [SRC]; 1430 (FL5) [SRC] | 2700 (FK8), 2735 (FL5) [SRC] | NS | NS | 0.31 to 0.33 Civic hatch [SRC-1P]; 0.35 Mini Cooper 2008 [SRC] | NS | NS |
| Sedan | 1480 to 1595 (Subaru WRX VA, generation range, 4-door) [SRC] | 2650 (VA WRX) [SRC] | NS | NS | 0.34 Impreza WRX 4-door 2009 [SRC]; 0.33 Honda Accord 2002 [SRC-1P]; 0.27 Toyota Avalon 2018 [SRC-1P] | NS | NS |
| Wagon / estate | NS | NS | NS | NS | 0.34 Subaru Legacy wagon 1993-99 [SRC-1P]; 0.31 Saab 9-5 wagon 2003 [SRC-1P]; 0.30 Focus wagon 2000-04 [SRC-1P] | NS | NS |
| Coupe | 1190 to 1298 (Toyota 86 gen 1) [SRC]; 1270 to 1307 (GR86 gen 2) [SRC] | 2570 (gen 1), 2575 (gen 2) [SRC] | NS | NS | 0.27 (GR86 gen 1) [SRC]; 0.30 Lotus Elan+2 1967-74 [SRC] | 53/47 (GR86 gen 1) [SRC] | NS |
| Roadster | 940 (MX-5 NA, 1989 launch) [SRC]; 440 (Caterham Seven 170 R) [SRC] | NS (MX-5); NS (Caterham) | NS | NS | 0.38 Mazda Miata 1989 [SRC]; 0.65 to 0.75 Lotus Seven [SRC]; 0.7 Caterham Seven [SRC] | NS | NS |
| Hot hatch | 1380 to 1430 (Civic Type R FK8/FL5) [SRC] | 2700 / 2735 [SRC] | NS | NS | NS (no Type R Cd on page) | NS | NS |
| Muscle car | 1627 to 1697 (EcoBoost S650); 1736 to 1820 (GT); 1791 to 1811 (Dark Horse) [SRC] | 2720 [SRC] | NS | NS | 0.46 Mustang coupe 1979 [SRC-1P]; 0.44 fastback 1979 [SRC-1P] | NS | NS |
| SUV | 2228 to 2697 (Defender L663, range across variants) [SRC]; 2133 (Defender 90, 4-cyl diesel) [SRC] | 2587 (Defender 90) [SRC]; 3022 (110/130) [SRC] | NS | NS | 0.59 Defender 2008 [SRC]; 0.45 Range Rover Classic 1990 [SRC] | NS | NS |
| Pickup | NS | NS | NS | NS | 0.40 Ford Ranger 2011-15 [SRC]; 0.39 Toyota Tacoma N300 2016 [SRC]; 0.357 Ram 1500 Quad Cab 2018 [SRC] | NS | NS |
| Van | GVWR only: 3930 (T-150) to 4990 (T-350HD) [SRC]. Kerb NS. | 3300 / 3750 (van); 3505 / 3955 / 4520 (cab-chassis) [SRC] | NS | NS | 0.37 VW T4 Transporter 1990-2004 [SRC]; 0.35 Toyota Previa 1991-97 [SRC]; 0.39 Ford Aerostar 1995 [SRC]; 0.44 VW Vanagon 1980-91 [SRC] | NS | NS |
| Sports car | 1418 (GT3 manual) to 1640 (Turbo S coupe) [SRC]; Carrera 1505 [SRC] | 2450 (992) [SRC] | NS | NS | 0.31 Porsche 997 Turbo/GT3 2006 [SRC]; 0.32 Porsche 997 GT2 2008-13 [SRC] (not 992) | NS | NS |
| Supercar | 1553 with fluids (Huracan LP610-4); 1339 to 1542 dry range across Huracan line [SRC] | 2620 [SRC] | NS | NS | 0.39 Huracan (disclosed 2021) [SRC] | NS | NS |
| Hypercar | 1420 (Jesko Attack), 1390 (Jesko Absolut) [SRC]; 1996 est. (Chiron) [SRC] | 2700 (Jesko); 2711 (Chiron) [SRC] | NS | NS | 0.278 Jesko Absolut only [SRC] | NS | NS |
| Rally car | 890 to 1050 (Delta S4 rally, infobox "Weight"); 1200 (Stradale) [SRC] | 2440 (Delta S4) [SRC] | NS | NS | NS | NS | NS |
| Drag car | Top Fuel minimum: 2300 lb (incl. driver, Review Journal snippet) [UNVERIFIED]; 2320 lb (Competition Plus snippet) [UNVERIFIED]; 2390 lb (IHRA 2026 snippet) [UNVERIFIED] | 280 to 300 in (snippet) [UNVERIFIED] | NS | NS | NS | NS | NS |
| JDM tuner coupe | 855 to 1045 (AE86, generation range) [SRC]; RX-7 FD 1280 to 1310 [UNVERIFIED] | 2400 (AE86) [SRC] | NS | NS | RX-7 FD 0.31 [UNVERIFIED] | NS | NS |
| Classic | NS | NS | NS | NS | 0.48 VW Beetle 1938 [SRC]; 0.48 Rover Mini 1998 entry [SRC]; 0.45 Range Rover Classic 1990 [SRC] | NS | NS |
| Kit car | 440 (Seven 170 R) [SRC]; 545 (Seven, infobox overall) [SRC]; 612 (Ariel Atom, infobox) [SRC] | 2345 (Atom) [SRC] | NS | NS | 0.40 Ariel Atom [SRC]; 0.65 to 0.75 Lotus Seven [SRC]; 0.7 Caterham Seven [SRC] | NS | NS |

Notes on the table:
- Frontal area: no fetched page gave it for a current car. The first pass listed Curbside Classic CdA figures as snippets. Drag-area (CdA, m2) values seen this pass: Porsche 911 Speedster 1994 0.550 m2; Porsche 911 Carrera 1986 0.583 m2; Land Rover Discovery 1995 1.62 m2; Lotus Elise 1999 0.590 m2; Lotus Esprit 1990 0.595 m2 [SRC, Wikipedia List of automobile drag coefficients]. These are Cd x A, not frontal area, so do not use them as A.
- Track width: none of the fetched pages gave track for any car. Leave as NS.
- Engine-bay dimensions: none sourced in this pass. Leave as NS.
- Weight range for "Hot hatch", "SUV" and "Sports car" is the generation or variant spread from the source, not a single car.
- The Huracan dry mass range (1339 to 1542) is the spread across the model line, not one car.

### 1.2 Three example cars per body type, with what is sourced

Format: car (source tag): mass / Cd / frontal area. Missing values are marked NS. Frontal area is NS for every car in this section.

- **Kei:** Suzuki Alto HA24 [SRC]: 720 to 810 kg, wb 2360, L 3395, W 1475, H 1500 to 1510, 658 cc K6A I3, 54 PS. Cd NS. Other kei named but with no specs fetched: Daihatsu Copen, Honda Beat, Suzuki Cappuccino (gallery entries only) [SRC].
- **Hatchback:** Honda Civic Type R FK8 [SRC]: 1380 to 1390 kg, wb 2700. Cd NS. Mini Cooper 2008 [SRC list]: Cd 0.35, mass NS. Honda Civic hatch 1992-95 [SRC-1P]: Cd 0.31, mass NS.
- **Sedan:** Subaru WRX VA 4-door [SRC]: 1480 to 1595 kg (generation range), wb 2650. Cd 0.34 (Impreza WRX 4-door 2009, [SRC list]); cross-check on same car not available. Honda Accord 2002 [SRC-1P]: Cd 0.33.
- **Wagon:** Subaru Legacy wagon 1993-99 [SRC-1P]: Cd 0.34. Mass NS. Saab 9-5 wagon 2003 [SRC-1P]: Cd 0.31. Mass NS.
- **Coupe:** Toyota GR86 gen 1 [SRC]: 1190 to 1298 kg, wb 2570, Cd 0.27, weight 53/47 F/R. Frontal area NS.
- **Roadster:** Mazda MX-5 NA [SRC]: 940 kg (1989 launch), 1.6 L, 116 hp, 5MT. Cd: Mazda Miata 1989 [SRC list] 0.38 (year-specific, but the same body style as NA). Wheelbase NS.
- **Hot hatch:** Civic Type R FL5 [SRC]: 1430 kg, wb 2735, 2.0 L, 330 PS (Japan/EU). Cd NS.
- **Muscle car:** Ford Mustang GT S650 [SRC]: 1736 to 1820 kg, wb 2720, Coyote 5.0 480 hp. Cd: Mustang coupe 1979 0.46 [SRC-1P] (different generation, do not use as S650 Cd).
- **SUV:** Land Rover Defender 90 [SRC]: 2133 kg (4-cyl diesel), wb 2587. Cd: Defender 2008 0.59 [SRC list] (body generation L663 not stated on the list; treat as indicative).
- **Pickup:** No pickup with sourced mass. Cd only: Ford Ranger 2011-15 0.40, Toyota Tacoma N300 2016 0.39, Ram 1500 Quad Cab 2018 0.357 [SRC list]. Mass NS for all three.
- **Van:** Ford Transit 2014 gen [SRC]: GVWR 3930 to 4990 kg (not kerb), wb 3300 / 3750, L 5532 to 6759, W 2052 to 2126, H 2088 to 3051. Cd: VW Vanagon 0.44 [SRC list]; Toyota Previa 0.35 [SRC list]; VW T4 0.37 [SRC list].
- **Sports car:** Porsche 911 GT3 992.1 [SRC]: 1418 kg (manual), 1435 kg (PDK), 4.0 NA flat-6, 510 PS, wb 2450. Cd for GT3 (997 generation, not 992): 0.31 [SRC list]. Lotus Elise 1999: drag area 0.590 m2 [SRC list] (CdA, not frontal area).
- **Supercar:** Lamborghini Huracan LP610-4 [SRC]: 1553 kg with fluids, wb 2620, Cd 0.39, 5.2 NA V10, 610 hp, 7-speed DCT. Frontal area NS.
- **Hypercar:** Koenigsegg Jesko Absolut [SRC]: 1390 kg, wb 2700, Cd 0.278, 5.1 twin-turbo V8, 1280 hp petrol. Jesko Attack: 1420 kg. Bugatti Chiron [SRC]: 1996 kg (estimated), wb 2711, W16 8.0 quad-turbo, 1479 hp. Cd and frontal area NS for Chiron.
- **Rally car:** Lancia Delta S4 rally [SRC]: 890 to 1050 kg, wb 2440, 1.8 twincharged (supercharger + turbo), 490 PS, 5-speed (Hewland), AWD with 60 to 75 percent of torque to the rear. Cd NS. Frontal area NS.
- **Drag car:** Top Fuel only (see 1.1). No sourced Cd or frontal area for dragsters. Tyre friction for drag tyres is in section 2.
- **JDM tuner coupe:** Toyota AE86 [SRC]: 855 to 1045 kg (generation range), wb 2400, 4A-GE 1.6 DOHC 16v. Power and torque NS on the page. Mazda RX-7 FD [UNVERIFIED, snippet]: 1280 to 1310 kg; Cd 0.31; 5-speed ratios 3.483, 2.015, 1.391, 1.000, 0.719 (Japanese 1992 spec sheet, https://www.rx7.net.nz/jpnspc.htm); final drive 4.10 manual, 3.909 auto.
- **Classic:** VW Beetle 1938 [SRC list]: Cd 0.48. Mass NS. Rover Mini entry 1998 [SRC list]: Cd 0.48 (not the classic Mini Cooper; treat as the list's naming).
- **Kit car:** Caterham Seven 170 R [SRC]: 440 kg, 0.7 L Suzuki R06A turbo I3, 84 hp, Suzuki-sourced gearbox. Ariel Atom (variant unspecified) [SRC]: 612 kg, wb 2345, Cd 0.40, 6MT or 6-speed sequential.

### 1.3 Other body-type sources of interest

- Mass for all sedans, wagons, pickups, classic cars: NS in this pass. Candidate fetches: Toyota Camry, Volvo V90, Ford F-150 curb weight on the Ford F-Series page (page lacked it), Volkswagen Beetle, Mini F56 (404).
- Weight distribution: only one car in this pass (GR86 gen 1, 53/47 F/R [SRC]). Porsche 911 rear-engine bias is not sourced in this pass.
- Track width: no source fetched gave track. This is a gap for every body type.

---

## 2. Tyres

Source list for this section:
- Engineering ToolBox, Friction coefficients: https://www.engineeringtoolbox.com/friction-coefficients-d_778.html [SRC]
- HPWizard, Tire friction and rolling resistance (cites Wong 1993 and Bosch 1996, plus Tire Rack treadwear data, dates vary): https://hpwizard.com/tire-friction-coefficient.html [SRC]. Attribution quality: secondary, mixed.
- Wikipedia, Rolling resistance: https://en.wikipedia.org/wiki/Rolling_resistance [SRC]
- x-engineer, Tire model for longitudinal forces: https://x-engineer.org/automotive-engineering/chassis/vehicle-dynamics/tire-model-for-longitudinal-forces/ [SRC]
- openVD docs, Tire models (lateral Pacejka structure only): https://andresmendes.github.io/openvd/build/html/tire.html [SRC]
- Wikipedia, Magic formula: the URL https://en.wikipedia.org/wiki/Magic_formula is a disambiguation page, not the tyre model. No numbers. Not usable.
- Tire Rack category and treadwear text: not fetched successfully. Only retailer snippets (UNVERIFIED).

### 2.1 Friction coefficient (mu) on dry asphalt, by source

| Source | Surface / condition | Value | Status |
|---|---|---|---|
| Engineering ToolBox | Rubber / dry asphalt | 0.5 to 0.8 and 0.9 (column labels unclear) | [SRC] |
| Engineering ToolBox | Rubber / wet asphalt | 0.25 to 0.75 | [SRC] |
| Engineering ToolBox | Car tyre / asphalt, clean and dry | 0.72 | [SRC] |
| Engineering ToolBox | Car tyre / grass | 0.35 | [SRC] |
| HPWizard (Wong 1993 p.26) | Asphalt and concrete dry, peak / sliding | 0.80 to 0.90 / 0.75 | [SRC] |
| HPWizard (Wong 1993) | Asphalt wet, peak / sliding | 0.50 to 0.70 / 0.45 to 0.60 | [SRC] |
| HPWizard (Wong 1993) | Concrete wet, peak / sliding | 0.80 / 0.70 | [SRC] |
| HPWizard (Wong 1993) | Gravel, peak / sliding | 0.60 / 0.55 | [SRC] |
| HPWizard (Wong 1993) | Earth road dry, peak / sliding | 0.68 / 0.65 | [SRC] |
| HPWizard (Wong 1993) | Earth road wet, peak / sliding | 0.55 / 0.40 to 0.50 | [SRC] |
| HPWizard (Wong 1993) | Snow hard-packed, peak / sliding | 0.20 / 0.15 | [SRC] |
| HPWizard (Wong 1993) | Ice, peak / sliding | 0.10 / 0.07 | [SRC] |
| HPWizard (Wong 1993 p.28) | Truck tyre on concrete, dry (min / max / avg) | 0.715 / 0.850 / 0.756 | [SRC] |
| HPWizard (Bosch 1996 p.335) | Passenger tyre, new, dry, 50 / 90 / 130 km/h | 0.85 / 0.80 / 0.75 | [SRC] |
| HPWizard (Bosch 1996 p.335) | Passenger tyre, 1.6 mm tread, dry, 50 / 90 / 130 km/h | 1.00 / 0.95 / 0.90 (as printed; higher than new, check) | [SRC] |
| HPWizard (Bosch 1996 p.335) | New tyre, wet 0.2 mm water, 50 / 90 / 130 km/h | 0.65 / 0.60 / 0.55 | [SRC] |
| HPWizard (Bosch 1996 p.335) | New tyre, heavy rain 1 mm, 50 / 90 / 130 km/h | 0.55 / 0.30 / 0.20 | [SRC] |
| HPWizard | Column "racing tires" | up to 1.8 (column assignment unclear) | [SRC] (unclear) |
| HPWizard | Drag tyres (unnamed manufacturer, undated): base 3.00, peak up to 5.00, average used 4.00 | Low-confidence, attribution weak | [SRC] |

The hpwizard speed and tread table is the only fetched source with speed dependence. Use the new-tyre column for road tyres.

### 2.2 Friction by tyre class (game table)

Dry mu values for tyre classes come from the treadwear formula on hpwizard (µ = 2.25 / TW^0.15, dry asphalt, Tire Rack tests 2002 to 2010 per the page, ±10% band). Page exponent may be garbled, and the page's own table shows µ = 1.00 at TW 300 where the formula gives 0.96. Values below are computed from the formula [SRC] (computed) and are only valid for street tyres in the TW range of the source.

| Class | Dry mu | Status | Notes |
|---|---|---|---|
| All-season (TW ~400 to 500) | 0.89 to 0.92 (computed: TW 400 = 0.92, TW 500 = 0.89) | [SRC] (computed); generic road 0.8 to 0.9 [SRC] | Street only |
| Summer performance (TW ~200 to 300) | 0.96 to 1.02 (computed: TW 200 = 1.02, TW 300 = 0.96) | [SRC] (computed) | Street only |
| Ultra-high / max-performance summer (TW ~100) | 1.13 (computed, TW 100) | [SRC] (computed); page range does not cover this | Extrapolation |
| Semi-slick | NS (formula at TW 40 to 60 gives 1.22 to 1.29, beyond page range) | [UNVERIFIED] | Do not use formula outside range |
| Full slick | NS | [UNVERIFIED] | Searched; no measured source found |
| Drag radial | NS. ET Street R 275/60R15 specs (tiresize.com snippet): 28.2 in diameter, 11.1 in section width, 737 rev/mile, 30 lb; compound R2 (snippet) | [UNVERIFIED] | Street-legal, DOT |
| Drag slick | NS. Top Fuel rear slicks 18 in wide (Review Journal snippet) | [UNVERIFIED] | Hallum SAE 1994 (snippet): effective tyre friction factor for Top Fuel over 4; average friction coefficient below 2 |
| Winter (dry) | NS | [UNVERIFIED] | Snow and ice per Wong (above) |
| Winter (snow, hard-packed) | Peak 0.20, sliding 0.15 (generic snow, not winter-tyre specific) | [SRC] (generic) | UMTRI SWT-2016-10: winter stops about 35 percent shorter than all-season on packed snow (snippet, [UNVERIFIED]) |
| Off-road / rally gravel | Gravel peak 0.60, sliding 0.55 (generic, Wong) | [SRC] (generic); rally-specific NS | No rally-tyre source |

Speed dependence (from Bosch table, [SRC]): new tyre dry mu falls from 0.85 at 50 km/h to 0.80 at 90 km/h to 0.75 at 130 km/h. Use as a tuning slope, not as a hard number.

### 2.3 Rolling resistance coefficient (Crr)

| Surface / tyre | Crr | Source |
|---|---|---|
| New passenger tyres, general | 0.007 to 0.014 | Wikipedia Rolling resistance, Measurement section [SRC] |
| EU top label class, passenger tyres | 0.0065 (upper limit) | Wikipedia [SRC] |
| Car tyre on concrete | 0.010 to 0.015 (Wikipedia); 0.015 (Wong 1993, HPWizard); 0.013 (Bosch 1996, car on concrete/asphalt) | [SRC] |
| Car tyre on tarmacadam | 0.025 | HPWizard (Bosch 1996) [SRC] |
| Car tyre on rolled gravel | 0.02 | HPWizard (Bosch 1996) [SRC] |
| Car tyre on unpaved road | 0.05 | HPWizard (Bosch 1996) [SRC] |
| Car tyre on field | 0.10 to 0.35 | HPWizard (Bosch 1996) [SRC] |
| Car tyre on sand | 0.30 | Wikipedia; Wong 1993 [SRC] |
| Truck tyre on concrete/asphalt | 0.006 to 0.010 | HPWizard (Bosch 1996) [SRC] |
| Drag slick or drag radial | NS | [UNVERIFIED] |
| Semi-slick, full slick | NS | [UNVERIFIED] |

Speed, inflation and diameter effects on Crr exist only as graphs in HPWizard. No numbers.

### 2.4 Tyre sizes

- ET Street R 275/60R15: [UNVERIFIED] (tiresize.com snippet, https://tiresize.com/tires/Mickey-Thompson/ET-Street-R-275-60R15.htm).
- All other tyre sizes for all-season, summer, semi-slick, slick, winter, off-road and rally tyres: NS. The first pass gave "205/55 R16" and "275/35 R19" only as examples, not sourced.

### 2.5 Simplified Pacejka tyre model

Longitudinal Magic Formula, as used by x-engineer [SRC]:

Fx = D * sin( C * arctan( B*k - E*(B*k - arctan(B*k)) ) )

- k = longitudinal slip ratio (dimensionless).
- B = stiffness factor, C = shape factor, D = peak factor (peak friction = D, when Fz is normalised, so Fx = mu * Fz * f(k)), E = curvature factor.
- The page prints "Fz =" on the left side; that is a typo for Fx.

Coefficient sets [SRC], from x-engineer (a tutorial, Scilab example; not measured for a named tyre):

| Surface | B | C | D | E |
|---|---|---|---|---|
| Dry tarmac | 10 | 1.9 | 1.00 | 0.97 |
| Wet tarmac | 12 | 2.3 | 0.82 | 1.00 |
| Snow | 5 | 2 | 0.30 | 1.00 |
| Ice | 4 | 2 | 0.10 | 1.00 |

Load-dependent longitudinal set [SRC, same page, Pacejka reference]: Cx1 1.685, Dx1 1.21, Dx2 -0.037, Ex1 0.344, Ex2 0.095, Ex3 -0.02, Ex4 0, Kx1 21.51, Kx2 -0.163, Kx3 0.254, Hx1 -0.002, Hx2 0.002, Vx1 0, Vx2 0. No surface split for this set.

Hand-computed dry-tarmac curve from the set above [SRC] (computed, check with a script):

| k (slip ratio) | Fx / (mu*Fz) |
|---|---|
| 0.05 | 0.735 |
| 0.10 | 0.956 |
| 0.15 | 0.997 |
| 0.20 | 0.999 |

This shape gives peak friction near 15 to 20 percent slip on dry tarmac. A search snippet (UNVERIFIED) reported dry-road adhesion peak near 15 percent slip and wet near 11.5 percent (field and simulation study, arXiv/Springer snippet, not fetched).

Lateral Magic Formula [SRC, openVD]: structure only. Fy = D sin(C arctan(B alpha - E (B alpha - arctan(B alpha)))) with B, C, D, E as functions of load and camber (a0 to a13 coefficients). No numeric lateral coefficient set in this pass. Lateral set is NS.

Rule-of-thumb stiffness factors (UNVERIFIED, student project snippet): lateral B about 1.3, longitudinal B about 1.65, aligning moment B about 2.4.

Recommendation for the game: use the longitudinal set above for a slip-ratio curve, scale D by the class mu in section 2.2 (dry D = class mu), and scale for wet/snow by swapping the set. Mark lateral as UNVERIFIED placeholder until a real set is sourced.

---

## 3. Differentials, driveline and weight transfer

Source list for this section:
- Wikipedia, Torsen: https://en.wikipedia.org/wiki/Torsen [SRC]
- Wikipedia, Weight transfer: https://en.wikipedia.org/wiki/Weight_transfer [SRC]
- Wikipedia, Limited-slip differential (first pass, [SRC-1P])
- fueleconomy.gov, Where the energy goes: https://www.fueleconomy.gov/feg/atv.shtml [SRC]
- Quaife technical support (snippet): https://quaife.co.uk/customer-service/technical-support [UNVERIFIED]
- Subaru WRX VB drivetrain (Wikipedia Impreza WRX STI page, [SRC])

### 3.1 Differential types: bias and lock

| Type | Bias / lock figure | Status |
|---|---|---|
| Open | Torque split equal at both wheels; slipping wheel gets the most power (first pass Wikipedia) | [SRC-1P] (qualitative) |
| Torsen T-1 (crossed helical) | Bias can be designed higher than T-2; more backlash and noise. Page illustrates 3:1 TBR as one side 3/4 of torque, other 1/4. No other numbers. | [SRC] |
| Torsen T-2 (parallel gears) | Standard bias 2.5:1 (retailer listing, snippet, maximummotorsports/parts sites); range 2.5 to 3.5:1 (retailer, UNVERIFIED) | [UNVERIFIED] for numbers; type description [SRC] |
| Torsen T-2R (RaceMaster, preload clutch) | High-bias listed at 4:1 by one retailer, 3:1 by another (conflict) | [UNVERIFIED] |
| Torsen T-3 (planetary) | Nominal split not 50:50; no ratio on page | [SRC] (qualitative) |
| Quaife ATB (helical) | Manufacturer does not publish a bias ratio. Forum estimate: up to about 4:1; another forum post says up to 2:1. | [UNVERIFIED] |
| Clutch / plate LSD | Preload: Drexler adjustable LSD manual, 30 to 35 Nm at first assembly, falls to 25 to 30 Nm after use (snippet, [UNVERIFIED]). Some units set preload near zero. Lock %: NS (no standard metric). | [UNVERIFIED] |
| Clutch LSD slip torque (OEM examples) | BMW E36 M Coupe 30 to 50 Nm; BMW M3 50 to 70 Nm (service manual listing, snippet, [UNVERIFIED]) | [UNVERIFIED] |
| Viscous coupling | No numbers in pass 2 (first pass qualitative) | [SRC-1P] |
| Electronic / locker / spool | NS | [UNVERIFIED] |
| Subaru WRX VB manual centre diff | Viscous, 50:50 split. CVT version: planetary centre gear with variable torque split. | [SRC] |
| Subaru WRX STI VA centre diff | Not stated on page | NS |
| Lancia Delta S4 rally, centre diff | 60 to 75 percent of torque to rear (AWD) | [SRC] |
| Lancia Delta S4 Stradale, centre diff | 30 percent front (open) / 70 percent rear (LSD) | [SRC] |

### 3.2 Final-drive ratios (sourced points)

| Car | Final drive | Status |
|---|---|---|
| Ford Mustang S650, 10R80 automatic (EcoBoost, GT) | 3.15 standard, 3.55 with Performance Package | [SRC] |
| Ford Mustang S650, 10R80 (Dark Horse) | 3.55 | [SRC] |
| Ford Mustang S650, MT82-D4 manual (GT) | 3.55 standard, 3.73 Performance Package | [SRC] |
| Ford Mustang S650, TR-3160 manual (Dark Horse) | 3.73 | [SRC] |
| Toyota GR86 gen 1 (6MT) | 4.10 before MY2017, 4.30 from MY2017 | [SRC] |
| Mazda MX-5 ND manual | 2.866 to 2.87 | [SRC-1P] (first pass snippet) |
| Honda S2000 AP1/AP2 | 4.10 (torque-sensing LSD) | [SRC-1P] (snippet) |
| Mazda RX-7 FD manual | 4.10 | [UNVERIFIED] (snippet, supercars.net and rx7.net.nz agree) |
| Mazda RX-7 FD automatic | 3.909 | [UNVERIFIED] (rx7.net.nz snippet) |
| Tesla Model 3 single-speed | 9.03 (gearbox ratio) | [SRC-1P] |
| Land Rover Defender L663 | Transfer case low-range ratio NS | NS |
| Final drive by car type (general range) | NS. The examples above are the only sourced points. | [UNVERIFIED] for any general range |

### 3.3 Drivetrain losses by layout

| Layout | Loss | Status |
|---|---|---|
| All vehicles, share of fuel energy (not crank-to-wheel) | Drivetrain losses 4 to 5 percent (city), 3 to 5 percent (highway), 3 to 5 percent combined | [SRC] (fueleconomy.gov) |
| Automated manual, DCT, lock-up, CVT | Named as technologies that reduce drivetrain losses; no numbers | [SRC] (qualitative) |
| Manual RWD (rule of thumb) | 10 to 15 percent of crank power | [UNVERIFIED] (horsepowercalc-site snippet, rule-of-thumb article: https://horsepowercalc-site.pages.dev/how-much-horsepower-do-you-lose-through-the-drivetrain.html) |
| Automatic RWD (rule of thumb) | 15 to 20 percent | [UNVERIFIED] (same) |
| AWD (rule of thumb) | 20 percent or more; forum claims 20 to 50 percent | [UNVERIFIED] |
| Manual gearbox, high load (VW paper, snippet) | About 96 percent efficiency; automatic just below | [UNVERIFIED] (Scribd snippet) |
| FWD | NS | [UNVERIFIED] |
| DCT | NS (only fueleconomy.gov qualitative) | [UNVERIFIED] |
| CVT | NS (first pass: belt CVT about 88 percent, [SRC-1P]) | [SRC-1P] |

Caveat: fueleconomy.gov numbers are a share of total fuel energy in the drive cycle, not a power loss. They cannot be applied directly to a dyno-based crank-to-wheel loss.

### 3.4 Weight transfer

Longitudinal, from Wikipedia [SRC]: the page gives ΔW_front = (a * h * m) / b (text rendering garbled; reading as a*h*m/b). Variables: a = longitudinal acceleration, h = centre-of-mass height, m = total mass, b = wheelbase, g = gravity.

Lateral: the page does not give a formula. It says increasing track reduces lateral transfer. The standard textbook form ΔW_lat = (m * a_y * h) / t, with t = track and a_y = lateral acceleration, is not on the source page. Mark it [UNVERIFIED] (textbook, not fetched in this pass).

Roll-stiffness distribution: NS.

---

## 4. Drive modes, shifting, throttle, launch, limiters and anti-lag

Source list for this section:
- MegaSquirt MShift tuning page: https://www.msgpio.com/manuals/mshift/tuning.html [SRC]
- MegaSquirt MShift sub-page V41tune.html: linked, not retrieved (404 or not included). Not used.
- 7226ctrl (Mercedes 722.6 TCU, GitHub): https://github.com/mkovero/7226ctrl [SRC]
- Haltech, How launch control works: https://support.haltech.com/portal/en/kb/articles/how-launch-control-works [SRC]
- Aaron Cake, MS3X RX-7 programming page: https://aaroncake.net/rx-7/megasquirt/ProgramMS3X.asp [SRC] (single builder's settings, not a manual)
- Wikipedia, Rev limiter: https://en.wikipedia.org/wiki/Rev_limiter [SRC]
- Wikipedia, Anti-lag system: https://en.wikipedia.org/wiki/Anti-lag_system [SRC]
- Wikipedia, Traction control system: https://en.wikipedia.org/wiki/Traction_control_system [SRC] (no numbers on the page)
- Pedal Commander, Throttle mapping: https://pedalcommander.com/blogs/garage/throttle-mapping-algorithms-and-pedal-sensitivity [SRC] (vendor blog)
- Wikipedia, Dual-clutch transmission (shift times): first pass [SRC-1P]

### 4.1 Shift maps (throttle or load vs speed or rpm)

**MegaSquirt MShift [SRC]**
- The shift table is 16 speed bins by 9 load rows. Cells hold gear numbers.
- The table is indexed by vehicle speed and manifold load (kPa), not throttle position. The page says throttle is not an input. Load rows: the row whose bin is at or below the short-term average load (100 kPa row for 100 kPa or higher, 90 kPa row for 90.0 to 99.9, etc.).
- Speed bins listed: 12, 18, 26, 36, 48, ... 140 mph.
- Example at 100 kPa: upshift 1 to 2 at 36.0 mph, 2 to 3 at 66.0 mph, 3 to 4 at 110.0 mph. Downshifts 4 to 3 at 109.9, 3 to 2 at 65.9, 2 to 1 at 35.9. These downshift points sit one bin-width (0.1 mph) below the upshift points; they are not the 3 mph hysteresis discussed below.
- Example at 45 kPa: 26, 48, 66 mph.
- Cruise path example: 36, 54, 66 mph.
- Hysteresis example: "+3 mph or -3 mph"; recommended "2 to 3 mph". No load hysteresis value.
- Shift Pressure Adjustment Delay and Shift Completion Delay: adjust in steps of 50 to 100 ms. Max Shift Line Pressure: no value given. No torque-reduction value given.
- Redline example from the page: engine to 4400 rpm, 26-inch tyres, 3.08 axle, 3rd at 110 mph reaches 4400 rpm. Lower-load example: upshift at 2800 rpm in 3rd, or 70 mph.
- Turbo example: top load bin 120 to 130 kPa, boost to 200 kPa or more.
- Kick-down: cruise mode below 50 kPa, kick-down above 50 kPa (example).

**7226ctrl (Mercedes 722.6, open-source TCU) [SRC]**
- Automatic upshifts and downshifts based on vehicle speed and throttle position (README claim, "tested and works"). No numeric thresholds in the README.
- Shift and modulation pressure maps indexed by oil temperature and load.
- Staged boost limiting during a pre-shift.
- Torque converter lock: 100 percent lock in 5th gear above 80 km/h at low load (the README's stated default).

**Porsche PDK, Sport and Sport Plus (forum only) [UNVERIFIED]**
- Rennlist posts (search results, not individually matched to threads): 991.1 Sport Plus holds to redline even at part throttle (non-GT3, with Sport Chrono). 991.2 Sport Plus can shift near 4000 rpm at casual throttle and to redline at full throttle.
- One post: about 7200 rpm upshift at full throttle in Sport and Sport+ on a GTS. Another: 7800 rpm upshift and 3000 rpm downshift as the only limits in Sport Plus auto.
- Cobb Tuning PDK map notes (aftermarket, not stock) raise min/max shift points in Sport and Sport Plus.
- No Porsche owner's manual or technical source fetched.

**Other manufacturer mode tables**: NS. No BMW, Mercedes, Ford, Toyota or Lamborghini mode shift table fetched.

### 4.2 Throttle pedal map

- Pedal Commander [SRC]: "the first 30% of pedal travel might only need 15% of the available torque" (illustrative, not a calibration). The last 20% of travel gives a disproportionately large torque rise (no number).
- Mode curve shapes (search snippets, UNVERIFIED): Sport throttle opening rises more per unit pedal travel (curve bends upward), Eco has a smaller increase, Normal is downward-convex. No exponents or percentages.
- Pedal-to-throttle exponent per mode: NS. The first-pass placeholder exponents (Comfort 1.5 to 2.0, Eco 2.0 to 2.5, Sport 1.0 to 1.2) remain [UNVERIFIED].
- Eco mode is not always lower peak power. Some Eco calibrations only reduce pedal sensitivity (snippet). Mode names are not standardised across makes (snippet, [UNVERIFIED]).

### 4.3 Shift time

- Ferrari F430 Scuderia sequential 60 ms; Enzo 150 ms [SRC-1P] (Wikipedia DCT).
- ZF 8HP shift time 0.2 s (vs predecessor) [SRC-1P].
- Lexus LC 500 torque-converter auto 120 ms (Wikipedia shift-time table, flagged as needing citations) [SRC-1P].
- Per-mode shift time: NS.

### 4.4 Traction control

- Wikipedia TCS page: no slip target, no slip threshold, no torque-reduction percentage, no response time [SRC].
- Optimal slip ratio: a field and simulation study snippet puts dry-road peak adhesion near 15 percent slip and wet near 11.5 percent [UNVERIFIED].
- Per-mode traction thresholds: NS.

### 4.5 Launch control

**Haltech, How launch control works [SRC]**
- Aux RPM limiter: a secondary limit active when clutch or brake pedal pressed or trans brake on. Example: normal limiter 9000 rpm drops to 5000 rpm for launch. Fuel, ignition or both can be cut, in hard, soft or cut-off styles.
- Launch RPM limit: mapped on a 3D table, example inputs throttle position and boost. Example: higher launch rpm at 50 percent throttle and low boost builds exhaust flow and boost; full throttle then drops rpm to the mapped launch value.
- Ignition retard (turbo with clutch): "massively retard the ignition timing." Examples go to -20 degrees or more (ATDC direction per the article). This spools the turbo.
- Torque converter launch (automatic): hold trans or foot brake, open throttle fully; ignition retard reduces power, so add timing if the target rpm and manifold pressure are not reached.
- Not specified: coolant threshold, manifold pressure, throttle thresholds, boost target, fuel amount, wheel speed, launch time.

**Other launch references (snippets, UNVERIFIED)**
- HP Tuners: launch control activates only when engine rpm is at or above the threshold when Launch Control Map Select is 3.
- Haltech Elite: temporary RPM limiter applied while the launch input is active; launch switch wired to ECU.

**MS3 (MegaSquirt) launch parameters**: NS (manual section heading only).

### 4.6 Rev limiter styles

**Wikipedia Rev limiter [SRC]**
- Fuel-cut: most common in road cars; reduces exhaust-component wear. Injectors shut off, leans out the engine. Only practical option on diesels.
- Ignition-cut (spark cut): fuel still injected, so unburned fuel reaches the exhaust and can wear the catalytic converter. Less common in production cars.
- Throttle control (drive-by-wire): described as "by far the safest method."
- Hard-cut: fuel or spark completely cut at the set rpm. The engine "bounces" off the limit (hysteresis). Racing applications want very short hysteresis.
- Soft-cut: partial fuel cut and possibly ignition retard before the limit, then holds rpm. If overrun continues, shuts cylinders off one by one.
- Soft limiter (separate): lower rpm limit when the car is not in gear.
- Numbers: F1 engines up to 15,000 rpm under F1 rules; manufacturer redlines range up to 12,000 rpm. No time or percentage values on the page.

**MS3 builder example (aaroncake, single build, [SRC])**
- Hard spark cut 8500 rpm, hard fuel cut 9000 rpm, fuel return 200 rpm below (about 8800 rpm). Spark cut removes every spark (1 from 1); softer option cuts 3 of 5 cylinders. Hysteresis disabled.
- Builder notes that S5 engines are redlined at 9000 rpm. These are a single build's choices.

### 4.7 Anti-lag and pops

**Wikipedia Anti-lag system [SRC]**
- Mechanism: retard ignition and add extra fuel (sometimes air). Excess mixture leaves through the exhaust valves, burns in the hot manifold, and spins the turbo.
- Throttle bypass: ignition at 35 to 45 degrees ATDC. Late ignition keeps pressure and temperature high at exhaust-valve opening with little torque. Slight fuel enrichment for cooling.
- Bypass: a solenoid slightly opens the throttle 12 to 20 degrees. (The page does not describe throttle closure.)
- Auto-deactivation when coolant reaches 110 to 115 degrees C.
- Intake bypass: air fed to the exhaust manifold to reignite partially burned gases.
- ECU ignition retard and fuel dump at launch rpm: "quite a few degrees" and "significantly more fuel", no values. Active only at wide-open throttle.
- Haltech (Launch Anti-Lag): ignition retard to -20 degrees or more; no exhaust air injection (contrast with rally anti-lag).
- Pops and bangs at lift-off: NS in this pass beyond the above mechanics.

### 4.8 Items with no sourced number (all remain placeholders)

- Upshift and downshift rpm by mode and throttle percentage: NS (only MShift load-based examples and Porsche forum anecdotes).
- Throttle exponent by mode: NS.
- Torque limit by mode and on shift: NS.
- Traction-control slip target and torque-cut percentage: NS.
- Exhaust-valve or pops threshold by mode: NS.
- Suspension damping by mode: NS.

First-pass placeholders (carried forward as [UNVERIFIED], game tuning only):
- Comfort: throttle exponent 1.5 to 2.0, upshift 85 to 90 percent of redline, downshift 60 to 70 percent.
- Eco: throttle exponent 2.0 to 2.5, upshift 60 to 70 percent of redline.
- Sport: throttle exponent 1.0 to 1.2, upshift 95 percent of redline, downshift 75 to 85 percent.
- Sport+ / Track: throttle exponent 1.0, upshift 97 to 99 percent of redline.
- Launch: 4500 to 6500 rpm on the boost limit (partly consistent with Haltech example 5000 rpm aux limit, but not the same parameter).
- Snow: first-gear start, traction limit 40 to 60 percent of Sport torque.

---

## 5. Car and engine pairings (reference list, 48 entries)

Format: car (variant, years) | engine (layout, displacement) | gearbox | power | kerb mass | source tag. "NS" = not sourced in this pass.

1. Mazda MX-5 NA (1989-97) | 1.6 L I4 | 5MT (4AT option) | 116 hp | 940 kg (at launch) | [SRC]
2. Mazda MX-5 NB (1998-2005) | 1.8 L I4 | 6MT option | 142 hp (106 kW, 2001 VVT) | NS | [SRC]
3. Mazda MX-5 NB Mazdaspeed (2004-05) | 1.8 L turbo I4 | 6MT | 178 hp (133 kW) | NS | [SRC]
4. Mazda MX-5 ND (2015-) | 2.0 L SKYACTIV-G (displacement per sidebar code P5-VPS/PE-VPS; text does not state) | 6MT, dual-mass flywheel from 2019 | 181 hp (135 kW) from 2019 | under 1100 kg (overall figure) | [SRC] for power and gearbox; mass is an overall figure
5. Toyota 86 / GR86 gen 1 (2012-21) | 2.0 L flat-4 FA20 | TL70 6MT | 200 PS | 1190 to 1298 kg | [SRC]
6. Subaru BRZ gen 1 (2012-21) | 2.0 L flat-4 FA20 | 6MT | 200 PS (same engine as 86) | 1190 to 1270 kg | [SRC]
7. Toyota GR86 gen 2 (2021-) | 2.4 L flat-4 FA24D | TL70 6MT | 231 to 235 PS | 1270 to 1307 kg | [SRC]
8. Toyota AE86 Sprinter Trueno (1983-87) | 1.6 L I4 4A-GE, DOHC 16v | 5MT (K50 or T50) or 4AT | NS | 855 to 1045 kg (generation range) | [SRC] (power NS)
9. Porsche 911 Carrera (992.1) | 3.0 L twin-turbo flat-6 | 8PDK | 385 PS | 1505 kg | [SRC]
10. Porsche 911 Carrera S (992.1) | 3.0 L twin-turbo flat-6 | 7MT or 8PDK | 450 PS | 1480 (MT) / 1515 (PDK) kg | [SRC]
11. Porsche 911 Carrera 4S (992.1) | 3.0 L twin-turbo flat-6 | 7MT or 8PDK | 450 PS | 1530 (MT) / 1565 (PDK) kg | [SRC]
12. Porsche 911 GT3 (992.1) | 4.0 L NA flat-6 | 6MT or 7PDK | 510 PS @ 8400 rpm | 1418 (MT) / 1435 (PDK) kg | [SRC]
13. Porsche 911 Turbo S (992.1) | 3.7 L twin-turbo flat-6 | NS | 650 PS | 1640 kg (coupe) | [SRC]
14. Ford Mustang GT (S650, 2024-) | 5.0 L Coyote V8 (5037 cc) | 10R80 auto or MT82-D4 6MT | 480 hp | 1736 to 1820 kg | [SRC]
15. Ford Mustang Dark Horse (S650) | 5.0 L Coyote V8 | 10R80 auto or TR-3160 6MT | 500 hp | 1791 to 1811 kg | [SRC]
16. Ford Mustang EcoBoost (S650) | EcoBoost (displacement NS in page snippet) | 10R80 auto | NS | 1627 to 1697 kg | [SRC] (engine NS)
17. Ford F-150 (14th gen, 2021-) | 5.0 L Coyote V8 | 10-speed (per Ford F-Series page: all engines on 10-speed) | 400 hp (2023 Tremor, 410 lb-ft) | NS | [SRC]
18. Ford F-150 Tremor (2021) | 3.5 L EcoBoost V6 twin-turbo | 10-speed | 400 hp, 500 lb-ft | NS | [SRC]
19. Ford Transit (2014 gen, 2020 update) | 3.5 L EcoBoost V6 twin-turbo | 10R80 | 310 hp | GVWR 3930 to 4990 kg (not kerb) | [SRC]
20. Ford Transit E-Transit | Electric motor | Single-speed | 266 hp (198 kW) | NS | [SRC]
21. Subaru WRX STI VA (export, 2015-21) | 2.5 L EJ257 flat-4 turbo | 6MT TY85, AWD | 305 hp (227 kW) | 1480 to 1595 kg (VA WRX range) | [SRC]
22. Subaru WRX VA (Japan) | 2.0 L EJ207 flat-4 turbo | 6MT TY85, AWD | 300 to 304 hp (page inconsistent) | 1480 to 1595 kg (VA range) | [SRC]
23. Subaru WRX VB (2022-) | 2.4 L FA24F flat-4 turbo | 6MT or CVT, AWD | 271 hp (NA market) | 1510 to 1600 kg | [SRC]
24. Land Rover Defender 90 P300 | 2.0 L petrol I4 | ZF 8-speed auto, permanent 4WD | 300 PS | NS | [SRC]
25. Land Rover Defender 110 P400 MHEV | 3.0 L petrol I6 MHEV | ZF 8-speed | 400 PS | 2228 to 2697 kg (range, all variants) | [SRC]
26. Land Rover Defender 110 P525 | 5.0 L petrol V8 | ZF 8-speed | 525 PS | NS | [SRC]
27. Land Rover Defender 90 D200 | 2.0 L diesel I4 | ZF 8-speed | 200 PS | 2133 kg (diesel 4-cyl, 90) | [SRC]
28. Lamborghini Huracan LP610-4 | 5.2 L NA V10 (90 degree) | 7-speed LDF DCT | 610 hp (449 kW) | 1553 kg with fluids | [SRC]
29. Lamborghini Huracan LP580-2 | 5.2 L NA V10 | 7-speed LDF DCT | 572 hp (427 kW) | NS | [SRC]
30. Lamborghini Huracan LP640-4 Performante | 5.2 L NA V10 | 7-speed LDF DCT | 631 hp (471 kW) | NS | [SRC]
31. Bugatti Chiron | 8.0 L W16 quad-turbo | 7-speed Ricardo DCT | 1479 hp (1103 kW) | 1996 kg (estimated) | [SRC]
32. Bugatti Chiron Super Sport 300+ | 8.0 L W16 quad-turbo | 7-speed Ricardo DCT | 1578 hp | NS | [SRC]
33. Koenigsegg Jesko Absolut | 5.1 L (5065 cc) twin-turbo V8 | 9-speed multi-clutch (page text says 10, infobox and ratio table say 9) | 1280 hp petrol / 1600 hp E85 | 1390 kg (dry 1290) | [SRC]
34. Koenigsegg Jesko Attack | Same | Same | Same | 1420 kg (dry 1320) | [SRC]
35. Lancia Delta S4 rally (Group B) | 1.8 L (1759 cc) twincharged I4 (Volumex supercharger + KKK turbo), mid-mounted | 5MT, Hewland | 490 PS (500 PS claimed) | 890 to 1050 kg (infobox "Weight") | [SRC]
36. Lancia Delta S4 Stradale | 1.8 L supercharged + turbo I4, mid-mounted | 5MT, CIMA | 250 PS at 6750 rpm | 1200 kg | [SRC]
37. Caterham Seven 170 R | 0.7 L turbo I3 Suzuki R06A | Suzuki-sourced (speeds NS) | 84 hp | 440 kg | [SRC]
38. Caterham Seven 620 | 2.0 L supercharged Ford Duratec I4 | 6-speed sequential | 310 hp | NS (Seven overall 545 kg) | [SRC]
39. Caterham Seven 420 Cup | 2.0 L Ford Duratec I4 | 6-speed sequential (Sadev) | NS | NS | [SRC]
40. Lotus Seven Superlight R500 | 2.0 L Ford Duratec I4 | Sequential optional | 263 bhp | NS | [SRC]
41. Lotus CSR260 (Superlight version) | 2.3 L Ford Duratec I4 (page also says 2.0 L in one section) | NS | 260 bhp | 550 kg | [SRC]
42. Ariel Atom 500 | 3.0 L Ariel H1 (Hartley) V8 | 6-speed sequential or manual | 500 bhp | 612 kg (Atom mass, variant NS) | [SRC]
43. Ariel Atom (K20Z4 variant) | 2.0 L Honda K20Z4 i-VTEC I4 | 6MT or 6 sequential | 245 bhp NA / 310 bhp supercharged | 612 kg (variant NS) | [SRC]
44. Ariel Atom 3.5R | 2.0 L K20C1 turbo (or other per page) | 6MT or 6 sequential | 350 bhp (3.5R) | NS | [SRC]
45. Honda Civic Type R FK8 (2017-) | 2.0 L turbo I4 (1996 cc) | 6MT | 310 PS (Japan/EU 320 PS) | 1380 to 1390 kg | [SRC]
46. Honda Civic Type R FL5 (2023-) | 2.0 L turbo I4 | 6MT | 330 PS (Japan/EU) | 1430 kg | [SRC]
47. Mazda RX-7 FD (1992-02), twin-turbo | Rotary (engine code and displacement NS in this pass) | 5MT (3.483, 2.015, 1.391, 1.000, 0.719; final 4.10) | 255 to 276 hp (autoevolution snippet) | 1280 to 1310 kg (snippet range) | [UNVERIFIED]
48. Suzuki Alto HA24 (2004-09) | 658 cc inline-3 K6A | 5MT or 3/4AT | 54 PS | 720 to 810 kg | [SRC]

Entry 47 is UNVERIFIED (snippet sources). The other 47 entries carry SRC tags for their sourced cells; cells marked NS were not found. Total: 48 entries.

Known discrepancies for the game team to decide:
- Jesko gearbox: 9 vs 10 speeds (page conflicts with itself).
- Chiron mass is an estimate.
- Lancia Delta S4 rally "weight" is not labelled kerb.
- CSR260 engine displacement conflicts (2.0 vs 2.3 L) within the Caterham/Lotus page.
- Subaru WRX VA power: 300 hp vs 304 hp on the same engine (page inconsistent).

---

## 6. What remains [UNVERIFIED] or NS

By area:
- Body types: frontal area (all types), track (all types), engine-bay dimensions (all types), kei Cd, pickup mass, sedan mass, wagon mass, van kerb mass, classic mass, drag-car Cd and frontal area, JDM tuner mass (except AE86), hatch mass (except Civic Type R), Porsche 911 992 Cd, Huracan frontal area, hypercar track and frontal area.
- Tyres: class mu for semi-slick, full slick, drag radial, drag slick, winter (dry), rally gravel; tyre sizes for all classes except the ET Street R snippet; lateral Pacejka coefficients; Crr for slicks.
- Diffs: numeric Torsen T-2 bias (2.5:1 is snippet only), Quaife bias (no official figure), clutch LSD lock percentage, clutch LSD preload (snippet only), electronic and locker types, viscous coupling numbers, general final-drive ranges by car type, FWD/DCT/auto drivetrain loss (only rule-of-thumb snippets).
- Drive modes: per-mode shift rpm and throttle percentage (Porsche forum only, UNVERIFIED), throttle exponent per mode (placeholders from first pass), per-mode shift time, per-mode torque limit, TC slip target, pops threshold, suspension.
- Launch: rpm thresholds for launch engagement in production cars (HP Tuners snippet only).
- Anti-lag: numeric retard at launch (not in Wikipedia; only Haltech -20 degrees).
- Weight transfer lateral formula (textbook, not on fetched page).

Checked and not found in this pass (so do not look again without a new target):
- Wikipedia Magic formula URL: disambiguation only.
- Wikipedia Automotive aerodynamics: no Cd or frontal area for cars.
- Wikipedia Traction control system: no numbers.
- Wikipedia Torsen: only one bias illustration.
- Wikipedia Rev limiter: no time or percentage values.
- Ford Focus RS, Mini F56, Toyota Land Cruiser 300, Nissan Skyline R34: pages did not give the requested specs (404 or not reached).
- Engineering ToolBox page: no ice/snow tyre rows; snow rows are ski wax.

## 7. Sources (fetched this pass unless noted)

- https://en.wikipedia.org/wiki/Rolling_resistance
- https://en.wikipedia.org/wiki/Torsen
- https://en.wikipedia.org/wiki/Weight_transfer
- https://en.wikipedia.org/wiki/Rev_limiter
- https://en.wikipedia.org/wiki/Anti-lag_system
- https://en.wikipedia.org/wiki/Traction_control_system
- https://en.wikipedia.org/wiki/Automotive_aerodynamics
- https://en.wikipedia.org/wiki/List_of_automobile_drag_coefficients
- https://en.wikipedia.org/wiki/Kei_car
- https://en.wikipedia.org/wiki/Suzuki_Alto
- https://en.wikipedia.org/wiki/Honda_Civic_Type_R
- https://en.wikipedia.org/wiki/Mazda_MX-5
- https://en.wikipedia.org/wiki/Porsche_911_(992)
- https://en.wikipedia.org/wiki/Bugatti_Chiron
- https://en.wikipedia.org/wiki/Caterham_Seven
- https://en.wikipedia.org/wiki/Ariel_Atom
- https://en.wikipedia.org/wiki/Ford_Mustang_(seventh_generation)
- https://en.wikipedia.org/wiki/Toyota_GR86
- https://en.wikipedia.org/wiki/Subaru_Impreza_WRX_STI
- https://en.wikipedia.org/wiki/Lamborghini_Hurac%C3%A1n
- https://en.wikipedia.org/wiki/Koenigsegg_Jesko
- https://en.wikipedia.org/wiki/Land_Rover_Defender_(L663)
- https://en.wikipedia.org/wiki/Ford_Transit
- https://en.wikipedia.org/wiki/Ford_F-Series
- https://en.wikipedia.org/wiki/Lancia_Delta_S4
- https://en.wikipedia.org/wiki/Toyota_Sprinter_Trueno
- https://x-engineer.org/automotive-engineering/chassis/vehicle-dynamics/tire-model-for-longitudinal-forces/
- https://andresmendes.github.io/openvd/build/html/tire.html
- https://hpwizard.com/tire-friction-coefficient.html
- https://www.engineeringtoolbox.com/friction-coefficients-d_778.html
- https://www.fueleconomy.gov/feg/atv.shtml
- https://www.msgpio.com/manuals/mshift/tuning.html
- https://github.com/mkovero/7226ctrl
- https://support.haltech.com/portal/en/kb/articles/how-launch-control-works
- https://aaroncake.net/rx-7/megasquirt/ProgramMS3X.asp
- https://pedalcommander.com/blogs/garage/throttle-mapping-algorithms-and-pedal-sensitivity

Search snippets only, not fetched (all tagged [UNVERIFIED]):
- https://tiresize.com/tires/Mickey-Thompson/ET-Street-R-275-60R15.htm
- https://www.reviewjournal.com/?p=663350 (Top Fuel spec sheet)
- https://competitionplus.com/?p=1993 (Top Fuel 2,320 lb)
- https://ihra.com/sites/default/files/2026-01/2026%20IHRA%20Top%20Fuel_0.pdf (IHRA 2,390 lb)
- https://saemobilus.sae.org/papers/magic-drag-tire-942484 (Hallum SAE 1994 abstract)
- https://www.rx7.net.nz/jpnspc.htm, https://www.supercars.net/blog/1993→1995-mazda-rx-7-jm1fd/, https://www.autoevolution.com/engine/mazda-rx-7-fd-1992-26-rotary-tt-255-hp.html, https://rushmagazine.co.uk/rush-radars/mazda-rx-7-fd, https://www.auto-data.net/en/mazda-rx-7-iii-fd-wankel-twin-turbo-239hp-11127
- https://horsepowercalc-site.pages.dev/how-much-horsepower-do-you-lose-through-the-drivetrain.html (rule-of-thumb drivetrain losses)
- https://quaife.co.uk/customer-service/technical-support (Quaife does not publish bias ratio)
- https://www.tapatalk.com/groups/dsrforum/quaife-bias-t6466.html (Quaife bias forum estimate)
- https://www.maximummotorsports.com/Torsen-T2R-torque-bias-differential-High-Bias-Ford-88-differential-P881.aspx (Torsen T-2R listing)
- https://autotech.com/pdf/183884 and https://manuals.autorepairshq.com/BMW/1999/M%20Coupe%20%28E36%2F7%29%20L6-3152cc%203.2L%20DOHC%20%28S52%29/Repair%20and%20Diagnosis/Transmission%20and%20Drivetrain/Differential%20Assembly/Specifications/Mechanical%20Specifications/Technical%20Specifications (clutch LSD preload and BMW slip torque, snippets)
- https://rennlist.com/forums/991/899365-driving-in-sport-plus.html and other Rennlist threads from the same search (Porsche PDK shift points)
- https://www.scribd.com/document/543604037/Management-Termic (VW manual vs automatic efficiency, snippet)
- https://arxiv.org/pdf/cond-mat/0502495 and https://rd.springer.com/content/pdf/10.1007/s11249-020-1273-5.pdf (friction snippets, not used for numbers)
