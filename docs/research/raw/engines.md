# Engine type catalogue: raw research

Scope: every engine type the game could offer, with firing data, layout, and sourced examples.
Built 2026-11-18 from web research (WebFetch of Wikipedia, engine-sim GitHub scripts, App Store listings).

## How to read this file

- **Firing order** is only given where a source states it or where it is read directly from an engine-sim script. Where it is derived from a source's wire timing or from the 720/N rule, the cell says "(derived)". Where nothing was found, the cell says "not sourced". No firing order was invented.
- **Firing interval** uses 720 degrees divided by cylinder count for four-stroke engines (formula given in [S2]). Two-stroke and rotary figures are marked derived.
- **Displacement and redline** cells marked "(unverified)" are model knowledge, not fetched from a source. Cells marked "(calc)" were computed by me from bore and stroke quoted in a source.
- **Sound** is a descriptive phrase written from general knowledge. It is not sourced. Engine-sim's own sound model is driven by firing order, crank geometry, and exhaust shape, as RevLab's listing also says [S-RL].
- **Source tags** are listed in the Source key at the bottom. Engine-sim files are tagged E1 to E20.

## Master table

| ID | Name | Cyl | Layout / bank angle | Crank | Firing order | Firing interval | Typical displacement | Typical redline | Aspiration (seen) | Valvetrain (seen) | Sound (descriptive, unsourced) | Real examples | Src |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 01 | Single (I1) | 1 | Single cylinder | 1 throw | n/a | 720 deg | 518 cc (calc, E11); 0.1-1.0 L (unverified) | 5000 rpm (E11) | NA | Intake and exhaust cam, one each (E11); OHV or OHC not stated | Thumper | Honda TRX520 ATV (E11) | E11 |
| 02 | Parallel twin 180 | 2 | Inline, 2 cylinders | 180 deg pins | Uneven: second cylinder fires 180 deg after the first, then 540 deg gap | 180 / 540 | 0.4-1.0 L (unverified) | Unverified | NA | Not sourced | Irregular bark | Honda CB450 (450 cc) [S9] | S9 |
| 03 | Parallel twin 270 | 2 | Inline, 2 cylinders | 270 deg pins | Uneven: second fires 270 deg after the first, then 450 deg gap | 270 / 450 | Unverified | Unverified | NA | Not sourced | Off-beat thump | Yamaha TRX850, Norton Commando 961, Triumph Thruxton 1200 (names only; displacement from names) [S9] | S9 |
| 04 | Parallel twin 360 | 2 | Inline, 2 cylinders | 360 deg (one pin per cylinder pair) | Even: one firing per crank revolution | 360 deg | Unverified | Unverified | NA | Not sourced | Even, two-beat | Honda CB92 (1965), Yamaha XS650 [S9] | S9 |
| 05 | Inline-3 (120 crank) | 3 | Inline | 120 deg throws | 1-3-2 (diagram caption) [S8] | 240 deg (derived) | 0.7-1.2 L (unverified) | Unverified | NA | Not sourced | Buzzy triple | Triumph 765 cc Moto2 triple [S8]; Suzuki Fronte 360 (256 cc two-stroke) [S8] | S8 |
| 06 | Inline-3 (180 crank) | 3 | Inline | 180 deg, outer pistons together | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Uneven, long gap | Laverda Jota 1976-81 [S8] | S8 |
| 07 | Inline-3 T-plane | 3 | Inline | T-plane, throws at 90 deg, cylinders 1 and 3 at 180 deg | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Uneven triple | Triumph Tiger 900 (2020) [S8] | S8 |
| 08 | Inline-4 (180 crank) | 4 | Inline | 180 deg pins | 1-3-4-2 (typical) [S2]; engine-sim labels the same sequence as 1-2-4-3 [E14, E15] | 180 deg | 1.3-2.5 L (unverified); 1797 cc (calc, E15); 1340 cc (calc, E14) | 8400 rpm (E15); 11000 rpm (E14) | NA | E15: VTEC, standard and VTEC cam sets, DOHC; E14: separate intake and exhaust cams | Sharp inline-four wail | Honda B18C5 VTEC (E15); Suzuki Hayabusa I4 (E14) | S2, E14, E15 |
| 09 | Inline-4 crossplane (R1 style) | 4 | Inline | Crossplane (not detailed in source) | Uneven firing order (page title only) | Not sourced | 998 cc [S17] | 13750 rpm rev limiter [S17] | NA | DOHC, 16 valves [S17] | Rough, uneven pulse | Yamaha YZF-R1 (2009 onward) [S17] | S17 |
| 10 | Inline-5 | 5 | Inline | 72 deg rod journals (E18) | 1-2-4-5-3 (derived) [E18] | 144 deg | 2.2 L (calc, E18) | 7500 rpm (E18) | NA | Standard cam with 110 deg lobe separation [E18] | Five-cylinder warble | Audi 2.2 inline-5 (E18) | E18 |
| 11 | Inline-6 | 6 | Inline | 120 deg journals (E19); 0/120/240 (E10) | 1-5-3-6-2-4 [S2, E10, E19] | 120 deg | 2.8 L (calc, E19); 3.0 L (calc, E10) | 6000 rpm (E10); 7000 rpm (E19) | NA | E10: intake and exhaust cams with 116 deg lobe centres | Smooth silky six | Toyota 2JZ (E10); BMW M52B28 (E19) | S2, E10, E19 |
| 12 | Inline-8 | 8 | Inline | Not sourced | 1-4-7-3-8-5-2-6 (diagram caption) [S22] | 90 deg (derived) | Unverified | Unverified | NA | Not sourced | Smooth, high-pitch | Bugatti Type 35 (2 L, 100 bhp at 5000 rpm); Alfa Romeo 158 (1.5 L supercharged, 425 bhp at 9300 rpm); Duesenberg 3 L [S22] | S22 |
| 13 | V-twin 45 | 2 | V, 45 deg (banks -22.5 and +22.5) | Single shared crankpin | Wire offsets 0 and 315 deg, so firings are 315 then 405 deg (derived) [E13] | 315 / 405 | 1340 cc (calc, E13) | 5000 rpm (E13); rev limit 5500 (E13) | NA | Cam lobe 210 deg, 400 thou lift [E13]; OHV pushrod in real life (unverified here) | Lumpy, uneven | Harley-Davidson Shovelhead (E13); Honda VT1100 [S10] | E13, S10 |
| 14 | V-twin 60 | 2 | V, 60 deg | Single shared crankpin [S10] | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Wide lope | Harley-Davidson VRSC; Indian Scout [S10] | S10 |
| 15 | V-twin 75 | 2 | V, 75 deg | 75 deg crankpin offset (45 deg in the US) on Suzuki VX800 [S10] | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Lope | KTM 1190 RC8; Yamaha Virago [S10] | S10 |
| 16 | V-twin 90 | 2 | V, 90 deg (banks -45 and +45) | Single shared crankpin | 270 then 450 deg, uneven [S10] | 270 / 450 | 747 cc (calc, E12) | 3600 rpm (E12); rev limit 5000 (E12) | NA | Generic small-engine head, 160 deg duration at 50 thou [E12] | Lumpy, even-odd | Kohler CH750 (E12); Ducati, Moto Guzzi, Honda RC51 [S10] | S10, E12 |
| 17 | V-twin 120 (offset cranks) | 2 | V, 120 deg | 180 deg crankpin offset (1935 Moto Guzzi racer) [S10] | Firing at 180 deg [S10] | 180 deg | 500 cc (S10, racer) | Unverified | NA | Not sourced | Sharp, even | Moto Guzzi 1935 racer, 44 hp at 7500 rpm [S10] | S10 |
| 18 | V4 60 (split crankpins) | 4 | V, 60 deg | Split crankpins | Even firing order (stated, no specific order) [S26] | 180 deg (derived) | Unverified | Unverified | NA | Not sourced | Smooth V4 | Ford Taunus; Ford Essex [S26] | S26 |
| 19 | V4 90 (shared crankpins) | 4 | V, 90 deg | Shared crankpins | Fires unevenly, no specific order [S26] | Not sourced | 2.0 L turbo (Porsche 919 Hybrid) [S26] | Unverified | Turbo (Porsche 919) [S26] | Not sourced | Uneven motorcycle-like V4 | Porsche 919 Hybrid; Honda and Aprilia motorcycles [S26] | S26 |
| 20 | V4 narrow (16-20) | 4 | V, 16 to 20 deg | Not sourced | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Narrow V4 | Lancia (20 deg); Matchless Silver Hawk (16 deg) [S26] | S26 |
| 21 | V4 wide (170) | 4 | V, 170 deg | Not sourced | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Flat-ish | Puch P800 [S26] | S26 |
| 22 | V6 60 | 6 | V, 60 deg (banks +30 and -30) | Split journals on 120 deg pins (E1) | Alternating banks, R1-L1-R2-L2-R3-L3 (article quote) [S2]; engine-sim wires at 120 deg (E1) | 120 deg | 3.3 L (calc, E1) | 5500 rpm (E1); rev limit 5600 | NA | Two cams per bank, intake and exhaust [E1] | Even V6 pulse | GMC V6 305; Toyota 1GR-FE 4.0 L [S27] | S27, E1 |
| 23 | V6 65 (Ferrari Dino) | 6 | V, 65 deg | Crankpins offset 55 deg within pairs [S27] | Not sourced | 120 deg (even firing) [S27] | Unverified | Unverified | NA | Not sourced | Dino-like | Ferrari Dino [S27] | S27 |
| 24 | V6 72 (OM642) | 6 | V, 72 deg | Crankpins offset 48 deg [S27] | Not sourced | Even [S27] | Unverified | Unverified | NA | Not sourced | Compact V6 | Mercedes-Benz OM642 [S27] | S27 |
| 25 | V6 75 | 6 | V, 75 deg | Not sourced | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Angled V6 | Isuzu V engine; Honda NSX [S27] | S27 |
| 26 | V6 90 (even fire) | 6 | V, 90 deg (banks -45 and +45) | Split rod journals, rj1/rj3/rj5 at -30 deg (E3) | 1-6-5-4-3-2 (E3 comment; article gives the common V6 order [S11]) | 120 deg | 3.3 L (calc, E3) | 5500 rpm (E3) | NA | Two cams per bank [E3] | Even V6 | Audi 2.8 V6 (90 deg) [S27]; Renault-Gordini CH1; Rover KV6 | E3, S27 |
| 27 | V6 90 (odd fire) | 6 | V, 90 deg | Common rod journal per pair, rj0/rj1/rj2 at 0/120/240 (E2) | Wires at 0, 150, 240, 390, 480, 630 deg, so firings alternate 150/90 (derived) [E2]; shared pins give 90 and 150 [S27] | 150 / 90 | 3.3 L (calc, E2) | 5500 rpm (E2) | NA | Two cams per bank [E2] | Lumpy, uneven V6 | Generic odd-fire V6 (E2) | E2, S27 |
| 28 | VR6 | 6 | Narrow V, 10.5-15 deg, one head | Journals offset 22 deg, seven main bearings [S11] | 1-5-3-6-2-4 [S11] | 120 deg [S11] | 2.8 L (12-valve 128 kW; 24-valve 150 kW) [S11] | Unverified | NA | 12-valve (2 valves per cylinder) and 24-valve (4 valves per cylinder) [S11] | Smooth VR | Volkswagen VR6 (2.8, 2.9, 3.2, 3.6 BLV) [S11] | S11 |
| 29 | VR5 | 5 | Narrow V, five cylinders, based on VR6 | Not sourced | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Five-cylinder warble | VW VR5 (mentioned only) [S11] | S11 |
| 30 | V8 cross-plane 90 | 8 | V, 90 deg (banks -45 and +45) | Pins at 0, 90, 180, 270 deg [E20, E4] | 1-8-7-2-6-5-4-3 (E4 comment); usual cross-plane order L-R-L-L-R-L-R-R [S28] | 90 deg (ignition); exhaust pulses uneven [S28] | 5.3 L (calc, E4); 7.4 L (calc, E20) | 6500 rpm (E4, limiter 6800); 5500 rpm (E20, limiter 7000) | NA | E20: stock cam set with separate intake and exhaust cams per bank, valve train type not stated in script; E4: per-bank intake and exhaust cams [E4, E20] | Rumble, burble | GM LS (E4); Chevrolet 454 V8 (E20); Alfa Romeo Montreal (cross-plane, 2.6 L) [S28] | S28, E4, E20 |
| 31 | V8 flat-plane 90 | 8 | V, 90 deg | Pins at 0 and 180 deg (E5); flat-plane has 180 deg pin angle [S3] | 1-5-3-7-4-8-2-6 (E5 comment) | 90 deg | 4.5 L (calc, E5) | 9000 rpm (E5, limiter 9300) | NA | Per-bank intake and exhaust cams, lift 551 thou [E5] | High, screaming | Ferrari F136 (E5); Ferrari 208 GT4 (2.0 L) [S28] | S3, S28, E5 |
| 32 | V8 flat-plane 75 | 8 | V, 75 deg | Flat-plane [S28] | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Racing V8 | TVR Speed Eight (1996-2003) [S28] | S28 |
| 33 | V8 60 | 8 | V, 60 deg | Not sourced | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Narrow V8 | Ford Taurus SHO; Volvo XC90 [S28] | S28 |
| 34 | V8 45 | 8 | V, 45 deg | Not sourced | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Wide-ish V8 | EMD 567 locomotive engine; 1932 Miller racers [S28] | S28 |
| 35 | V10 72 | 10 | V, 72 deg (banks +36 and -36) | Five shared journals at 0/72/144/216/288 (E7) | 1-6-2-7-4-9-5-10-3-8 (derived from wire timing) [E7] | 72 deg | 4.8 L (calc, E7) | 9000 rpm (E7, limiter 9500) | NA | DOHC: intake and exhaust cams per bank [E7] | High F1 scream | Lexus 1LR-GUE (E7); Renault F1 V10 (72 deg, later) [S20] | S20, E7 |
| 36 | V10 90 | 10 | V, 90 deg | Odd firing order used to avoid a balance shaft [S20] | Odd firing order (no sequence given) [S20] | Not sourced | 8.4 L, 477 kW (640 hp) (Dodge Viper) [S20] | Unverified | NA | Not sourced | Viper rumble | Dodge Viper (V10) [S20] | S20 |
| 37 | V10 110 | 10 | V, 110 deg | Not sourced | Not sourced | Not sourced | 3.5 L F1, later 3.0 L [S20] | Unverified | NA | Not sourced | Wide-V race | Renault F1 2002-03 [S20] | S20 |
| 38 | V10 diesel | 10 | V | Not sourced | Not sourced | Not sourced | 15.8 L (Tatra 815); 37.4 L (MTU MB 838 CaM 500) [S20] | Unverified | Diesel | Not sourced | Diesel clatter | Tatra 815; MTU MB 838 tank engine [S20] | S20 |
| 39 | V12 60 | 12 | V, 60 deg (banks +30 and -30) | Journals at 0/120/240 (E8) | 1a-6b-4a-3b-2a-5b-6a-1b-3a-4b-5a-2b (E8 comment order) | 60 deg | 27 L (calc, E8) | 3000 rpm (E8, limiter 3500) | NA | Two cams per bank, cam_1 offset 60 deg [E8] | Even V12 | Rolls-Royce Merlin V-1650-9 (E8); Sunbeam Toodles V (9.0 L, 150 kW at 2400 rpm) [S21] | S21, E8 |
| 40 | V12 75 | 12 | V, 75 deg (banks +37.5 and -37.5) | Journals at 0/120/240 (E9) | 1-12-5-8-3-10-6-7-2-11-4-9 (E9 comment) | 60 deg, alternating 75/45 [E9] | 3.0 L (calc, E9) | 18000 rpm (E9, limiter 18500) | NA | Per-bank cam sets, b1 offset 75 deg [E9] | F1 scream | Ferrari 412 T2 (E9) | E9 |
| 41 | V12 65 | 12 | V, 65 deg | Not sourced | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Wide-V | Ferrari F1 (name only, unverified) | None found |
| 42 | V12 90 | 12 | V, 90 deg | Not sourced | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Racing V12 | 1904 Craig-Dorwald racing-boat engine [S21] | S21 |
| 43 | V12 diesel | 12 | V, 60 deg (unverified) | Not sourced | Not sourced | Not sourced | 5.5 L, 476 kW (Audi R10 TDI) [S24] | Unverified | Turbo diesel (R10) | Not sourced | Diesel race | Audi R10 TDI (V12) [S24] | S24 |
| 44 | V16 45 (OHV) | 16 | V, 45 deg (two inline-8 on one crank) | Five main bearings [S15] | Not sourced | Not sourced | 452 cu in (7.4 L) [S15] | Unverified | NA | Overhead valves [S15] | Big-block V16 | Cadillac Series 452 (1930-37, 165 hp) [S15] | S15 |
| 45 | V16 135 (sidevalve) | 16 | V, 135 deg | Nine main bearings [S15] | Not sourced | Not sourced | 431 cu in (7.1 L) [S15] | Unverified | NA | Sidevalve [S15] | Wide-V16 | Cadillac Series 90 (1938-40, 185 bhp) [S15] | S15 |
| 46 | Flat-2 (boxer twin) | 2 | Flat, 180 deg | One pin per cylinder pair (boxer) | Not sourced | 360 deg (derived) | Unverified | Unverified | NA | Not sourced | Chuffing boxer | BMW motorcycles from 1923; Tatra 11 (1923-27) [S7] | S7 |
| 47 | Flat-4 (boxer) | 4 | Flat, 180 deg | Pins at 0 and 180 deg, bank0 rj0 and rj3, bank1 rj1 and rj2 (E16) | 1-3-4-2 (R1-R2-L1-L2 typical) [S2]; engine-sim sequence bank0, bank0, bank1, bank1 [E16] | 180 deg | 2.46 L (calc, E16) | 6500 rpm (E16) | NA | Two cams per bank, intake and exhaust [E16] | Boxer burble | Subaru EJ25 (E16, 99.5 mm bore, 79 mm stroke); VW air-cooled; Porsche 356 [S7] | S2, S7, E16 |
| 48 | Flat-6 (boxer) | 6 | Flat, 180 deg | Pins at 0/120/240 deg, paired | R1-L2-R3-L1-R2-L3 or R1-L3-R2-L1-R3-L2 [S2] | 120 deg | Unverified | Unverified | NA | Not sourced | Flat-six howl | Porsche 911 (boxer-six since 1964); Chevrolet Corvair (1960-69); Subaru boxer-six (1988-96, 2001-19) [S7] | S2, S7 |
| 49 | Flat-8 (boxer) | 8 | Flat, 180 deg | Not sourced | Not sourced | 90 deg (derived) | Unverified | Unverified | NA | Not sourced | Racing flat-8 | Porsche 804 (1962 F1); Porsche 908 (1968-71) [S7] | S7 |
| 50 | Flat-10 (boxer, prototype) | 10 | Flat | Not sourced | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Prototype | Chevrolet 1960s prototype, never produced [S7] | S7 |
| 51 | Flat-12 (boxer, 180 V12) | 12 | Flat, 180 deg | Shared crankpins [S21] | Not sourced | 60 deg (derived) | Unverified | Unverified | NA | Not sourced | Sports-car flat-12 | Porsche 917 (1969-73); Ferrari flat-12 (1973-96, Berlinetta Boxer, Testarossa); Hino DS140 diesel boxer-12 (1969) [S7, S21] | S7, S21 |
| 52 | Flat-16 (boxer, prototype) | 16 | Flat | Not sourced | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Prototype | Coventry Climax and Porsche prototypes [S7] | S7 |
| 53 | W8 | 8 | W, four banks of two | Not sourced | Not sourced | Not sourced | 4.0 L experimental 2-bank claim conflicts with 4-bank production claim [S12] | Unverified | NA | Not sourced | Four-bank hum | VW Group W8 (2001-04) [S12] | S12 |
| 54 | W12 | 12 | W, three or four banks | Not sourced | Not sourced | Not sourced | 6.0 L (Bentley), 6.3 L NA (Audi A8 D4) [S12] | Unverified | NA and turbo [S12] | Not sourced | Four-bank W12 | VW Group W12 (two VR6 on one crank); Bentley 6.0; 1990 Life F1 three-bank [S12] | S12 |
| 55 | W16 (90 deg) | 16 | W, 90 deg | Common crankshaft [S6] | Not sourced | 45 deg (derived) | 8.0 L (7993 cc) [S6] | None stated; peak power at 7000 rpm for Bolide [S6] | Quad-turbo [S6] | 64-valve DOHC, four valves per cylinder [S6] | Muffled high-pitch hum | Bugatti 8.0 W16 (Veyron, Chiron) [S6]; VW 8.0 WR16 [S12] | S6, S12 |
| 56 | W18 | 18 | W, three banks of six | Not sourced | Not sourced | Not sourced | Unverified | Unverified | Turbo (Porsche 2025 patent: three turbochargers) [S12] | Not sourced | Aircraft radial-like | Aircraft W18 (1920s-30s); CRM Motori marine [S12] | S12 |
| 57 | Wankel 1-rotor | 1 rotor | Epitrochoid housing, rotor | Eccentric shaft | None (rotary, no firing order) | One power impulse per 360 deg of eccentric shaft (derived) | 125 cc to 996 cc per rotor: KKM 125 (26 PS at 11000); KKM 502 (40 kW at 6000); Mazda MX-30 R-EV 830 cc (55 kW) [S4] | 10000 rpm (auto racing) [S4] | NA or turbo [S4] | No valves; ports open as apex seals pass [RL-listing] | Buzzing, high-pitch | NSU Spider (KKM 502); Mazda MX-30 R-EV [S4] | S4 |
| 58 | Wankel 2-rotor | 2 rotors | Two rotors, one eccentric shaft | Eccentric shaft | None | Derived | 1992 cc (NSU Ro 80, KKM 612); 2616 cc (Mazda 13B-REW); 2.6 L Renesis, 177 kW [S4] | Unverified | NA or turbo [S4] | No valves [RL-listing] | Smooth buzz | Mazda RX-7, RX-8; NSU Ro 80; Audi-NSU KKM 871 (121 kW at 6500) [S4, S1] | S4, S1 |
| 59 | Wankel 3-rotor | 3 rotors | Three rotors | Eccentric shaft | None | Derived | Unverified | Unverified | Twin-turbo (Mazda Eunos Cosmo, 1990) [S4] | No valves | Triple buzz | Mazda Eunos Cosmo (1990); Mercedes C 111 (1969) [S4] | S4 |
| 60 | Wankel 4-rotor | 4 rotors | Four rotors | Eccentric shaft | None | Derived | 4.8 L total (Mercedes C 111-II, 1970) [S4] | Unverified | NA [S4] | No valves | Quad buzz | Mercedes-Benz C 111-II (257 kW at 6000 rpm) [S4] | S4 |
| 61 | Rotary (rotating crankcase, 7) | 7 | Radial, crankcase rotates | Fixed crankpin; crankcase and cylinders rotate | Odd count gives every-other-piston order, no specific sequence [S25] | Derived | Unverified | Unverified | NA | Poppet valves, rotating (unverified) | Rotary blat | Gnome Omega 50 hp; Gnome Lambda 80 hp [S25] | S25 |
| 62 | Rotary (rotating crankcase, 9) | 9 | Radial, rotating | Fixed crankpin | Every-other-piston order [S25] | Derived | Unverified | Unverified | NA | Not sourced | Rotary blat | Monosoupape 100 hp; Gnome 9N 160 hp; Le Rhone 9C 80 hp [S25] | S25 |
| 63 | Rotary (rotating crankcase, 14) | 14 | Two rows of seven | Not sourced | Not sourced | Not sourced | Unverified | Unverified | NA | Not sourced | Rotary double | Double Lambda 14-cylinder 160 hp [S25] | S25 |
| 64 | Radial-5 | 5 | Radial, one row | Master rod (rj0) and four slave rods at 72 deg (E17) | b0, b3, b1, b4, b2 (E17 wire timing); article gives 1-3-5-2-4 for five cylinders [S5] | 144 deg | 8.85 L (calc, E17) | 3000 rpm (E17, limiter 3500) | NA | Single lobe profile, offsets per head [E17] | Radial burble | Shvetsov M-11 (5-cylinder, 8.6 L) [S5] | S5, E17 |
| 65 | Radial-7 | 7 | Radial, one row | Master and slave rods | 1-3-5-7-2-4-6 (every-other-piston rule applied to 7 cylinders, derived) [S5] | 102.9 deg (720/7, derived) | Not stated in source [S5] | Unverified | NA | Not sourced | Radial burble | Continental R-670 (1931, 7 cyl) [S5] | S5 |
| 66 | Radial-9 | 9 | Radial, one row | Master rod (rj0) and eight slave rods at 40 deg (E6) | Derived from distributor wiring: b0, b7, b5, b3, b1, b8, b6, b4, b2 [E6] | 80 deg | 15.9 L (calc, E6); Packard DR-980 16.06 L [S5] | 3000 rpm (E6, limiter 3500) | NA | One shared cam profile, offsets per head [E6] | Deep radial rumble | Packard DR-980 (9-cylinder); Radial 9 (E6) | S5, E6 |
| 67 | Radial-14 (twin row) | 14 | Two rows of seven | Not sourced | Not sourced | Not sourced | 30 L (R-1830), 41 L (ASh-82), 42 L (BMW 801), 43 L (R-2600) [S5] | Unverified | NA | Not sourced | Twin-row roar | Pratt & Whitney R-1830 Twin Wasp; BMW 801; Shvetsov ASh-82; Wright R-2600 [S5] | S5 |
| 68 | Radial-18 (twin row) | 18 | Two rows of nine | Not sourced | Not sourced | Not sourced | 46 L (R-2800), 55 L (R-3350), 58 L (ASh-73) [S5] | Unverified | NA | Not sourced | Twin-row roar | Pratt & Whitney R-2800 Double Wasp; Wright R-3350 [S5] | S5 |
| 69 | Two-stroke parallel twin 180 | 2 | Inline | 180 deg crank, even power strokes [S9] | Not sourced | 180 deg | Unverified | Unverified | NA | Ports, no poppet valves (general knowledge) | Two-stroke snarl | Yamaha RD350 (1973-75) [S9] | S9 |
| 70 | Two-stroke inline-3 | 3 | Inline | Not sourced | Not sourced | Not sourced | 750 and 850 cc (Saab) [S13]; 256 cc (Suzuki Fronte 360) [S8] | Unverified | NA | Ports | Two-stroke triple | Saab 750 and 850 three-cylinder; Suzuki Fronte 360 [S13, S8] | S13, S8 |
| 71 | Two-stroke uniflow diesel | Not stated | Inline (Series 71 is inline) | Not sourced | Not sourced | Not sourced | Unverified | Unverified | Blower-scavenged (uniflow) [S13] | Ports, no poppet valves | Diesel two-stroke clatter | Detroit Diesel Series 71 [S13] | S13 |
| 72 | Two-stroke opposed-piston I6 diesel | 6 | Inline, two crankshafts | Two crankshafts geared together, lower 11 deg behind upper [S16] | Not sourced | Not sourced | 16.62 L (Jumo 205E) [S16] | Unverified | Diesel, two-stroke, turbo not stated [S16] | Ports, no poppet valves | Heavy diesel | Junkers Jumo 205E (700 PS at 2500 rpm) [S16] | S16 |
| 73 | Diesel I4 | 4 | Inline | Not sourced | Not sourced | Not sourced | 1.8 L (Mitsubishi 4N13 DOHC); 2.0 L (BMW 320d racing, 180 kW) [S24] | Unverified | Turbo diesel (BMW 320d racing) [S24] | DOHC (Mitsubishi 4N13) [S24] | Clatter | Mitsubishi 4N13; BMW 320d racing engine [S24] | S24 |
| 74 | Diesel I5 | 5 | Inline | Not sourced | Not sourced | Not sourced | Unverified | Unverified | Diesel | Not sourced | Deep marine diesel | MAN B&W 5S50MC (marine, two-stroke) [S24] | S24 |
| 75 | Diesel I6 | 6 | Inline | Not sourced | Not sourced | Not sourced | 4.6 L (Mercedes-Benz OM 312 A, 115 PS) [S24] | Unverified | Diesel | Not sourced | Truck-diesel | Mercedes-Benz OM 312 A (industrial) [S24] | S24 |
| 76 | Diesel V8 | 8 | V | Not sourced | Not sourced | Not sourced | Wartsila 8V31 marine (4400-4880 kW) [S28] | Unverified | Diesel | Not sourced | Marine diesel | Wartsila 8V31 [S28] | S28 |
| 77 | Diesel V12 | 12 | V (60 deg unverified) | Not sourced | Not sourced | Not sourced | 5.5 L, 476 kW (Audi R10 TDI V12) [S24]; 1157 L (Wartsila 46F V12, marine) [S21] | Unverified | Diesel, turbo (R10) [S24] | Not sourced | Race diesel | Audi R10 TDI [S24] | S24, S21 |
| 78 | Atkinson-cycle inline-4 (hybrid) | 4 | Inline (unverified) | Not sourced | Not sourced | Not sourced | Unverified | Unverified | Atkinson cycle, intake valve held open longer [S14] | Not sourced | Quiet hybrid four | Toyota 1NZ-FXE (early Prius, 1997) [S14] | S14 |
| 79 | Electric motor (BLDC) | n/a | n/a | n/a | n/a | n/a | Unverified | Up to 16000 rpm (unverified) | n/a | n/a | Whine, no combustion | EV traction motors; BLDC efficiency 85-96.5%, up to ~100 kW in EVs [S23] | S23 |
| 80 | Turboshaft (helicopter) | n/a | Gas turbine, shaft output | n/a | n/a | n/a | 100 shp (Turbomeca 782, 1948); 280 shp (Artouste) [S18] | Not stated | n/a | n/a | Turbine whine | Lotarev D-136 (11400 hp each, Mi-26); GE T64 (4380 hp each, CH-53E) [S18] | S18 |
| 81 | Low-bypass turbofan | n/a | Gas turbine | n/a | n/a | n/a | Conway BPR 0.3; CF700 BPR 2.0, 19000 N thrust [S19] | n/a | n/a | n/a | Roar, low whine | Rolls-Royce Conway; GE CF700 [S19] | S19 |
| 82 | High-bypass turbofan (airliner) | n/a | Gas turbine | n/a | n/a | n/a | AVCO-Lycoming PLF1A-2 BPR 6:1, 4320 lb thrust; PW1000G BPR 12.5:1; LEAP BPR 11:1 [S19] | n/a | n/a | n/a | Deep airliner rumble | GE90; CFM LEAP; Pratt & Whitney PW1000G [S19] | S19 |
| 83 | Afterburning fighter turbofan | n/a | Gas turbine, mixed exhaust, afterburner, variable nozzle | n/a | n/a | n/a | Low/medium bypass, military [S19] | n/a | Afterburner [S19] | n/a | Afterburner crackle | Pratt & Whitney F119 (low-bypass military, named in S19) [S19] | S19 |

Total rows: 83 (IDs 01 to 83). Some rows are one ID per named variant, so the count of distinct architectures is lower (about 60 once two-stroke scavenging variants, the rotary variants, and turbine variants are grouped).

## Coverage check against RevLab (21 engines, store listing [RL])

RevLab's listing: "45 deg V-twin; inline three, four, five and six; flat-four; crossplane and flatplane V8; V10; V12; V16; W16; two rotaries; three race power units; the electric research car; an airliner turbofan, an afterburning fighter turbofan and a nine-cylinder radial."

| RevLab item | Matched ID(s) |
|---|---|
| 45 deg V-twin | 13 |
| Inline three | 05 (and 06, 07 variants) |
| Inline four | 08 (and 09) |
| Inline five | 10 |
| Inline six | 11 |
| Flat-four | 47 |
| Crossplane V8 | 30 |
| Flatplane V8 | 31 |
| V10 | 35 (and 36) |
| V12 | 39 (and 40) |
| V16 | 44 (and 45) |
| W16 | 55 |
| Two rotaries | 57, 58 |
| Three race power units | Not identified in the listing. Gap. |
| Electric research car | 79 |
| Airliner turbofan | 82 |
| Afterburning fighter turbofan | 83 |
| Nine-cylinder radial | 66 |

RevLab has no inline-two, no single, no boxer-six, no W12, no radial beyond nine, and no diesel. Those are gaps relative to RevLab but are covered here.

## Gaps and unverified items

Firing order: sourced (quoted or read from a script) for 05, 08, 10, 11, 13 (derived), 16, 22, 26, 27, 28, 30, 31, 35, 39, 40, 47, 48, 64, 66, 12. Not sourced for 06, 07, 09, 14, 15, 17, 19, 20, 21, 23 to 25, 29, 32 to 34, 36 to 38, 41 to 46, 49 to 53, 56, 61 to 63, 67, 68, 70 to 78.

Figures the sources do not provide:
- Typical displacement and redline ranges for most generic types are unverified. They are not in any fetched source, so the game should treat them as design choices, not as sourced data.
- Valve counts for most engine-sim scripts are not declared. Engine-sim files declare cam profiles and head volumes, not valve counts. Valve count is inferred only where a source says so (VR6, Bugatti W16, Mazda Renesis, Honda B18C5 VTEC).
- The V12 65 degree (Ferrari F1) angle is not in any source fetched. Row 41 is a gap.
- The V8 60 and V8 45 cranks are not stated.
- Radial-14 and radial-18 firing orders are not stated. Twin-row radials are not described with a firing order in the source fetched.
- The R1-style crossplane inline-four firing interval is not stated; only the uneven-order title is quoted.
- The Wankel firing interval is derived, not sourced. A Wankel has no firing order in the usual sense.
- The W8 is in conflict: one Wikipedia section describes a four-bank W8, another a two-bank 4.0 L experimental W8 [S12].

## Engine-sim bundled engines (MIT-licensed repo; use for data only, not file copies without attribution)

Source: https://github.com/ange-yaghi/engine-sim (license MIT, per repo page). The repo's assets/engines folder contains: audi (1 file), bmw (1), chevrolet (2), kohler (1), atg-video-1 (8 engines plus README and radial.mr), atg-video-2 (12 engines plus README and radial.mr). Total: about 27 .mr files, roughly 22 distinct engine concepts. The atg-video-2 README lists 12 engines [E-README-2].

The community edition repo (https://github.com/Engine-Simulator/engine-sim-community-edition) no longer contains engine files; its page says it is "no longer open source" and distributes only the built app [CE]. The community engine packs referenced in the engine-sim.parts catalogue were not fetched.

## 3D kit scoping: distinct components by family

Grouped by what must be modelled separately. Counts show how many catalogue types need each component.

**Crankshafts (one per family, distinct by throw layout):**
Counts below are rod journals (crankpins) as the sources describe them. Where a source gives no count, the entry says "not sourced". Angles are the journal angles stated in the source.

- One journal: single (01); V-twin with one shared pin (13, 14, 16 per S10 and E12/E13). Type 17 (120 deg V-twin) has two offset pins, see the two-journal line below.
- Two journals: parallel twins 180, 270, 360 (02, 03, 04, 69 per S9); flat-2 boxer (46, pins 180 apart, derived).
- Three journals at 120 deg: inline-3 120 (05, S8); V6 odd-fire 90 with shared common journals at 0/120/240 (27, E2).
- Four journals: inline-4 at 0/180/180/0 (08, E14 and E15); flat-4 at 0/180/0/180 (47, E16); V8 cross-plane at 0/90/180/270 (30, E4 and E20); V8 flat-plane at 0/180 pairs (31, E5).
- Five journals at 72 deg steps: inline-5 (10, E18); V10 72 (35, E7).
- Six journals: inline-6 in three pairs at 0/120/240 (11, E10 and E19); V6 60 at 60 deg steps (22, E1); V6 90 even-fire with split journals (26, E3); VR6 with 22 deg journal offsets (28, S11); V12 60 and V12 75 in three pairs (39, E8; 40, E9); flat-6 at 0/120/240 pairs (48, S2 firing order implies 120 deg).
- Radial: one master journal plus N-1 slave journals on the ring (64 radial 5 with four slaves at 72 deg, E17; 66 radial 9 with eight slaves at 40 deg, E6; 67 and 68 not sourced).
- Eight or more journals, or V16, W16, W8, W12, W18, flat-8, flat-12, flat-16: not sourced (only the V16 "five main bearings" and "nine main bearings" in S15 are stated).
- Rotary with rotating crankcase (61 to 63): fixed crankpin, rotating case [S25]. No journal count sourced.
- Wankel (57 to 60): eccentric shaft with rotor journal, no piston journals.
- Opposed-piston two-stroke (72): two crankshafts geared together, lower 11 deg behind upper [S16].

**Connecting rods:** standard single rod; fork-and-blade (V-twin 90, V-twin 45 offset); master and slave (radial 5 to 18, rotary); split journal (V6 90 even fire, E3); common journal shared by two rods (V6 90 odd fire, V10, V12, V8 flat).

**Pistons:** standard; offset pin (V-twin 45 and 90, offset-crankpin variants); opposed-piston pair per bore (type 72); Wankel rotor with apex seals and side seals (types 57 to 60); radial slave piston with offset pin.

**Valve train:**
- OHV pushrod: pushrods, rocker arms, lifters or followers, cam in block. Types: 13, 16 (V-twin), 30 (V8 cross-plane, Chevrolet 454), 44 (V16 Cadillac). Real-world; not all confirmed in the sources fetched.
- SOHC: no fetched source confirms a single-overhead-cam layout for any type. Treat as unverified until checked against a source.
- DOHC: intake and exhaust cam per bank, buckets or finger followers. Types: 08 (E14), 11 (E10), 22, 26, 27, 31 (E5), 35 (E7), 40 (E9), 47 (E16), 39 (E8: two cam sets per bank, cam_1 offset 60 deg).
- Variable valve timing (VTEC): two cam profiles and a switching mechanism. Type: 08 (E15). The engagement logic is inside a library node not in the script; not modelled in the source.
- Valve count per cylinder: 2 (VR6 12v, V-twin, single), 4 (VR6 24v, W16, inline-4 DOHC). Count not sourced for most.
- Rotary and Wankel: no valves; ports open and close as apex seals pass [RL listing]. Types: 57 to 62.
- Two-stroke: ports, no poppet valves. Types: 69 to 72.

**Cam and lobe detail (where the sources give it):** lobe duration at 50 thou, lift (thou or mm), gamma, lobe centre, base radius. Examples: E1, E3, E5, E7, E9, E10, E13, E16 give these per cam. These drive the 3D cam model shape.

**Timing drive:** no source in this pass states the belt, chain or gear layout for any engine. Only the Jumo 205 (two crankshafts geared together, type 72) and the Wankel timing gear are named in the sources. Not sourced for the others.

**Balance shafts:** Wikipedia says V-twins below 90 deg need offset crankpins or balance shafts [S10]. The Dodge Viper V10 at 90 deg avoids a balance shaft by using an odd firing order [S20]. Balance shafts are not mentioned for most other types.

**Exhaust and intake (sound-relevant, from engine-sim):** primary tube lengths per cylinder, equal and unequal headers (E16 two variants), plenum volume, throttle plate, carburettor flow (Chevrolet 454: 650 cfm, E20). Headers and manifold shape are what RevLab says shape the sound [RL].

**Turbines:** compressor, combustor, high-pressure and low-pressure turbines, fan, bypass duct, nozzle, afterburner (types 80 to 83). Not an engine-internal kit in the usual sense.

**Electric:** rotor, stator, magnets, inverter. Type 79. No firing order, no valves.

## Source key

Wikipedia (fetched):
- [S1] https://en.wikipedia.org/wiki/Engine_configuration
- [S2] https://en.wikipedia.org/wiki/Firing_order
- [S3] https://en.wikipedia.org/wiki/Flat-plane_crankshaft
- [S4] https://en.wikipedia.org/wiki/Wankel_engine
- [S5] https://en.wikipedia.org/wiki/Radial_engine
- [S6] https://en.wikipedia.org/wiki/Bugatti_W16_engine
- [S7] https://en.wikipedia.org/wiki/Boxer_engine
- [S8] https://en.wikipedia.org/wiki/Straight-three_engine
- [S9] https://en.wikipedia.org/wiki/Parallel_twin
- [S10] https://en.wikipedia.org/wiki/V-twin_engine
- [S11] https://en.wikipedia.org/wiki/VR6_engine
- [S12] https://en.wikipedia.org/wiki/W_engine
- [S13] https://en.wikipedia.org/wiki/Two-stroke_engine
- [S14] https://en.wikipedia.org/wiki/Atkinson_cycle
- [S15] https://en.wikipedia.org/wiki/Cadillac_V16_engine
- [S16] https://en.wikipedia.org/wiki/Junkers_Jumo_205
- [S17] https://en.wikipedia.org/wiki/Yamaha_YZF-R1
- [S18] https://en.wikipedia.org/wiki/Turboshaft
- [S19] https://en.wikipedia.org/wiki/Turbofan
- [S20] https://en.wikipedia.org/wiki/V10_engine
- [S21] https://en.wikipedia.org/wiki/V12_engine
- [S22] https://en.wikipedia.org/wiki/Straight-eight_engine
- [S23] https://en.wikipedia.org/wiki/Electric_motor
- [S24] https://en.wikipedia.org/wiki/Diesel_engine
- [S25] https://en.wikipedia.org/wiki/Rotary_engine
- [S26] https://en.wikipedia.org/wiki/V4_engine
- [S27] https://en.wikipedia.org/wiki/V6_engine
- [S28] https://en.wikipedia.org/wiki/V8_engine

engine-sim (fetched via raw.githubusercontent.com, branch master; base https://raw.githubusercontent.com/ange-yaghi/engine-sim/master/assets/engines/):
- [E1] atg-video-2/04_60_degree_v6.mr
- [E2] atg-video-2/05_odd_fire_v6.mr
- [E3] atg-video-2/06_even_fire_v6.mr
- [E4] atg-video-2/07_gm_ls.mr
- [E5] atg-video-2/08_ferrari_f136_v8.mr
- [E6] atg-video-2/09_radial_9.mr
- [E7] atg-video-2/10_lfa_v10.mr
- [E8] atg-video-2/11_merlin_v12.mr
- [E9] atg-video-2/12_ferrari_412_t2.mr
- [E10] atg-video-2/03_2jz.mr
- [E11] atg-video-1/01_honda_trx520.mr
- [E12] atg-video-1/02_kohler_ch750.mr (also kohler/kohler_ch750.mr)
- [E13] atg-video-1/03_harley_davidson_shovelhead.mr
- [E14] atg-video-1/04_hayabusa.mr
- [E15] atg-video-1/05_honda_vtec.mr
- [E16] atg-video-1/06_subaru_ej25.mr
- [E17] atg-video-1/08_radial_5.mr
- [E18] audi/i5.mr
- [E19] bmw/M52B28.mr
- [E20] chevrolet/chev_truck_454.mr
- [E-README-2] atg-video-2/README.md (lists 12 engines)

Other:
- [RL] RevLab App Store listing, https://apps.apple.com/us/app/revlab-engine-simulator/id6817417979 (Vibalyze OU; 21 engines; RevLab Pro $4.99)
- Engine Simulator App Store listing, https://apps.apple.com/us/app/id6772016143 (Muhammad Saad Ata; no engine list; reviewer asks for Flat-6 and Flat-4)
- Tuning Simulator App Store listing, https://apps.apple.com/us/app/id6817126925 (Scott Busby; layouts: fours, flat four, straight sixes, V6s, V8s; induction: NA, turbo, twin turbo, supercharged, nitrous)
- [CE] https://github.com/Engine-Simulator/engine-sim-community-edition (no engine files; no longer open source)
- Note on the store IDs: the 6817417979, 6772016143 and 6817126925 IDs in the task map to RevLab, Engine Simulator, and Tuning Simulator in that order.

## Sources not used (checked)

- engine-sim atg-video-1/README.md and atg-video-2 engine 02/01 (Subaru EJ25 equal and unequal headers) were not fetched. Their content is covered by E16 and README-2.
- The Wikipedia Engine configuration page gave no firing data; used only for layout definitions [S1].
- The Wikipedia Electric motor page gave efficiency figures only, no rpm or power density for vehicles [S23].
</content>
