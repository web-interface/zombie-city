# English-speaking player sentiment on survivor-likes ("bullet heaven"): what earns "one more run" vs what makes people quit

Coverage note (read first):
- Main evidence = Steam "Most Helpful" (top-rated) positive/negative English reviews on steamcommunity.com review pages (fetched 2026-11-07), Steam discussion threads, patch notes (wiki copies / news re-posts), and press reviews. Helpful-vote counts are given as a proxy for how widely a view is shared.
- Reddit was NOT fetched directly (Reddit's robots.txt blocks general crawlers; I did not use mirror/proxy sites). The few Reddit points below come only from search-engine snippets and are flagged. Steam's JSON review API redirected (blocked), so I did not use it.
- Weight labels: **[Recurring]** = appears across several games and/or in multiple top-voted reviews; **[Common]** = several sources for one game; **[One-off]** = single source. Itch.io jam comments are small indie games — useful as examples of a pattern, low weight.
- Dates: most Steam review quotes are 2022–2025. Vampire Survivors (VS) praise is mostly early-2022 (EA era) — marked.

## 1. What praise recurs for the best-reviewed survivor-likes, and which mechanics get the credit?

### Takeaway
Top-voted praise is about **a very low-friction loop that pays out constantly** ("press play and it's 3am"), **cheap price vs. hours**, **characters that genuinely change how a run plays**, and **builds you discover yourself** (weapon combos/evolutions). Games praised as best-in-class (Halls of Torment, Brotato) add a reason to stay alert ("still feeling vulnerable 20hrs in", shop breaks between waves) and progression through goals/quests rather than farming.

### Cited Findings
**"One more run" / compulsion (Recurring, highest-voted praise in VS & Brotato)**
- VS top review: "There is no escape. You press play, and it's 3am." (2,284 helpful, 15 Apr 2022); "It's that kind of game where you're just going to play one more run" (1,893 helpful, 21 Feb 2022); "digital bubble wrap" (454 helpful, 13 Dec 2023) — [VS top positive reviews](https://steamcommunity.com/app/1794680/positivereviews/?browsefilter=toprated&filterLanguage=english)
- Brotato top review: "i uninstalled the game. it was the only way i could stop playing." (1,058 helpful, 30 May 2023); "proceeded to play this for 8 hours straight" (210 helpful, 24 Dec 2023) — [Brotato top positive reviews](https://steamcommunity.com/app/1942280/positivereviews/?browsefilter=toprated&filterLanguage=english)
- Design analysis (Peter Howell, Univ. of Portsmouth, 13 Apr 2023): VS satisfies "competence (a sense of power and mastery) and autonomy (a sense of freedom)"; "Periods where players comfortably dominate enemies are followed by periods of increased tension"; "No run ever feels wasted as players feel a sense of increasing mastery and progression"; "The game is built around multilayered rewards." — [The Conversation](https://theconversation.com/vampire-survivors-how-developers-used-gambling-psychology-to-create-a-bafta-winning-game-203613)

**Low friction / accessibility (Common for VS)**
- "Do I need a cutscene explaining what's happening? No. You press Start and now you kill stuff until you die." (2,194 helpful, 30 Jan 2022); "I'm a disabled gamer and the controls are very accessible." (4,667 helpful — the single most-helpful positive review, 15 Jan 2022); "all you have to do is move the joystick, press A to accept, and press B to return" (382 helpful, 2 Feb 2024) — [VS top positive reviews](https://steamcommunity.com/app/1794680/positivereviews/?browsefilter=toprated&filterLanguage=english)

**Power fantasy via density (Common, but contested — see Q2 clutter)**
- HoT forum, LunarisRuin (5 Aug 2023): wants to keep high monster density because it is the "power trip" of a "reverse bullet hell" — while still asking for an opacity slider — [HoT discussion](https://steamcommunity.com/app/2218750/discussions/0/3801652929323026410)
- Death Must Die negative review (268 helpful, 27 Apr 2025): "The whole premise under this kind of game should be fast paced free movement and power fantasy" (complaining that new content broke this) — [DMD negative reviews](https://steamcommunity.com/app/2334730/negativereviews/?browsefilter=toprated&filterLanguage=english)

**Characters that change play + build discovery (Recurring)**
- Brotato: "Many different characters that feel unique and vary the gameplay" (477 helpful, 4 Jun 2023); "Each character that you can choose has a set of bonuses and penalties that affect the base stats" (289 helpful, 7 Oct 2022); "After 3 hours I realised that I can combine similar weapons." (123 helpful, 22 Oct 2022) — [Brotato top positive](https://steamcommunity.com/app/1942280/positivereviews/?browsefilter=toprated&filterLanguage=english)
- Halls of Torment (HoT): "I cycle every character, swapping each run." / "I'm willing to try different trait builds." (186 helpful, 17 Jun 2023); "The number of possible combinations (spells/equipment/potions/characters, etc.) makes every game different." (137 helpful, 14 Sep 2024) — [HoT top positive](https://steamcommunity.com/app/2218750/positivereviews/?browsefilter=toprated&filterLanguage=english)
- HoloCure: "There are literally dozens of characters to try, and each one has a completely unique set of moves to play with." (416 helpful, 10 Sep 2023) — [HoloCure top positive](https://steamcommunity.com/app/2420510/positivereviews/?browsefilter=toprated&filterLanguage=english)
- VS long-term player (Feb 2025): the game "becomes a MUCH MORE COMPLEX AND DEEP GAME once you spend enough time"; lists weapon evolutions, mutators, randomized events, endless mode as what kept it going — [Steam discussion](https://steamcommunity.com/app/1794680/discussions/0/595141473937133142)

**Pacing structure credited (Common for Brotato/HoT)**
- Brotato: "The intensity is broken up by shops at the end of each wave" (477 helpful) — [Brotato top positive](https://steamcommunity.com/app/1942280/positivereviews/?browsefilter=toprated&filterLanguage=english); mobile tester: "This game is a great way to spend 10 minutes." — [Pocket Gamer App Army, 13 Apr 2023](https://www.pocketgamer.com/brotato/app-army-assemble)
- HoT: "Still feeling vulnerable 20hrs in. Still having to earn each step." (186 helpful); meta progression praised for "not rellying on farming ressources but rather by achieving some quests" (137 helpful, 14 Sep 2024); "This is a remarkable step up from Vampire Survivors" (366 helpful) — [HoT top positive](https://steamcommunity.com/app/2218750/positivereviews/?browsefilter=toprated&filterLanguage=english)
- 20 Minutes Till Dawn: press frames manual aim + 20-minute runs (vs. genre-standard 30) as the differentiator, with a half-length option; bosses with their own attack patterns praised (Destructoid) — [KeenGamer](https://www.keengamer.com/articles/reviews/pc-reviews/20-minutes-till-dawn-review-surviving-the-swarm/), [Destructoid](https://destructoid.com/?p=330784), [Way Too Many Games](https://waytoomany.games/2023/12/30/review-20-minutes-till-dawn-switch/) (via search summaries, not fetched in full)

**Mobile portrait works if readable**
- VS mobile review: "Vampire Survivors plays in either vertical or horizontal mode"; "You can see enough of the screen to know what's going on even vertically." — [Pocket Tactics (updated 9 Oct 2025)](https://www.pockettactics.com/vampire-survivors/review)
- Brotato mobile testers: "the movement on the touchscreen is very tight and accurate, which is extremely important for a game like this" vs. "there was ZERO effort to adapt the interface to a phone screen" / "the text is tiny." — [Pocket Gamer App Army](https://www.pocketgamer.com/brotato/app-army-assemble)

### Inferences
- The mechanics players actually name are: auto-attack + movement-only control, frequent level-ups/chests (multilayered rewards), per-character stat identities, weapon combination/evolution discovery, and a forced breather (Brotato shop) or lingering danger (HoT). "Power fantasy" is praised only when it coexists with some threat — the Conversation's "dominate → tension" alternation is the pattern to copy.
- For a portrait mobile game: tight movement and readable UI text are the two things mobile testers single out; "ZERO effort to adapt the interface" is a named failure.

### Gaps
- Secrets/hidden characters were not prominent in the top-voted positive review text I could fetch (VS top reviews focus on price/compulsion). Their role is asserted by long-time players and analysis pieces, not measured.
- No Reddit threads could be read directly; praise from r/VampireSurvivors / r/Brotato is not represented beyond Steam.

## 2. What are the most common complaints?

### Takeaway
The dominant complaint across genre leaders is **late-run passivity**: once the build is done, players "stand still and win" for 15–20 minutes — not the early game. Close behind: **screen-filling own effects hiding enemies/hazards**, **samey runs/abilities**, **grindy meta-currency** (DRG: Survivor, Soulstone), **character/weapon imbalance**, **RNG-gated builds** (Brotato), and **difficulty that only stacks more layers at once**. Accidental level-up picks are a real but narrower complaint (mostly controller/keyboard; mods and input-locks exist).

### Cited Findings
**A. "Game plays itself" / late-game boredom / power curve (Recurring — the #1 negative theme)**
- VS top negative reviews: "the hitting is automatic, it's just about walking around." (146 helpful, 24 Dec 2022); "I was expecting an action game where I kill monsters, not where I run from them until my autoattacks kill them." (171 helpful, 2 Dec 2022); "Once you unlock all the items and figure out the evolutions, there's not much to the strategy." (142 helpful, 4 Apr 2023); "the game becomes a stand-still-for-30-minutes-and-win simulator." (140.6 h played, 17 Mar 2025); "Just far farrr too passive for me. I feel like I'm waiting, not playing a game." (14 Oct 2023); "there's not really any space to express skill or progression in either gameplay or strategy." (113 helpful) — [VS top negative](https://steamcommunity.com/app/1794680/negativereviews/?browsefilter=toprated&filterLanguage=english)
- HoT negative: "Takes like 10minutes to clear the map of items, then you just stand there for literally 20minutes" (20 Nov 2025); "it just plays so slow." (30 helpful, 27 Sep 2024) — [HoT top negative](https://steamcommunity.com/app/2218750/negativereviews/?browsefilter=toprated&filterLanguage=english)
- HoT run-length thread (Jul 2023–Mar 2024, 40 comments): "im literally doing nothing during these stand still do nothing times" (Mac); one player finds "the first 15 minutes too easy" and the rest wasted (Murder, paraphrased); most-detailed reply (Tazzitsune, 11 Mar 2024): "What we need isn't a shorter run, we need engagement." — the last 15–20 min have little to do because the build is done and enemies die before reaching you — [HoT discussion](https://steamcommunity.com/app/2218750/discussions/0/6643422659548568474)
- HoT "Game is too easy now?" (Sispir, 19 Feb 2024): "I get bored when I know that I WILL win every single run even with agony turned on." — [HoT discussion](https://steamcommunity.com/app/2218750/discussions/0/7953990088755842331)
- Brotato forum (Lod101, 6 Jul 2023): VS is hard early but becomes easy later (paraphrase) — [Brotato discussion](https://steamcommunity.com/app/1942280/discussions/0/3810657379788919419); Brotato negative: "Most of the time the regular levels are way too easy" (21 helpful, 6 Jun 2023) — [Brotato top negative](https://steamcommunity.com/app/1942280/negativereviews/?browsefilter=toprated&filterLanguage=english)
- The opposite failure also exists — too little power: DRG: Survivor "The main problem is that you are always rushing, never crushing." (101 helpful, 5 Apr 2024); "Stages are too short, and leveling is too slow." (561 helpful, 18 Feb 2024) — [DRG:S top negative](https://steamcommunity.com/app/2321470/negativereviews/?browsefilter=toprated&filterLanguage=english)
- "Manipulative" critique (minority but highly voted): "shallow manufactured addiction delivered through progression induced dopamine hits." (84 helpful); "a whole genre of games you don't play but still can't put down." (55 helpful, 28 Apr 2024) — [VS top negative](https://steamcommunity.com/app/1794680/negativereviews/?browsefilter=toprated&filterLanguage=english)

**B. Visual clutter / can't see enemies, projectiles, hazards (Recurring — every major title has a thread)**
- VS thread "Is there anything I can do to improve visibility?" (Nov 2024, 18 comments): "can't see anything anymore due to the weapon effects" / "no option to lower effects"; evolved Clock "covers the whole screen and draws over the character"; Space Gun evolution makes the map "nearly unrecognizable"; effects hide bosses and chests; one says visuals are so intense the game isn't fun; removing damage numbers "helped a little". Requested fixes: opacity slider, cap on projectiles displayed per weapon, pause-menu toggle to hide chosen weapons' effects, draw boss/important objects above weapon effects — [VS discussion](https://steamcommunity.com/app/1794680/discussions/0/4631482569784862180)
- HoT thread (3 Aug 2023): "Monster density is killing the playability"; "There REALLY needs to be a slider for ability opacity." — called "one of the biggest issues with these games"; damage numbers "useless and cause clutter" — [HoT discussion](https://steamcommunity.com/app/2218750/discussions/0/3801652929323026410)
- Soulstone Survivors: "on higher curse runs, you have to turn down visual effects just to see what's happening" (126 helpful, 27 Nov 2025); "The ground is just a chaos of one-shot mechanics that you'll eventually run into." (126 helpful, 18 Feb 2024) — [Soulstone top negative](https://steamcommunity.com/app/2066020/negativereviews/?browsefilter=toprated&filterLanguage=english)
- DRG: Survivor: "There is no mechanism to see aliens which are visually behind something." (181 helpful, 30 Oct 2025) — [DRG:S top negative](https://steamcommunity.com/app/2321470/negativereviews/?browsefilter=toprated&filterLanguage=english)
- 20 Minutes Till Dawn: "due to the monochrome colors and the flashing lights I just cannot focus on the screen" (55 helpful, 20 Jun 2022) — [20MTD top negative](https://steamcommunity.com/app/1966900/negativereviews/?browsefilter=toprated&filterLanguage=english)
- Color coding (indie demo feedback, ~2025): "Just a sea of red where you don't know what is what."; asks for outlines or a strict color scheme; dev replied "I honestly never thought it was difficult to detect or dodge them" — [itch.io CRYPTWAKE](https://itch.io/post/12889497) (illustrates developer blind spot)

**C. Unclear damage source / dying without noticing (Common in indie feedback; less visible in big-game reviews because those games already have strong hit feedback)**
- "I just wish it was more obvious that I was taking damage as it took me a couple of runs to work out why I just died." Dev: "I didn't have time to fully juice up the player or add some obvious visual feedback!" — [itch.io OverPowered](https://itch.io/post/12972805)
- "It took me multiple runs to realize that enemies had already spawned behind me & killed me." Dev added "a hitflash and hit sound effect" and planned a mini-map — [itch.io PROJECT AEGIS](https://itch.io/post/9585949)
- "Having to look at my heart in the top left to see if I was hit isn't ideal in a bullet hell game." / "nice to have both a visual and audio cue" — [itch.io CRYPTWAKE](https://itch.io/post/12889497)
- Note: Brotato's default behavior darkens the screen when the player takes damage (inferred from patch 0.6.0.7 adding "an option to remove screen darkening when taking damage") — [Brotato wiki 0.6.0.7](https://brotato.wiki.spellsandguns.com/Patch_0.6.0.7)

**D. Accidental level-up picks (Occasional; mostly keyboard/controller; no strong mobile-specific evidence found)**
- Megabonk community mod "SpacebarBlock": "Automatically blocks the Spacebar and E keys for 3 seconds whenever a non-whitelisted menu (like a Level Up or Shrine) appears" — [Thunderstore](https://thunderstore.io/c/megabonk/p/guarnecessities/SpacebarBlock/) (a mod existing = enough players hit the problem)
- Yet Another Zombie Survivors: "Added a 0.2s input lock after activating the "Banish" function to help with double-input issues." — [GOGDB release notes](https://www.gogdb.org/product/1967904485/releasenotes) (via search snippet)
- An unnamed game's patch note (SteamDB page returned 403, game not identified): "there is a short delay between when your skill options are displayed and when you can actually click on them, in an effort to prevent accidentally clicking on skills as soon as the level up screen is brought up. This delay has been increased." — [SteamDB patchnotes 9327117](https://steamdb.info/patchnotes/9327117) (unverified game)
- Itch player request: "you should add a delay for the upgrade screen ... I was shooting and went to the upgrade screen and just clicked something immediately by mistake" — itch.io (search snippet; exact post not verified)
- VS controller bug: controller could not select the Skip button on level-up — [VS discussion](https://steamcommunity.com/app/1794680/discussions/0/4631482569784919503) (via search summary)

**E. Repetitive runs / learning everything early (Recurring)**
- HoT: "build variety being so limited is the worst part." (57 helpful, 28 Oct 2023); "After 30 minutes all the skills were uninspired stat bonuses." (3 Dec 2023); "Seeing the same 15 abilities over and over and over while you're grinding away agony levels" (19 Mar 2025) — [HoT top negative](https://steamcommunity.com/app/2218750/negativereviews/?browsefilter=toprated&filterLanguage=english)
- DRG:S: "The first run feels like all runs." (18 Nov 2025); "3 maps that have the same end boss, same enemy types and only differ visually" (310 helpful, 14 Feb 2024) — [DRG:S top negative](https://steamcommunity.com/app/2321470/negativereviews/?browsefilter=toprated&filterLanguage=english)
- Soulstone: "Every run will end up the same, only looking different visually" (97 helpful); "Every build, character, weapon, and run all feel the exact same." — [Soulstone top negative](https://steamcommunity.com/app/2066020/negativereviews/?browsefilter=toprated&filterLanguage=english)
- VS: "There are hardly any novel challenges, and the vast majority of enemies do roughly the same thing." (17 Mar 2025) — [VS top negative](https://steamcommunity.com/app/1794680/negativereviews/?browsefilter=toprated&filterLanguage=english)
- 20MTD: "There isn't a ton of variation" (13 Oct 2025) — [20MTD top negative](https://steamcommunity.com/app/1966900/negativereviews/?browsefilter=toprated&filterLanguage=english)

**F. Run length (Split opinion — the complaint is really about dead time, not minutes)**
- HoT: "I'm sorry, but 30 minutes per run is asking too much." (38 helpful, 25 Jul 2023) — [HoT top negative](https://steamcommunity.com/app/2218750/negativereviews/?browsefilter=toprated&filterLanguage=english); thread split: some find 30 min "just right", many ask for VS-style 2x speed / Hurry mode; "it's never just 30 minutes"; trait screens push real length to 45+ min (Tazzitsune) — [HoT discussion](https://steamcommunity.com/app/2218750/discussions/0/6643422659548568474)
- DRG:S players called mid-run saving "much requested" (added Dec 2025) — [GamingOnLinux](https://gamingonlinux.com/2025/12/deep-rock-galactic-survivor-gets-mid-game-saves-and-cpu-optimizations) (via search summary)
- Reddit r/roguelites (Feb 2024, search snippet only): "too many VS like games don't really have good time flexibility in run lengths" — [reddit r/roguelites thread 1axj60r](https://www.reddit.com/r/roguelites/comments/1axj60r/) (not fetched)

**G. Overlapping spawns / everything at once (Common at higher difficulties)**
- Brotato: "Higher difficulties just add too many layers at the same time." (55 helpful, 25 Oct 2022); "just tripling the health of everything and adding bullet spam on top of the map is not fun." (54 helpful, 434 h) — [Brotato top negative](https://steamcommunity.com/app/1942280/negativereviews/?browsefilter=toprated&filterLanguage=english)
- Brotato forum (Sokaku, Jul 2023): difficulty increase "will come from Elites & numbers" — [Brotato discussion](https://steamcommunity.com/app/1942280/discussions/0/3810657379788919419)
- Soulstone: "This game is on all the time so there's no breathing room from the hordes of extremely oppressive mechanics." (268 helpful, 4 Dec 2022); "It's essentially a dodging simulator." — [Soulstone top negative](https://steamcommunity.com/app/2066020/negativereviews/?browsefilter=toprated&filterLanguage=english)
- Death Must Die: "Getting stuck on terrain while being pelted with attacks you can't meaningfully avoid is not my idea of fun." (95 helpful) — [DMD top negative](https://steamcommunity.com/app/2334730/negativereviews/?browsefilter=toprated&filterLanguage=english)

**H. Weak characters / balance (Recurring)**
- HoT: "characters are horribly unbalanced" (57 helpful, 28 Oct 2023) — [HoT top negative](https://steamcommunity.com/app/2218750/negativereviews/?browsefilter=toprated&filterLanguage=english)
- Brotato: "Classes/items/weapons are extremely unbalanced." (28 helpful, 14 Apr 2024); "Pool weightings per character should be fixed." (26 helpful) — [Brotato top negative](https://steamcommunity.com/app/1942280/negativereviews/?browsefilter=toprated&filterLanguage=english)
- DRG:S: "Weapon balance is terrible. It has always been terrible since the early days and has barely been addressed." (181 helpful, 30 Oct 2025) — [DRG:S top negative](https://steamcommunity.com/app/2321470/negativereviews/?browsefilter=toprated&filterLanguage=english)
- Soulstone: "if you don't adhere to meta builds, it's no fun." (115 helpful) — [Soulstone top negative](https://steamcommunity.com/app/2066020/negativereviews/?browsefilter=toprated&filterLanguage=english)
- Nerf backlash: Death Must Die "just daily patches to nerf things people find out are good" (422 helpful, 20 Nov 2023) — [DMD top negative](https://steamcommunity.com/app/2334730/negativereviews/?browsefilter=toprated&filterLanguage=english); Brotato "The dev will intentionally nerf items and change stat values to stop you from doing that." (22 helpful) — [Brotato top negative](https://steamcommunity.com/app/1942280/negativereviews/?browsefilter=toprated&filterLanguage=english); HoT Sept 2023 patch: "New patch made the game not enjoyable anymore." (25 helpful) — [HoT top negative](https://steamcommunity.com/app/2218750/negativereviews/?browsefilter=toprated&filterLanguage=english)

**I. RNG builds (Common for shop/item games)**
- Brotato: "RNG gating, if you don't get proper items your run is basically doomed" (791.8 h, 17 Jun 2025); "Every run relies on rng and it gets so tedious having a run ruined" (34 helpful, 28 Oct 2022); "certain high-rarity items totally breaking open a run" — [Brotato top negative](https://steamcommunity.com/app/1942280/negativereviews/?browsefilter=toprated&filterLanguage=english)

**J. Grindy meta progression (Recurring for DRG:S/Soulstone; HoT praised for avoiding it)**
- DRG:S: "Instead of reducing the mindless grind they are increasing it." (782 helpful, 25 Jun 2024); "Hurray, one run gives me enough currency to increase my critical hit damage by 2%" (219 helpful, 28 Sep 2025); "Meta progression is ridiculous." (181 helpful, 30 Oct 2025) — [DRG:S top negative](https://steamcommunity.com/app/2321470/negativereviews/?browsefilter=toprated&filterLanguage=english); press: "the grind in the game is relentless, especially early on" — [Twinfinite](https://twinfinite.net/reviews/deep-rock-galactic-survivor-review/) (via search snippet)
- Soulstone: "Spending 10-15 minutes per run farming to get 1/6 of the material needed to craft 1 weapon for 1 character is nonsense" (110 helpful, 21 Sep 2023) — [Soulstone top negative](https://steamcommunity.com/app/2066020/negativereviews/?browsefilter=toprated&filterLanguage=english)
- HoT: "Sacrificing fun for artificial difficulty and dragging the longevity of the game out." (34 helpful, 4 Sep 2023) — [HoT top negative](https://steamcommunity.com/app/2218750/negativereviews/?browsefilter=toprated&filterLanguage=english)

**K. Abandonment / no updates (Recurring as a reason to downvote otherwise-liked games)**
- 20MTD's most-helpful negatives are almost all "PC abandoned for mobile": "The steam version has been abandoned by the developer in favor of the mobile port." (340 helpful) — [20MTD top negative](https://steamcommunity.com/app/1966900/negativereviews/?browsefilter=toprated&filterLanguage=english)
- Death Must Die: "No update or message from the dev(s) in 6 months." (173 helpful, 2 Oct 2025) — [DMD top negative](https://steamcommunity.com/app/2334730/negativereviews/?browsefilter=toprated&filterLanguage=english)

**L. Mobile F2P monetization (Survivor.io)**
- r/MobileGameReviewers certified review (27 Nov 2023, search snippet only): described "some of the worst ads that I have seen in the industry", still scored it 7 and noted the energy system never ran low in 4 hours — [reddit post](https://www.reddit.com/r/MobileGameReviewers/comments/184s07f/survivorio) (not fetched)
- AI-generated review aggregator claims sentiment shifted toward a late-game "pay-to-win wall" — [Marlvel](https://marlvel.ai/apps/survivor-io/reviews) (low reliability; AI summary, flagged by the site itself as unaffiliated)

### Inferences
- Tester complaint "after evolution everything melts" = the genre's #1 top-voted criticism (VS, HoT). Players explicitly say the fix is *engagement* in the back half (threats that still matter, goals), not just shortening the run.
- Tester complaint "can't tell my ground effects from enemy ground effects" matches a recurring cross-game complaint; the requested fixes are consistent: own-effect opacity, enemy hazards drawn above player effects, strict enemy-attack color, outline/highlight on enemy projectiles.
- "Died without noticing damage" appears mostly in small-game feedback, which suggests the big games solved it by default (hit flash + sound + screen darkening/vignette). It is a "basics missing" signal, not a niche one.
- "Waves and elites overlap" matches Brotato's "too many layers at the same time" and Soulstone's "no breathing room" — players want alternating pressure, not simultaneous stacking.
- "One character too weak" — players punish visible imbalance, but they punish *nerfs* of fun things even more; buffing the weak option is the lower-backlash path.
- Accidental level-up picks: evidence is real but thin; the community-fix pattern is a short input lock (0.2 s – 3 s) after the menu appears, or moving choices to a calm moment (Brotato picks level-ups at wave end).

### Gaps
- No direct Reddit data (r/VampireSurvivors, r/Brotato, r/AndroidGaming, r/iosgaming) — robots.txt; only snippets.
- I found no top-voted review specifically about *touch* accidental selection on mobile (VS mobile, Survivor.io); the evidence is from keyboard/controller and indie feedback.
- Army of Ruin and Survivor.io (beyond monetization) were not covered by fetched sources.

## 3. How did developers respond in patches?

### Takeaway
The clearest pattern: **visibility options** (own-projectile/explosion/particle opacity, highlighting enemy projectiles, turning off flashes/damage numbers) were added by Brotato, Megabonk and Soulstone; **Vampire Survivors reportedly declined** an opacity slider (secondhand). Difficulty complaints were answered with **opt-in modes** (VS Hurry/Hyper/Endless/Curse, Brotato Danger tiers + sliders + Endless, HoT Agony/Shrine), **numeric character buffs**, and for grind, **removing a currency + adding goal/gear rewards + mid-run saves** (DRG:S 1.0).

### Cited Findings
**Visibility / effects**
- Brotato 0.5.11c: added accessibility option to turn off explosion flashes (patch also reduced enemy damage per headline) — [Player.One](https://player.one/brotato-enemies-now-deal-less-damage-patch-0511c-151276) (via search summary)
- Brotato 0.6.0.7: "Added an option to highlight enemy projectiles"; "Added an option to remove screen darkening when taking damage"; "Added an option to hide boss health bars"; "Added an option to enable manual aiming when pressing the left mouse button" — [Brotato wiki](https://brotato.wiki.spellsandguns.com/Patch_0.6.0.7)
- Brotato (Dec 2023 patch): "Added projectile and explosion opacity options to improve visibility in endless mode"; "The health bar will now indicate whether tardigrades are still active in the current wave using a purple color" — [GamingOnLinux, 5 Dec 2023](https://www.gamingonlinux.com/2023/12/brotato-expanding-with-new-content-steam-deck-top-game/comment_id=254079)
- Megabonk v1.0.17 (19 Oct 2025): "Particles and effects opacity slider added in Visuals settings." / "You can change the opacity of your projectiles and particles."; added full map with fog of war; level-up screen now shows "the stats change on the right hand side as you pick upgrades." — [ConsolePCGaming](https://consolepcgaming.com/megabonk-v1-0-17-patch-notes-full-map-opacity-slider-dx12-option)
- Soulstone Survivors: has an own-ability opacity setting — players cite it as the model ("turning down opacity of your abilities, thus increasing visibility of enemies and danger zones") — [Spell Brigade discussion](https://steamcommunity.com/app/2904000/discussions/0/501685556736992126/?l=dutch) (via search snippet); [HoT discussion](https://steamcommunity.com/app/2218750/discussions/0/3801652929323026410); confirmed in use by a Nov 2025 Soulstone review — [Soulstone top negative](https://steamcommunity.com/app/2066020/negativereviews/?browsefilter=toprated&filterLanguage=english)
- Vampire Survivors: a player recalls poncle saying they don't plan to add an opacity slider; others call it "obstinacy"/"stubborn" (Nov 2024, secondhand, not verified) — [VS discussion](https://steamcommunity.com/app/1794680/discussions/0/4631482569784862180)
- HoT: an older patch note said the devs "plan to add more transparency as we continue with the development" (unclear if it refers to visuals; not confirmed shipped) — [SteamDB](https://steamdb.info/patchnotes/12169502) (via search snippet; page not fetched)
- Small devs, after feedback: added hit flash + hit sound, planned mini-map for off-screen spawns — [itch.io](https://itch.io/post/9585949)

**Difficulty / spawns / endless**
- Brotato 0.6.0.7: "Replaced Danger II's effect "inflation is higher" with "elites and hordes appear""; Danger IV → "more elites and hordes appear"; "Tweaked most waves (especially on Danger 1+)" — [Brotato wiki](https://brotato.wiki.spellsandguns.com/Patch_0.6.0.7)
- Brotato 0.8.0.0 (9 Feb 2023): "Added endless mode"; 0.8.0.1: "Endless runs that go further than wave 20 are now counted as won runs"; 0.8.0.2: "Endless starts scaling faster after wave 35" — [Brotato wiki](https://brotato.wiki.spellsandguns.com/Beta_Patches_0.8.0.x)
- Brotato "All Pain No Gain" update: Nightmare difficulty + accessibility option to disable/enable/amplify Nightmare projectile fire — [Nintendo Everything](https://nintendoeverything.com/brotato-all-pain-no-gain-update-announced-patch-notes-nightmare-difficulty-new-character-weapon-more/) (via search summary)
- HoT: Frozen Depths was nerfed after complaints it was unfair (Feb 2024); community says a "Shrine of Torment" was planned for players wanting challenge — [HoT discussion](https://steamcommunity.com/app/2218750/discussions/0/7953990088755842331); 1.0 (Sept 2024) was advertised with "shorter game modes, more enemies, traps and additional loot" — [Fullcleared](https://fullcleared.com/news/halls-of-torment-exits-early-access-in-september/) (via search summary). Standard runs remain capped at 30 min — [PCGamesN](https://www.pcgamesn.com/halls-of-torment/steam-update) (via search summary)
- VS modes: Hurry (clock doubled; 30-min Reaper at 15 min; XP bonus per guide), Hyper (faster, more risk/reward), Inverse, Endless; Curse is a stat raising enemy speed/HP/spawns with more XP/gold — [Siliconera: Curse](https://www.siliconera.com/what-does-curse-do-in-vampire-survivors/), [GameSpot 1.0 patch notes](https://gamespot.com/articles/vampire-survivors-1-0-patch-notes-new-stage-and-modes/1100-6508498/) (via search summaries; guide numbers vary)

**RNG / build control**
- VS 1.1.0 (Nov 2022) added Seal: pre-run exclusion of items from the level-up pool, complementing in-run Banish — [Vampire Survivors wiki: Seal](https://vampire.survivors.wiki/w/Seal), [GamingBolt 1.1.0](https://gamingbolt.com/vampire-survivors-update-1-1-0-adds-tiny-bridge-challenge-stage-new-character) (via search summaries)
- Brotato 0.6.0.7: "Added an option to keep items locked between shops" — [Brotato wiki](https://brotato.wiki.spellsandguns.com/Patch_0.6.0.7)

**Character balance**
- Brotato 0.6.0.7 buffs/reworks: "Soldier: +10% Speed"; "Ranger: +33% Ranged Damage => +50%..."; Explorer/Lucky get new start weapons; Engineer landmines "no longer spawn grouped up" — [Brotato wiki](https://brotato.wiki.spellsandguns.com/Patch_0.6.0.7)

**Grind / session length**
- DRG:S 1.0 (17 Sep 2025): "streamlined progression by removing Morkite Reactor Cores and improved mastery, overclocks, and boss fight rewards"; added a loot Gear system — [ConsolePCGaming](https://consolepcgaming.com/deep-rock-galactic-survivor-1-0-lands-with-loot-escort-missions-and-bigger-progression), [FinalBoss](https://finalboss.io/deep-rock-galactic-survivor-1-0s-gear-overhaul) (via search summaries); later "much requested" mid-game saving; 1.1 Endless mode — [GamingOnLinux](https://gamingonlinux.com/2025/12/deep-rock-galactic-survivor-gets-mid-game-saves-and-cpu-optimizations) (via search summary)

**Level-up input**
- Community/indie fixes only: Megabonk mod (3 s key block on level-up), YAZS 0.2 s input lock after Banish, an unnamed game increasing the display→clickable delay — sources in Q2-D.

### Inferences
- Opacity for *own* effects is now a de-facto genre standard request; the games that added it (Brotato, Megabonk, Soulstone) framed it as visibility/accessibility, while players who resisted density still wanted it. Highlighting *enemy* projectiles (Brotato) is the complementary fix.
- Developers rarely made the base game harder after complaints of "too easy"; they added opt-in layers (modes, curse, danger, endless, shrines) and kept the default accessible. HoT shows the risk: nerfing a hard zone after complaints triggered "too easy now" threads.
- No major title was found adding a level-up confirm/input-delay in official notes; the problem is solved by mods or by design (Brotato's end-of-wave picks).

### Gaps
- Could not open SteamDB pages (403) to confirm game/version for "Weapon opacity option" (patchnotes 12324890) and the level-up click-delay note (9327117).
- No official poncle statement on opacity found; only secondhand.
- HoT opacity/visibility option status after 1.0 is unconfirmed.

## 4. Difficulty options: do hardcore and casual players want different things, and how do good games serve both?

### Takeaway
Yes. Casual/accessibility players want **sliders that lower damage/HP/speed without losing unlocks**; challenge players want **designed difficulty (new mechanics, bosses, tighter patterns)**, not stat inflation, and some resent unlocks being obtainable on easy settings. The best-served approach is a stack: an accessible default + optional tiers that **change mechanics** (Brotato Danger adds elites/hordes; VS Hyper/Hurry/Curse with reward trade-offs; HoT Agony) + separate accessibility sliders.

### Cited Findings
- Brotato thread (Jul 2023): OP calls achievement-eligible sliders "idiotic" and says "it's a pity it's not a game, but a sandbox" (challenge view); Deathraven13: sliders exist because danger levels "aren't very balanced, a lot of new players struggle to beat D0"; Azael: sliders sit under Accessibility and are for players who need them; Jaeus: slider is "a rather silly but remarkably simple way to give players another difficulty toggle" — [Brotato discussion](https://steamcommunity.com/app/1942280/discussions/0/3810657379788919419)
- Brotato: difficulty doesn't affect achievements; guides tell players they can turn sliders down to 25% — [Ludo guide](https://www.ludo.guide/guide/brotato/difficulty-modifiers), [CommonSenseGamer](https://commonsensegamer.com/brotato-how-to-beat-difficulty-5-danger-5/) (via search summaries); most community strategy treats Danger 5 as the default — (via search summary of guides; same sources)
- Hardcore dislike of pure stat inflation: "just tripling the health of everything and adding bullet spam on top of the map is not fun." (434 h); "Higher difficulties just add too many layers at the same time." — [Brotato top negative](https://steamcommunity.com/app/1942280/negativereviews/?browsefilter=toprated&filterLanguage=english)
- Mobile casual testers liked tiers: "The higher difficulties also make it possible to renew the experience."; "It's challenging enough to make me feel good each time I live a little longer." — [Pocket Gamer App Army](https://www.pocketgamer.com/brotato/app-army-assemble)
- HoT "Game is too easy now?" (Feb 2024): challenge player: self-imposed difficulty isn't fun because the challenge wasn't designed in (Sispir, paraphrase); others: "If you find it easy, make it harder for yourself."; "Just turn the blessings you have down."; requests for a Hades-style heat system, tougher bosses, prestige levels; a marked "answer" says the nerf was deliberate after complaints and only a handful find the game too hard — [HoT discussion](https://steamcommunity.com/app/2218750/discussions/0/7953990088755842331)
- HoT Agony criticized as slow to ramp yet hard at 0 multiplier, and as "too brutal for those on the lower end and not enough for those on the higher end" — Steam threads surfaced by search (exact thread not verified) — e.g. [HoT discussion list](https://steamcommunity.com/app/2218750/discussions/0/3816292165308187402) (via search summary)
- HoT run-length thread: some want curse mechanics/new difficulties instead of shorter runs (DotNL); others want 2x speed / Hyper like VS — [HoT discussion](https://steamcommunity.com/app/2218750/discussions/0/6643422659548568474)
- VS: Curse is "the only stat that intentionally makes the game harder" and trades difficulty for more kills/XP/gold; Hurry/Hyper are opt-in per stage — [Siliconera](https://www.siliconera.com/what-does-curse-do-in-vampire-survivors/), [Prima Games: Hyper](https://primagames.com/tips/what-is-hyper-mode-in-vampire-survivors-answered) (via search summaries)
- Soulstone shows the failure mode of high tiers: curse levels = screen clutter + one-shot ground hazards ("chaos of one-shot mechanics") — [Soulstone top negative](https://steamcommunity.com/app/2066020/negativereviews/?browsefilter=toprated&filterLanguage=english)
- Death Must Die: new act forces players to take hits, conflicting with "fast paced free movement and power fantasy" — [DMD top negative](https://steamcommunity.com/app/2334730/negativereviews/?browsefilter=toprated&filterLanguage=english)

### Inferences
- Serve both by separating three dials: (1) accessibility (damage/HP/speed sliders, no penalty), (2) designed challenge tiers that add *new* threats one at a time (elites, faster spawns, enemy projectiles) and pay more rewards, (3) a mode for time (Hurry/2x) — players asked for (3) independently of (1)/(2).
- Hardcore players accept harder content only if it is readable; difficulty that comes from clutter/one-shot ground effects is criticized even by 100+ hour players.

### Gaps
- No quantitative data on what share of players use easier settings.
- Brotato "Abyssal Terrors"/1.0-era difficulty reception and VS "Limit Break"/Arcana debates not fetched.

## 5. What makes players feel a game is "worth the money" and recommend it?

### Takeaway
"Worth it" = **hours per dollar** (VS $3 → 100 h; HoT $5 → 50 h; HoloCure free), **no predatory monetization** (explicitly praised; poncle built VS mobile itself to avoid it), and **continued updates** — the most-helpful negatives for otherwise-liked games (20MTD, Death Must Die) are about abandonment, not gameplay. On mobile, optional/rewarded ads are tolerated; forced ads/energy walls are the main hate.

### Cited Findings
- VS: "This has to be the best $3 game on steam." (963 helpful); "This game is ridiculously good for its pricepoint." (823 helpful); "Imagine getting 100 hours of game play out of a $3 game." (620 helpful) — 2022 — [VS top positive](https://steamcommunity.com/app/1794680/positivereviews/?browsefilter=toprated&filterLanguage=english); long-time player: "it really gives you ROI (Return on Investment)" (Feb 2025) — [Steam discussion](https://steamcommunity.com/app/1794680/discussions/0/595141473937133142)
- HoT: "better than $70 I spent on Diablo IV" (637 helpful, 9 Jul 2023); "50 hours in halls of torment- damn near completed the game and spent 5 bucks" (130 helpful); "for $5USD? And already 20hrs and counting? Easy sell." — [HoT top positive](https://steamcommunity.com/app/2218750/positivereviews/?browsefilter=toprated&filterLanguage=english)
- Brotato: "Cheap and no macroscamsactions" (477 helpful) — [Brotato top positive](https://steamcommunity.com/app/1942280/positivereviews/?browsefilter=toprated&filterLanguage=english); mobile: "All in all, the game is well worth its price tag." — [Pocket Gamer App Army](https://www.pocketgamer.com/brotato/app-army-assemble)
- HoloCure: "HOW IS THIS GAME FREE!?!?!?!" (615 helpful); "it's free. There's no reason not to at least try this game."; gacha uses only in-game currency "(no pay to win)" — [HoloCure top positive](https://steamcommunity.com/app/2420510/positivereviews/?browsefilter=toprated&filterLanguage=english)
- VS mobile (Dec 2022): "a free game with no in app purchases. It is ad-supported"; ads optional and "actually help to gain additional coins" — [TouchArcade](https://toucharcade.com/2022/12/09/vampire-survivors-mobile-review-controller-cloud-save-sync-dlc-unlock-iphone-ipad-pro/) (via search summary); ads "fairly unobtrusive" — [Pocket Tactics](https://www.pockettactics.com/vampire-survivors/review); poncle's stated approach: monetization "designed to never interrupt your game, always be optional and in your control" — [Yahoo/Kotaku-syndicated](https://malaysia.news.yahoo.com/crappy-mobile-games-accidentally-led-203000507.html) (via search summary); headline: poncle "couldn't find a 'non-predatory' mobile developer, so it did the job itself" — [PC Gamer](https://pcgamer.com/vampire-survivors-studio-says-it-couldnt-find-a-non-predatory-mobile-developer-so-it-did-the-job-itself) (headline only; body not retrieved)
- Updates matter: VS reviewer edit "Update for the release edition: Yes, still very good." (4,667 helpful) — [VS top positive](https://steamcommunity.com/app/1794680/positivereviews/?browsefilter=toprated&filterLanguage=english); 20MTD downvoted for PC abandonment (340 helpful) — [20MTD top negative](https://steamcommunity.com/app/1966900/negativereviews/?browsefilter=toprated&filterLanguage=english); Death Must Die "it will never go out of early access" (193 helpful) — [DMD top negative](https://steamcommunity.com/app/2334730/negativereviews/?browsefilter=toprated&filterLanguage=english)
- Brand alone doesn't carry it: DRG:S "The game has nothing going for it other than branding and graphics." (1,231 helpful, 14 Feb 2024 — early access launch) — [DRG:S top negative](https://steamcommunity.com/app/2321470/negativereviews/?browsefilter=toprated&filterLanguage=english)
- Survivor.io: widely played but ads/energy/late-game spending are the recurring gripes — [reddit r/MobileGameReviewers](https://www.reddit.com/r/MobileGameReviewers/comments/184s07f/survivorio) (snippet only), [Marlvel](https://marlvel.ai/apps/survivor-io/reviews) (AI summary, low reliability)

### Inferences
- For a small mobile survivor-like, the recommendable package per these sources is: no forced ads/energy, optional rewarded ads at most, a visible stream of unlockable characters that each play differently, and visible updates. Grind-to-unlock is tolerated when it is goal/quest-based (HoT) and hated when it is currency farming (DRG:S, Soulstone).
- "Content per dollar" is judged by *distinct* experiences (characters/builds), not total hours of the same run — the repetitive-run complaints (Q2-E) are the flip side.

### Gaps
- No hard data on retention or refund rates tied to these factors.
- Mobile store reviews (App Store / Google Play) for VS mobile and Survivor.io were not read directly; only press and aggregators.
