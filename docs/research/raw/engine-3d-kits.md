# Engine 3D kits: free / cheap model research

Date of research: 2026-11-18. Scope: free or cheap 3D models of engines and engine components for the iOS engine-tuning simulator (App Store / sideload, commercial-ish use).

## 1. Method and limits (read this first)

- **Sketchfab Data API (api.sketchfab.com/v3/search)** was the main source. It was queried with `downloadable=true` and `licenses=cc0` or `licenses=by` (Sketchfab's CC Attribution label). Each query returned only the **first page (24 results)**. Results are fuzzy; multi-word queries often returned zero results, so single-word queries were used. Coverage is therefore partial, not exhaustive.
- **Licence column**: "CC Attribution" is the label Sketchfab's API returns for the CC BY family. For the items opened individually (see section 3, marked "API detail") the licence URL read was `creativecommons.org/licenses/by/4.0/` (CC BY 4.0). Items marked "label only" were **not opened** - the licence is the API label, not read from the page.
- **Triangle count**: the API returns `faceCount` (polygons). Triangles are roughly 1.5-2x faces. The `archives` (format) key was absent for most results, so **formats are unknown** unless stated.
- **Download**: the API reports `isDownloadable: true` for every result. I did **not** test a download. My understanding (not verified in this session) is that Sketchfab's file-download endpoint needs an authenticated API token, so a developer account would be needed for bulk pulls.
- **Separate moving parts**: confirmed only where the description says so. Otherwise "not verified".
- **Brand marks**: checked only on items opened individually. Title-based brand flags are listed in section 4 and must be checked by opening the model.
- **Sites that refused automated fetch** (HTTP 403/404): GrabCAD, Free3D, OpenGameArt node 141769, Smithsonian 3d.si.edu, cqparts GitHub URL, BlenderKit (redirected). Their licences are **not verified** and they are not in the usable table.
- **CC BY is not a clearance for trademarks.** A CC BY model with a Ferrari, Toyota, Lamborghini or Porsche logo is still a trademark risk in a commercial app. The licence says nothing about marks.

## 2. Summary

| Layout / part | Usable candidates (CC0 or CC BY, no brand flag, label or detail checked) | Notes |
|---|---|---|
| I3 | 0 | Not searched directly. One "Three Cylinder Motorcycle Engine" seen in a result list (CC Attribution label, no UID, not opened). |
| I4 | 6 | Best: "Engine" (JuanG3D), API detail verified. |
| I5 | 0 | Not searched directly. |
| I6 | 0 complete engines (1 crankshaft) | Crankshaft I6/V12 (OUTPISTON) verified. |
| V6 (60/90) | 1 | "V6 car engine with engine [MoreThem]" - copyright holder KitBash; check before use. |
| V8 (cross/flat) | 3 | "Animated Engine V8" verified (exports as .abc, not glb). |
| V10 | 0 standalone | Only whole cars (Audi R8 V10) found. |
| V12 | 2 | "(FREE) V12 - 12 Cylinder V-Engine" and "[Free] RWD V12 Engine" (label only). |
| W12 | 0 | Not searched directly. |
| W16 | 0 standalone | Bugatti Mistral results are whole cars with brand names. |
| Flat-4 | 0 clean | "GT-86 Engine" (DRIVER-FIRE) is brand-flagged (Toyota/Subaru) and layout unverified. |
| Flat-6 (boxer) | 0 clean | "F6 Boxer Engine" carries a non-CC condition - rejected pending clarification. |
| Flat-8 | 0 | None found. |
| VR6 | 0 standalone | Only VW cars found. |
| Rotary | 1 (layout unverified) | "Rotary Engine" (kyou0086), 1.66M faces - probably too heavy. |
| Radial | 5 | Layout is radial, but these are not automotive. |
| Motorcycle twin / triple / four | 2 clean | "Motorbike Engine" (lunea), "Bike Engine" (roy.3dartist). Layout unverified. |
| Turbochargers | ~14 | Many CC BY turbos, mixed poly counts. |
| Superchargers | ~3 | Roots / twin-screw / centrifugal not distinguished. |
| Intercoolers | 0 clean | Only a Volvo truck intercooler (brand). |
| Intake manifolds | 2 clean | Others are brand-flagged. |
| Exhaust headers / manifolds | ~4 manifold + ~5 exhaust/muffler | Log / tubular / equal-length not distinguished. |
| Mufflers | ~2 | See above. |
| Catalytic converter | 1 (CC0) | Science Museum Group, 1982-83 type. |
| Wastegate / blow-off valve | 0 | Not found. |
| ECU | 1 | "ECUS" (acaonweb3d). Bosch DF1 ECU is brand-flagged. |
| Fuel injectors | 3 | Mostly simplified / low detail. |
| Spark plugs | ~14 | CC BY, mixed detail. |
| Alternator | ~10 | CC BY, mixed detail. |
| Radiator | 1 | Low detail. |
| Crankshafts | ~13 | Several scans and game models. |
| Pistons / rods | ~10 | Piston + rod assemblies found. |
| Camshafts | ~6 | Plus cam followers and bearings (fasteng). |
| Valves (poppet) | 0 standalone | Valves appear only inside full-engine packs. |
| Rocker arms | 0 | Not found. |
| Pushrods | 0 | Only suspension pushrods found. |
| Timing chains | 0 | Not searched directly. |
| Flywheel | 4 | |
| Clutch | 1 | Single clutch plate (Er.Praveen.Kumar). |
| Manual gearbox | ~10 | Several tflexcad and designwithboi items. |
| Automatic gearbox | 0 clean | "Turbo Hydramatic 400" (Rysky) is CC BY but brand-flagged (GM). |
| DCT | 0 | "DCT SHIFTER" is a shifter lever, not a DCT. |

Counts are candidate counts from first-page results. They are not quality-checked.

## 3. USABLE candidates

### 3a. Verified by opening the API detail (licence URL read)

| Name | URL | Part / layout | Licence | Download | Faces (API) | Separate parts | Formats | Brand marks | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Engine (JuanG3D) | https://sketchfab.com/3d-models/36c1f32d649c46df9f2f8b4d34cf32c7 | Complete engine, I4 (4 pistons) | CC BY 4.0 (API detail) | Flag true, not tested | 195,285 (verts 110,526) | Description: "4 pistons, 4 connecting rods, crankshaft and flywheel". Separation not confirmed. | Not listed | None found | Made in Moment Of Inspiration 2. Good I4 candidate. |
| Animated Engine V8 (meeww) | https://sketchfab.com/3d-models/b0dbf778b81e4afba4edf11336e2a099 | Complete engine, V8 | CC BY 4.0 (API detail) | Flag true, not tested | 157,680 (verts 78,589) | Multiple objects per description; constraint-animated (not rigid body). Tags: piston, crankshaft, flywheel, sparkplug, manifold, belt. | Description says exported as **.abc** (Alembic) - needs conversion to glb. | None | Credit appreciated. Good V8 reference. |
| Detailed Engine Components Pack (mujtaba.abbasi.pk) | https://sketchfab.com/3d-models/957cd4e295614071bfe3d861f2fde8aa | Component kit: pistons, crank, gears, valves, block parts | CC BY 4.0 (API detail) | Flag true, not tested | **1,883,522** (verts 941,647) | Description lists pistons, crankshaft, gears, valves, block parts. Separation not confirmed. | No archives key | None mentioned | Far too heavy for mobile as-is. Decimate heavily if used. |
| Crankshaft \| I6/V12 (OUTPISTON) | https://sketchfab.com/3d-models/840520859c7e4b158afe679111393004 | Crankshaft, I6 / V12 | CC BY 4.0 (API detail) | Flag true | 29,236 (verts 14,620) | Single crank | Not listed | None | Description gives crank-pin radius 35 mm, pin length 50 mm, overall length 700 mm. Best crank with stated dimensions. |
| Catalytic converter, 1982-1983 (Science Museum Group) | https://sketchfab.com/3d-models/5e59f014795748e5b8354d6321eaf082 | Catalytic converter | **CC0 1.0** (API detail, licence URL read) | Flag true | 60,000 (verts 30,002) | Not stated; one texture, one material | Not listed | None on the part. Samsung credited as digitisation funder only. | Only CC0 engine-bay part found. Check mesh cleanliness and whether it is a single mesh. |
| F6 Boxer Engine (scudmorello) | https://sketchfab.com/3d-models/5700259eeb494b8f8a0b8f63486c59cc | Flat-6 boxer | CC BY label, **but** description adds: must not modify, overlap or remove the "Morello" name or horse icon | Flag true | 80,528 (verts 49,389) | Not stated | Not listed | Morello, Porsche, Subaru named in description | **Conditional / rejected pending clarification.** An extra condition on a CC BY licence conflicts with CC BY 4.0 terms. |
| V6 car engine with engine [MoreThem] (Blendoriano) | https://sketchfab.com/3d-models/7309cf5e6b07435c962f954513ca170e | V6 | CC BY 4.0 (API detail; copyright holder listed as KitBash SF Operations LLC) | Page shows download button, 3,086 downloads | 1,290,656 faces (API) / 1.3M triangles (page) | Not confirmed | Not listed | None found on page | Page says "comprehensive set of internal components" but does not name them. Copyright holder is a commercial kit company; check their terms before use. |

### 3b. Label only (CC Attribution / CC0 from the API; page NOT opened)

Licence = Sketchfab API label. URL pattern: https://sketchfab.com/3d-models/<uid> (not tested in a browser). Brand flag is title-based only.

**Complete engines**

| Name | UID | Author | Licence label | Faces | Layout | Notes |
|---|---|---|---|---|---|---|
| Inline-4 Engine | 64c16a336bd74b2db337ca03bc156f7a | rafaelaraujo55 | CC Attribution | 187,414 | I4 | |
| 4 Cylinder Engine | 448e9e6fdd0c469ba14573f1a35c2ee0 | devkrsm | CC Attribution | 57,136 | I4 | |
| Four Cylinder Engine | b06ecbd3c1a641b6bd5fdc3c30d7c588 | ChinmaySingh | CC Attribution | 706,236 | I4 | Heavy |
| Rigged 4-Cylinder Engine (FREE) | e14ebe68273d49a3becda6802270b4b0 | david.gnzlv | CC Attribution | 78,832 | I4 | Title says rigged (animation rig). |
| Inline-4 Engine Modelling & Rigging Study | 652cf3def1ae40b7a6e546e62ed19778 | s1d.fx0 | CC Attribution | 27,864 | I4 | Study piece; check completeness. |
| Engine Low Poly game-ready | b1245affff464d599289292ce4788eeb | ʟ н σ ʂ τ | CC Attribution | 68,027 | Unknown | Layout not in title. |
| V8 Motorbike Engine | 8f0aff30f0f748619ae4fa2fd8778125 | roy.3dartist | CC Attribution | 1,881,945 | V8 | Title says motorbike; too heavy. |
| (FREE) V12 - 12 Cylinder V-Engine | e3508e360b5041c5972d78c9b04907e3 | Exonl | CC Attribution | 461,756 | V12 | |
| [Free] RWD V12 Engine | c6810aad10cb400993b6492bc8bbd33f | Dev365TH | CC Attribution | 91,324 | V12 | |
| Rotary Engine | fae8a079080c49669502fda3621e893e | kyou0086 | CC Attribution | 1,656,832 | Rotary (layout unverified) | Too heavy as-is. |
| Radial 7-cyl Diesel Engine | f5e004dd0ef54ac580b27f04c22b9f40 | jxstnxlll | CC Attribution | 169,919 | Radial | Not automotive. |
| Radial Engine Mechanism | 654aa59996b64cb0a9fb1466a07fe2cb | trinityscsp | CC Attribution | 172,616 | Radial | Mechanism, not full engine. |
| 3d Printable Radial Pneumatic Engine | 3cbddbecd6c5462391e9936a3ccd7d32 | Slava Z. | CC Attribution | 111,620 | Radial | |
| radial engine | 25b49d63734748f7a37da9e065da2f72 | basharnazzal | CC Attribution | 2,251,655 | Radial | Too heavy. |
| Sturgeon Double Piston Engine | d5fe887d07044054885562ca37602a39 | trinityscsp | CC Attribution | 151,652 | Opposed-piston (not in target list) | |
| Opposed Piston Engine Mechanism | 5457fd510d54454085a548776397666d | trinityscsp | CC Attribution | 145,660 | Opposed-piston (not in target list) | |
| Motorbike Engine | 33db399c34ef4d61bd93d422b1c0c92e | lunea | CC Attribution | 76,344 | Motorcycle (layout unverified) | |
| Bike Engine | 0dd210b3ef244aa1ae7da8918e53619f | roy.3dartist | CC Attribution | 10,831 | Motorcycle (layout unverified) | |
| Three Cylinder Motorcycle Engine | (no UID seen) | | CC Attribution (seen in a result list, not opened) | unknown | Motorcycle I3 | Need UID before use. |
| Engine (kreion "v6") | f9405aee91664d03b298a66d05fab988 | kreion | CC Attribution | 213,768 | Unclear | Title is only "v6"; not confirmed as an engine. Not counted. |

**Crankshafts (label only)**

| Name | UID | Author | Faces | Notes |
|---|---|---|---|---|
| CRANKSHAFT | 5d73705abcd047a789f9d0ea546058ea | VR DESIGNER | 99,790 | |
| Crankshaft 3D Scan | a1e1bc2fd1fe412ba624146b142c0017 | GoMeasure3D | 1,032,570 | Scan; decimate. |
| Crankshaft Baked Anim / Anim Vilebrequin | caf53ce76a0142199bc629395c4a92de | Davy Chang | 274,624 | Animated. |
| Crankshaft_Pistons | 34d438b4d0d94e63b8ffea3ef0398d51 | fasteng | 7,185 | Low detail. |
| Crankshaft_ Pistons | ef6a621b9638451681f861cf7bf84391 | mediabrandbook | 79,646 | |
| CRANKSHAFT | a3d8b494358a403688e3ab280c17d67e | Anton Alpha Mathew | 63,888 | |
| Old Broken Crankshaft | 6222bb1682324013954011d980a99ab9 | djpc820 | 249,999 | Damaged model; check. |
| Crankshaft | 5e2c551a8a2d46b4b30485e2d9beeb41 | satriek | 12,374 | |
| Crankshaft | 97772ceec97e40b69ea9a4db8c7a0536 | kecheng | 14,260 | |
| Crankshaft | 95aec545a37144beaf660a947da82337 | dilkaarrow | 5,543 | |
| Crankshaft | 9be407f052db4f66950d1b5ff4762c45 | fvaler | 892 | Too low for hero use. |
| V8 cross-plane crankshaft | dffcd58d45174232b46877988531cf3b | arnero | 11,000 | Title gives V8 cross-plane - good for V8 cross-plane. |

**Pistons, rods, camshafts, flywheels, clutch, gearboxes (label only)**

| Name | UID | Author | Faces | Part | Notes |
|---|---|---|---|---|---|
| Piston and connecting rod | 940d24ffb7864be898963391665fcc9f | francobravo | 11,608 | Piston + rod | |
| Piston Full | bf600da36ad44fd7a7c96ceb0c732cf5 | spsvision | 19,344 | Piston | |
| PISTON | f7878b113c284a359daf9b1e4c4a2515 | VR DESIGNER | 59,486 | Piston | |
| PISTON HEAD | c184d4cb35354964b544dd37096ad3a5 | VR DESIGNER | 32,202 | Piston | |
| Piston - Low Poly | 1060eb5de89d4f30bdfe54fc026f9755 | JiggleSticks | 60,152 | Piston | |
| Piston for engine | 1519606057de48ffbaed38ed90175c40 | Lame3dModels | 3,804 | Piston | |
| Working Piston-Rod | d7f881fdd8b5466c9e1150708195ff5e | roy.3dartist | 44,282 | Piston + rod | |
| Piston | e3e4dc6c56544bfebe8806a3fbc7c83f | outpiston | 234,060 | Piston | |
| Piston | 127bf425bb82481287d1ca850bc76d17 | Res1n | 473,936 | Piston | |
| Camshaft | 1f1c66b214834f9887aab1ecb3111149 | IUI-UniversityLibrary | 80,482 | Camshaft | |
| Camshaft Box | d7d58bd9804446599adefd8cc1a172bd | IUI-UniversityLibrary | 48,620 | Cam housing | |
| Camshaft | e2b9a94a6dc4410ba9d06ea2016b9fdf | fasteng | 12,842 | Camshaft | |
| Camshaft | d8086cf5b99c4e2ab0ceb12ff6848cc5 | dilkaarrow | 3,566 | Camshaft | |
| Cam Sahaft | 5eb05fd366744d43bf575033d8c474b2 | Askutty | 31,296 | Camshaft | |
| Flywheel | c95495190e724887802b6ca4f7905eb8 | vr.designer_09 | 68,906 | Flywheel | |
| Flywheel | c40398c7433b490197c566075b89e9a8 | outpiston | 53,076 | Flywheel | |
| Flywheel with Cylinder | 2d60d641ab7348249a523bdc0587c85b | patspet | 21,692 | Flywheel | |
| Flywheel | a7e4c864455a4cb5b68c158fd5e7ec6f | ItzKii | 2,708 | Flywheel | |
| Single Clutch Plate Assembly in Solidworks | f0323440d10140c2817aa4abe9af5dc2 | Er.Praveen.Kumar | 443,459 | Clutch | |
| Gearbox Assembly | 5c59e88ece0340d4a5b01b6c8496aafe | designwithboi | 46,968 | Manual gearbox | |
| Manual Transmission Gearbox With Differential | d48d46543d844857b31475e56f941410 | avredu | 346,767 | Manual gearbox + diff | |
| Mini Gearbox | 923e143af03b4db5bb34c9aeb551acf8 | fasteng | 37,936 | Gearbox | |
| Gearbox | 329f6830284840ecb8d8343e5ffd3776 | mmaamm | 27,284 | Gearbox | |
| Gearbox (Conical) | 60f023924ee0456daa758eb590b6064b | tflexcad | 608,606 | Gear set | Engineering kit style. |
| Gearbox (Planetary) | 2bee7992d266456aaef1f1394b0ebb98 | tflexcad | 382,906 | Planetary gear set | |
| Warm Gearbox | e7fedd86a90b4c46a53fe88882e66aa3 | tflexcad | 240,380 | Gearbox | |
| Herringbone Gearbox Drive | 8ed85c6e3484430a9af202a703afd94c | bhavsarakshar28 | 41,556 | Gear drive | |
| GearBox | d28e75a6e2574ecaa1980420b1fc92c2 | zaza117 | 8,278 | Gearbox | |

**Turbochargers, superchargers, intake, exhaust, ECU, injectors, spark plugs, alternators, radiator (label only)**

| Name | UID | Author | Faces | Part | Notes |
|---|---|---|---|---|---|
| Turbocharger | 624d65ab867c473aa6e53d3659f231a9 | _JooL_ | 10,820 | Turbo | |
| Turbocharger | a0e1624d1229423395716014fcb98fde | Heisenberg Labs | 21,916 | Turbo | |
| Turbocharger | 8c7fcc0da3614cb0af5c19c6d9a3637e | Lame3D models | 48,219 | Turbo | |
| Turbocharger | adaff01860a14e078ae5ccea05cb0df0 | Lauri Grekula | 10,402 | Turbo | |
| Turbocharger (w/ supports) | e1167ee56af249d49334e6b0bfda7e3f | arjuntripathi2k10 | 14,642 | Turbo | |
| Turbocharger Compressor Wheel | 2c0669ec71a54ec4a3d909ceb5bcf884 | Marcel | 22,223 | Compressor wheel | |
| Basic Turbo Charger | 414dd8615bb24b798807fd187cedfe73 | Angus Whitburn | 13,249 | Turbo | |
| Engine Turbocharger | fb7acbcc169e4ee095d309aea008bb63 | BROTHERFUL | 9,580 | Turbo | |
| TURBOCHARGER | 4e22e0217ee847caafabd9a239ce94a7 | VR DESIGNER | 553,884 | Turbo | Heavy. |
| TURBOCHARGER TURBINE | dd92e61bd8294e87bd381b1834e4d18f | VR DESIGNER | 197,116 | Turbine wheel | |
| Car Turbocharger | 086dde202cd7436cbae2ba77c2a4549b | ml-design | 276,102 | Turbo | |
| Car Turbocharger | d6b04f7d370c444792c312db95684cdd | Kappa_3D | 805,876 | Turbo | Heavy. |
| Sci-fi turbocharger | 071da6d19c7541d7b3a87c3bc12085ca | Nokken | 16,532 | Turbo | Stylised, not automotive. |
| Supercharger | c933b86e30ac4b13b519230c74eeea39 | TheJzuken | 22,118 | Supercharger | Type not stated. |
| Impeller | cfdc150d16314406b2c21b172608d9e5 | Steven Samuel | 108,024 | Compressor impeller | |
| Exhaust Manifold | e207a050afef44b8805e88acfa439cd7 | hoxsvl | 635,704 | Exhaust manifold | Heavy. |
| Exhaust manifold | 94d0ac53e94a496686d78d54e7b00b85 | La_Grekula | 11,516 | Exhaust manifold | |
| Exhaust Manifold | ec292e27aa3b4c13ab6c1f0f748b831e | AnsysLearn | 94,786 | Exhaust manifold | |
| EXHAUST MANIFOLD | b7ffccf1ceac48eaa941537fe54a25cd | vr.designer_09 | 323,140 | Exhaust manifold | |
| Car muffler exhaust | 2c859b615d024e968e3196f5c631f91c | Silver10211 | 68,548 | Muffler | |
| MUFFLER & EXHAUST | 8e7403032ecb4ea49c590b3dc4aa5ebc | vr.designer_09 | 57,158 | Muffler | |
| Exhaust System | f4ac64c4e0364cc7a5e0b4126727503e | kryoxshade | 28,108 | Exhaust system | |
| Intake Manifold | f3c587cad2264d57982393abe584913d | DRIVER-FIRE | 14,858 | Intake manifold | |
| Engine Intake Manifold - by Creality Otter Lite | 4d92dc6c2065454e88cfb75456e43500 | creality3dscanner | 7,458,284 | Intake manifold (scan) | Far too heavy. |
| ECUS | 4ce9d58084cb4099bd8ac22c3e166c78 | acaonweb3d | 499,990 | ECU (several) | |
| Fuel Injector | f12b4bee65774605a297bea80fcec92b | BladeManEXE10 | 4,504 | Injector | |
| Fuel Injector - Simplified | 5cb4820bb5ee44c28c903bc434742763 | reyn.ad | 1,232 | Injector | Simplified. |
| Spark Plug | 34b6b7a766f044878a5329f4f6d3e539 | ghostbusterjeffrey | 38,880 | Spark plug | |
| Spark Plug | e4bcb0763e704adb897132e703b27507 | JiggleSticks | 50,334 | Spark plug | |
| Spark Plug | 398d4795562544f28e2efb2066876776 | flow3d | 18,312 | Spark plug | |
| Spark plug from Poly by Google | c1347b956f484145a4d45ea97373b381 | ie-niels | 4,796 | Spark plug | Poly by Google origin; label only. |
| Spark Plug | 3f6f16d07a214a32b6316bf9d57ba104 | valtabohm | 401,258 | Spark plug | |
| Spark_plug-3D Model | b000c4aaf1154c25a4ab5a804df06d47 | Yuvan16 | 862,752 | Spark plug | |
| Car alternator | c7ddcec7798349d5abcdb84002a64340 | unrealengine432 | 1,319,604 | Alternator | Heavy. |
| Alternator | e94842c63e6b4557a20f5751779c7e7f | B0bik | 147,482 | Alternator | |
| Alternator | 4f3258f5264b46b1b839d992ca1bad68 | Rickoseptian | 156,434 | Alternator | |
| Alternator | d2789bf232614301a0325c864706e0e6 | dilkaarrow | 7,734 | Alternator | |
| Alternator | 3cdda49cf89a4574b4eeb7613a374f03 | budidebby | 1,444 | Alternator | |
| Alternator-prototype | 4cf63ad932c44fa99103a30d1a4ddee0 | Nothingness2 | 17,388 | Alternator | |
| Farit M - Alternator | 3247bbcdc38f459d8671d3e022e9fddb | Farit.M | 1,284 | Alternator | |
| Alternator | aa66f85cff60443ea36c93a8ccd9ef84 | BrettDow | 1,482,107 | Alternator | Heavy. |
| Engine Radiator | 590a29882e764c368c857ebaba4fd01b | Terllok | 812 | Radiator | Very low detail. |

## 4. USABLE WITH BRAND CAUTION (CC licence OK; trademark/brand check needed before use)

Title-based flags. Open each model and check for logos, badges and grilles before use. A CC licence does not cover trademarks.

| Name | UID | Author | Licence label | Faces | Brand in title | Relevance |
|---|---|---|---|---|---|---|
| Engine Lamborghini V12 6.5L/19L SDC (FREE) | 16d4a2d9ee954bdd8ccf71fcf647b52b | SDC PERFORMANCE | CC Attribution | 107,750 | Lamborghini | V12 |
| V8 Hemi Intake Manifold | 3941c51c04fe48bc9ac05bafba91cb01 | Lame3dModels | CC Attribution | 1,440 | Hemi (Chrysler) | V8 intake |
| Pro LS Turbo Manifold | 57ae5f5d271747fe8097569759a1a3e7 | brian-aa | CC Attribution | 19,448 | LS (GM) | Turbo manifold |
| Intake Manifold 4AGE Small Port | 9a1845e27b3c4e829ff60e7b87dee0df | superCnight | CC Attribution | 11,978 | Toyota 4AGE | I4 intake |
| Car Engine 4 Cylinder - Toyota 1ZZ-FE | 3442d69b82b6416389eff8e961dfe333 | zarrarabbas73 | CC Attribution | 460,493 | Toyota | I4 |
| Toyota 1ZZ-FE - Complete Engine Block - 3D Scan | 0746cac279b24dea90e3bc952e8d0614 | sylvester.bartos | CC Attribution | 1,997,625 | Toyota | I4 scan; heavy |
| Toyota 2jz | 9563ead21ec54d2798fff43fd4cd99b2 | DRIVER-FIRE | CC Attribution | 303,282 | Toyota | I6 candidate |
| GT-86 Engine | a6771bc3089443779fdcdc70abff4d35 | DRIVER-FIRE | CC Attribution | 509,218 | Toyota / Subaru | Flat-4 candidate (layout unverified) |
| Crankshaft Yamaha ZR120 | 12269b1e65214cb7805ec76297ead6b1 | BO SONGPOL | CC Attribution | 15,800 | Yamaha | Crank |
| Honda CB 125 1972ish (Custom Engine) | f3b98e8cac7c4480b053f20160341fc7 | drcrazzie | CC Attribution | 53,754 | Honda | Motorcycle twin candidate |
| Honda CB175 motorcycle - Downloadable 3D scan | e69c3bd3a52c40c09e5e3048f1ddcf2f | David.Antalek | CC Attribution | 500,007 | Honda | Full bike |
| Chevy Caprice Big Block with Supercharger | cd3b774ed2414fc188fd13280087aeff | 3001105 | CC Attribution | 204,286 | Chevy | Supercharged V8 candidate |
| Engine Chevy Chevette 1977 | ef123ab4b01140179745751dab5d7864 | flow3d | CC Attribution | 439,893 | Chevy | I4 |
| Volvo B8444S Lower Intake Manifold | 1e09b33e8c224f318f37f616f9b2c478 | lunchinthetree | CC Attribution | 332,683 | Volvo | Intake |
| B8444S Upper Intake Manifold | 83e200c4b6b14d01ad146ad67801f340 | lunchinthetree | CC Attribution | 16,762 | Volvo | Intake |
| VOLVO-FH12- Intercooler | 5da23008dd4b400a924a74da76c2725f | Alien1974555 | CC Attribution | 1,485,069 | Volvo (truck) | Intercooler - only one found |
| ECU: Bosch Df1 Ecu | 007363d8220a4202ba8a7b8bef2be138 | nameiz | CC Attribution | 745,556 | Bosch | ECU |
| Valvetronic Quad Exhaust System | bb6be6106fce465698548917732c4b13 | Silver10211 | CC Attribution | 99,136 | BMW "Valvetronic" name | Exhaust |
| BMW M3 S54 Piston | e2f54827ddfd435f9f60a5d371017638 | altrous | CC Attribution | 33,141 | BMW | Piston |
| Spark plug BMW E36 | 16ae205d29784ffb879cd58f4d9084a1 | 2LegitCustoms | CC Attribution | 913,647 | BMW | Spark plug |
| Turbo Hydramatic 400 Transmission | 3fb4fc9c7d5b458e9b511dfbc2addd0d | Rysky | CC Attribution | 13,274 | GM "Turbo Hydramatic" | Only automatic gearbox found |
| Eliminator Supercharged LS-based V8 Engine | cfe6f543644b437b8a698b936c87d2a8 | DRIVER-FIRE | CC Attribution | 80,270 | "LS" (GM) | Supercharged V8 candidate |
| Engine Chevy Chevette 1977 (listed here, not in 3b) | ef123ab4b01140179745751dab5d7864 | flow3d | CC Attribution | 439,893 | Chevy | I4 |
| Rolls-Royce Merlin | 381d36b784424225a9d0b08fe61a785a | atombits_assets | CC Attribution | 652,849 | Rolls-Royce | Aero V12 |
| Rolls-Royce Merlin (RM 3SM) | 6cfd7db5a2ef4f5882e0428a5dee7e2b | davidmarton1987 | CC Attribution | 385,274 | Rolls-Royce | Aero V12 |

## 5. REJECTED

| Name | URL / UID | Licence (source) | Reason |
|---|---|---|---|
| V8 engine Internals (UnforgettableName) | f8d41716b0a641dda9151c84c7159a24 | CC Attribution-NonCommercial (API label) | NC - not allowed for commercial app. |
| Supercharged Sbc V8 Engine (revised) | 582d3f69b0f7460ea0e7d091bdf1f778 | CC Attribution-NonCommercial (API label) | NC. |
| V8 beach buggy engine (wear, low res) | https://sketchfab.com/3d-models/6293a484965c4936b7b816d69569a380 | CC BY-NC (API detail, page opened) | NC. |
| 1997 Toyota Supra RZ (OUTPISTON) | d6ed1376d91e4fd3b8e6fc061065c44f | CC BY-NC-SA (API label) | NC and SA. |
| F6 Boxer Engine (scudmorello) | 5700259eeb494b8f8a0b8f63486c59cc | CC BY label + extra condition in description | Additional restriction on the name/icon conflicts with CC BY 4.0. Hold until author clarifies. |
| Work Station (WeSVa) | 8ca477d95b554d67aae7c4fb1580dece | "Free Standard" (not a CC licence) | Not a CC licence; not an engine. |
| CGTrader / TurboSquid / RenderHub engine models (general) | various | Royalty-free or custom licences (search snippets) | Paid or custom licences; not verified individually. Not free for commercial app use without reading each licence. |
| Museum CC0 items seen (QE2 turbine pattern, steam hammer, boiler, aircraft such as SR-71, Vulcan, Lancaster, Spitfire, B-17, A-10, Vacuum pump) | e.g. 8e135c1a917c476a98f011a48c4192c7, 9fc474d5aee94b55854c9d3059775aea | CC0 (API label) | CC0, but not automotive engine parts, or whole vehicles with no separated internals. Out of scope. |

## 6. Sources checked with no usable result

| Source | What was done | Result |
|---|---|---|
| Sketchfab (Data API) | Filtered CC0 and CC BY searches, about 50 queries, first page each. Detail pulls for 8 models. | See sections 3-4. CC0 engine-related results: 1 (catalytic converter). |
| Sketchfab website search page | Not usable - JS-rendered; API used instead. | - |
| Poly Pizza (poly.pizza/search/engine) | Fetched search page. | No mechanical engine models with a visible licence. Results were game-engine packages, one cylinder, gear and oil pump (Poly by Google), and a generator. Licences not shown. Not verified. |
| GrabCAD | HTTP 403. | Not verified. Terms not read. Treated as not usable. |
| Free3D (V8 engine 554) | HTTP 403. | Not verified. |
| OpenGameArt node 141769 | HTTP 403. | Not verified. |
| Smithsonian 3d.si.edu | HTTP 403 on explorer page. Search snippets say many models are CC0 but none confirmed as an engine. | Not verified. |
| Wikimedia Commons | Search snippets only. No CC0 engine cutaway found. Commons textured 3D support described as limited. | No usable result. |
| Thingiverse / Printables | Search snippets only. Licences set per model; one NC engine seen. | Not verified individually. |
| BlenderKit (asset 2316bb62...) | Redirected to a different domain; not followed. | Not verified. |
| Kenney | Search snippet: Car Kit is CC0. | Car Kit has bodies and wheels, no engine internals. Not counted. |
| Blender Market / Superhive / Gumroad engine generators | Search snippets only. | Paid add-ons: Engine Generator (Superhive, listed GPL in snippet), Engine Generator (Gumroad, $9.99). Licences not read. |
| NASA 3D resources | Not searched. | - |
| Mixamo-style CC0 sites | Not searched. | - |

## 7. Code and parametric generators

| Project | URL | Licence | What it is | Usable for us? |
|---|---|---|---|---|
| engine-sim (ange-yaghi) | https://github.com/ange-yaghi/engine-sim | **MIT** per GitHub sidebar (LICENSE text not read) | Engine simulator (C++). README says the project has **moved** to Engine-Simulator/engine-sim-community-edition. Assets folder licence not stated on the page. The page showed no 3D model files in the root; art/assets/design folders not expanded. | Code and engine definitions may be reusable under MIT. Check the community edition's licence and the assets folder before reuse. An AlternativeTo listing (search snippet) calls it "Proprietary and Free", which conflicts with MIT. Trust the repo LICENSE. |
| CADAM benchmarks (Adam-CAD/CADAM) | https://github.com/Adam-CAD/CADAM | **GPL-3.0** (README) | Benchmark suite. README says each model is "fully parametric OpenSCAD", including a V8 with 90-degree banks, crank, pistons and rods (22 parameters). The .scad source was not read. | GPL-3.0 would copy-left any code we embed. Use as a reference only, or ask the author for a separate licence. Generated mesh outputs are a separate question. |
| cq-warehouse | https://github.com/michaelgale/cq-warehouse | **Apache-2.0** (page) | CadQuery parametric parts library (fasteners and similar). No engine generator. | Yes as a dependency for a fastener / gear / bearing pack. Not an engine generator. |
| cqparts | https://github.com/fragmuffin/cqparts | Not verified (GitHub URL returned 404) | CadQuery parametric framework. | Not verified. |
| Blender "Engine Generator" (Superhive) | https://superhivemarket.com/products/engine-generator | GPL (search snippet only) | Procedural engine generator for Blender (paid). | Paid. Licence not read. |
| Blender "Engine Generator" (Gumroad, malcd) | https://malcd.gumroad.com/l/EngineGenerator | Not read | Geometry-nodes engine generator, $9.99. | Paid. Not read. |
| Pistonpusher / Mechflow / Automech Pro | superhivemarket / blendermarket | Commercial | Animated mechanical rigs and piston add-ons. | Paid. Not read. |
| bend-n/enginesound | https://github.com/bend-n/enginesound | Not read | Procedural engine sound for Godot, not a mesh generator. | Not relevant to meshes. |

Tool licences from general knowledge, not re-verified in this session: Blender (GPL-2.0-or-later; the GPL does not extend to generated output files), OpenSCAD (GPL-2.0-or-later; output unencumbered), CadQuery (Apache-2.0), OpenCASCADE (LGPL-2.1 with exception). Verify before shipping.

## 8. GAP list (no usable free model found in this session)

Gaps are relative to this session's searches. "Not searched" means no query was run.

| Layout / part | Status |
|---|---|
| I3 | Not searched directly. One motorcycle I3 title seen without a UID. Gap for car I3. |
| I5 | Not searched directly. Gap. |
| V10 (engine only) | Gap. Only whole cars (Audi R8 V10, Santa Cruz V10 bicycle). |
| W12 | Not searched. Gap. |
| W16 (engine only) | Gap. Bugatti Mistral results are whole cars with brand names. |
| VR6 (engine only) | Gap. Only VW cars. |
| Flat-8 | Gap. None found. |
| Flat-4 boxer (clean) | Gap. GT-86 engine is brand-flagged and layout unverified. |
| Flat-6 boxer (clean) | Gap. F6 Boxer has an extra condition. |
| Rotary (clean and light) | Gap. One candidate (1.66M faces, layout unverified). |
| Motorcycle triple / four (clean) | Gap for triple (UID missing) and four. Twin: 2 candidates, layout unverified. |
| Wastegate | Gap. Not found. |
| Blow-off valve | Gap. Not found (not searched directly). |
| Standalone poppet valves | Gap. Valves only appear inside full-engine packs. |
| Rocker arms | Gap. Not found. |
| Pushrods (engine) | Gap. Only suspension pushrods. |
| Timing chain / belt | Gap. Not searched directly. |
| Automatic gearbox (clean) | Gap. Turbo Hydramatic is GM-branded. |
| DCT (dual-clutch) | Gap. Only a shifter lever found. |
| Roots / twin-screw / centrifugal superchargers (typed) | Partial. Superchargers found without type. |
| Log / tubular / equal-length headers (typed) | Partial. Exhaust manifolds found without type. |
| Intercooler (clean, car) | Gap. Only a truck intercooler, brand-flagged. |
| Radiator (usable detail) | Gap. One very low-detail model. |
| Oil pump, water pump, starter, ECU (clean and typed) | Partial. Not searched directly beyond one ECU query. |

## 9. Procedural alternative (assessment)

**Why it is probably needed.** Across about 50 API queries, the CC-licensed pool is dominated by one-off author models: different poly density (1k to 2M faces), different axes and scale, different naming, and different level of detail. A complete consistent set (every layout, shared scale, named nodes for pistons, rods, crank, cams and valves, one crank-angle driver) is not achievable by curating this pool. Mixed styles would also be visible on screen. Several candidates are scans or game-ready packs far above mobile budgets.

**Recommended approach (hybrid).**

1. Build a parametric kit, not a library of found models. Options:
   - **Blender Python (bpy)** run offline, exporting glb. Parameters: cylinder count, bank angle, bore, stroke, crank type (flat-plane / cross-plane / I6 / V12), firing order, turbo / supercharger / manifold options. Named nodes (for example `piston_1..n`, `rod_1..n`, `crank`, `cam_intake_x`, `valve_x_y`) so one crank-angle scalar drives the whole rig. Output licence is ours. Blender itself is GPL; generated files are not GPL-encumbered (general knowledge, verify).
   - **CadQuery + cq-warehouse** (Apache-2.0) for precise, dimensioned parts (crank throws, rods, gear sets). Export STEP for reference and tessellate to glb with a converter. Better for dimensions; worse for organic turbo volutes and manifold sweeps.
   - Mix the two: CadQuery for dimensioned mechanicals, Blender for turbo, manifold and exhaust geometry.
2. **Use the best CC BY 4.0 models as references, not as shipped assets** (except where a single clean part is needed, e.g. a catalytic converter from the CC0 Science Museum model). Decimate, check the model in our own style, and keep the attribution in an in-app credits screen.
3. **Engine-sim (MIT per sidebar)**: reuse the engine definitions and physics model as data if the community edition's licence agrees. Do not depend on its assets without reading the assets licence.
4. **Do not embed CADAM (GPL-3.0) code** in the app. Use it only as a reference, or ask the author for a separate licence.

**Effort and risk.** Not estimated in hours, because nothing in this session measured it. The risk is in turbo compressor and turbine geometry, manifold routing, and gearbox packaging. Pistons, rods, crank, cams and valves are straightforward parametric shapes.

**Open questions before committing.**

- Do the target poly budgets (per engine and per part) fit the device class? Set a budget first.
- Is attribution in a credits screen acceptable for CC BY assets?
- Does Zach want to ship any CC BY asset at all, or keep everything generated?

## 10. Next steps

1. Open the top candidates in a browser (uid URLs above) and record: formats offered, separate mesh names, brand marks, real triangle counts. Start with: 36c1f32d (I4 Engine), b0dbf778 (V8 Animated), 840520859c (I6/V12 crank), 5e59f014 (CC0 catalytic converter), 957cd4e2 (component pack, decimate test).
2. Confirm the licence on each candidate page before shipping; the API label was not read off the page for section 3b.
3. Query the remaining unsearched layouts and parts: I3, I5, W12, timing chain, rocker arm, valve, wastegate, blow-off valve, DCT, Roots / twin-screw / centrifugal superchargers.
4. Decide on procedural generation before more searching; the gap list is large.
