# Gearbox ratio gap-fill: sourced tables, round 2

Research date: 2026-11-18. Status: gap-fill pass on top of `gearboxes-and-cars.md`. That file was not edited.

## Conventions

- `[SRC]` = figure read from a page I fetched with WebFetch in this pass. The page's own quality is graded in each section.
- `[UNVERIFIED]` = figure seen only in a search-result snippet, or on a page that could not be fetched, or on a page I could not decode. Not for presentation as data.
- Ratios are gear ratios as printed on the source page (input:output). "Main", "final" and "axle" are the final drive as printed. Where a page is silent, the cell says "not stated". Nothing has been filled in from memory.
- Quality grades: **OEM** = manufacturer page; **Wiki** = Wikipedia; **Spec** = parts or spec aggregator; **Listing** = vendor or used-car listing; **Forum** = forum.
- Where two `[SRC]` sources conflict, both are shown and the conflict is flagged.
- Some printed values look non-monotonic (for example 5th higher than 4th). They are reproduced as printed and flagged.

---

## 1. Manual transmissions

### 1.1 4-speed manual

Sourced (1 set, short of 3):

**Ford Mustang SROD (single rail overdrive), 1979–1983 Mustang GT 5.0 302 [SRC, Steeda guide, Spec/aftermarket retailer]**
https://www.steeda.com/mustang-manual-transmission-guide

| Years | 1st | 2nd | 3rd | 4th | Reverse |
|---|---|---|---|---|---|
| 1979–1983 | 3.07 | 1.72 | 1.00 | 0.70 | 3.07 (as printed) |

Final drive: not stated on the page. The page lists the 5th as "absent" because it is a 4-speed. The printed reverse equals 1st; treat with care.

Leads that were not fetched (all `[UNVERIFIED]`, snippet only):
- Richmond Super T-10 racing 4-speed: 2.64 / 1.75 / 1.34 / 1.00, reverse 2.55; and 2.43 / 1.61 / 1.23 / 1.00, reverse 2.35. JEGS listing returned 403. https://JEGS.com/p/Richmond-Gear/Richmond-4-Speed-Super-T-10-Transmissions/746183/10002/-1
- 1965 factory 4-speed (manufacturer not named): 2.56 / 1.91 / 1.48 / 1.00, reverse 2.64. NCRS forum. https://www.tst.forums.ncrs.org/forum/technical-discussion-archives/19531-munci-gear-ratio-calculations
- 1968 Pontiac 428 4-speed: 1st 2.52, 2nd 1.88 (standard); close-ratio option 2.20, 1.64. firstgenfirebird.org returned 403. https://firstgenfirebird.org/?p=1353
- Getrag 4-speed 3.86 / 2.20 / 1.40 / 1.00 and AMC SR4 3.50 / 2.21 / 1.43 / 1.00. GTPlanet guide, not fetched. https://www.gtplanet.net/forum/threads/the-gearing-guide.282712/latest

**Gap: 1 sourced 4-speed set, 1 transmission. Needs 2 more.**

### 1.2 5-speed manual

**Sporty: Ford Mustang Tremec T-5 and T-45 [SRC, Steeda guide]**
https://www.steeda.com/mustang-manual-transmission-guide

| Transmission, years | 1st | 2nd | 3rd | 4th | 5th | Reverse |
|---|---|---|---|---|---|---|
| T-5, 1983½ | 2.95 | 1.94 | 1.34 | 1.00 | 0.73 | 2.76 |
| T-5, 1984 | 2.95 | 1.94 | 1.34 | 1.00 | 0.63 | 2.76 |
| T-5, 1985–1988 | 3.35 | 1.93 | 1.29 | 1.00 | 0.68 | 3.15 |
| T-5, 1989–1995 | 3.35 | 1.93 | 1.29 | 1.00 | 0.68 | 3.15 |
| T-45, 1996–2001 (GT, Cobra 4.6 4V, Bullitt) | 3.37 | 1.99 | 1.33 | 1.00 | 0.67 | 3.22 |

- Conflict flagged: the same page's 1993 Cobra / Cobra R table gives 2.95 / 1.94 / 1.34 / 1.00 / 0.63, reverse 2.76, against 3.35 / 1.93 / 1.29 / 1.00 / 0.68 for the 1989–1995 row.
- The page lists 6th as absent for all T-5 and T-45 rows.
- Final drive: not stated.

**Truck: GM / Dodge NV3500 5-speed [SRC, Wiki and Spec]**
- https://www.dieselhub.com/transmission/nv3500.html (fetched)
- https://en.wikipedia.org/wiki/New_Venture_Gear_3500_transmission (fetched)

| Variant | 1st | 2nd | 3rd | 4th | 5th | Reverse | Applications (as listed) |
|---|---|---|---|---|---|---|---|
| Wide ratio (MG5) | 4.02 | 2.32 | 1.40 | 1.00 | 0.73 | 3.55 | GM C/K 1993–98 and Silverado/Sierra 1500 & 2500LD 1999–2006; Dodge Ram 1500 1994–2004 |
| Close ratio (M50) | 3.49 | 2.16 | 1.40 | 1.00 | 0.73 | 3.55 | GM S-10 / Blazer 1993–2003 (4.3 V6); Dodge Ram 2500 LD 1994–95 |
| Close ratio HD | 3.49 | 2.14 | 1.38 | 1.00 | 0.73 | 3.55 | Dodge Dakota 1994–2004 (340 ft-lb rated, per Wikipedia) |

- Final drive: not stated on either page.
- Both pages agree on every figure.

**Gap: sporty 5-speed has 2 sourced transmissions (T-5, T-45). Truck 5-speed has 1 transmission with 3 sets. Honda Civic EK9 Type R 5-speed (1st 3.230 / 2nd 2.105 / 3rd 1.458 / 4th 1.107 / 5th 0.848 / reverse 3.000 / final 4.400) came only from a Japanese used-car listing that did not fetch (HTTP 429). It is `[UNVERIFIED]` and not counted.**

### 1.3 6-speed manual (beyond MX-5 ND and S2000)

Sourced, 4 transmissions. Those below are `[SRC]`.

**A. Tremec T-56 / TR-6060 family [SRC, Wiki]**
https://en.wikipedia.org/wiki/Tremec_TR-6060_transmission (fetched). The page calls the TR-6060 "derived from the Tremec T-56 six-speed manual transmission designed by BorgWarner". Its applications list is "w/o any claim of completeness". 21 rows; selected:

| Application (as listed) | 1st | 2nd | 3rd | 4th | 5th | 6th | Reverse |
|---|---|---|---|---|---|---|---|
| 2008–2013 Chevrolet Corvette | 2.66 | 1.78 | 1.30 | 1.00 | 0.74 | 0.50 | 2.90 |
| 2016–2024 Chevrolet Camaro SS | 2.66 | 1.78 | 1.30 | 1.00 | 0.74 | 0.50 | 2.90 |
| 2012–2015 Chevrolet Camaro ZL1 | 2.66 | 1.78 | 1.30 | 1.00 | 0.80 | 0.63 | 2.90 |
| 2009–2023 Dodge Challenger 5.7/6.1/6.4 | 2.97 | 2.10 | 1.46 | 1.00 | 0.74 | 0.50 | 3.28 |
| "2015-2923" Dodge Challenger Hellcat (year as printed; page typo) | 2.26 | 1.58 | 1.19 | 1.00 | 0.76 | 0.63 | 2.90 |
| 2022–present Cadillac CT4-V Blackwing | 2.66 | 1.78 | 1.30 | 1.00 | 0.80 | 0.63 | 2.90 |
| 2022–present Cadillac CT5-V Blackwing | 2.29 | 1.61 | 1.21 | 1.00 | 0.82 | 0.54 | 3.11 |
| 2009–2013 Chevrolet Corvette ZR1 | 2.29 | 1.61 | 1.21 | 1.00 | 0.82 | 0.68 | 3.11 |

- Final drive: not stated for any row.
- Conflict flagged: Steeda lists the 2007–2010 Shelby GT500 at 2.97 / 1.78 / 1.30 / 1.00 / 0.80 / 0.63 with reverse 3.28, and Wikipedia's first row for the same application reads reverse 2.90. Steeda also lists 2011–2012 GT500 reverse 3.28 and 2013–2014 GT500 reverse 2.90 (Wikipedia prints 3.98 for both GT500 rows). Check the part number before using the reverse figure.

Steeda (same URL as 1.2) also gives T-56/TR-6060 rows: 2003–2004 SVT Terminator Cobra (2.66 / 1.78 / 1.30 / 1.00 / 0.80 / 0.63, reverse 2.90); 2011–2012 Shelby GT500 (2.97 / 1.78 / 1.30 / 1.00 / 0.74 / 0.50, reverse 3.28); 2013–2014 Shelby GT500 (2.66 / 1.82 / 1.30 / 1.00 / 0.77 / 0.50, reverse 2.90).

**B. Getrag MT-82, Ford Mustang [SRC, Steeda]**

| Application (as listed) | 1st | 2nd | 3rd | 4th | 5th | 6th | Reverse |
|---|---|---|---|---|---|---|---|
| 2011–2017 5.0 V8 | 3.66 | 2.43 | 1.69 | 1.32 | 1.00 | 0.65 | 3.32 |
| 2011–2017 3.7 V6 | 4.24 | 2.54 | 1.66 | 1.24 | 1.00 | 0.70 | 3.32 |
| 2015–2017 2.3 EcoBoost | 4.24 | 2.54 | 1.66 | 1.24 | 1.00 | 0.70 | 3.32 |
| 2018–2021 5.0 V8 | 3.237 | 2.104 | 1.422 | 1.000 | 0.814 | 0.622 | 3.32 |
| 2018–2021 2.3 EcoBoost | 3.237 | 2.104 | 1.422 | 1.000 | 0.814 | 0.622 | 3.32 |

**C. Tremec TR-3160, 2015–2020 Shelby GT350 / GT350R [SRC, Steeda]**
3.25 / 2.23 / 1.61 / 1.24 / 1.00 / 0.63; reverse 2.95. Final drive not stated.

**D. Honda Civic Type R, 6-speed manual, Honda's 2024 spec page [SRC, OEM]**
https://www.hondainfocenter.com/2024/civic-type-r/feature-guide/civic-type-r-specifications/ (fetched)
- 1st 3.625 / 2nd 2.115 / 3rd 1.529 / 4th 1.125 / 5th 0.911 / 6th 0.734 / Reverse 3.757.
- Final drive **3.842** (as printed on the Honda page).
- Conflict flagged: CarBuzz (via AOL, search snippet) says the close-ratio six-speed uses **4.11:1** final drive. The 2024 page's model name is what it is; the search snippets disagreed on whether these gears belong to the FK8 or FL5 generation. Use the page as it stands.

Not counted (snippet only): Honda S2000 and MX-5 ND rows from the first pass stay `[SNIP]` as before.

### 1.4 7-speed manual

**Gap: no sourced table.**
- Snippet only, `[UNVERIFIED]`: 2021 Ford Bronco optional Getrag 7-speed (6+1 crawler), crawler 6.588 / 1st 4.238 / 2nd 2.365 / 3rd 1.453 / 4th 1.000 / 5th 0.776 / 6th 0.646 / reverse 5.625. The search result attributes this to MotorTrend. I did not fetch the article.
- Tremec TR-6070 (a 7-speed manual) was named but its ratios were not retrieved.
- Tremec's 7-speed RWD manual page (tremec.com/?p=1016) was in results but not fetched.

### 1.5 Close-ratio racing gearsets

Sourced, aftermarket (not stock):

**Quaife Mazda RX-7 FC close-ratio synchromesh gearkit, non-turbo [SRC, Listing]**
https://shop.quaife.co.uk/mazda-rx7-5-speed-close-ratio-synchromesh-quaife-gearkit (fetched)

| Set | 1st | 2nd | 3rd | 4th | 5th | Reverse |
|---|---|---|---|---|---|---|
| A | 2.345 | 1.544 | 1.222 | 1.000 | 0.868 | not stated |
| B | 2.564 | 1.670 | 1.273 | 1.000 | 0.794 | not stated |

Final drive: not stated. The page says "FC variant", not FD.

**Hewland FTR family (5/6-speed racing gearbox), option tables [SRC, OEM]**
https://motorsport.hewland.com/upcp_product/ftr-200/ (fetched). The page lists per-gear **option** part numbers, not a single fixed set. Selected:
- Final drive (crownwheel and pinion), 6-speed: 3.889 / 3.444 / 2.833. 5-speed: 3.444 / 2.833.
- 1st options, 6-speed: 3.167 down to 2.417 (e.g. 2.583, 2.750, 2.917).
- 2nd options: 2.500 down to 1.625.
- 3rd to 6th standard options: 0.889 to 1.500.
- Weight 40 kg (6-speed). Torque "up to 325 Nm / 240 lb.ft (dependent on FD)". Selector order R-N-1-2-3-4-5-6.
- Reverse ratio not stated.

**Gap: dogleg racing has 0 sourced tables.** The Quaife QBE62G dogleg replacement was named in a search result without a ratio table. A Quaife 5-speed kit with 2.308 / 1.688 / 1.389 / 1.200 / 1.045 appeared in a snippet with no application named. `[UNVERIFIED]`.

### 1.6 Sequential dog boxes (5, 6, 7-speed)

**5-speed: Quaife Mitsubishi Lancer Evo 4–9 rally sequential [SRC, Listing]**
https://shop.quaife.co.uk/shop/gearboxes/sequential/qbe6u/ (fetched)
- 1st 3.000 / 2nd 2.000 / 3rd 1.470 / 4th 1.111 / 5th 0.857. Reverse not stated.
- Final drive 4.308 or 4.143 (listed; default not stated). Replaces the factory H-pattern box. Weight 20 kg.

**6-speed: Quaife Honda FK2 / FK8 Type R sequential [SRC, Listing]**
https://shop.quaife.co.uk/shop/gearboxes/sequential/qbe10j/ (fetched)
- Row 1: 1st 2.769 / 2nd 1.944 / 3rd 1.476 / 4th 1.182 / 5th 0.952 / 6th 0.769.
- Row 2 (4th–6th only): 1.227 / 1.042 / 0.920. Page does not label the rows as options; it says "a choice of gearing".
- Final drive options 3.706 and 4.143 (not linked to a ratio set). Reverse not stated.

**6-speed: Hewland FTR family (see 1.5).**

**7-speed sequential: 0 sourced.** Not searched in this pass. The Porsche 7DT-45 PDK is a robotic DCT, not a dog box (see section 4).

---

## 2. Rotary (Mazda RX-7, RX-8) manuals

**RX-7 FC: Quaife close-ratio kit (1.5 above) [SRC]**. This is the only fetched rotary manual ratio in this pass, and it is aftermarket for the FC generation, not stock FD.

**RX-7 FD stock 5-speed: not sourced.**
- `[UNVERIFIED]` OS Giken listing (justjap.com), FD3S 1993–2002 stock: 3.483 / 2.015 / 1.391 / 1.000 / 0.806. https://justjap.com/products/os-giken-5-speed-cross-gear-set-with-input-shaft-mazda-rx-7-fd3s-r15m-d
- The same vendor family lists an aftermarket set 2.578 / 1.772 / 1.289 / 1.000 / 0.821 for the FC3S (torqen.uk listing). That is aftermarket and FC, not stock FD.
- rx7.com and racingbeat.com were not usable (racingbeat returned 403).

**RX-8 6-speed (RC4): not sourced.**
- mazda-specs.pages.dev RC4 page fetched [SRC], but it gives no gear ratio figures. It says "Gear Ratios: Close-ratio" only. https://mazda-specs.pages.dev/rx-8/2003-2012/rc4-trans/specs
- `[UNVERIFIED]` snippets: early cars 3.76 / 2.27 / 1.65 / 1.19 / 1.00 / 0.84, reverse 3.56, final 4.44. Later (2009+) cars 3.82 / 2.26 / 1.54 / 1.18 / 1.00 / 0.79, reverse 3.60, final 4.78. Sources conflict on the final drive for the 2008 model year (4.444 vs 4.777 vs 4.78). Not fetched. Mazda USA spec PDF (portal.mazdausa.com) was in results and not fetched.

---

## 3. Motorcycle sequential (5 and 6-speed)

**Yamaha YZF-R1, 2004, 6-speed [SRC, Spec]**
https://www.totalmotorcycle.com/motorcyclespecshandbook/yamaha/2004-yamaha-YZF-R1.htm (fetched)
- 1st 2.533 / 2nd 2.063 / 3rd 1.762 / 4th 1.522 / 5th 1.364 / 6th 1.269. The page prints third as "3th" (typo).
- Primary 65/43 = 1.512.
- Final drive: chain 45/17 = 2.647.
- Conflict flagged: blog-hosted spec copies show 47/17 = 2.765 `[UNVERIFIED]`.
- Gearbox type not named on the page; six ratios implies six-speed.

**Honda CBR600RR: 0 sourced.**
- The owner's manual PDF (bike-parts.fr, `CBR600RRG_RAG_EN/.../0124.pdf`) was fetched but its content streams were compressed and could not be decoded. Not used. https://www.bike-parts.fr/thumbs/pdf_url/img/owner_manuals/owner_CBR600RRG_RAG_EN/2500_2500/0124.pdf
- `[UNVERIFIED]` snippet from the manual's text: 2.750 / 2.000 / 1.666 / 1.444 / 1.304 / 1.208; primary 2.111; final 2.625. Model year not confirmed from the file.
- `[UNVERIFIED]` 2003 forum post: 2.666 / 1.937 / 1.661 / 1.409 / 1.285 / 1.666, final 2.625. The poster says 6th looks like a misprint.
- `[UNVERIFIED]` JT Sprockets 16/42 = 2.625 and 16/43 = 2.69 (sprocket standard ratios).
- ultimatespecs and motorcycledb CBR600RR 2004 pages were in results and not fetched.

**Kawasaki Ninja, Suzuki and other sport 600/1000 boxes: not searched.**

**Gap: 1 sourced motorcycle set (R1 2004).**

---

## 4. Dual-clutch transmissions (DCT)

### 4.1 6-speed wet DCT

**VW DQ250 (wet, 6-speed), 3 sources, 2 conflicting [SRC]**

(a) volkswagen-specs.pages.dev, Passat 2011–2014 DQ250 [SRC, Spec; site names no source]
https://volkswagen-specs.pages.dev/passat/2011-2014/dq250-trans/specs
- 1st 3.46 / 2nd 2.05 / 3rd 1.37 / 4th 1.03 / 5th 0.84 / 6th 0.68. Reverse and final drive not listed.
- The same site's Passat page gives fluid capacity as 7.2 L in one place and 7 L in another. Treat as low confidence.

(b) gearboxlist.com, VW Passat B6 2008 2.0 TDI (example only) [SRC, Spec]
https://gearboxlist.com/volkswagen/dq250/
- Main (final) 4.118 / 3.043. 1st 3.462 / 2nd 2.050 / 3rd 1.300 / 4th 0.902 / 5th 0.914 / 6th 0.756. Reverse 3.987.
- Torque "up to 350 (400) Nm". Codes 02E (FWD) and 0D9 (AWD), not linked to the table.
- Conflict flagged: 3rd to 6th differ from (a). 4th 0.902 is below 5th 0.914, which looks like a page error.

**Getrag 6DCT450, Ford PowerShift (2011 Kuga 2.0 diesel example) [SRC, Spec]**
https://gearboxlist.com/getrag/6dct450/ (fetched)
- Main 4.533 / 3.238. 1st 3.583 / 2nd 1.952 / 3rd 1.194 / 4th 0.842 / 5th 0.943 / 6th 0.789. Reverse 4.843.
- Torque "up to 450 Nm". Engine up to 2.5 L. The page lists the unit as "Ford Powershift or MPS6".
- Flag: 5th (0.943) is higher than 4th (0.842) as printed.

**Ford MPS6 / PowerShift (2012 Mondeo 2.0 EcoBoost example) [SRC, Spec]**
https://gearboxlist.com/ford/mps6/ (fetched)
- Main 3.933 / 2.682. 1st 3.818 / 2nd 2.150 / 3rd 1.407 / 4th 1.029 / 5th 1.188 / 6th 0.971. Reverse 5.283.
- Flag: 5th (1.188) is higher than 4th (1.029) as printed.
- The page calls this a clone of the Getrag 6DCT450, succeeded by MPS6i / 6DCT451 from 2014.

**Nissan GT-R 6-speed DCT (Ricardo, GR6): 0 sourced.** CarExpert and ECUTEK pages were in results; the ECUTEK TCM tuning guide has a "Gear Ratios" section but its numbers were not in the returned text. Not counted.

### 4.2 7-speed DCT

**VW DQ500 (wet, 7-speed) [SRC, Spec]**
https://gearboxlist.com/volkswagen/dq500/ (fetched). Example: Golf R360S 2017, 2.0 TSI.
- Main 4.059 / 3.450 (two values printed, not linked). 1st 3.562 / 2nd 2.526 / 3rd 1.678 / 4th 1.022 / 5th 0.788 / 6th 0.761 / 7th 0.635. Reverse 2.789.
- Torque "up to 500 (600) Nm". Variants 0BH (PQ35), 0DL (MQB), 0BT (Transporter).
- Conflict flagged: Audi RS5 and RS4 spec pages in search results (`[UNVERIFIED]`) give 1st 3.50 / 2nd 2.18 / 3rd 1.52 and a different set. Not used.

**VW DQ381 (dry, 7-speed, "DSG 7 0GC") [SRC, Spec]**
https://gearboxlist.com/volkswagen/dq381/ (fetched). Example: Taos 2021, 1.4 TSI.
- Main 4.813 / 3.667. 1st 3.190 / 2nd 2.750 / 3rd 1.897 / 4th 1.040 / 5th 0.793 / 6th 0.860 / 7th 0.661. Reverse 2.900.
- Torque "up to 420 Nm".
- Flag: 6th (0.860) is higher than 5th (0.793) as printed.

**Mercedes 7G-DCT, 724.0 (preselective 7-speed) [SRC, Spec]**
https://gearboxlist.com/mercedes/7g-dct-724-0/ (fetched). Example: A-Class 2020, 2.0 L.
- Main 4.130. 1st 3.857 / 2nd 2.429 / 3rd 1.536 / 4th 1.049 / 5th 0.776 / 6th 0.604 / 7th 0.480. Reverse 3.375.
- Torque up to 350 Nm (AMG version up to 475 Nm). Applications: A, B, CLA, GLA, GLB, Infiniti Q30 / QX30.

**Porsche PDK, ZF 7DT-45 (7-speed preselective robotic) [SRC, Spec]**
https://gearboxlist.com/zf/7dt-45/ (fetched). Example: 2014 Cayman 3.4 L.
- Main 3.25. 1st 3.91 / 2nd 2.29 / 3rd 1.65 / 4th 1.30 / 5th 1.08 / 6th 0.88 / 7th 0.62. Reverse 3.55.
- Torque up to 500 Nm (engines up to 4.0 L). Versions 7DT45FL / HL / HLA, not linked to models.
- Other PDK sets in results, not counted: 991.2 Carrera 4 Cabriolet (AWD) rear axle 3.09 and 1st 3.91 ... 7th 0.62 (Stuttcars, `[UNVERIFIED]` snippet); 718 Spyder 1st 3.91 ... 6th 0.88 (Porsche newsroom PDF returned a DNS error and was not fetched); 991 GT3 (Rennlist forum, `[UNVERIFIED]`).
- Flag: the 3.25 main in the gearboxlist page and 3.09 in the Stuttcars page are for different cars and drivelines.

**Ferrari 458 7DCL750 (Getrag 7-speed): 0 numeric.** go4trans.com page fetched in search only; it says first, seventh and final drive are chosen per application and gives no numbers. Rated 750 Nm per a forum post `[UNVERIFIED]`.

**McLaren SSG and Lamborghini 7-speed: not searched in this pass.**

---

## 5. Torque-converter automatics

### 5.1 4-speed

**GM 4L60E (also 4L65E / 4L70E note) [SRC, Wiki, Spec, Spec]**
- https://www.dieselhub.com/trans/4l60e.html (fetched; the primary table source)
- https://en.wikipedia.org/wiki/4L60-E (fetched; the article has a single-source maintenance tag)
- https://gearboxlist.com/gm/4l60/ (fetched; example 2008 Tahoe 5.3 L)

| Gear | Ratio (all three sources agree) |
|---|---|
| 1st | 3.059 |
| 2nd | 1.625 |
| 3rd | 1.000 |
| 4th | 0.696 |
| Reverse | 2.294 |

- Final drive: gearboxlist 2008 Tahoe 5.3 L = **3.73** (listed as "Main"). Wikipedia's only stated final drive is the 2005–06 Pontiac GTO with 4L65E, **3.46**.
- Stall: dieselhub Table 1 gives a **stall ratio of 1.84 to 2.34**. Neither dieselhub nor Wikipedia gives a stall speed in rpm.
- Lock-up: dieselhub says "Yes, actuated by electric solenoid (TCC solenoid)", normally open. A PWM apply-feel solenoid was added in 1995.
- Converter: 298 mm (11.73 in) for non-LS; 300 mm (11.81 in) for LS and for 4L65E / 4L70E. Wikipedia gives 360 lb-ft torque rating for the 4L60E and 380 lb-ft for the 4L65E.
- Gap: this is the only 4-speed TC unit sourced. Need 2 more.

### 5.2 5-speed

**GM / Allison 1000, 2001–2005 five-speed version [SRC, Spec]**
https://www.dieselhub.com/trans/allison-1000.html (fetched)
- 1st 3.094 / 2nd 1.809 / 3rd 1.406 / 4th 1.00 / 5th 0.711 / Reverse 4.48.
- Applications: GMC Sierra 2500HD / 3500HD and Chevrolet Silverado HD with 6.6 L Duramax.
- Final drive, stall speed, converter: not stated.
- Gap: 1 sourced 5-speed TC unit.

### 5.3 6-speed

Four sourced units.

**GM 6L80 / 6L90 [SRC, Wiki]** (also gearboxlist 6L80 `[SRC]`)
https://en.wikipedia.org/wiki/GM_6L80_transmission (fetched)
- 6L80 / 6L90: 1st 4.027 / 2nd 2.364 / 3rd 1.532 / 4th 1.152 / 5th 0.852 / 6th 0.667 / Reverse 3.064.
- 6L45 / 6L50: 4.065 / 2.371 / 1.551 / 1.157 / 0.853 / 0.674; reverse 3.200.
- ZF 6HP (reference): 4.171 / 2.340 / 1.521 / 1.143 / 0.867 / 0.691; reverse 3.403.
- Lock-up: "a torque converter lock-up for all 6 forward gears". Converter spec and stall: not stated.
- Final drive: gearboxlist 2010 Tahoe 5.3 L = 3.08 (`[SRC]`, https://gearboxlist.com/gm/6l80/).

**Ford 6R80 (also 6R60, 6R140 row) [SRC, Wiki]**
https://en.wikipedia.org/wiki/Ford_6R_transmission (fetched)
- 6R 60 / 6R 80 row: R -3.403 / 1st 4.171 / 2nd 2.340 / 3rd 1.521 / 4th 1.143 / 5th 0.867 / 6th 0.691. Nominal span 6.035.
- 6R 140 row: R -3.128 / 3.974 / 2.318 / 1.516 / 1.149 / 0.858 / 0.674. Span 5.899.
- Maximum input torque 600 N·m and 800 N·m (the page does not split these for 6R 60 vs 6R 80). 6R 140: 1,400 N·m.
- Lock-up: "a torque converter lock-up for all 6 forward gears". Stall: not stated.
- Diesel applications listed: Ford Ranger (2011–present, 2.2 and 3.2 diesel), Mazda BT-50 (2011–present, diesel), Ford Everest (2015–present, diesel). The page's applications list is marked incomplete.

**Toyota U660E / U760E / U661E / U760F [SRC, Wiki]**
https://en.wikipedia.org/wiki/Toyota_U_transmission (fetched)
- U660E: 3.300 / 1.900 / 1.421 / 1.000 / 0.713 / 0.609; reverse 4.148. Final drive varies by model: Avalon 08–12 3.685; Avalon 13–15 3.238; Camry 08–11 3.685; Camry 12–15 3.458; Sienna 11–15 3.935; Venza 09–15 4.398; Highlander 14–15 4.154; Lotus Evora 3.685.
- U760E/F: 3.300 / 1.900 / 1.420 / 1.000 / 0.713 / 0.608; reverse 4.148; final 3.815 (single value). U661E/F: final FWD 3.888, AWD 4.117.
- The earlier snippet had a 3.300 / 1.900 / 1.421 set `[UNVERIFIED]`; the Wikipedia table agrees.
- Lock-up, stall, converter: not stated on the page.

**Allison 1000, 2006–2019 six-speed [SRC, Spec]** (same page as 5.2)
- 1st 3.094 / 2nd 1.809 / 3rd 1.406 / 4th 1.00 / 5th 0.711 / 6th 0.614 ("double overdrive, 2006 MY+"); reverse 4.48.
- Final drive: not stated.

### 5.4 7-speed TC

**Gap: 0 sourced.** The 7G-TRONIC rows in mercedes-specs pages (1st 4.38 ... reverse 3.42) appeared in a search result only, `[UNVERIFIED]`.

### 5.5 8-speed TC

**ZF 8HP family (11 variants, Wikipedia)** — already `[SRC]` in `gearboxes-and-cars.md` section 3.3. Not repeated.

**Aisin / Toyota 8-speed family [SRC, Wiki]**
https://en.wikipedia.org/wiki/Aisin%E2%80%93Toyota_8-speed_automatic_transmission (fetched)

| Unit (year) | R1 | 1st | 2nd | 3rd | 4th | 5th | 6th | 7th | 8th | Layout |
|---|---|---|---|---|---|---|---|---|---|---|
| AA80E / TL-80SN (2006) | -4.056 | 4.597 | 2.724 | 1.864 | 1.464 | 1.231 | 1.000 | 0.824 | 0.685 | Long |
| AB80E/F (2015) | -3.786 | 4.796 | 2.811 | 1.844 | 1.429 | 1.214 | 1.000 | 0.818 | 0.672 | Long |
| AL80E/F (2023) | -3.646 | 4.413 | 2.808 | 1.950 | 1.511 | 1.274 | 1.000 | 0.793 | 0.652 | Long |
| UA80E/F, AW F8 F45 (2016) | -4.221 | 5.519 | 3.184 | 2.050 | 1.492 | 1.235 | 1.000 | 0.801 | 0.673 | Transverse |
| UB80E/F, AW F8 F35 (2016) | -4.015 | 5.250 | 3.029 | 1.950 | 1.457 | 1.221 | 1.000 | 0.809 | 0.673 | Transverse |

- Reverse gear 2 (R2) is printed for some rows; the page says it "will most likely not be used".
- Final drive: the page's drivetrain column is scraped and not mapped cleanly to models. Application-level pairs from the Applications section: GS F 2.937; RC F 3.133; IS 500 F Sport Performance 3.133; GS 350 2.937; IS 350 RWD 3.133; CTS 2.85 (`[SRC]` for the pairing as printed).
- Lock-up, stall, converter: not stated.

**GM 8L90 [SRC, Spec]**
https://www.dieselhub.com/transmission/8l90.html (fetched)
- 1st 4.56 / 2nd 2.97 / 3rd 2.08 / 4th 1.69 / 5th 1.27 / 6th 1.00 / 7th 0.85 / 8th 0.65 / reverse 3.82. (GM's own 8L90 page, seen in search, gives the same numbers `[UNVERIFIED]` as fetched.)
- Converter: 258 mm (10.16 in). Max input torque 635 to 738 lb-ft depending on application. Stall: not stated. Lock-up: not stated.
- Final drive: not stated.
- Applications listed: 2015–present Colorado / Canyon, Silverado 1500, Sierra 1500; 2017–present Express / Savana (2.8 L diesel); 2015–2017 Escalade, Yukon Denali.

### 5.6 9-speed TC

**ZF 9HP (9HP 28 and 9HP 48, one shared table) [SRC, Wiki]**
https://en.wikipedia.org/wiki/ZF_9HP_transmission (fetched)
- Reverse -3.8049; 1st 4.7001 / 2nd 2.8419 / 3rd 1.9094 / 4th 1.3818 / 5th 1.0000 / 6th 0.8081 / 7th 0.6995 / 8th 0.5802 / 9th 0.4792.
- Nominal span 9.8085; effective 7.9402; span centre 1.5007; average step 1.3303.
- Torque: 280 N·m (both fuels, 78 kg); 450 N·m petrol and 480 N·m diesel (86 kg). Not mapped to 28 or 48.
- Lock-up: **absent** from the article. Converter specification (stall, diameter): **absent**. The article calls it a hydraulic torque converter.
- Applications listed (incomplete): Acura TLX, MDX; Alfa Tonale; Chrysler Pacifica, Voyager; Honda Civic (diesel 2018–22), CR-V (diesel), Pilot, Ridgeline, Passport; Jeep Cherokee, Renegade, Compass; Land Rover Evoque, Discovery Sport; Jaguar E-Pace; Nissan Pathfinder (2022–). Gearboxlist (search snippet) also places 9HP48 in Jeep, Honda, Nissan, Jaguar and Land Rover.
- BMW fitment could not be confirmed from the sources retrieved.
- Gap: 1 sourced 9-speed unit (2 variants).

### 5.7 10-speed TC

**Ford / GM 10-speed family [SRC, Wiki]**
https://en.wikipedia.org/wiki/Ford%E2%80%93GM_10-speed_automatic_transmission (fetched). Forward gears only; no final drive given for any unit.

| Unit (first year) | R | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Ford 10R80 / GM 10L80 / GM 10L90 (2017 / 2017 / 2018) | -4.866 | 4.696 | 2.985 | 2.146 | 1.769 | 1.520 | 1.275 | 1.000 | 0.854 | 0.689 | 0.636 |
| Ford 10R140 (2020) | -4.695 | 4.615 | 2.919 | 2.132 | 1.773 | 1.519 | 1.277 | 1.000 | 0.851 | 0.687 | 0.632 |
| GM 10L1000, Allison (2020) | -4.545 | 4.538 | 2.868 | 2.061 | 1.715 | 1.482 | 1.258 | 1.000 | 0.851 | 0.688 | 0.632 |
| Ford 10R60 (2020) | -4.885 | 4.714 | 2.997 | 2.149 | 1.769 | 1.521 | 1.275 | 1.000 | 0.853 | 0.689 | 0.636 |

- Applications: 10R80 — F-150 (2017–present), Mustang, Expedition, Navigator, Ranger, Transit, VW Amarok (2023–). 10L80 — Suburban, Escalade, Tahoe, Yukon Denali (2018–), Camaro SS (2019–24), Silverado/Sierra 1500 (2019–). 10L90 — Camaro ZL1 (2017–24), CT6 (2019–20), CT5 and CT4 (2020–). 10R140 — Super Duty (2020–). 10L1000 — Silverado HD / Sierra HD (2020–). 10R60 — Explorer, Bronco, Ranger (2024–).

**GM 10L90, Cadillac CT5-V Blackwing example [SRC, Spec]**
https://gearboxlist.com/gm/10l90/ (fetched)
- Main 2.85. 1st 4.696 / 2nd 2.985 / 3rd 2.146 / **4th 1.800** / 5th 1.520 / 6th 1.275 / 7th 1.000 / 8th 0.854 / 9th 0.689 / 10th 0.636. Reverse 4.886.
- Torque "up to 900 Nm" (engines up to 6.2 L). Stall and converter: not stated.
- Conflict flagged: 4th is 1.800 here and 1.769 in the Wikipedia row that includes 10L90.

### 5.8 Stall speed and lock-up summary (sourced only)

| Unit | Stall | Lock-up | Converter | Source |
|---|---|---|---|---|
| 4L60E | Ratio 1.84–2.34 (no rpm) | Electric TCC solenoid, normally open; PWM apply-feel from 1995 | 298 mm / 300 mm | dieselhub `[SRC]` |
| 6L80 / 6L90 | not stated | All six gears | not stated | Wikipedia `[SRC]` |
| 6R80 | not stated | All six gears | 600 / 800 N·m rating (not split) | Wikipedia `[SRC]` |
| 8L90 | not stated | not stated | 258 mm, 635–738 lb-ft | dieselhub `[SRC]` |
| 9HP | not stated | Absent from article | hydraulic, no spec | Wikipedia `[SRC]` |
| 10L90 | not stated | not stated | 900 N·m rating | gearboxlist `[SRC]` |

---

## 6. Diesel pickup automatics

**GM / Allison 1000, Duramax 6.6 L (2001–2005 5-speed, 2006–2019 6-speed)** `[SRC]` (see 5.2 and 5.3). 2 transmission-level sets from one page.

**Ford 6R80 (Ranger, BT-50, Everest diesel)** `[SRC]` (see 5.3).

Gap: 2 sourced diesel-pickup transmissions. Need 1 more. The Getrag 6DCT450 (Kuga 2.0 diesel) is a DCT and is in section 4.1.

---

## 7. CVT

**Subaru Lineartronic (family range only) [SRC, Wiki]**
https://en.wikipedia.org/wiki/List_of_Subaru_transmissions (fetched)
- "Gear Ratio Range: 3.581:1 - 0.570:1 (varies by trim and vehicle)". Spread about 6.28:1.
- Final drive: 3.7:1 (listed separately).
- Virtual gears: 6 or 7 (with diesel) or 8 manual "virtual" steps.
- TR580 and TR690 have torque ratings only (250 N·m and 400 N·m); no separate ratio ranges.
- Gap: family-level range only, no per-model table.

**Nissan Xtronic: 0 sourced.**
- Nissan's archive page https://www.nissan-global.com/EN/INNOVATION/TECHNOLOGY/ARCHIVE/XTRONIC_CVT/ was fetched `[SRC]`; it gives no low or high ratio figures. It defines ratio range as low ratio divided by high ratio.
- `[UNVERIFIED]` search snippet from a Nissan training document: 3.5 L class low 2.371 / high 0.439; 2.0 L 2.349 / 0.394; 1.5–1.8 L 2.561 / 0.427. Not fetched.

**Toyota (Super CVT-i and K-series) [SRC, Wiki]**
https://en.wikipedia.org/wiki/Super_CVT%e2%80%90i (fetched)

| Unit | Low | O/D | Reverse | Final drive as printed | Vehicles (as listed) |
|---|---|---|---|---|---|
| K311 (2006), Corolla Axio 1.8 L ZRE142 | 2.386 | 0.411 | 2.505 | 5.698 (1.8 L Corolla 2ZR-FE; 1.5 L Allion/Premio 1NZ-FE); 5.356 (1.8 L Allion/Premio 2ZR-FE) | Corolla, Corolla Cross, Altis, C-HR, Vios, Yaris (K312 also) |
| K410 (2004) | 2.4 | 0.43 | 2.505 | 5.833 (1.0 L 1KR-FE); 5.08 (1.3 L 1NR-FE) | Belta, Vitz |
| K120 Direct Shift (2018) | 3.377 / 2.206 / 1.9 / 1.6 / 1.3 / 1.0 / 0.8 / 0.65 / 0.5 / 0.447 | — | — | not stated | Yaris (XP210), Corolla E210 2.0 L, Camry XV70/XV80 2.0 L, RAV4, Harrier, Lexus ES 200 / UX 200 |

- K120: the page lists ten ratios under the gear-ratio heading but does not say whether they are belt range or stepped virtual steps. Not labelled low or O/D.
- Pulley range (K320, `[UNVERIFIED]`): 2.236 to 0.447, final 4.007 (toyota-club.net FAQ, snippet).
- Prius (planetary, not belt) is not covered by the Super CVT-i page.

---

## 8. Fetch failures and skipped sources

- 403 Forbidden: racingbeat.com (RX-7 transmission), jegs.com (Richmond T-10), firstgenfirebird.org (Pontiac 4-speed), curbsideclassic.com (4-speed article), shop.quaife.co.uk pages were fine.
- 404: moderndriveline.com T-56 Magnum page; en.wikipedia.org/wiki/ZF_9HP (the correct title is ZF_9HP_transmission).
- 429 Too Many Requests: goo-net-exchange.com (Honda Civic Type R EK9 listing). Retry-After 86400.
- DNS error: download.newsroom.porsche.com (718 Spyder PDK PDF).
- Undecodable: bike-parts.fr CBR600RR owner's manual PDF (compressed content streams).
- Search results that did not lead to fetched tables: Nissan GT-R GR6 ratios (ECUTEK guide, CarExpert), Ferrari 7DCL750 ratio list (go4trans), McLaren SSG, Lamborghini, Ninja ZX-6R, Yamaha R1 (other years), Toyota Aisin 8-speed (AA80E 4th to 8th confirmed via Wiki instead).

Figures carried from the first pass (`gearboxes-and-cars.md`) and not re-verified here: MX-5 ND, Honda S2000 AP1/AP2 (`[SNIP]`), ZF 8HP table (`[SRC]`), Ford 10R80 (`[SNIP]`, now confirmed `[SRC]` by the Wikipedia row above), Yamaha R6 2006 (`[SNIP]`), Tesla, Taycan, Porsche 991 notes.

---

## 9. Combined summary

`[SRC]` counts are distinct ratio sets (or units) read from fetched pages in this pass. "Sets" for family tables are counted by row.

| Type | Speeds | Example (car / engine) | Sourced sets (`[SRC]`) | Gap |
|---|---|---|---|---|
| Manual, 4-speed | 4 | Mustang SROD 1979–83, 5.0 302 | 1 | Needs 2 more |
| Manual, 5-speed sporty | 5 | Mustang Tremec T-5 (1983–95), T-45 (1996–2001) | 5 (2 transmissions) | Needs 1 more transmission |
| Manual, 5-speed truck | 5 | GM / Dodge NV3500 (wide, close, HD) | 3 (1 transmission) | Needs 2 more transmissions |
| Manual, 6-speed (beyond MX-5/S2000) | 6 | Tremec T-56 / TR-6060 (Corvette, Camaro, Challenger, GT500, CT5-V), Getrag MT-82 (Mustang), TR-3160 (GT350), Honda Civic Type R 2024 | 21 TR-6060 rows + 5 MT-82 + 1 TR-3160 + 1 Honda | Met |
| Manual, 7-speed | 7 | none sourced (Bronco Getrag 6+1 `[UNVERIFIED]`) | 0 | Needs 3 |
| Manual, close-ratio racing | 4–6 | Quaife RX-7 FC close-ratio kit, sets A and B (aftermarket) | 2 (1 kit) | Needs 2 more |
| Manual, dogleg racing | 5 | none sourced | 0 | Needs 3 |
| Sequential dog box, 5-speed | 5 | Quaife Mitsubishi Evo 4–9 rally sequential | 1 | Needs 2 more |
| Sequential dog box, 6-speed | 6 | Hewland FTR-200 family (option tables); Quaife Honda FK2/FK8 sequential | 2 | Needs 1 more |
| Sequential dog box, 7-speed | 7 | none | 0 | Needs 3 |
| DCT wet, 6-speed | 6 | VW DQ250 (Passat B6 2.0 TDI, 2 sources), Getrag 6DCT450 (Kuga 2.0 diesel), Ford MPS6 (Mondeo 2.0 EcoBoost) | 4 sets, 3 units | Met (with conflicts flagged) |
| DCT, 7-speed | 7 | VW DQ500 (Golf R360S), VW DQ381 (Taos 1.4 TSI), Mercedes 7G-DCT 724.0 (A-Class 2.0), Porsche PDK ZF 7DT-45 (Cayman 3.4) | 4 units | Met |
| DCT, Ferrari 7-speed (7DCL750) | 7 | 458 Italia, no numbers | 0 | Needs 3 |
| DCT, McLaren 7-speed / Lamborghini 7-speed | 7 | not searched | 0 | Needs 3 |
| DCT, Nissan GT-R GR6 | 6 | Ricardo GR6, no numbers | 0 | Needs 3 |
| TC auto, 4-speed | 4 | GM 4L60E (dieselhub, Wikipedia, gearboxlist) | 1 unit (3 pages) | Needs 2 more units |
| TC auto, 5-speed | 5 | Allison 1000 (2001–05, Duramax) | 1 unit | Needs 2 more |
| TC auto, 6-speed | 6 | GM 6L80/6L90, Ford 6R80, Toyota U660E / U760E, Allison 1000 (2006–19) | 4 units | Met |
| TC auto, 7-speed | 7 | none sourced | 0 | Needs 3 |
| TC auto, 8-speed | 8 | ZF 8HP (11 variants, from first pass), Aisin AA80E family (5 rows), GM 8L90 | 3 units | Met |
| TC auto, 9-speed | 9 | ZF 9HP (9HP 28 and 9HP 48, one table) | 1 unit (2 variants) | Needs 2 more |
| TC auto, 10-speed | 10 | Ford 10R80 / GM 10L80 / 10L90, Ford 10R140, GM 10L1000 (Allison), Ford 10R60, GM 10L90 (gearboxlist) | 5 sets, 4 units | Met |
| CVT | variable | Subaru Lineartronic (range only), Toyota Super CVT-i (K311, K410, K120), Nissan Xtronic (no numbers) | Toyota 3 sets (1 page); Subaru 1 (family range); Nissan 0 | Subaru and Nissan need per-model data |
| Motorcycle, 6-speed sequential | 6 | Yamaha YZF-R1 2004 | 1 | CBR600RR 0 sourced; Ninja 0 |
| Diesel pickup auto | 5–6 | GM / Allison 1000 Duramax (5 and 6-speed); Ford 6R80 (Ranger, BT-50 diesel) | 3 sets, 2 transmissions | Needs 1 more transmission |
| Rotary manual, RX-7 | 5 | Quaife FC close-ratio kit (aftermarket) | 2 (1 kit) | Stock FD 0 sourced |
| Rotary manual, RX-8 | 6 | Mazda RC4 (page gives "Close-ratio" only) | 0 | Needs 3 |

Categories that still lack 3 sourced examples: 4-speed manual (1), 5-speed sporty (2 transmissions), 5-speed truck (1 transmission), 7-speed manual (0), close-ratio racing manual (1 kit), dogleg racing (0), 5-speed sequential (1), 6-speed sequential (2), 7-speed sequential (0), Ferrari / McLaren / Lamborghini 7-speed (0), Nissan GT-R 6-speed DCT (0), 4-speed TC (1 unit), 5-speed TC (1 unit), 7-speed TC (0), 9-speed TC (1 unit), Subaru and Nissan CVT per-model (0 to 1), CBR600RR and other motorcycles (1 total), diesel pickup (2 transmissions), RX-7 FD and RX-8 stock manuals (0).

Categories that meet 3 or more: 6-speed manual beyond MX-5/S2000, 6-speed DCT, 7-speed DCT, 6-speed TC, 8-speed TC, 10-speed TC.
