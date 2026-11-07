# Combat readability in crowded action games: own vs. enemy effects, and noticing incoming damage

Scope: survivor-likes / bullet heavens, twin-stick shooters, ARPGs, MOBAs. Goal: inputs for redesigning a 180×320 portrait mobile zombie survivor-like so players never confuse "my ground zone" with "enemy ground zone" and never die without noticing damage.
Research date: 2026-11-07. Source dates noted inline. "(snippet)" = quote taken from a search-result snippet; the page itself was not opened (blocked with 403 or not fetched). Treat those as lower confidence.

---

## 1. Recurring player complaints (clutter, "can't see what's killing me", own vs. enemy confusion)

### Takeaway
The same complaint comes up across Vampire Survivors, Soulstone Survivors, Brotato, Path of Exile 2, Diablo IV, Risk of Rain 2 and LoL: **the player's own (or allies') effects pile up on top of enemy telegraphs and ground hazards, so players die to things they never saw.** The fixes players ask for keep converging on the same three: (a) an opacity slider or hide option for *own/ally* effects, (b) enemy hazards always drawn on top, and (c) a distinct color and outline for enemy versus friendly zones. Players also push back that "lower your graphics slider" is not a real design fix.

### Cited Findings

**Vampire Survivors (Poncle)**
- Steam thread, 1–4 Nov 2024. OP: effects make late runs unreadable, "There also seems to be no option to lower effects or so.." Replies: "We could have done with an effects visibility slider for even the previous couple DLCs"; late-game runs are "virtually unplayable since you literally can't see anything"; Power of Sire procs "rendering the screen permanently black"; the Clock "blots out the entire screen and takes rendering priority over everything including the character"; Space Gun evolution makes the map "near unrecognizeable" — [Steam discussion](https://steamcommunity.com/app/1794680/discussions/0/4631482569784862180)
- Fixes players asked for in the same thread: an opacity slider; "An option to limit the number of maximum projectiles displayed"; a per-weapon option to hide effects; drawing boss crests *above* effects. One user turned off damage numbers, which helped, but screen-wide effects were still a problem. A secondhand claim that Poncle does not intend to add an opacity slider has no source behind it — [Steam discussion](https://steamcommunity.com/app/1794680/discussions/0/4631482569784862180)

**Soulstone Survivors**
- Steam thread "Getting rather annoyed", 23 Nov 2022: "I literally could not see the incoming attacks through my own attack fx." Another player pointed to the existing slider: "You can reduce the opacity of your own special effects to make it easier to see enemy attacks." — [Steam discussion](https://steamcommunity.com/app/2066020/discussions/0/3591086730691827584)
- Pushback in the same thread: "The solution to a game design issue should not be 'alter graphics settings'." "25% is too high." Because "the fx can overlap each other CONSTANTLY," 25% opacity stacks back up to close to 100%. The real issue is "enemy attack indicators being underlay rather than overlay," and the proposed fix is to "paint the enemy attack indicators ON TOP of the rest of the scene's final render." — [Steam discussion](https://steamcommunity.com/app/2066020/discussions/0/3591086730691827584)
- Color conflict: with "a chaos build" where "red is the predominant color," red enemy indicators stop standing out. Fire, bomb, holy and lightning FX were called more disruptive than poison, ice or shadow — [Steam discussion](https://steamcommunity.com/app/2066020/discussions/0/3591086730691827584)
- A player on another game's forum praised it: "Soulstone Survivors had this neat option of turning down opacity of your abilities, thus increasing visibility of enemies and danger zones" (snippet) — [The Spell Brigade Steam discussion](https://steamcommunity.com/app/2904000/discussions/0/501685556736992126/?l=dutch)

**Brotato**
- An itch.io player asked for a slider "that would allow me to dim the projectiles appearance on the screen" (snippet) — [itch.io post](https://itch.io/post/5254515). The developer later shipped opacity options (see Q3).

**Halls of Torment**
- Patch 2023-09-21 had a "Visibility" section: "improved contrast of bright purple enemy projectiles against bright backgrounds", plus more sprite contrast for burning-skull monsters (snippet; the page returned 403) — [Prima Games patch notes](https://primagames.com/tips/halls-of-torment-update-2023-09-21-patch-notes). This implies players were losing enemy projectiles against bright floors.

**Path of Exile 2 (GGG), Early Access feedback**
- "Ground Effects Visibility" (OP 13 Dec 2024; still being bumped in July 2026). Enemy ground effects get hidden by foliage and fog, and players die to effects they didn't see. Quotes: "the effect layer should always be visible"; "make ground enemy attacks WAYYY brighter and more visible"; "a transparency slider for Ally and Player attacks"; "make allied and enemy elements different colors … Like blue fire vs red fire"; a request for "some kind of screen indicator (other than or in addition to the debuff icon)" when standing in harmful ground. No developer reply was visible — [PoE forum](https://www.pathofexile.com/forum/view-thread/3626389)
- "Visual Clarity" (8 Dec 2024). Proposals: a thin ground border showing each skill's real hit area, "Color it green for ally effects and red for enemy effects", optional blue for self, citing League of Legends as the precedent; Z-order enemy > self > ally; separate brightness/opacity per enemy, ally and self. A follow-up asks for a darker red on the enemy flame wall and suggests borrowing readability techniques from shmups — [PoE forum](https://www.pathofexile.com/forum/view-thread/3598854)
- "The VISUAL CLARITY Issue – Why it's already WORSE than POE 1" (16 Jan 2026): some builds make boss mechanics "literally impossible to see"; an effect "completely obscures a ground degen or boss mechanic and I die"; the request is a "visual effect opacity slider" — [PoE forum](https://www.pathofexile.com/forum/view-thread/3906258)

**Diablo IV (Blizzard)**
- 13 Aug 2024: "the skill effects cover even the red circles that form on the ground before the attack hits"; "It's season 5, let us toggle off other player effects already. This is unplayable." Players noted that minions and traps are already transparent to other players and want the same for all skills — [CharlieIntel](https://charlieintel.com/diablo/diablo-4-players-desperate-for-fix-to-ally-skills-making-it-impossible-to-see-335851)
- Icy Veins: players ask for a toggle to hide other players' effects, or "an opacity or intensity slider rather than a hard on/off". D4 already de-prioritizes the visibility of Necromancer minions and some traps for other players — [Icy Veins](https://www.icy-veins.com/d4/news/diablo-4-effect-toggles-players-renew-calls-for-this-feature/)
- 20 May 2026: in 2023, other players' effects (Necromancer corpse explosions) hid enemy AoE and got teammates killed. Blizzard "made adjustments" (details not given). The *Lord of Hatred* Warlock has brought the problem back, and the community wants Warlock effects shown only to the Warlock player — [MeinMMO](https://mein-mmo.de/en/diablo-4-accidentally-killed-its-players-in-2023-now-the-problem-with-the-warlock-exists-again,1568357/)

**Risk of Rain 2**
- Review, 12 May 2021: "the effects on screen get really intense really quickly. To the point that you can't even see enemy attack alerts" (snippet) — [The Giant Brain review](https://giantbrain.co.uk/2021/05/12/risk-of-rain-2/)
- The community made a mod, "ShowDeathCause", that shows what killed you and the damage taken — evidence that the base game did not explain deaths well — [Thunderstore](https://thunderstore.io/package/NotTsunami/ShowDeathCause/). Steam players also describe "Killed by 'the planet'" as the fallback when the game can't work out the killer (snippet; exact thread not verified) — [Steam discussion](https://steamcommunity.com/app/632360/discussions/0/2141966124564475924)

**League of Legends**
- "League of Legends' visual clarity is an ongoing hotly debated issue." One complaint was about a skin that showed a *blue* ultimate indicator even when the champion was on the enemy team (snippet) — [Dot Esports](https://dotesports.com/?p=1248450)
- Some skillshots look dodged but still hit, because "the visual indicator of the spells sometimes does not correspond to the hitbox of the spell" (snippet) — [Millenium](https://us.millenium.gg/news/27474.html)

**Binding of Isaac**
- A Steam Workshop mod, "Enemy Bullet Trails", is called "Most useful mod of all time" in comments (snippet). Players point others to the in-game "bullet visibility" option set to "high" — [Steam Workshop comments](https://steamcommunity.com/sharedfiles/filedetails/comments/1180973766); [mod mirror](https://catalogue.smods.ru/?p=165690)

**Other ARPG and action forums with the same complaint** (thread titles only; content not read)
- Last Epoch: "Option to turn off on-hit flashing white effects" — [forum](https://forum.lastepoch.com/t/option-to-turn-off-on-hit-flashing-white-effects/32545); "Visual cues for enemy attacks are too dull" — [forum](https://forum.lastepoch.com/t/visual-cues-for-enemy-attacks-are-too-dull/58166); "VFX transparency" — [forum](https://forum.lastepoch.com/t/vfx-transparency/48307); and the opposite complaint, "You have gone overboard with the telegraphing" — [forum](https://forum.lastepoch.com/t/you-have-gone-overboard-with-the-telegraphing/26464)
- No Rest for the Wicked: "Finding it very hard to see enemies and attacks" — [forum](https://forum.norestforthewicked.com/t/finding-it-very-hard-to-see-enemies-and-attacks/20379)
- Space Marine 2: "Certain AoE attacks by Chaos enemies are either too quick, or too hard to see, or both" — [Focus community](https://community.focus-entmt.com/focus-entertainment/space-marine-2/ideas/16171-increase-visibility-and-warning-time-for-certain-aoe-attacks)

### Inferences
- The root complaint is about **draw priority and contrast**, not simply "too many effects". Even with a 25% opacity slider, overlapping self-FX stack back up to full opacity (Soulstone). An opacity slider alone is not enough: enemy telegraphs must sit on a layer that self-FX can never cover.
- **Color collisions are build-dependent.** If any of the player's weapons are red, orange or fire-colored, a red enemy-zone language breaks (Soulstone "chaos build", PoE2 "darker red flame wall"). So the friendly palette has to *exclude* the enemy hue entirely, not merely "mostly avoid" it.
- **The player's own HP bar and sprite get buried too.** Brotato had to fix "player HP bar being hidden by some effects" (see Q3), and in Vampire Survivors the Clock FX renders above the character. Keep the player and HP bar above all self-FX.
- **Deaths with no explanation are their own complaint** (RoR2's "the planet", the ShowDeathCause mod). A death recap ("killed by: spitter acid pool") is cheap and addresses it directly.
- Over-telegraphing also annoys players (Last Epoch thread title). Telegraph clarity should come from consistency and contrast, not from size and spectacle.

### Gaps
- No specific threads found for **HoloCure, Deep Rock Galactic: Survivor, Survivor.io, Nuclear Throne or Enter the Gungeon** about own-vs-enemy confusion. Searches returned nothing relevant, and app-store reviews were not searched.
- Reddit threads were not reachable directly (search returned only mirrors); the Steam, official-forum and press coverage above stands in for them.
- No developer replies were found in any of the PoE2 or Soulstone threads read.

---

## 2. Concrete techniques games use

### Takeaway
Shipped solutions cluster into: **(1) opacity or hide controls for one's own or others' effects** (Soulstone, Brotato, Isaac, D4 minions and traps, LoL perspective-dependent VFX); **(2) contrast and outline fixes on enemy projectiles** (Halls of Torment, Isaac "bullet visibility"); **(3) separate team colors** (Overwatch red/blue, Vampire Survivors co-op colors and outlines); **(4) shmup layer order with enemy bullets on top**; **(5) multi-channel damage feedback** (direction halo, flash, audio, haptics). Most "red-for-enemy outline" practice is folk convention or player proposal; I found no official Riot document that states it.

### Cited Findings

**Opacity / visibility controls**
- Soulstone Survivors: Settings > Graphics > "Special Effects Visibility" slider; moving it left lowers the opacity of your own skill FX — [Steam discussion](https://steamcommunity.com/app/2066020/discussions/0/3591086730691827584). The game can sometimes reset it to zero, so no skill effects appear at all — [Pro Game Guides](https://progameguides.com/soulstone-survivors/how-to-fix-spell-effects-not-showing-up-in-soulstone-survivors)
- Brotato (patch, Dec 2023): "Added projectile and explosion opacity options to improve visibility in endless mode"; also "Fixed the player HP bar being hidden by some effects" — [GamingOnLinux, 5 Dec 2023](https://www.gamingonlinux.com/2023/12/brotato-expanding-with-new-content-steam-deck-top-game/). A third-party guide lists a "Projectile Visibility" setting under Accessibility > Visual Aids, with levels from Normal/High Visibility (more opaque) down to Low Visibility (more transparent). Labels not verified in-game — [ludo.guide](https://www.ludo.guide/guide/brotato/getting-started/controls-keybindings/accessibility-options)
- Binding of Isaac: an options-menu "bullet visibility" setting that can be set to "high" for more contrast on enemy shots (user reports). One modder notes some shots end up invisible but can still be seen with high bullet visibility — [Steam Workshop comments](https://steamcommunity.com/sharedfiles/filedetails/comments/1180973766)
- Diablo IV: Necromancer minions and certain traps are de-prioritized (made transparent) for *other* players — [Icy Veins](https://www.icy-veins.com/d4/news/diablo-4-effect-toggles-players-renew-calls-for-this-feature/); [CharlieIntel](https://charlieintel.com/diablo/diablo-4-players-desperate-for-fix-to-ally-skills-making-it-impossible-to-see-335851)
- Deep Rock Galactic: Survivor (mobile v1.0.12): "Added Compatibility Mode to Video Settings when running in Vulkan. Less visual effects, but more stable experience. On by default." This is a performance option, not a readability one — [APKMirror listing](https://www.apkmirror.com/?p=12648645)

**Perspective-dependent VFX (show different things to the caster, enemies and allies)**
- Riot rates each spell's visual importance separately for the player, enemies and allies; "if these values differ significantly we might consider making a visual effect that looks different from different perspectives." Morgana R: "the circle is only shown to Morgana and targets affected by the chains" because to allies "it will only add visual clutter" — [Riot Beardilocks, Real Time VFX, 25 May 2020](https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062)
- LoL Teleport "is now colored based on enemy/ally team" (preseason summary; snippet) — [Rift Patch Notes](https://www.riftpatchnotes.com/lol/system/wards-vision)

**Vampire Survivors options (exact names)**
- "Flashing VFX" (Display / Favorites): toggles flashing effects. Since v1.6.0 (17 Aug 2023) the Pentagram flash also obeys it. "Damage Numbers" (Gameplay): hiding them also hides recovery numbers (fix 21 Jul 2022). "Disable blood" (v1.6.0). "Weapons ScreenShake". Co-op: "Show co-op indicators", "Permanent co-op outlines", "Player 1–4 Colour", "Tint UI selection". Mobile: "Orientation", "Touch screen control stick" — [Vampire Survivors Wiki: Options](https://vampire.survivors.wiki/w/Options)
- No opacity, hide-weapon-FX or "visible damage taken" option is listed — [Vampire Survivors Wiki: Options](https://vampire.survivors.wiki/w/Options)

**Contrast / outlines on enemy projectiles and sprites**
- Halls of Torment 2023-09-21: "improved contrast of bright purple enemy projectiles against bright backgrounds"; more contrast on burning-skull sprites (snippet) — [Prima Games](https://primagames.com/tips/halls-of-torment-update-2023-09-21-patch-notes)
- Dev bug-tracker suggestion for a bullet game: "A heavy outline on enemy bullets would do wonders here as would *not* having enemy shooting the same colour as the player" (snippet) — [Arcen bug tracker](https://bugtracker.arcengames.com/view.php?id=18624)
- For Honor (cited by Xbox): team symbols carry a black outline *and* a white outer outline. The white keeps them visible on dark backgrounds and the black on light ones — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- Eagle Island: a "dim backdrop" option (100% = solid black) plus "outline characters" / "outline platforms" add white outlines — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)

**Layer / draw order (shmup convention)**
- Shmup community advice: draw enemy bullets *above* player shots and keep them always visible, "since being hit by bullets you can't see is the bigger problem." Touhou: Imperishable Night uses semi-transparent, dimmer player shots that still read well because they move fast (snippet; page returned 403) — [shmups.system11 forum](https://shmups.system11.org/viewtopic.php?p=1485812)
- A design doc puts enemy bullets above everything, including player fire, and draws smaller bullets above larger ones. Recommended order: enemy bullets > player bullets > enemy sprites > player sprites (snippet) — [Google Doc (PDF export)](https://docs.google.com/document/d/1TZ7UIZTUeQjVwcPiGYbotG4FOLZQbC-ykNf23zEeKWM/export?format=pdf)
- Player proposals for PoE2: Z-order enemy > self > ally — [PoE forum](https://www.pathofexile.com/forum/view-thread/3598854). For Soulstone: enemy indicators as a "top layer" overlay — [Steam](https://steamcommunity.com/app/2066020/discussions/0/3591086730691827584)

**Team color language**
- Overwatch: enemy players have a red aura and nametag, friendlies the same in blue. Overwatch 2 lets you recolor UI/HUD elements, including player outlines, but "this does not extend into the actual characters effects from abilities, that are still red" (forum users; snippet) — [Blizzard forum](https://eu.forums.blizzard.com/en/overwatch/t/colour-blind-accessibility-issues/30890)
- Downwell: black / white / red palette, with red as the danger accent. Walls that hurt the player are drawn mainly in the highlight color (fan analysis, secondary) — [blog analysis](https://liighteffog.blogspot.com/2017/11/downwell-packs-lot-into-few-pixels.html); [Wikipedia](https://en.wikipedia.org/wiki/Downwell_(video_game))
- RoboQuest design note: "red explosion zones warn players of danger areas" (snippet) — [Game Designer Notes (Patreon)](https://www.patreon.com/GameDesignerNotes/posts/roboquest-combat-140820288)

**Telegraphs**
- Enemy attacks need a "small delay" (wind-up) before they land. The most common projectile telegraph is a charge-up: "A ball of particles accumulates around the barrel," then a "bright flash," then "the projectile let fly." Pair it with an audio cue (a "vacuum-cleaner-in-reverse" charge sound), voice-over and force feedback — [Mike Stout, "Enemy Attacks and Telegraphing", Game Developer, 2 Sep 2015](https://www.gamedeveloper.com/design/enemy-attacks-and-telegraphing)

**Damage-taken feedback and direction**
- Grounded: "the red halo indicates that damage is being taken, as well as the direction it's coming from." It is paired with grunt and beeping audio (the beeping plays when health is fully depleted), distinct hit sounds and controller vibration — [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)
- Immortals Fenyx Rising: "a white directional arrow with black outline" warns of an incoming attack and its direction — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- The damage flash informs the player "that they are receiving damage as well as the direction it is coming from" — [Giant Bomb concept page](https://giantbomb.com/damage-flash/3015-3282/)
- Isaac and many retro games show invincibility frames by flashing the sprite (snippet) — [DEV Community tutorial](https://dev.to/aleksandrhovhannisyan/invincibility-frames-in-unity-how-to-make-a-player-flash-when-taking-damage-4nkm)
- Darkness: Isaac Repentance patch: "Brightness around players has been increased in order to aid visibility in Curse of Darkness on lower gamma settings" (snippet) — [DualShockers](https://www.dualshockers.com/the-binding-of-isaac-repentance-patch-notes-full-list-of-new-features/)

### Inferences
- **The strongest pattern is asymmetric treatment.** Friendly effects get low alpha, soft edges and no hard outline, and are drawn under enemies. Enemy hazards get hard outlines, saturated warning colors and are drawn on top. Making both "pretty" and equally loud is the root of every complaint above.
- **Perspective-dependent rendering** (Riot's Morgana example, D4 transparent minions) generalizes to "render friendly AoE differently from hostile AoE even when it is the same skill art."
- **Draw order recommendation for a survivor-like** (bottom to top; my synthesis of the shmup order, the Soulstone overlay request and the Brotato HP-bar fix): ground tiles → *player* ground zones (low alpha, no outline) → *enemy* ground-zone fill/telegraph → pickups → enemies and the player sprite → *player* projectiles (dim) → *enemy* projectiles (bright, outlined) → *enemy* zone outlines re-drawn as an overlay → player HP bar and hurt flash → screen-edge damage vignette and off-screen arrows → HUD.
- Flashing is a damage cue but also a photosensitivity risk. Vampire Survivors and Last Epoch both had to add "turn off flashing" options, so pair any hurt-flash with a "Flashing VFX" toggle that falls back to a non-flashing tint.

### Gaps
- I found **no official Riot source** stating "enemy ability ground indicators have a red outline". The PoE2 player cites LoL as the precedent, and the LoL wiki only documents the blue self-range indicator — [LoL Wiki: Spell indicator](https://wiki.leagueoflegends.com/en-us/Spell_indicator). Treat "red border = enemy" as a genre convention, not a documented Riot rule.
- No source found for concrete **alpha values** (e.g., "self FX at 40%") in any shipped game. Soulstone players argue 25% is still too much because effects stack.
- No source found on Risk of Rain 2's own damage-direction indicator or option names; Hades or Hades II telegraph colors or timings; or the Nuclear Throne and Enter the Gungeon bullet color rules.
- No source found for **low-health heartbeat or vignette** conventions (the search returned nothing usable).

---

## 3. What GDC talks, dev blogs and design articles say (option names, patch notes)

### Takeaway
Developer-side sources agree on **visual hierarchy**: visual weight should match gameplay importance; "if everything is important, nothing is important"; damage effects are sharper and more threatening, while heals are green and soft. Accessibility guidance (Xbox XAG, Game Accessibility Guidelines) adds hard numbers: 4.5:1 contrast for standard gameplay elements, 3:1 for large ones, 7:1 in high-contrast mode, never color alone, and important cues on at least two senses. Exact option names that shipped: VS "Flashing VFX" / "Damage Numbers" / "Disable blood"; Soulstone "Special Effects Visibility"; Brotato "projectile and explosion opacity"; Isaac "bullet visibility".

### Cited Findings

**Riot (League of Legends) VFX**
- Designers keep a Visual Hierarchy document rating each spell's importance from 1 to 10, and "if everything is important, nothing is important." Damage "should be bigger, brighter, and more threatening, with sharper shapes"; "Heals should be green, and their shape should not feel threatening"; status effects should have a stronger visual than damage alone; and each ability needs "a unique visual identity" — [Riot Beardilocks, 25 May 2020](https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062)
- "League of Legends, after all, is a competitive game, and ideally no visual should take away from clarity." Effects should "clearly tell the size and directionality of an ability without being distracting or too subtle" — [Riot Phoenix dev blog, reposted 22 Jun 2015](https://www.surrenderat20.net/2015/06/red-post-collection-dev-blog-on-vfx.html)
- Riot's goal for small VFX updates: "improve the overall gameplay clarity of vfx" (Riot Beardilocks, via press; snippet) — [Dot Esports](https://dotesports.com/league-of-legends/news/vfx-changes-league-of-legends-14211)

**GDC**
- GDC 2024, "Attention Overload! Creating Readable VFX for *Suicide Squad: Kill the Justice League*", Hanno Hinkelbein (Rocksteady). Covers using VFX to guide attention when many character actions, weapons and talents all need feedback. Problems often come from VFX artists being brought in too late, after individual designs are already combined. The public abstract does not detail enemy vs. player color rules — [GDC Vault](https://gdcvault.com/play/1034360/Attention-Overload-Creating-Readable-VFX)
- GDC 2025 VFX Summit, "Crafting Clear and Satisfying VFX" (Rachel Quitevis): VFX should improve comprehension and readability (secondary summary; snippet) — [VFX Apprentice](https://www.vfxapprentice.com/blog/vfx-apprentice-at-gdc-2025)

**Telegraph design**
- Wind-up delay, charge-up particles, then a bright flash, then the shot, layered with sound, voice-over and haptics. Durations are not given — [Mike Stout, Game Developer, 2015](https://www.gamedeveloper.com/design/enemy-attacks-and-telegraphing)

**Xbox Accessibility Guidelines**
- XAG 102 (Contrast; doc date 2023-06-08): "Large-scale text and large-scale visual elements should meet a minimum contrast of 3:1"; standard-size visual elements that carry gameplay information should be "at least 4.5:1"; high-contrast mode should reach "7:1 for all UI elements". Measure "between the text and the lowest contrasting area of the background". Mobile large text is 36 px at 100 DPI / 72 px at 200 DPI / 144 px at 400 DPI. Approaches include adding borders around elements, letting players pick colors, and supporting a high-contrast mode. "Outlining characters or other key gameplay elements is helpful for increasing the contrast ratio … The color used for the outline should also be configurable" — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- XAG 102 note: "The use of red and green for targeting icons or other important elements can cause difficulty for players with certain types of colorblindness" — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- XAG 103 (Additional channels; doc date 2022-05-09): "Color alone should never be used to represent information." Critical visual content should also be expressed through "at least one other sensory method" (spatial audio, haptics). Critical color-coded content also needs "shape, pattern, iconography, or text labels". If color is the primary channel, let players configure colors through presets or free choice (e.g., Call of Duty: Black Ops Cold War lets players set minimap colors for player, allies, enemies and party). Its explicit anti-example: "enemy characters are outlined in red, ally characters are outlined in green" — [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)
- XAG 103's "impacted players" list includes "players who are reading text on a small screen … on a screen with glare … or playing with the sound off" — [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)

**Game Accessibility Guidelines**
- "Ensure no essential information is conveyed by a fixed colour alone": use color "as a back-up for another means of communicating the information"; use "additional signifiers first"; allow color-dependent UI and gameplay to be customized. Red/green deficiency affects "around 8-10% of males". "Orange Vs blue works for the three most common three types." Avoid whole-screen filters where possible. A player quote: "I really like it when they just change UI and the likes so I can tell the difference between enemies and friendlies" — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-colour-alone/)

**Patch notes and option names (dated)**
- Vampire Survivors: "Flashing VFX" (Pentagram flash obeys it from v1.6.0, 17 Aug 2023); "Damage Numbers" (hides recovery numbers too, 21 Jul 2022); "Disable blood" (v1.6.0); "Weapons ScreenShake"; "Permanent co-op outlines"; "Player 1–4 Colour" — [VS Wiki](https://vampire.survivors.wiki/w/Options)
- Brotato, Dec 2023: "Added projectile and explosion opacity options to improve visibility in endless mode"; "Fixed the player HP bar being hidden by some effects" — [GamingOnLinux](https://www.gamingonlinux.com/2023/12/brotato-expanding-with-new-content-steam-deck-top-game/)
- Halls of Torment 2023-09-21: enemy projectile and sprite contrast (snippet) — [Prima Games](https://primagames.com/tips/halls-of-torment-update-2023-09-21-patch-notes)
- Soulstone Survivors: Graphics > "Special Effects Visibility" — [Pro Game Guides](https://progameguides.com/soulstone-survivors/how-to-fix-spell-effects-not-showing-up-in-soulstone-survivors)
- Isaac Repentance: brighter area around the player under Curse of Darkness (snippet) — [DualShockers](https://www.dualshockers.com/the-binding-of-isaac-repentance-patch-notes-full-list-of-new-features/)
- Path of Exile 2: no patch found that adds ally/self opacity or ground-effect clarity options. Only map-mod ground-effect frequency fixes and "decreasing visual clutter on some maps" came up (snippet) — [poepatchnotes aggregate](https://poepatchnotes.pages.dev/poe2.html)
- Diablo IV: no patch found adding an "other players' effects" toggle as of the May 2026 coverage — [MeinMMO, 20 May 2026](https://mein-mmo.de/en/diablo-4-accidentally-killed-its-players-in-2023-now-the-problem-with-the-warlock-exists-again,1568357/); [Icy Veins](https://www.icy-veins.com/d4/news/diablo-4-effect-toggles-players-renew-calls-for-this-feature/)

### Inferences
- XAG's own example of bad practice ("enemy outlined in red, ally outlined in green") is exactly the naive own-vs-enemy zone scheme. The fix is *orange/red vs. blue* **plus** a non-color signal (outline style, pattern, icon, animation).
- The 4.5:1 / 3:1 contrast targets can be checked directly on palette swatches: enemy-hazard edge vs. the darkest and brightest floor tiles, and enemy bullet vs. floor. A 180×320 game has few colors, so this is quick to audit.
- Riot's hierarchy maps cleanly onto a survivor-like. Enemy damage zones get the top visual-importance rank; the player's own damage auras are low (the player already knows where they are); pickups are mid.

### Gaps
- No Supergiant (Hades), Hopoo or Gearbox (Risk of Rain 2), Poncle-authored, or Blobfish (Brotato) design-rationale article on telegraphs or own-vs-enemy readability was found. Only option and patch evidence exists.
- No Celia Hodent text was consulted (not found in searches within budget).
- No full talk content (slides/video) for the GDC 2024 Rocksteady talk; only the abstract.

---

## 4. Extra considerations for tiny pixel-art screens on phones (finger occlusion, low resolution, darkness)

### Takeaway
There is little formal research here. The evidence that exists says: keep critical information **above** the thumb zone; give everything important a hard outline because low resolution and glare kill subtle contrast; use a restricted palette where one hue means danger (Downwell); and add a light radius around the player in dark or night stages (Isaac's Curse of Darkness fix). Mobile versions of survivor-likes also expose orientation and touch-stick options and trim effects for performance.

### Cited Findings
- Finger occlusion: a community Godot mobile-adaptation guide says never to forget finger occlusion, puts the occluded area at roughly 50–100 px radius, and says to place critical info *above* touch controls, not below (community-authored; rule of thumb) — [Godot adapt-desktop-to-mobile guide](https://claudeskills.info/skills/thedivergentai/gd-agentic-skills/godot-adapt-desktop-to-mobile/)
- Joystick: a user test (n=11) of a portrait mobile game found no significant difference between floating and fixed joysticks on comfort, fatigue or learnability, and recommended floating for that game — [UPI thesis repository](https://repository.upi.edu/101077)
- Palm and edge accidental touches happen when the left thumb works a stick fixed in the lower-left corner (patent background) — [USPTO patent PDF](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/11590412)
- Vampire Survivors mobile exposes "Orientation" and a "Touch screen control stick" option — [VS Wiki](https://vampire.survivors.wiki/w/Options)
- Deep Rock Galactic: Survivor mobile ships a "Compatibility Mode" with "Less visual effects", on by default — [APKMirror](https://www.apkmirror.com/?p=12648645)
- Small screens and glare are named as situational impairments that contrast guidelines are meant to cover. XAG gives mobile "large text" sizes per DPI (36 px at 100 DPI, and so on) — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102); [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)
- Restricted palette at low resolution: Downwell is black, white and a red accent, with red signaling danger. Hurting walls and traps are drawn in the accent color (secondary analyses) — [blog](https://liighteffog.blogspot.com/2017/11/downwell-packs-lot-into-few-pixels.html); [Wikipedia](https://en.wikipedia.org/wiki/Downwell_(video_game))
- Darkness: Isaac Repentance increased "Brightness around players … to aid visibility in Curse of Darkness on lower gamma settings" (snippet) — [DualShockers](https://www.dualshockers.com/the-binding-of-isaac-repentance-patch-notes-full-list-of-new-features/)
- Dim the background and outline sprites: Eagle Island's backdrop dimming plus white character outlines — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- Telegraphs that look clear in close-up captures can fail at real gameplay zoom and with clutter, so review them under live conditions (blog; secondary) — [gamineai blog](https://gamineai.com/blog/enemy-telegraph-shape-language-top-down-boss-fights-fast-visual-consistency-audit-2026)

### Inferences (design proposals for a 180×320 portrait screen; not sourced as facts)
- **Player placement:** with a floating joystick in the bottom ~30% of the screen (about y > 225 of 320), keep the camera so the player sits around 40–45% of screen height (y ≈ 130–145). More danger-reading space then sits *in front of* the thumb than under it. Put the HP bar and status UI at the top edge, never bottom-center.
- **Joystick:** semi-transparent, and hidden while untouched (floating). Never draw it over enemy telegraphs; telegraphs near the bottom edge should still show an edge arrow.
- **Pixel budget:** at 180 px width, a 1 px soft-edged glow disappears on phone screens with glare. Give enemy projectiles at least 3×3 px bright cores *plus* a 1 px dark outline, the For Honor double-outline idea scaled down (bright core, dark rim). Give enemy ground zones a 1 px bright border plus a 1 px dark outer rim so they read on both dark and light floor tiles.
- **Night palette:** keep floor tiles dark and desaturated (low value, low chroma), and reserve high-chroma warm hues *only* for enemy hazards. Add a light radius around the player like Isaac's Curse of Darkness fix, and make enemy telegraphs **self-lit** (unaffected by the darkness overlay or fog) so night never hides a hazard. The PoE2 complaint is precisely that fog and foliage covered hazards.
- **Effect budget:** following DRG:S's mobile compatibility mode and the VS "limit max projectiles displayed" request, cap simultaneously drawn friendly particles. Drop friendly FX first, never enemy telegraphs.

### Gaps
- No peer-reviewed or platform-holder (Apple/Google) guidance found that gives exact thumb-occlusion areas for portrait games. The 50–100 px figure comes from a community guide.
- No source found on minimum readable projectile size for low-resolution pixel art on phones; the sizes above are my inference.
- No player-complaint data found specifically for Survivor.io or other mobile survivor-likes. App-store reviews were not searched.

---

## 5. Accessibility: colorblind-safe "friend vs. foe" (shape + color, not color alone)

### Takeaway
Use **orange/red vs. blue** (it holds up for the three common color-vision deficiency types), never red vs. green, and always **double-encode** with shape and motion: outline style, hatching or pattern, icon, flashing or filling animation. Offer a preset or custom color for the enemy-hazard color and a high-contrast mode. Avoid full-screen colorblind filters when possible; players prefer that only the friend/foe elements change.

### Cited Findings
- Red/green deficiency affects "around 8-10% of males". "Orange Vs blue works for the three most common three types". Use "additional signifiers first"; customization (presets plus a custom option) is the most-requested fix — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-colour-alone/)
- Players dislike whole-palette filters: "I hate it when games do that for colourblind mode", and prefer games that "just change UI and the likes so I can tell the difference between enemies and friendlies" — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-colour-alone/)
- "Color alone should never be used to represent information." The red-vs-green enemy/ally outline is given as the failing example. Cataracts, which also affect color perception, are "even more common than colorblindness" — [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)
- Configurable friend/foe colors: Black Ops Cold War lets players set minimap colors for player, allies, enemies and party — [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103). Battlefield 2042 offers Deuteranopia/Protanopia/Tritanopia/custom presets with a color picker, previewed in shadowy, midtone and bright environments — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- A partial implementation draws complaints: Overwatch 2 recolors HUD and outlines, but ability effects stay red (user report; snippet) — [Blizzard forum](https://eu.forums.blizzard.com/en/overwatch/t/colour-blind-accessibility-issues/30890)
- Faster Than Light's colorblind mode shifts the palette of enemy indicators and adds a pattern overlay for damaged areas (snippet of a gameaccessibilityguidelines.com page) — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/?p=688)
- Vampire Survivors co-op uses per-player colors *plus* "Permanent co-op outlines" and "Show co-op indicators", i.e. color plus outline plus marker — [VS Wiki](https://vampire.survivors.wiki/w/Options)
- Riot's shape language: damage uses "sharper shapes"; heals are green and non-threatening; roots use a floor ring plus a rising cylinder — [Riot Beardilocks 2020](https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062)

### Inferences (concrete friend/foe encoding proposal for the redesign)
| Channel | Enemy ground hazard (acid, fire, blast) | Player's own ground zone (aura, garlic-like, holy water-like) |
|---|---|---|
| Hue | warm: orange-red / magenta (one reserved "danger" hue family; no player weapon may use it) | cool: cyan / blue / white |
| Opacity | fill ~50–70%, edge 100% | fill ~25–40%, optional slider; no edge or a faint dotted edge |
| Outline | crisp 1 px bright edge + 1 px dark outer rim | none (soft gradient falloff) |
| Pattern / icon | diagonal hatching or chevrons; small skull or "!" glyph at center for large zones | plain fill or sparkle particles |
| Motion | telegraph = expanding fill ring (inner circle grows to the edge, then the hit); active zone = slow edge pulse | gentle rotation or shimmer; never flashes |
| Layer | drawn **above** all player FX (edge re-drawn as an overlay) | drawn at the lowest FX layer, below enemies |
| Sound | wind-up "hiss" or charge sound at spawn | none or very quiet |

- This keeps the distinction readable for deuteranopes and protanopes (warm vs. cool *plus* outline, hatching, pulse) and in grayscale (enemy = high-contrast edge, player = edgeless haze).
- Options to expose (names modeled on shipped games): "My effects opacity" (Soulstone/Brotato-style; default about 60–70%, range 0–100), "Enemy attack highlight" (Isaac-style "bullet visibility": Normal / High, where High adds a thicker outline and a brighter core), "Flashing effects" on/off (VS), "Damage numbers" on/off (VS), and "Danger color" presets (default orange-red / magenta / yellow).
- **Noticing incoming damage** (layered, so at least two channels survive mute or colorblindness, per XAG 103): (1) the player sprite flashes white, then blinks during i-frames; (2) a red screen-edge vignette biased toward the hit direction (Grounded-style halo), shown as a static tint when "Flashing effects" is off; (3) a short hurt sound plus phone vibration (optional); (4) a "-N" damage-taken number in a distinct color with a dark outline, above the player; (5) below about 30% HP, a persistent pulsing edge vignette plus a heartbeat loop (convention; not sourced); (6) off-screen ranged threats get edge arrows (Fenyx-style white arrow with black outline); (7) a death recap, "killed by: [enemy/hazard icon + name]", which answers the RoR2 "killed by the planet" complaint.

### Gaps
- No primary study validating a particular warm/cool pair for *pixel art at tiny sizes*. The orange-vs-blue advice is general (GAG).
- The heartbeat or low-HP vignette conventions are common practice, but I found no citable source within budget. Treat them as unsourced design convention.
- The FTL colorblind example comes from a snippet of a gameaccessibilityguidelines.com page; the page itself was not opened.
