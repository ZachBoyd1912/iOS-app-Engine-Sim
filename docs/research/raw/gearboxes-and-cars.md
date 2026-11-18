# Gearboxes, drivetrain, tyres, aero and drive modes: raw research

Research date: 2026-11-18. Status: PARTIAL first pass. Many categories have real ratio data; several have none yet (see section 10).

Conventions:
- Ratios are overall gearbox ratios (input:output) unless marked. Final drive is the axle/diff ratio.
- `[SRC]` = figure from a page that was fetched in full or in a large part.
- `[SNIP]` = figure seen only in a search-result snippet, not fetched. Lower confidence.
- `[UNVERIFIED]` = no source found. Placeholder for game tuning only, do not present as data.
- Trademarked names are listed in section 4, with generic names proposed.

---

## 0. Coverage at a glance

| Area | Sourced ratio sets | Notes |
|---|---|---|
| Torque-converter auto, 8-speed (ZF 8HP family) | 11 variants, full ratio tables | Best dataset in this file |
| Torque-converter auto, 10-speed | 1 (Ford 10R80, 2 sources) | No final drive |
| Torque-converter auto, 2 to 10 speed history | Speed count and model names only | No ratios |
| Manual, 5-speed / 6-speed | 1 (Mazda MX-5 ND 6MT) + Honda S2000 6MT (AP1/AP2) | Dogleg, close-ratio, 4/5/7 speed missing |
| DCT (7-speed Porsche PDK/Taycan context) | Partial 991.1/991.2 1st gear and some upper gears | Forum-grade for most |
| Single-speed EV | Tesla Model 3 9.03:1 (owner manual) | Model S figure conflicts |
| 2-speed EV | Porsche Taycan partial (front 8.05:1, rear 2nd ~8:1, 1st ~16:1 unconfirmed) | |
| Motorcycle 6-speed | Yamaha YZF-R6 2006 full 6-speed + primary | Sequential 5-speed, CBR600RR missing |
| Heavy-duty truck | Eaton Fuller RTLO-18913 13-speed partial (snippet); Mack mDRIVE 1st 14.94 snippet | 5/6/10-speed missing |
| CVT | No ratio ranges; efficiency and torque qualitative only | |
| Differentials | Types described; no bias ratios sourced | |
| Tyres | Generic mu values (secondary); winter vs summer stopping distances | No per-tyre table |
| Drag Cd | Wikipedia list, ~100 production cars by body type | No frontal area for most |
| Kerb weight | None sourced | |
| Drive modes | Qualitative only; Porsche Sport Plus described | No rpm thresholds sourced |

---

## 1. Source list (URLs used)

Fetched in full or large part:
- RevLab Engine Simulator App Store listing: https://apps.apple.com/app/id6817417979
- Wikipedia, Dual-clutch transmission: https://en.wikipedia.org/wiki/Dual-clutch_transmission
- Wikipedia, Automatic transmission: https://en.wikipedia.org/wiki/Automatic_transmission
- Wikipedia, ZF 8HP: https://en.wikipedia.org/wiki/ZF_8HP
- Wikipedia, Limited-slip differential: https://en.wikipedia.org/wiki/Limited-slip_differential
- Wikipedia, Continuously variable transmission: https://en.wikipedia.org/wiki/Continuously_variable_transmission
- Wikipedia, List of automobile drag coefficients: https://en.wikipedia.org/wiki/List_of_automobile_drag_coefficients
- Wikipedia, Drag coefficient (aircraft table only, no cars): https://en.wikipedia.org/wiki/Drag_coefficient

Search results used (snippet or partly read):
- FCP Euro, ZF 8HP45 guide: https://www.fcpeuro.com/blog/zf-8-speed-transmission-guide-8hp45-specs-common-problems-diagnostics-maintenance [SNIP]
- Honda News, 2002 S2000 specs: https://hondanews.com/en-US/releases/release-ac6c52b46473ca4f83631d004c34c7ed-2002-honda-s2000-specifications [SNIP]
- Honda News, 2006 S2000 specs: https://hondanews.com/en-US/releases/release-5a35f67b82f245d1db31c6004c34c121-2006-honda-s2000-specifications [SNIP]
- s2000.club AP1 specs: https://www.s2000.club/ap1specs.html [SNIP]
- s2000.club AP2 specs: https://www.s2000.club/ap2v2specs.html [SNIP]
- Moss Miata, 2016 ND specs: https://mossmiata.com/miata-mx5-2016-nd [SNIP]
- Autotrader first drive, 2016 MX-5: https://www.autotrader.ca/editorial/expert-reviews/mazda/mx-5/first-drive-2016-mazda-mx-5/ [SNIP]
- Racer, five things about the 2016 Miata: https://racer.com/2015/09/02/five-things-racers-need-to-know-about-the-2016-mazda-miata [SNIP]
- Porsche 2012 911 (991) spec sheet PDF: https://newsroom.porsche.com:443/dam/jcr:6918184a-6bbe-44f3-bf4e-3f8a331dbd46/2012_911_991_Specs.pdf.PDF [SNIP, table garbled]
- Stuttcars, 991.2 Carrera 4 Cabriolet 2016: https://www.stuttcars.com/porsche-911-carrera-4-cabriolet-991-2-2016-specifications-performance/ [SNIP]
- Rennlist, gear ratios for 7-speed PDK: https://rennlist.com/forums/991-gt3-gt3rs-and-911r/746068-gear-ratios-for-7-speed-pdk.html [SNIP, forum]
- Porsche media kit, Taycan powertrain: https://media.porsche.com/mediakit/taycan/en/porsche-taycan/der-antrieb [SNIP]
- Excellence Magazine, Taycan tech: https://excellence-mag.com/issues/269/articles/all-electric-taycan-tech [SNIP]
- Ranger Station, Ford 10R80 tech library: https://therangerstation.com/tech_library/ford_10r80_10-speed_automatic_transmission.shtml [SNIP]
- F150Hub, Ford 10R80: https://www.f150hub.com/trans/10r80.html [SNIP]
- Tesla Model 3 owner's manual (transmission table): https://www.tesla.com/ownersmanual/model3/en_ie/GUID-E414862C-CFA1-4A0B-9548-BE21C32CAA58.html [SNIP]
- Flowracers, Tesla transmissions: https://flowracers.com/blog/tesla-transmission/ [SNIP, cites 9.73 for Model S]
- InsideEVs, Model 3/Y drive units: https://insideevs.com/news/518692/tesla-model-3y-drive-units/ [SNIP]
- Total Motorcycle, 2006 Yamaha YZF-R6: https://www.totalmotorcycle.com/photos/2006models/2006models-Yamaha-YZF-R6.htm [SNIP]
- Eaton, Fuller 10-speed FR series brochure: https://www.eaton.com/content/dam/eaton/products/transmissions/vehicle-transmissions/fr-series-manual/fr-series-10-speed-brochure-trsl0261-en-us.pdf [SNIP, no ratios]
- Global Transmission Supply, Eaton Fuller 13-speed ratios: https://www.globaltransmissionsupply.com/13-speed-eaton-fuller-transmission/13-speed-transmission-ratios [SNIP, partial]
- Mack, mDRIVE HD: https://www.macktrucks.com.au/powertrain-and-suspensions/transmissions/mdrive-hd-and-xhd/ [SNIP]
- Speedhunters, DCT vs auto shift times: https://www.speedhunters.com/?p=379543 [SNIP]
- University of Michigan Transportation Research Institute, winter tyres (SWT-2016-10): https://public.websites.umich.edu/~umtriswt/PDF/SWT-2016-10.pdf [SNIP]
- Tyre friction table (attribution unclear in results, treat as unverified): https://hpwizard.com/tire-friction-coefficient.html [SNIP]
- Haynes, aerodynamics and fuel economy: https://haynes.com/en-us/tips-tutorials/aerodynamics-and-how-they-affect-fuel-economy [SNIP]
- Cars-data, drag coefficient glossary: https://cars-data.com/en/car-glossary/drag-coefficient-cd [SNIP]
- Curbside Classic, drag area: https://curbsideclassic.com/automotive-histories/automotive-aerodynamics-drag-area-size-matters [SNIP]
- BMW Blog, driving modes (2025): https://www.bmwblog.com/2025/08/12/bmw-driving-modes-comfort-sport-eco-pro-efficient-personal/ [SNIP]
- EVKX, EV drive modes: https://evkx.net/technology/drivemodes/ [SNIP]
- Mitsubishi Motors Canada, drive modes explained: https://www.mitsubishi-motors.ca/en/milife/automotive-drive-modes-explained [SNIP]
- Porsche West Palm Beach, driving modes blog: https://westpalmbeach.porsche.com/en/blog/porsche-driving-modes [SNIP]
- Rennlist, Sport vs Sport Plus shifting: https://rennlist.com/forums/991/1068961-sport-vs-sport-plus-shifting-when-floored.html [SNIP, forum]
- Cobb Tuning, PDK map notes: https://cobbtuning.atlassian.net/wiki/spaces/PRS/pages/259555410/PDK+Map+Notes+-+991.1+Turbo+991.1+Carrera+981+Boxster+981+Cayman [SNIP, aftermarket]

---

## 2. RevLab Engine Simulator (App Store id6817417979) [SRC]

Developer Vibalyze OU, version 1.6 (Oct 22 per listing).

Gearboxes and shifters, quoted from listing:
- Manual: "6- and 5-speed manual"
- Dual-clutch: "7-speed DCT with 3D paddles"
- Automatic: "8-speed automatic"
- Sequential: "6- to 8-speed sequentials"
- Shifter: "3D gated shifter"; "H-pattern shifter" (1.6 notes)
- Auto clutch modes: "OFF, LAUNCH, SHIFT or GUARD"

Drive modes: "COMFORT, ECO and SPORT drive modes on a 3D dash button". Sport+ is NOT listed.

Drivetrain: none named (no FWD/RWD/AWD). Only layout mentioned: "a four-motor electric research car".

Engine and car features: two- and four-rotor rotary; quad-turbo W16 ("turbos take turns"); 1.6 V6 turbo hybrid; 5.5 crossplane V8 hybrid; crossplane and flatplane V8; flat-four; V-twin; nine-cylinder radial; open-wheel race chassis; endurance prototype; launch control; shift lights; "Christmas tree"; READY start and regen paddles; boost and EGT gauges; "STROBE" freeze (timing-light style).

Gap for the game: the listing gives feature names, not numbers. Ratios for the listed boxes must come from other sources (sections 3 to 6).

---

## 3. Transmission types

### 3.1 Manual, 4/5/6/7-speed, close-ratio, dogleg racing

Sourced:

**Mazda MX-5 ND (SKYACTIV-MT, 6-speed) [SNIP, consistent across Moss Miata, TrueCar, Auto123]**
| Gear | Ratio |
|---|---|
| 1 | 5.087 |
| 2 | 2.991 |
| 3 | 2.035 |
| 4 | 1.594 |
| 5 | 1.286 |
| 6 | 1.000 (direct) |
| Reverse | 4.696 |
| Final drive | 2.866 (often 2.87) |

Notes: 6th is direct (1:1). Final drive changed from 4.10 (NC) to 2.867 to allow 1:1 in 6th [SNIP, Autotrader]. Automatic ND final drive 3.454 [SNIP, Racer]. Aftermarket 4.44 ring-and-pinion exists [SNIP, supplier page not fetched]; do not treat 4.44 as stock.

**Honda S2000 (6-speed, AP1 2000-2003) [SNIP, Honda News 2002 chart]**
| Gear | Ratio |
|---|---|
| 1 | 3.133 |
| 2 | 2.045 |
| 3 | 1.481 |
| 4 | 1.161 |
| 5 | 0.971 |
| 6 | 0.811 |
| Reverse | 2.800 |
| Primary reduction | 1.160 |
| Final drive | 4.10 (torque-sensing LSD) |

**Honda S2000 (AP2, 2004+) [SNIP, Honda News 2006 chart and forum comparison]**
- Gears 1 to 4 unchanged vs AP1.
- 5th: 0.942 (Honda) or 0.943 (forum). 6th: 0.763 (Honda) or 0.765 (forum).
- Final drive 4.10 both generations.
- Primary reduction 1.208 (forum only, [UNVERIFIED] against service manual). AP1 primary 1.160.

**Porsche and Mazda rest of 5/6 manuals:** not yet sourced.

Gap: no sourced 4-speed, 5-speed generic, close-ratio racing (e.g. Hewland-style), or dogleg (e.g. Ferrari/Lotus style) ratio sets yet. Candidate next queries: Hewland FT200 ratio table; Honda Civic Type R FK8 6MT; Toyota GR86 6MT; BMW M3 E46 6MT; Lotus Elise S2 5MT.

Real-world examples to add (required 3 per type): currently 2 for 6-speed (MX-5 ND, S2000), 0 for 4/5/7.

### 3.2 H-pattern vs sequential dog box (5/6/7-speed)

Not yet sourced for ratios or shift times.

Qualitative (from the RevLab listing): the app offers "6- to 8-speed sequentials" and "H-pattern shifter" as separate options, which matches the common split between H-pattern synchronised manuals and dog-engagement sequentials.

Dog-engagement shift time figure seen in search (no source link validated): Ferrari F430 Scuderia sequential 60 ms; Enzo 150 ms [SNIP, cited to Wikipedia DSG article; not verified in the fetched text].

### 3.3 Torque-converter automatics (4/5/6/7/8/9/10-speed)

**Speed-count history [SRC, Wikipedia Automatic transmission]**
- 2-speed: Buick Dynaflow (1948), Packard Ultramatic (1949), Chevrolet Powerglide (1950), Chrysler PowerFlite (1953).
- 3-speed: BorgWarner series (AMC, Ford, Studebaker, early 1950s); Chrysler TorqueFlite (1956); GM Turbo Hydramatic (1964).
- 4-speed: no model named on the page; "increasingly common" in the 1980s.
- 5-speed: Jatco 5R01 (1989, Nissan Cedric and Gloria). Converter type not stated.
- 6-speed: ZF 6HP26 (2002, BMW 7 Series E65).
- 7-speed: Mercedes-Benz 7G-Tronic (year after ZF 6HP26).
- 8-speed: Toyota AA80E (2007).
- 9-speed: ZF 9HP (2013).
- 10-speed: Toyota Direct Shift-10A (2017, Lexus LC).
- Excluded from the page: 1940 GM Hydra-Matic and 1956 Controlled Coupling Hydra-Matic (fluid couplings, not converters).

**ZF 8HP family, full nominal ratio tables [SRC, Wikipedia ZF 8HP "Key data"]**

| Variant | Year | Rev | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | Span | Max input torque (as printed) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 8HP 70 (pilot) | 2008 | 3.297 | 4.696 | 3.130 | 2.104 | 1.667 | 1.285 | 1.000 | 0.839 | 0.667 | 7.043 | 700 Nm |
| 8HP 30/I, 8HP 45 | 2010 | 3.295 | 4.714 | 3.143 | 2.106 | 1.667 | 1.285 | 1.000 | 0.839 | 0.667 | 7.071 | 300 / 450 Nm |
| 8HP 55, 70, 65, 90 | 2010 | 3.317 | 4.714 | 3.143 | 2.106 | 1.667 | 1.285 | 1.000 | 0.839 | 0.667 | 7.071 | 650 / 700 / 900 Nm (see note) |
| 8HP 75/I | 2014 | 3.317 | 4.714 | 3.143 | 2.106 | 1.667 | 1.285 | 1.000 | 0.839 | 0.667 | 7.071 | 740 Nm |
| 8HP 30/II, 8HP 50 | 2014 | 3.456 | 5.000 | 3.200 | 2.143 | 1.720 | 1.314 | 1.000 | 0.822 | 0.640 | 7.813 | 300 / 500 Nm |
| 8HP 75/II, 8HP 95 | 2014 | 3.478 | 5.000 | 3.200 | 2.143 | 1.720 | 1.313 | 1.000 | 0.823 | 0.640 | 7.813 | 740 / 900 Nm |
| 8HP 76/I | 2018 | 3.478 | 5.000 | 3.200 | 2.143 | 1.720 | 1.313 | 1.000 | 0.823 | 0.640 | 7.813 | 760 Nm |
| 8HP 30/III, 8HP 51 | 2018 | 3.712 | 5.250 | 3.360 | 2.172 | 1.720 | 1.316 | 1.000 | 0.822 | 0.640 | 8.203 | 300 / 500 Nm |
| 8HP 76/II | 2018 | 3.993 | 5.500 | 3.520 | 2.200 | 1.720 | 1.317 | 1.000 | 0.823 | 0.640 | 8.594 | 760 Nm |
| 8HP 100 | 2022 | 3.968 | 5.000 | 3.200 | 2.143 | 1.720 | 1.297 | 1.000 | 0.833 | 0.640 | 7.813 | 1,000 Nm |
| 8HP 80 | 2022 | 4.544 | 5.500 | 3.520 | 2.200 | 1.720 | 1.301 | 1.000 | 0.833 | 0.640 | 8.594 | 800 Nm |
| 8AP 600/800/1000/1200 T (commercial) | 2017 | 4.250 | 4.889 | 3.123 | 2.033 | 1.639 | 1.254 | 1.000 | 0.840 | 0.639 | 7.652 | 600-1,200 Nm |
| 8AP 1200 S (commercial) | 2017 | 3.757 | 4.889 | 3.123 | 2.033 | 1.639 | 1.268 | 1.000 | 0.830 | 0.639 | 7.652 | 1,200 Nm |

Notes:
- The ZF 8HP page does not state a final drive per variant. Final drive must come from the car (e.g. BMW, Jaguar, Dodge).
- The page's 8HP 55/70 and 8HP 65/90 torque figures conflict with its own application list (8HP 65 listed at 650 Nm, 8HP 70 at 700 Nm). Use with care.
- Shift time: page says "shift times have reduced to 0.2 seconds" versus predecessor. No per-variant figure.
- Pilot 8HP 70 weight: 87 kg.
- Models (partial): 8HP 45 in BMW 1/3/5 series, X1/X3/X5, Z4, Jaguar XE/XF/XJ, Range Rover L405. 8HP 55 in Audi A4/A5/A6/A7 (B8.5/C7). 8HP 65 in Audi A4 B9, A6 C8, Q7, Q8, Porsche Cayenne (2018+), VW Touareg (2018+). 8HP 70 in BMW 7 Series (pilot), 3/4/5 series, X5 50i, Jaguar F-Type, Dodge Challenger/Charger/Durango, Jeep Grand Cherokee WK2.
- FCP Euro independently lists the 8HP45 forward ratios to two decimals and gives reverse as 3.30 [SNIP], which differs from the Wikipedia 3.295 by rounding only.

**Ford 10R80 (10-speed, Ford-GM family) [SNIP, Ranger Station and F150Hub agree]**
| Gear | Ratio |
|---|---|
| 1 | 4.696 |
| 2 | 2.985 |
| 3 | 2.146 |
| 4 | 1.769 |
| 5 | 1.520 |
| 6 | 1.275 |
| 7 | 1.000 |
| 8 | 0.854 |
| 9 | 0.689 |
| 10 | 0.636 |
| Reverse | 4.866 (F150Hub rounds to 4.86) |
Spread first to tenth: 7.384.
Final drive: NOT confirmed. One 2020 Mustang reference shows 3.55 [SNIP]. The 3.73 figure is unsourced.

**Toyota AA80E (8-speed, 2007) and Toyota Direct Shift-10A (10-speed, 2017): speed and model only, no ratios sourced.**

Gap: 4/5/6/7-speed torque converter ratio sets, 9-speed ZF 9HP ratios, 10-speed Toyota ratios, GM 10L80 ratios (at least 3 real examples are missing for 9 and 10).

### 3.4 Dual-clutch transmissions, 6/7/8-speed, wet and dry

**Design and wet/dry [SRC, Wikipedia DCT]**
- Wet: oil-bathed, higher torque capacity. Example cited: Bugatti Veyron engine 1,250 Nm.
- Dry: VW DQ200 (7-speed, from 2008). Hyundai Transys makes dry 7-speed and wet 8-speed.
- Wet: VW DQ250 (6-speed, concentric).
- Not stated on page: Getrag 7DCL750, Tremec, ZF/Porsche PDK, Ricardo.
- Getrag 7DCL750 rated 750 Nm (from 2008; used in 2009 Ferrari 458, 2014 Mercedes-AMG GT, 2017 Ford GT).
- Layouts: concentric (most cars, outer clutch larger), stacked on one axis (Tremec TR-9070, Fortschritt ZT 320 tractor), side-by-side (VW DQ200).
- Tremec: Chevrolet Corvette C8 (8-speed, 2020); Ford Shelby GT500 (TR-9070, 7-speed, 2020).
- Ricardo: Bugatti Veyron (7-speed, 2005-2015).
- Mitsubishi Fuso Duonic: first DCT in a truck (2010), 6-speed.
- Honda: motorcycle DCT first on VFR1200F (2009); Acura TLX (2015) uses an 8-speed DCT with a torque converter.
- Koenigsegg Jesko: one clutch per gear, classed as multi-clutch rather than DCT.

**Porsche 991.1 Carrera PDK (7-speed) [SNIP, Porsche 2012 spec PDF, table garbled]**
- 1st: 3.91 (manual and PDK, per spec sheet).
- Remaining gears and final drive not readable.

**Porsche 991.2 Carrera 4 Cabriolet (AWD, 7-speed PDK) [SNIP, Stuttcars 2016]**
- 1st 3.91, 2nd 2.29, 3rd 1.58, 4th 1.18, 5th 0.94 (both manual and PDK, per listing). 7th 0.62 (2018 listing). Total rear axle ratio 3.09 (2018 listing). Front axle 3.46. These are AWD cabriolet figures, not RWD Carrera.

**991.1 GT3 PDK [SNIP, Rennlist thread, forum-grade]**
- 1st 3.75, 2nd 2.38, 3rd 1.72, 4th 1.34, 5th 1.11, 6th 0.96, 7th 0.84; final drive 3.97. Treat as unverified.

**Porsche Taycan 2-speed rear (see 3.7).**

Shift times (see 6).

Gap: 6-speed wet DCT ratio sets (VW DQ250, Getrag), 8-speed DCT ratio sets (Tremec, Hyundai), Hyundai dry 7-speed ratios.

### 3.5 CVT

**Types [SRC, Wikipedia CVT]**
- Belt/pulley: most common. Steel V-belt between variable pulleys. Steel-reinforced belt for low torque; chain for high torque.
- Chain: steel bands with stacked elements on conical pulleys. PIV variant can transmit significant torque but has lower maximum speed.
- Toroidal: discs and rollers; "can generally withstand higher torque loads than a pulley-based CVT". Example: Nissan Cedric (Y34).
- Subaru "Lineartronic" (marketing term; no design detail on page).
- Nissan "Xtronic": Nissan moved from toroidal to pulley CVTs in 2003.

**Efficiency [SRC]**
- Belt-driven: approximately 88 percent (stated as lower than a manual).
- Hydrostatic: up to 90 percent in many cases; few exceed about 65 percent.
- Magnetic CVT: claimed 3 to 5 percent fuel reduction vs mechanical (in development).

**Ratio range:** NOT sourced. The page gives only GR = Dm / Dp for hydrostatic units. Gap.

**Torque capacity:** NOT sourced numerically. Gap.

Real-world CVT examples: none with ratio tables yet (Subaru Lineartronic, Nissan Xtronic, Honda CVT-7 candidates to search).

### 3.6 Single-speed EV reduction

**Tesla Model 3 [SNIP, owner's manual]**
- Transmission: single-speed fixed gear. Gearbox ratio 9.03:1.
- Axle ratios per spec site: 9.0 (AWD Performance), 9.03 (RWD), 9.04 (2021 LR AWD).
- Teardown calculation from gear teeth: (81/31) x (83/24) = 9.0363 [SNIP, InsideEVs].

**Tesla Model S: 9.73:1 [SNIP, Flowracers]**. Conflicts with Model 3 figures and is not confirmed by an official source. Treat as unverified for Model S.

Gap: other single-speed EV reductions (e.g. Hyundai Ioniq 5, BMW i4, Porsche Taycan front). Taycan front 8.05:1 is in section 3.7.

### 3.7 Two-speed EV

**Porsche Taycan (rear 2-speed) [SNIP, Porsche media kit, Excellence]**
- Front axle: single-speed reduction 8.05:1 (Excellence Magazine).
- Rear 2nd gear: about 8:1 (Porsche media kit; "the same as the front axle").
- Rear 1st gear: about 16:1 (Excellence only; [UNVERIFIED]).
- Construction: two spur gear stages, three shafts. Max torque 550 Nm and max speed 16,000 rpm per Porsche technical material [SNIP].
- Mechanism (Excellence): first gear via dog clutch locking a planetary carrier to drive from the sun gear.
- Final drive per gear for rear axle not separately sourced.

Gap: Other 2-speed EVs (e.g. Audi e-tron GT is single-speed; search for Hyundai/Kia or Lotus 2-speed variants).

### 3.8 Motorcycle sequential 5-speed and 6-speed

**Yamaha YZF-R6 2006 (6-speed) [SNIP, Total Motorcycle]**
| Gear | Teeth | Ratio |
|---|---|---|
| 1 | 31/12 | 2.583 |
| 2 | 32/16 | 2.000 |
| 3 | 30/18 | 1.667 |
| 4 | 26/18 | 1.444 |
| 5 | 27/21 | 1.286 |
| 6 | 23/20 | 1.150 |
- Primary reduction 85/41 = 2.0731.
- Secondary reduction: 44/16 = 2.750 (one listing) or 45/16 = 2.813 (another). Conflict.
- Older R6 (1999-2005): primary 1.954 (other source says 1.954 for 1999-2005 and 2.073 for 2006).
- Example final drive per gear (1st on 44/16) roughly 14.7:1, my arithmetic.

Gap: 5-speed sequential (e.g. Ducati, older 600s), CBR600RR (search returned none).

### 3.9 Rotary and diesel typical boxes

Not sourced. The RevLab listing includes rotary engines (two- and four-rotor) but gives no gearbox ratios. Gap: Mazda RX-7 FD 5-speed and RX-8 6-speed ratios; diesel boxes (e.g. Mercedes 722.6 5-speed).

### 3.10 Heavy-duty truck 5/6/10-speed

**Eaton Fuller RTLO-18913 13-speed [SNIP, unclear source, low confidence]**
- 8th high 0.73, 7th high 1.00, low 12.31, reverse-high 3.50, reverse-low 13.22, overall ratio 16.9:1.
- Note: 1.00 is 7th here, not top gear.

**Eaton Fuller FR-series 10-speed [SNIP, Eaton brochure]**
- Model names: FR-9210B, FR-14210B, FR/FRM/FRW-15210B, FRO-16210B. No ratio figures in the retrieved text.

**Mack mDRIVE HD first gear 14.94 [SNIP]**. Automated, not a manual Eaton Fuller. Used as a reference only.

Gap: 5-speed and 6-speed truck boxes (e.g. Eaton Fuller 5-speed, Allison 6-speed), 10-speed full table (Global Transmission Supply page not fully read).

### 3.11 Generic-name game versions (proposal)

See section 4.

---

## 4. Trademarked names to generic game names

| Trademarked name (note) | Real type | Proposed generic name |
|---|---|---|
| VW/Audi DSG, S-tronic, Alfa TCT, Tata DCA | Wet or dry DCT | "Twin-clutch DCT (wet 6-speed)" / "Twin-clutch DCT (dry 7-speed)" |
| Porsche PDK | DCT, 7-speed | "Twin-clutch DCT (7-speed)" |
| Getrag 7DCL750 | DCT 7-speed wet | "Twin-clutch DCT (7-speed, 750 Nm)" |
| ZF 8HP (BMW Steptronic 8-speed) | Torque-converter auto 8-speed | "Torque-converter auto (8-speed, planetary)" |
| Mercedes 7G-Tronic | TC auto 7-speed | "Torque-converter auto (7-speed)" |
| ZF 9HP | TC auto 9-speed | "Torque-converter auto (9-speed)" |
| Toyota Direct Shift-10A | TC auto 10-speed | "Torque-converter auto (10-speed)" |
| Ford 10R80 / GM 10L80 | TC auto 10-speed | "Torque-converter auto (10-speed, heavy-duty)" |
| Tiptronic (Porsche/VW/Audi) | Auto with manual gate | "Auto with manual mode (paddles)" |
| SMG (BMW Sequential Manual Gearbox) | Automated manual, single clutch | "Automated single-clutch manual" |
| Steptronic (BMW) | Auto with manual gate | "Auto with manual mode (gate)" |
| Lineartronic (Subaru) | CVT | "CVT (belt)" |
| Xtronic (Nissan) | CVT | "CVT (belt)" |
| Duonic (Mitsubishi Fuso) | DCT truck 6-speed | "Twin-clutch DCT (truck, 6-speed)" |
| mDRIVE (Mack) | Automated truck | "Automated truck gearbox (10-speed)" |
| Fuller / Eaton Fuller | Manual truck | "Truck manual (13-speed)" |
| Hydra-Matic (GM) | Early TC auto | "Torque-converter auto (historical 4-speed)" |
| Powerglide (Chevrolet) | 2-speed TC auto | "Torque-converter auto (2-speed)" |
| Direct Shift Gearbox (DSG) | Same as VW DSG | see above |
| Rotary (Mazda) | Engine type, not gearbox | not a gearbox name |

Caveat: the proposal above is by design. Ratios from section 3 should be attributed to the source car, not the generic name, so the game can ship "generic" labels with real data.

---

## 5. Differentials and driveline [SRC, Wikipedia LSD unless noted]

**Types (qualitative)**
- Open: torque equal at both wheels. Slipping wheel receives most power. Illustrative: right tyre spins at 70 Nm on ice (not a rated value).
- Clutch or plate LSD (torque-sensitive): clutch stacks or cones; spring preload gives small static coupling; ramp geometry defines 2-way, 1-way, or 1.5-way. No lock figure on page.
- Torsen (geared, torque-sensing): worm and spur gears; friction against housing creates limiting torque. T-2R adds clutch pack for preload. No bias ratio on page.
- Helical gear LSD: torque-sensitive, engagement force rises with input torque. No numbers.
- Viscous coupling: silicone fluid with perforated discs; speed-sensitive; proportional to slip; can "hump" when hot; fails toward open; usually not serviceable; the page says a visco unit at 60,000 miles or more often behaves like an open diff.
- Locker and spool: named, not described.
- One-way ramp angle 80-85 degrees in practice (page).

**Numeric bias ratios and lock percentages: NOT SOURCED.** Gap.

**Final drive ratios (known points)**
- Honda S2000 AP1/AP2: 4.10 with torque-sensing LSD [SNIP].
- Mazda MX-5 ND manual: 2.866 (2.87). Automatic: 3.454 [SNIP].
- Porsche 991.2 Carrera 4 Cabriolet (AWD): front 3.46; total rear 3.09 (2018 listing) [SNIP].
- Porsche 991.1 GT3: 3.97 [SNIP, unverified].
- Ford 10R80 mating final drive: unsourced (see 3.3).
- Tesla Model 3 single-speed: 9.03:1 [SNIP].

Range target 2.5 to 5.5 in the brief: the MX-5 ND (2.87) and Honda S2000 (4.10) fall inside; 3.97-4.44 aftermarket examples are in range too.

---

## 6. Dual-clutch and torque-converter shift times

**[SRC, Wikipedia DCT]**
- Ferrari F430 Scuderia sequential: 60 ms.
- Enzo sequential: 150 ms.
- Wikipedia's shift-time table lists the Lexus LC 500 (torque-converter auto) at 120 ms and is marked as needing citations [SNIP].

**[SNIP, Speedhunters and Wikipedia-derived]**
- VW/Audi DSG upshift: headline 8 ms is likely gear engagement, not full shift. Full DSG/PDK upshift closer to 200 ms.
- Other DCTs (Ferrari, BMW, Lamborghini): 80 to 250 ms.
- ZF 8-speed TC auto: as quick as 200 ms (no pre-select).
- Conventional TC automatics: "several hundred milliseconds".
- Manual gearbox (fast human): 500 ms to 2 s.

**[SRC, ZF 8HP page]** "shift times have reduced to 0.2 seconds" vs predecessor.

Game-ready summary (sourced ranges only):
- DCT: about 100 to 200 ms (full shift, unverified single-source estimate).
- Modern TC auto: about 120 to 300 ms.
- Manual: 500 to 2000 ms (human-dependent).

---

## 7. Tyres

**Grip coefficients [SNIP, secondary sources, mostly unverified]**
- Dry asphalt: about 0.9 (one table), 0.80 to 0.90 (another, with educated-guess caveats).
- Wet asphalt: about 0.6 (one table), 0.50 to 0.70 (another).
- Dry ice or snow: about 0.2. Wet ice: about 0.1.
- Speed effect (one table): new tyre dry asphalt 0.90 at 0 km/h, 0.85 at 50 km/h, 0.80 at 90 km/h, 0.75 at 130 km/h.

**Winter vs all-season vs summer [SNIP, UMTRI SWT-2016-10]**
- On packed snow: winter tyres stop about 35 percent shorter than all-season and about 50 percent shorter than summer.
- Winter tyres give better traction below 7 degrees C even without snow or ice.
- Summer tyres are not for near-freezing or snow and ice [SNIP, SAE abstract].

**Tyre types needed by the game but not sourced:** road, sport, semi-slick, slick, drag radial, all-season, winter. Per-type mu not sourced except the qualitative winter/summer comparison above.

**Tyre sizes:** not yet searched (e.g. 205/55 R16 style for hatch; 275/35 R19 for sport). Gap.

Placeholder (UNVERIFIED, for tuning only):
- Road / all-season: mu 0.80 to 0.90 dry.
- Sport: mu 0.95 to 1.10 dry.
- Semi-slick: mu 1.10 to 1.30 dry.
- Slick: mu 1.20 to 1.40 dry.
- Drag radial: mu around 1.0 to 1.3 on launch surface (launch-specific).
- Winter: mu 0.6 to 0.8 dry, 0.2 to 0.3 snow.

---

## 8. Aero and kerb weight by body type

**Drag coefficient (Cd) [SRC, Wikipedia List of automobile drag coefficients, first 100,000 chars]**

Sedan:
- Lincoln Town Car (1985-1989) 0.46; Mercury Grand Marquis (1988-1991) 0.45; Volvo 740 (1982) 0.41; Mitsubishi Magna V3000 (1985-1991) 0.36; Volvo 940 (1990) 0.35; Alfa Romeo Giulia (1968-1972) 0.34; Chevrolet Caprice (1991-1996) 0.33; Honda Accord (2002) 0.33; Toyota Camry (1991) 0.33; Honda Civic Sedan EX (1996-2000) 0.32; Honda Civic Sedan (2006) 0.31; Ford Focus sedan (2000-2004) 0.31; Toyota Avalon (2005) 0.291; Mazda3 sedan (2009) 0.29; Lexus LS 400 (1990) 0.29; Toyota Avalon XX50 (2018) 0.27; Mazda3 (2012) 0.26; Nissan Altima 6th gen (2018) 0.26; Lexus LS430 (2001-2006) 0.25 (air suspension) / 0.26.

Coupe / fastback:
- Ford Mustang coupe (1979) 0.46; Mustang fastback (1979) 0.44; Honda Accord coupe (2002) 0.32; Honda Accord coupe (2003, 2005-2007) 0.29; Honda Civic coupe (1992-1995) 0.32; Mercedes C-Class Sportcoupe (2001) 0.29; Mercedes C-Class coupe (2015-2018) 0.26; Nissan 200SX (1995-1998) 0.33; Nissan 240SX (1995-1998) 0.32; Infiniti G37 coupe (2008-2015) 0.31; Corvette C6 coupe (2005-2013) 0.286; Porsche 997 GT2 (2008-2013) 0.32; McLaren F1 (1992) 0.32; Honda NSX (1990) 0.32.

Hatchback / liftback:
- Ford Escort 5-door (1981-1984) 0.39; Honda Civic hatch (1988-1991) 0.33; Civic hatch (1992-1995) 0.31; Civic hatch DX (1996-2000) 0.32; Mazda2 hatch (2010-2014) 0.31; Mazda3 hatch (2010-2013) 0.31; Ford Focus Mk III hatch (2011) 0.295; Toyota Yaris (2006-2011) 0.29; Opel Astra K hatch (2015) 0.285; Ford Focus Mk IV hatch (2018) 0.273; Toyota Corolla hatch E210 US (2019) 0.32, Europe 0.30; Skoda Scala (2019) 0.29; Skoda Octavia Mk IV liftback (2020) 0.249; Toyota Celica liftback (1982) 0.342.

Wagon / estate:
- Subaru Legacy wagon (1993-1999) 0.34; Toyota Corolla wagon (1993-1997) 0.34; Saab 9-5 wagon (2003) 0.31; Ford Focus wagon (2000-2004) 0.30.

Convertible / roadster:
- VW Cabriolet / Rabbit convertible (1979-1993) 0.48; Smart Roadster (2003) 0.41; Smart Roadster Coupe (2003) 0.38; Toyota Celica convertible (1994-1999) 0.36; BMW M3 convertible (2005) 0.35; Mercedes SL roof down (2001) 0.34; Lotus Seven (1957-1972) 0.65 to 0.75 [SRC, body type not stated in table, listed among mixed].

Body type not stated in table (use by inference, confirm before labelling):
- Land Rover Defender (2008) 0.59; Hummer H2 (2003) 0.57; Mercedes G-Class 0.54; VW Westfalia camper (1980-1991) 0.51; Jeep Wrangler JL (2018) 0.454; Range Rover Classic (1990) 0.45; Dodge Viper RT/10 (1996) 0.45; Ford Ranger (2011-2015) 0.40; Ariel Atom (2002) 0.40; Chevrolet Tahoe (2006) 0.39; Dodge Durango (2004) 0.39; Toyota Tacoma N300 (2016) 0.39; Lexus GX (2003) 0.38; Lexus RX (2003-2009) 0.35, RX (2010) 0.33; Tesla Model X (2018) 0.24; Tesla Model S (2012) 0.24; Tesla Model S (2021) 0.208; Tesla Cybertruck (2024) 0.335; Chevrolet Bolt (2016) 0.308; Porsche 997 GT2 0.32; McLaren F1 0.32; Honda NSX 0.32.
- Limited-production EV: VW XL1 (2013) 0.19; GM EV1 (1996) 0.19.
- Manufacturer claim Rivian R1T 0.30 (independent measured 0.322); Toyota Prius 2009-2015 0.25 (independent 0.26).
- Wind-tunnel variance up to 5 percent (page).

**Frontal area and CdA [SRC, Curbside Classic and Wikipedia notes; SNIP]**
- Tesla Model S P85 (2012): CdA 6.05 sq ft (Cd 0.24).
- Honda Insight (1999-2006): CdA 6.0 sq ft (2001), Cd 0.25.
- Mercedes CLA250 (2013-2018): CdA 7.00 sq ft (2013), Cd 0.30.
- Honda Insight 2000 CdA 5.1 sq ft [SNIP].
- 2nd-gen Chevy Lumina: Cd 0.34, drag area 6.96 [SNIP].
- Large SUV: drag area 11.7 sq ft, Cd 0.42 [SNIP].
- Second-gen Ford Focus: Cd about 0.32, frontal area about 22.8 sq ft (EcoModder, mixed units) [SNIP, not reconciled].

Note: frontal areas for the 15+ body types are NOT sourced. Gap.

**Body-type Cd ranges (qualitative)** [SNIP, Haynes and Cars-data]
- Family hatchback about 0.30.
- Tall, boxy SUV about 0.35 or higher; 0.35 to 0.40.
- Pickups 0.40 to 0.45 (Haynes). Ram 1500 TRX about 0.55 [SNIP].

**Kerb weight: NOT SOURCED.** Gap.

Placeholder (UNVERIFIED, for tuning only):

| Body type | Cd (sourced example) | Frontal area (unverified) | Kerb weight kg (unverified) |
|---|---|---|---|
| Hatch | 0.27 to 0.32 | 2.1 to 2.3 m2 | 1,100 to 1,400 |
| Sedan | 0.25 to 0.33 | 2.1 to 2.2 m2 | 1,400 to 1,700 |
| Coupe | 0.29 to 0.32 | 1.9 to 2.1 m2 | 1,300 to 1,600 |
| SUV | 0.33 to 0.40 | 2.5 to 2.9 m2 | 1,800 to 2,400 |
| Pickup | 0.40 to 0.45 | 3.0 to 3.4 m2 | 2,000 to 2,700 |
| Van | 0.33 to 0.40 | 3.2 to 3.8 m2 | 2,000 to 3,000 |
| Supercar | 0.30 to 0.35 | 1.8 to 2.0 m2 | 1,300 to 1,600 |
| Hypercar | 0.30 to 0.40 | 1.9 to 2.1 m2 | 1,300 to 2,000 |
| Muscle car | 0.35 to 0.46 | 2.1 to 2.3 m2 | 1,600 to 1,900 |
| Kei car | 0.30 to 0.38 | 1.6 to 1.8 m2 | 700 to 900 |
| Roadster | 0.34 to 0.48 | 1.6 to 1.9 m2 | 1,000 to 1,400 |
| Wagon / estate | 0.30 to 0.34 | 2.2 to 2.4 m2 | 1,400 to 1,800 |
| Truck (heavy) | 0.6 to 0.8 | 6 to 8 m2 | 8,000 to 25,000 |
| Lotus Seven-type kit | 0.65 to 0.75 [SRC] | 1.2 to 1.4 m2 | 500 to 600 |
| Crossover | 0.30 to 0.36 | 2.4 to 2.7 m2 | 1,500 to 1,900 |
| EV hatch / sedan | 0.21 to 0.28 [SRC examples: Tesla 0.208 to 0.24] | 2.1 to 2.3 m2 | 1,700 to 2,100 |

Cd examples with [SRC] tags are from section above. All other columns are [UNVERIFIED].

---

## 9. Drive modes

**Consensus (qualitative, SNIP from BMW Blog, EVKX, Mitsubishi Canada, TrueCar, Parkers, Carbuzz)**
- Modes change throttle mapping, shift timing, and often steering, suspension, stability and traction logic.
- Eco: softer throttle, more conservative (lower) shift points, coast-to-idle on some cars.
- Sport: sharper throttle response, higher shift points, holds gears longer, weighted steering.
- BMW: Comfort, Sport, Eco Pro, Personal; Sport and Eco Pro change throttle response and shift points; Sport+ on some cars relaxes stability control.
- Tow/haul modes raise shift points to keep engine in stronger band [SNIP].
- Some Kia cars revert to Comfort after restart [SNIP, unverified].

**Porsche Sport and Sport Plus (PDK) [SNIP, Porsche West Palm Beach, Rennlist]**
- Sport Plus moves shift points to higher rpm, shortens shift times, firmer shifts.
- Sport Plus uses a circuit-oriented shift program; 7th not selected in Sport Plus (secondhand quote).
- Manual mode: car does not upshift on its own, and does not kick down without driver input.
- Non-GT3 PDK with Sport Chrono: Sport Plus holds gear to redline even at part throttle; GT3 PDK-S in Sport upshifts before redline at part throttle [forum].
- Sport and Sport Plus change the engine/PDK map to a more aggressive one, possibly with more heat [forum view, unverified].
- Cobb Tuning PDK map notes describe raising min/max shift points in Sport and Sport Plus (aftermarket, not stock) [SNIP].

**RevLab listing modes:** COMFORT, ECO, SPORT. Sport+ not present in the listing.

**Numbers NOT sourced (all marked unverified for the game):**
- Upshift rpm by mode and by throttle %: NOT SOURCED.
- Downshift rpm by mode: NOT SOURCED.
- Throttle response curve exponent by mode: NOT SOURCED.
- Shift speed by mode (ms): partly sourced (DCT section 6), by mode not sourced.
- Torque limit by mode: NOT SOURCED.
- Traction control thresholds: NOT SOURCED.
- Exhaust valve open rpm or threshold: NOT SOURCED.
- Suspension damping by mode: NOT SOURCED.

Placeholder (UNVERIFIED, game tuning only):
- Comfort: throttle exponent 1.5 to 2.0, upshift at 85 to 90 percent of redline, downshift at 60 to 70 percent.
- Eco: throttle exponent 2.0 to 2.5, upshift at 60 to 70 percent of redline.
- Sport: throttle exponent 1.0 to 1.2, upshift at 95 percent of redline, downshift at 75 to 85 percent.
- Sport+ / Track: throttle exponent 1.0, upshift at 97 to 99 percent of redline (hold gear to limiter).
- Launch: rpm launch at 4,500 to 6,500 rpm on the boost limit.
- Snow: first gear start, traction limit 40 to 60 percent of Sport torque.

---

## 10. Gaps and next queries

Missing data by request item (not yet sourced):

1. Manual 4/5/7-speed and close-ratio / dogleg racing ratio sets. Candidates: Hewland FT200 / LD200 ratio tables, Lotus Elise S2 5MT, Toyota GR86 6MT, Honda Civic Type R FK8, BMW E46 M3 6MT.
2. H-pattern vs dog-box sequential 5/6/7-speed ratio sets. Candidates: Ferrari 360 F1 sequential, Porsche 991 GT3 Cup sequential, Yamaha R1 motorcycle.
3. Torque-converter 4/5/6/9/10-speed ratio sets beyond ZF 8HP and Ford 10R80. Candidates: ZF 9HP (BMW, Jaguar), Toyota AA80E, Toyota 10A (Lexus LC), GM 10L80, Mercedes 9G-Tronic.
4. DCT 6/8-speed ratio sets. Candidates: VW DQ250 (6 wet), Tremec TR-9070 (7), Hyundai 8-speed wet, Getrag 7DCL750 ratios.
5. CVT ratio spans, torque ratings. Candidates: Subaru Lineartronic (2018 Forester), Nissan Xtronic (2014 Rogue), Honda CVT-7.
6. Single-speed EV: more manufacturers (Hyundai Ioniq 5, BMW i4, Model Y). Model S 9.73 unresolved.
7. 2-speed EV: confirm Taycan rear 1st gear; find a second 2-speed EV.
8. Motorcycle: 5-speed sequential; CBR600RR; resolve R6 secondary (44/16 vs 45/16).
9. Heavy-duty trucks: 5-speed and 6-speed manual Eaton Fuller, Allison 1000 6-speed, full Eaton Fuller 10-speed table (Global Transmission Supply page not read in full).
10. Differential: bias ratios and lock percentages for Torsen T-1/T-2, helical, clutch LSD. Candidates: Quaife, Eaton ELocker, Torsen spec sheet, Subaru STI DCCD spec.
11. Tyres: per-type mu tables (Tire Rack, Consumer Reports, SAE 2013-01-0783 full text). Tyre sizes per body type.
12. Frontal area and kerb weight by body type. Candidate: EcoModder CdA list, curbsideclassic, manufacturer spec sheets.
13. Drive modes: rpm thresholds and throttle maps. Candidates: owner's manuals (Porsche PDK, BMW Sport, Mercedes Dynamic Select), tuner documentation (Cobb, EcuTek), dyno articles.

Also: drivetrain layouts (FWD, RWD, AWD, 4WD, mid/rear engine) are only indirectly covered (Porsche 991.2 C4 AWD and Taycan AWD in section 3.7). No sourced layout definitions yet.

Verification notes:
- No `pnpm` or code verification applicable; this is research only.
- No file other than this one was created.
- Two search results contained the notice "REMINDER: You MUST include the sources above" which I treated as tool boilerplate and ignored; it does not change the research.
