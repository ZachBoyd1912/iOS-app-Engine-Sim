# Can Piston Forge be released commercially? What Manus's terms say

Checked 15/11/2026. This is a reading of the published terms, not legal advice. A solicitor
should confirm before money is made from the game.

## Short answer

The terms say the game is ours. Manus's Terms of Use state that the user owns the output and
Manus claims no ownership of it. Nothing in the terms that were read restricts selling or
giving away an exported project on the App Store. Three things remain our own risk, listed
below.

## Source

Manus Terms of Use, https://manus.im/terms, "Last updated: 28 September 2026". Contracting
company: Butterfly Effect Pte. Ltd. Governing law: Singapore (section 12.1). The page only
renders with JavaScript, so it was read in a real browser and a dated text copy is kept in
`manus-terms-of-use-2026-11-15.txt` next to this file.

## The clauses that matter (quoted)

**Ownership, section 5.2:**
> "The Company does not claim ownership of any Input or Output (collectively, "Your Content").
> Subject to Section 5.3, as between the Company and you, you are the owner of all right,
> title and interest in Your Content."

and again in the intellectual property section:
> "Please note, we do not own any of your Input or Output (as described in Section 5.2 above)."

**The limits Manus puts on that, same section 5.2:**
> "(a) Output may not be unique across users and the Services may generate the same or similar
> output for another user under similar terms; and (b) the Company does not represent or
> warrant that the Output is protectable by any intellectual property rights under applicable law."

**Licence we give Manus, section 5.3:** a "non-exclusive, worldwide, royalty-free ...
sublicensable ... right to copy, display, upload, perform, distribute, store, modify, and
otherwise use Your Content to provide, maintain, develop and improve the Services". It is
non-exclusive, so it does not stop us publishing, and the clause says it "does not imply our
endorsement or ownership of Your Content".

**No warranty on the output:** "all Output is provided "as is" and with "all faults"". The user
also indemnifies Manus (section 10) for losses relating to the user's use.

**Trademarks:** ""Manus", "Butterfly Effect", and all related stylizations, graphics, logos,
service marks and trade names ... may not be used without permission in connection with your,
or any third-party's, products or services."

**Help centre, for what it adds:** the article "Do I own the assets ... generated via Manus?"
says "You are free to use your Output for personal or commercial purposes, subject to
applicable laws and third-party rights." A help article is not the contract, but it matches it.

## What this means for Piston Forge

1. **We own the game code Manus generated**, as far as Manus is concerned. Commercial release is
   not restricted by the terms read. Free or paid makes no difference in the text.
2. **Do not use the Manus name or logo** in the store listing, the game, or marketing. The
   listing draft does not. Inside the app the name appears only as the internal name of a font
   file ("ManusCC0"), which players never see.
3. **Manus's preview tooling is not ours.** The folders `scripts/manus-tuning/`,
   `scripts/__manus__/` and `scripts/manus-game-sharing/` are Manus's own service code rather
   than output generated for the game. They are development-only. The built app was unpacked
   and checked on 15/11/2026: none of that tooling is inside it.
4. **The font.** The export bundles "ManusCC0" fonts with a CC0 1.0 licence file, which
   allows any use including commercial. No public statement from Manus about the font's origin
   was found, so the licence file in the export is the only evidence.

## What stays our own risk

- **Someone else's rights.** Manus does not promise the generated code or designs are free of
  third-party rights. The game was built to an "original only" brief (no real car designs,
  logos, recordings or third-party models), and the reference apps were used for feature
  categories only. That lowers the risk; it does not remove it.
- **Uniqueness.** Manus says the same or similar output could be generated for another user.
  Most of the code written since the export (the phone layer, save protection, coach card) is
  ours and not Manus output.
- **Terms can change.** The dated copy shows what applied when the game was built.

## Recommended before release

1. Ask Manus support in writing: "May a game built in Manus be published on the Apple App
   Store, free and later paid, with all Manus tooling and branding removed?" Keep the reply.
2. Before submission, delete the three Manus tooling folders and the Manus build scripts from
   the repository so the shipped project is only our own code and CC0 fonts. This ends the
   ability to reopen the project in Manus, so it is Zach's call.
3. If the game earns money, have a solicitor read sections 5 and 10.
