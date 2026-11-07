# Survivor-like difficulty curves, spawn pacing, and player power growth

Scope note: wiki data comes from fan or datamined wikis (vampire.survivors.wiki, brotato.wiki.spellsandguns.com, holocure.wiki.gg, 20minutestilldawn.wiki.gg, deeprockgalactic.wiki.gg). These are community-maintained and can lag behind patches. Items marked "(snippet)" were seen only in search-result summaries, not in a fetched page. Treat them as lower confidence, and where a candidate URL is uncertain it is listed as such. Items marked "(derived)" are arithmetic I did from cited numbers. The Left 4 Dead Director source is from 2009, outside the 2021–2026 window, but it is included because it is the original primary source for "director" pacing.

## 1. How enemy HP and count scale over time and against player power

### Takeaway
The successful games rarely use one smooth global multiplier. Brotato adds a fixed amount of HP and damage per wave to each enemy type, plus flat Danger multipliers (+12/26/40%). Vampire Survivors mostly scales through a hand-authored per-minute table: new enemy types, a minimum-alive quota, and spawn interval. Only some enemies and bosses scale with player level, and Curse/Hyper/Inverse/Endless act as global multipliers on top. HoloCure keeps base stats flat until 23:00 and then ramps them per minute, with an exponential "kill screen" after 30:00. Every game uses hard spawn caps (VS 300/500, Brotato 100).

### Cited Findings
**Vampire Survivors (VS)**
- Normal Mad Forest enemies have no per-minute or per-level HP scaling listed on the stage page. Difficulty comes from the authored wave table: enemy types, a "Min" quota of alive enemies, and the spawn interval. Hyper mode lists enemy health "x3 (+0.05 per minute)", enemy minimum x1.25, and enemy and player move speed x2 — [Mad Forest](https://vampire.survivors.wiki/w/Mad_Forest)
- Mad Forest per-minute table (Min alive / spawn interval s):
  - 0:00 15/1.0; 1:00 30/1.0; 2:00 50/0.5 (+Bat Swarm); 3:00 40/0.25; 4:00 30/1.0; 5:00 10/1.0 (boss Mantichana); 6:00 20/0.5; 7:00 80/0.5; 8:00 100/1.5 (Giant Bat boss + swarm with 15 s delay); 9:00 30/0.5
  - 10:00 10/0.5 (Giant Mantichana boss + Flower Wall 60 s); 11:00 300/0.1; 13:00 150/0.5 (Ghost Swarm); 15:00 100/0.1 (Giant Werewolf + Flower Wall); 17:00 20/1.0 (Big Mummy introduced); 20:00 100/0.1 (Giant Mummy); 21:00–29:00 mostly 200–300/0.1
  - 30:00 the Reaper "clears all enemies on screen", and one more Reaper spawns per extra minute
  - The table also lists treasure-chest bosses roughly every 1–3 minutes (e.g., "Glowing Bat / Lv1, evo") — [Mad Forest](https://vampire.survivors.wiki/w/Mad_Forest)
- Enemies with the "HP x Level" skill have health "multiplied … based on the player's level". It is applied at spawn and "will not be updated in case the player gains levels while it's alive". Many unique bosses (The Trickster, The Stalker, The Drowner, The Maddener, The Ender, Goshadokuro, Mimics) have it — [VS Enemies](https://vampire.survivors.wiki/w/Enemies)
- Spawn rules:
  - "When 300 or more enemies are alive the game will not spawn more enemies periodically." Only bosses and map events can spawn until 500 are alive, then "no enemies will spawn".
  - Waves arrive about once per minute. If the minimum isn't met, enemies spawn "until the quota is filled".
  - Enemies spawn off-screen and can despawn if the player moves far away. Bosses are teleported back instead — [VS Enemies](https://vampire.survivors.wiki/w/Enemies)
- Curse:
  - Raises "the frequency and quantity of enemy waves, as well as their speed and health, by the percentage of Curse". Base is 100%, sources add together, and there is no cap.
  - The health effect applies immediately to new spawns. Other effects apply at the next minute.
  - The on-screen cap of 500 stays regardless.
  - Sources include the PowerUp (+10%/rank, max +50%), Skull O'Maniac (+10%/level, max +50%), and Torrona's Box (+100% at level 9) — [VS Curse](https://vampire.survivors.wiki/w/Curse)
- Other modes and stages:
  - Inverse Mode: enemies "start with +200% HP" plus +5% HP per minute. The movement-speed figure conflicts between the page and the Oct 2022 patch notes.
  - Endless Mode, per cycle: enemies +100% of base HP, spawn frequency and quantity +50%, enemy damage +25%.
  - The Bone Zone: +15% HP and +2.5% speed per minute, uncapped. Bat Country: +10% HP and +1.25% speed per minute.
  - Room 1665: enemy HP scales with player level.
  - Rewards for Inverse: +200% gold, +20% Luck — [VS Inverse Mode](https://vampire.survivors.wiki/w/Inverse_Mode)
- Conflict: a guide in search results gave Bone Zone as +15% HP per minute, while a community post said +3% (snippet). The wiki's Inverse page says +15% — [search snippet: rogueranker stages guide](https://rogueranker.com/vampire-survivors-stages/)

**Brotato**
- Each enemy has a base HP plus a "+hp/wave" value. Damage scales the same way using "+dmg/wave". Speed does not change with wave or Danger.
- Examples: a Tree has 10 HP at wave 1 and gains +5 per wave. A Pursuer at wave 11 has "10 base HP + 10×24 = 250 HP" — [Brotato Enemies](https://brotato.wiki.spellsandguns.com/Enemies)
- Danger modifiers are totals, not stacked:
  - D3: +12% HP and damage. D4: +26%. D5: +40%.
  - D1+ adds enemy types and moves some first-appearance waves earlier (e.g., Fly appears at wave 4 on D1+).
  - The accessibility sliders multiply with Danger — [Brotato Danger Levels](https://brotato.wiki.spellsandguns.com/Danger_Levels); [Brotato Enemies](https://brotato.wiki.spellsandguns.com/Enemies)
- Elites and bosses:
  - Elites have 750 HP (Monk and Turtle 700) and "75% health when spawning on Wave 11 or 12".
  - The wave 20 boss (Predator or Invoker) has 29,250 HP (30,712 on D5). On D5, two bosses spawn, each with 75% HP before the +40% modifier — [Brotato Enemies](https://brotato.wiki.spellsandguns.com/Enemies)
- Cap: "Waves have a maximum of 100 enemies that can be on screen at once". Excess random non-elite enemies die without dropping loot — [Brotato Enemies](https://brotato.wiki.spellsandguns.com/Enemies)

**HoloCure**
- Scaling formulas, recalculated every minute:
  - a = max(0, minute − 23) + 37·hour; b = minutes past 30:00 (+60 per hour past 1:00:00)
  - HP = (baseHP + baseHP·0.05·a)^(1 + b/50)
  - ATK = (baseATK + 2a)^(1 + b/25)
  - SPD = (baseSPD + 0.12a)^(…), max 300
- Phases: before 23:00 stats equal base; 23:00–30:00 a gradual rise; after 30:00 the spawn pool is "totally replaced with YAGOOs" and stats "skyrocket".
- Mini-bosses every 2 min and main bosses every 10 min (this likely describes Endless; see Q2).
- Spawn rate, spawn cooldown, and max enemy limit are per-phase variables. Periodic spawning stops at the limit, but timed events and bosses still spawn — [HoloCure Enemy](https://holocure.wiki.gg/wiki/Enemy)
- Hard Stage 3: "enemies are much stronger and faster", and the design is "much focused on dodging enemy attacks" (snippet) — [HoloCure Stage 3 (Hard)](https://holocure.wiki.gg/wiki/Stage_3_(Hard))

**20 Minutes Till Dawn (Darkness levels, cumulative)**
- D1: small-enemy spawn rate +25%
- D2: small-enemy HP +25%
- D3: elite HP +50%
- D4: boss HP +50%
- D5: elite damage x2
- D6: boss damage x2
- D7: small-enemy speed +15%
- D8: elite speed +25%
- D9: player gets 1 fewer upgrade choice
- D10: small-enemy damage x2 in the last 5 minutes
- D11: player XP −15%
- D12: small-enemy HP +50% more (75% total)
- D13: elite HP +75% more (125% total)
- D14: boss HP +100% more (150% total)
- D15: boss attack frequency +80%
- Source: [20MTD Darkness](https://20minutestilldawn.wiki.gg/wiki/Darkness)
- Boss HP: Shoggoth and Reaper 35,000; Hastur 30,000; Yog 10,000. Mini-boss Winged Terror has 18,000 — [20MTD Bosses](https://20minutestilldawn.wiki.gg/wiki/Bosses)

**Deep Rock Galactic: Survivor (DRG:S)**
- Hazard I–V raise "enemy density, faster movement and attack speed, increased enemy health and damage, special or elite variants". The guide gives no numbers — [Ludo.guide DRG:S hazard](https://www.ludo.guide/guide/deep-rock-galactic-survivor/getting-started/game-overview-ui/hazard-levels-and-difficulty-scaling)
- Gate mutators give concrete numbers, e.g., "Omega Grunts (Grunts: +15% HP, +15% DMG, +10% Speed)", "Serrated Claws II (Enemies: +20% DMG)", and "Hyper Mini Elites" (+30% Speed). Gate minimums run from Hazard 2+ to Hazard 5+ — [DRG wiki: Survivor Elimination](https://deeprockgalactic.wiki.gg/wiki/Survivor:Elimination)
- Player data on armor (Steam):
  - Armor has "different damage reduction curves depending on what hazard level you're playing on".
  - "~100 armor ≈ 83% reduction" (secondhand). "Game kinda soft caps around level 60."
  - Players ask devs to "tone down the swarm scaling" — [Steam DRG:S thread](https://steamcommunity.com/app/2321470/discussions/0/7607215003621904597)

**Halls of Torment (HoT)**
- Agony mode scales difficulty by performance. Higher Agony raises "the number of enemies, their health, and the amount of XP they drop" (snippet) — [PC Invasion](https://www.pcinvasion.com/?p=380733)
- Kills raise the meter and reviving lowers it. Players report the old version also drained the meter while monsters stayed alive, and the newer version rises only on kills. Not confirmed by an official patch note found (snippet, one of these threads) — [Steam thread A](https://steamcommunity.com/app/2218750/discussions/0/4029095104373831884); [Steam thread B](https://steamcommunity.com/app/2218750/discussions/0/4346618033170500747)

### Inferences
- (derived) Brotato's additive per-wave HP gives large relative jumps early and small ones late. A Pursuer (10 + 24/wave) goes 10 → 34 HP from wave 1 to 2 (3.4x), but only about +5% per wave near wave 20. Late difficulty therefore leans on more enemies, elites, new enemy types, and the boss rather than raw HP growth.
- VS's "Min alive" quota is a count floor, not a fixed spawn rate. If the player kills faster, more spawn, so density self-adjusts to player DPS. The 300 periodic / 500 hard cap bounds the top.
- Several games anchor enemy power to time or wave, not player level. VS reserves "HP x Level" for bosses and special enemies, and applies it only at spawn. Scaling everything by player level would cancel the player's growth, and none of these games do that globally.
- For a run where level resets each night, Brotato's per-wave additive model maps most directly onto "per-night" scaling: enemy stats as base + k·(night−1), plus tier multipliers. This is design inference, not tested.

### Gaps
- No public datamine found for DRG:S Hazard 1–5 HP, damage, or spawn multipliers. The base-game DRG hazard tables are a different game and should not be reused.
- A snippet claimed DRG:S biome penalties of +5% (Magma Core), +10% (Hollow Bough), and +15% (Salt Pits) enemy HP and damage. The source was not fetched, so it is unverified.
- Halls of Torment numbers for HP over time and Agony multipliers per level were not found. hallsoftorment.wiki.gg returned HTTP 401.
- Soulstone Survivors per-Curse enemy multipliers were not found. The only data is a player estimate that "Curse VII, 760% Overlord Mode" means about 60x enemy damage (snippet, Steam forum, thread URL unverified), and an old v0.3.3 mutation "+10% damage taken per curse" (snippet) — [steamdb patch 0.3.3](https://steamdb.info/patchnotes/9548739)
- No full Brotato table of enemy counts per wave.

## 2. How pacing is structured within a run: wave/lull rhythm, events, bosses, caps, directors

### Takeaway
Good pacing alternates pressure and relief on purpose. The VS Mad Forest table drops the minimum-alive count sharply when a new tougher enemy type or a boss arrives (e.g., Min 100 at 8:00 → 30 → 10 at 10:00), then spikes it (300 at 11:00). Brotato puts "challenging waves" (elite or horde, never both) only in fixed windows. Valve's L4D Director shows the canonical anti-overlap rules: suppress new threats after a peak (Relax 30–45 s), deal bosses from a shuffled deck with no repeats, and keep bosses outside adaptive pacing.

### Cited Findings
**Left 4 Dead AI Director (Booth, 2009, primary)**
- Population uses "Structured Unpredictability". Mobs spawn "at randomized interval between 90 and 180 seconds", 75% of the time from behind, with 20–30 Common Infected per mob. Mob size "grows from minimum just after spawn to maximum after a duration to balance difficulty of successive, frequent Mobs" — [Booth, AI Systems of L4D](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)
- Survivor Intensity:
  - Rises with damage taken, incapacitation, being pulled off ledges, and nearby infected dying ("inversely proportional to distance").
  - It decays toward 0 but does not decay "if there are Infected actively engaging the Survivor".
  - The Director tracks the max across 4 players — [Booth](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)
- Phases:
  - Build Up: "full threat population until Survivor Intensity crosses peak threshold".
  - Sustain Peak: "3-5 seconds".
  - Peak Fade: minimal population until intensity decays. It "won't allow the Relax period to start until a natural break in the action occurs".
  - Relax: "minimal threat population for 30-45 seconds, or until Survivors have traveled far enough".
  - Relax means "No Wanderers until team is 'calm', No Mobs, No Special Infected" — [Booth](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)
- "Boss Encounters NOT affected by adaptive pacing — overall pacing affected too much if they are missing." Bosses are placed every N units along the route. Tank, Witch, and Nothing are "shuffled and dealt out", and "successive repeats are not allowed" — [Booth](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)
- Design rationale:
  - "Constant, unchanging combat is fatiguing; long periods of inactivity are boring."
  - "Algorithm adjusts pacing, not difficulty — Amplitude (difficulty) is not changed, frequency (pacing) is."
  - "Survivor Intensity estimation is crude, yet the resulting pacing works" — [Booth](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)
- Commentary: the Director is "more of a story-telling device than … a simple difficulty mechanism" (Newell, quoted). There is "a fine line between pushing the player into the discomfort zone and unfairly screwing with the player". Players must have "plenty of options" when disrupted — [Game Developer, Serviss 2013](https://www.gamedeveloper.com/design/the-discomfort-zone-the-hidden-potential-of-valve-s-ai-director)

**Brotato**
- There are 20 waves. Wave 1 lasts 20 s and each wave adds 5 s up to 60 s at wave 9. Wave 20 lasts 90 s. Endless waves after 20 last 60 s — [Brotato Enemies](https://brotato.wiki.spellsandguns.com/Enemies); the 1.0 press release says "waves lasting 20 to 90 seconds" — [Game Developer press release](https://www.gamedeveloper.com/press-release/brotato-10-release)
- Challenging waves:
  - D0–1: none. D2–3: one. D4–5: three.
  - Timing: first at wave 11 or 12, second at 14 or 15, third at 17 or 18. The third is always an Elite wave.
  - The first two are 40% Horde / 60% Elite. A wave is one or the other.
  - Rewards: an Elite drops a Legendary crate that "heals 100 HP", and the same Elite never repeats in a run. Horde enemies drop 35% fewer materials — [Brotato Horde Wave](https://brotato.wiki.spellsandguns.com/Horde_Wave)
- Timed rare spawns: Looter has a 10% chance at 25 s into a wave, then every 15 s. Gobbler has a 3% chance at 10 s — [Brotato Enemies](https://brotato.wiki.spellsandguns.com/Enemies)

**Vampire Survivors**
- Events are layered on the minute table, with explicit delays: at 8:00, "Bat Swarm 80%, x3, 15s delay"; Flower Walls last 60 s at 10:00 and 15:00. Lulls are built in: Min drops to 10 at 5:00 and at 10:00 (boss minutes) and to 20 at 17:00 (new archetype, Big Mummy) — [Mad Forest](https://vampire.survivors.wiki/w/Mad_Forest)
- Hard stop: the Reaper at 30:00 clears the screen — [Mad Forest](https://vampire.survivors.wiki/w/Mad_Forest)
- A PC Gamer writer noted the game "wildly escalate[s] the assaults against you in the last 5–10 minutes" so new power has targets (snippet; URL candidate) — [PC Gamer](https://www.pcgamer.com/great-moments-in-pc-gaming-reaching-the-dps-singularity-in-vampire-survivors)

**HoloCure / 20MTD / HoT / Survivor.io**
- HoloCure Stage Mode: the final boss "appears after 20 minutes", and the stage ends when it is defeated. Main bosses come every 10 min and mini-bosses every 2 min (Enemy page) — [HoloCure Stage](https://holocure.wiki.gg/wiki/Stage); [HoloCure Enemy](https://holocure.wiki.gg/wiki/Enemy)
- 20MTD: "When bosses spawn, a rectangular electric barrier traps the player for 1 minute" — a dedicated arena phase separate from the swarm — [20MTD Bosses](https://20minutestilldawn.wiki.gg/wiki/Bosses)
- HoT: 30-minute runs. "Hordes grow denser as the run progresses", mini-bosses appear at set times with telegraphed attacks, and surviving the full run brings one of the Lords — [Wikipedia: Halls of Torment](https://en.wikipedia.org/wiki/Halls_of_Torment). A player reported bosses don't scale with time and a boss engaged at about 59:43 died almost instantly (snippet, single anecdote)
- Survivor.io Chapter 1 (fan guide): minute 13 brings waves "from all sides", minute 14 zombie dogs, and at minute 15 the "third and final boss". Chapter 2 runs about 15–16 min with 3 bosses. Elites and bosses drop chests — [simplegameguide Ch1](https://simplegameguide.co.uk/how-to-beat-chapter-1-survivor-io); [Ch2 guide](https://simplegameguideorg.pages.dev/how-to-beat-chapter-2-survivor-io); [progameguides](https://progameguides.com/survivor-io/how-to-clear-chapters-1-10-in-survivor-io/)

**DRG:S stage rhythm**
- "Constant trickle of enemies that builds to a larger wave". Waves per stage: S1 one, S2 two, S3 three, S4 three.
- Combat continues "until Elite enemies spawn". When they are defeated, the Drop Pod returns. A mid-stage Supply Pod run gives Artifacts.
- Stage 5: four Elites, then a Dreadnought (50% Glyphid Dreadnought / 50% Twins). Players can force the timing by tearing open cocoons — [DRG wiki: Survivor Elimination](https://deeprockgalactic.wiki.gg/wiki/Survivor:Elimination)

### Inferences
- A pattern recurs across Brotato, DRG:S, 20MTD, and L4D. Elites or bosses are put in their own slot, not stacked on peak swarm density:
  - Brotato: either a horde or an elite, never both.
  - DRG:S: elites end the stage after waves.
  - 20MTD: a boss arena that separates the fight.
  - L4D: bosses are dealt separately, with Relax after peaks.
- VS sometimes stacks a boss with a swarm, but it uses delays (e.g., 15 s) and drops the minimum-alive count on boss minutes.
- For 3-minute nights, a minimal rule set modeled on Booth: one Build Up → Peak → short Relax per night, with elites only during Relax or replacing the peak. Intensity could be estimated from damage taken and nearby kills. This is untested design inference.
- Brotato's ramp of 20 → 60 s wave length means early rounds are short and low-risk. That supports a lighter, shorter opening rather than full density from second 0.

### Gaps
- No primary source found for Survivor.io elite/boss minute marks by Habby; only low-authority fan guides.
- HoT per-stage boss timings conflict: one guide says the Imp Chieftain appears at 24:00, another says early in the stage. Wiki access failed.
- No 20MTD per-map spawn session values; the wiki fields (SpawnCD, Max, Num p/spawn) were empty in the fetch.

## 3. Pacing player power growth: XP curves, slots, evolutions, card pools, reroll/banish, and avoiding late-game boredom

### Takeaway
Power is gated by four things: a rising XP cost per level, hard slot caps (VS: 6 weapons + 6 passives, max level, no offers once maxed), evolutions that need conditions plus a boss/chest drop, and difficulty modes that remove choices (20MTD Darkness 9: −1 choice, D11: −15% XP). Brotato delays level-up rewards to the end of the wave so power doesn't spike mid-fight. Players widely say VS becomes boring once a build "comes online" around 15–17 min. The fixes used are stronger late escalation (VS's last 10 min, HoloCure's post-23:00 scaling, a timed kill-screen or Reaper) and opt-in multipliers (Curse, Hyper, Inverse, Endless, Danger, Darkness).

### Cited Findings
- VS XP: level 1→2 costs 5 XP and each level adds +10 XP through level 20. Levels 21–40 add +13 per level, then +16. Levels 20 and 40 need an extra 600 and 2,400 XP, with +100% Growth until the next level — [VS Level up](https://vampire.survivors.wiki/w/Level_up)
- VS level-up offers:
  - 3 or 4 options (4 with Luck). Owned items get an extra Luck-based chance to appear. Maxed items are not offered.
  - When nothing is left, the options become Floor Chicken or Gold.
  - Reroll, Skip, and Banish are PowerUps. "Rerolls and Skips are unavailable when the inventory is full" — [VS Level up](https://vampire.survivors.wiki/w/Level_up)
- VS evolution gating: the Mad Forest table tags specific boss chests (e.g., "Glowing Bat / Lv1, evo" at 1:00, "Giant Mantichana / Lv1, evo" at 10:00), so evolutions arrive through boss-dropped chests on a schedule — [Mad Forest](https://vampire.survivors.wiki/w/Mad_Forest)
- Brotato XP to next level = (Level+3)². Level 0→1 costs 16 XP and 1→2 costs 25. Cumulative XP for level 20 is 4,310. Each level gives +1 Max HP immediately and "an Upgrade at the end of the wave" — [Brotato Experience](https://brotato.wiki.spellsandguns.com/Experience)
- HoT: level-up picks from four stat increases, with reroll. Bosses drop a scroll granting new abilities for the run plus a chest with a choice of 3 armor/jewelry items — power spikes are tied to boss kills — [Wikipedia: Halls of Torment](https://en.wikipedia.org/wiki/Halls_of_Torment)
- 20MTD reduces player power as a difficulty lever: D9 gives 1 fewer upgrade choice and D11 gives −15% XP — [20MTD Darkness](https://20minutestilldawn.wiki.gg/wiki/Darkness)
- DRG:S player: "Game kinda soft caps around level 60", so bonus XP adds little late — [Steam DRG:S thread](https://steamcommunity.com/app/2321470/discussions/0/7607215003621904597)
- Player sentiment on the VS late game (snippets from Steam threads; exact thread for each quote unverified):
  - "Around 15-17 minute mark I either die horribly or I have correct skills set and for the remaining 15 minutes game is boring and everything around me just dies."
  - "It's too hard and I always lose, but if I turn off Charm and Curse… it's too easy and I always win" — candidates: [Steam VS thread](https://steamcommunity.com/app/1794680/discussions/0/3275813740941980470), [Steam VS thread 2](https://steamcommunity.com/app/1794680/discussions/0/3489752656787332984)
- Commentary: VS works because it "is well tuned and letting you go absolutely wild with power" (snippet) — [Escapist](https://www.escapistmagazine.com/roguelites-items-power-scale-game-development-vampire-survivors/). The A.V. Club argued Vampire Crawlers recreates the feeling when things get "too damn easy", and that its penalties "arrive too late" (snippet) — [A.V. Club](https://www.avclub.com/game-theory-vampire-crawlers)
- An indie survivors-like dev conceded "the game being too easy after the weapon is maxed out" was a fair critique. Another player said it "became impossible to lose since the powerups took care of everything" (snippets, itch.io; exact post URLs unverified) — e.g., [itch post](https://itch.io/post/13299231)
- A Reddit thread (third-party mirror) argued the problem is how power scales with your position on the curve, and that reused mechanics make the late game feel "way too easy" (snippet) — [Reddit snapshot](https://reddit.sentinel-team.org/posts/1qknjks/snapshots/2026-01-23T18%3A30%3A03.889978Z)

### Inferences
- (derived) VS cumulative XP to reach level L (L ≤ 21) = 5·(L−1)². Level 10 needs 405 XP and level 20 needs 1,805. Brotato's cumulative cost grows roughly cubically, about 1 level per wave over 20 waves (4,310 XP by level 20). Both make each later level cost much more, so slots fill early and evolutions and maxing come mid-to-late.
- Where the power fantasy peaks: in VS, players report it at about 15–17 min of 30. The designer response is a much denser late table (Min 300, 0.1 s intervals from 21:00) and a hard Reaper end at 30:00. A time-boxed run ends before "everything dies" becomes long.
- For a game where level resets every 3-minute night, a VS-style curve would refill every slot each night. Testers' complaint that all skills are learned early fits that structure (inference).
  - Brotato-style "upgrade at end of wave" or 20MTD-style choice/XP throttles are documented alternatives.
  - So is HoT-style tying of big ability unlocks to boss kills.
  - This is design inference; no game in this set uses exactly the reset-each-stage model.
- Evolutions that "melt everything": in VS, evolutions arrive through scheduled boss chests, and the table then ramps density immediately (10:00 → 11:00 Min 10 → 300). The spike is followed by a content ramp, not left unmatched.

### Gaps
- No exact VS evolution rule fetched (max weapon level + required passive + chest; chest timing restrictions). Only the chest "evo" tags from the stage table.
- No public numbers on typical level reached per run (VS, HoloCure, HoT), or on card-pool size vs. level-ups per run.
- Soulstone Survivors skill/rune pool sizes and level pacing were not found.

## 4. How multi-stage and chapter structures keep stage 2+ from feeling like grinding

### Takeaway
Games that go multi-stage add something new at each step: new enemy rosters and bosses per map, more waves per stage (DRG:S 1 → 2 → 3 → 3 → boss gauntlet), stacked mutators per sector/gate, and harder remixes of earlier maps (HoloCure Hard stages focused on dodging). Critics flagged HoT for "level design wasn't unique enough across stages", so per-stage novelty is noticed when missing.

### Cited Findings
- DRG:S Elimination:
  - 5 stages, with waves per stage rising 1, 2, 3, 3.
  - Stage 5 is a gauntlet of 4 Elites then a Dreadnought (50/50 between two boss variants).
  - A shop between stages, and a mid-stage Supply Pod objective.
  - Each sector adds mutators: Sector 02 "The Floor is Lava, Dark Caves…", Sector 05 "Hardened Carapace III, Hyper Mini Elites…"
  - Each gate adds a player buff ("Mandatory Pep Talk: +10% XP Gain…") alongside an enemy buff ("Omega Grunts") — [DRG wiki: Survivor Elimination](https://deeprockgalactic.wiki.gg/wiki/Survivor:Elimination)
- HoloCure:
  - 5 regular stages, each with distinct major bosses (e.g., Stage 1 Fubuzilla and Smol Ame; Stage 2 Mikodanye and A-chan).
  - Recommended shop upgrades rise per stage (Stage 2: ATK/SPD Lv2 … Stage 5: Lv5). HoloCoin multipliers go x1.0 → x1.5.
  - Hard variants (x1.4–x1.9) reuse maps with combined bosses plus a new one — [HoloCure Stage](https://holocure.wiki.gg/wiki/Stage)
- HoloCure Stage 3 (Hard): "all enemies before the 22:00 mark appear just as they did in Stage Mode", and enemies after Spiderchama get end-game scaling (snippet) — [HoloCure Stage 3](https://holocure.wiki.gg/wiki/Stage_3)
- HoT: "Six levels, each with a different layout, from open spaces to a long bridge with enemies on both sides". Ars Technica "felt the level design wasn't unique enough across stages" — [Wikipedia: Halls of Torment](https://en.wikipedia.org/wiki/Halls_of_Torment)
- Brotato in-run novelty:
  - New enemy types have set first-appearance waves, shifted earlier at higher Danger (e.g., Fly D1 at wave 4).
  - Elite waves at 11/12, 14/15, and 17/18 never repeat the same Elite.
  - Wave 20 is a boss (random of 2) — [Brotato Enemies](https://brotato.wiki.spellsandguns.com/Enemies); [Brotato Horde Wave](https://brotato.wiki.spellsandguns.com/Horde_Wave)
- VS: each minute row introduces or swaps enemy types (Skeleton at 3:00, Werewolf at 12:00, Big Mummy at 17:00, Flower Wall/Venus at 21:00), so novelty is authored per minute — [Mad Forest](https://vampire.survivors.wiki/w/Mad_Forest)
- Survivor.io: each chapter is about 15 min with its own enemy roster (e.g., Chapter 2 "butterflies, zombie dogs, construction zombies") and multiple bosses. Difficulty "increasingly more difficult with each stage" (snippet) — [simplegameguide Ch2](https://simplegameguideorg.pages.dev/how-to-beat-chapter-2-survivor-io); [PocketGamer guide](https://www.pocketgamer.com/survivor-io/guide/)

### Inferences
- The common per-stage novelty is roughly: one or more new enemy archetypes, a new boss, and one rule change (mutator or hazard), plus one more "beat" than the previous stage (DRG:S wave count). For a 30-night run, this suggests a deck of mutators, enemy sets, and boss variants dealt across nights. This mirrors Booth's "shuffle and deal, no successive repeats" boss rule. It is untested design inference.
- DRG:S pairs a player buff with an enemy buff at each gate. That keeps later stages feeling like progress rather than a pure tax.

### Gaps
- No source found describing Soulstone Survivors' per-stage novelty or chapter structure in detail.
- No developer statements (Funday, Habby, Chasing Carrots) on why each stage introduces what it does; interviews found were about business and scope, not tuning.

## 5. Difficulty tiers for casual and hardcore players

### Takeaway
The standard pattern is a ladder of cumulative, unlockable tiers that you clear one at a time: Brotato Danger 0–5, 20MTD Darkness 0–15, DRG:S Hazard I–V, VS Curse/Hyper/Inverse/Endless, HoloCure Hard stages, and HoT per-stage Agony. Brotato also offers free accessibility sliders for enemy HP, damage, and speed, which stack with Danger. Higher tiers usually pay more (gold, coins, XP).

### Cited Findings
- Brotato:
  - Danger 0 has "No modifiers". D1–2 add enemy types and elite waves. D3/4/5 give +12/26/40% enemy HP and damage, and D5 adds two bosses.
  - Accessibility sliders multiply with Danger — [Brotato Danger Levels](https://brotato.wiki.spellsandguns.com/Danger_Levels)
  - The 1.0 press release lists "Accessibility options: tweak the health, damage and speed of enemies" — [Game Developer press release](https://www.gamedeveloper.com/press-release/brotato-10-release)
- 20MTD: 16 cumulative Darkness levels, mixing enemy buffs with player nerfs (−1 choice, −15% XP) — [20MTD Darkness](https://20minutestilldawn.wiki.gg/wiki/Darkness)
- VS:
  - Curse is an uncapped, additive, player-chosen difficulty stat (PowerUp ranks, items).
  - Hyper: x3 HP +0.05/min on Mad Forest, +50% gold.
  - Inverse: +200% HP, +5%/min, +200% gold, +20% Luck.
  - Endless cycles: +100% base HP, +50% spawns, +25% damage per cycle — [VS Curse](https://vampire.survivors.wiki/w/Curse); [VS Inverse Mode](https://vampire.survivors.wiki/w/Inverse_Mode); [Mad Forest](https://vampire.survivors.wiki/w/Mad_Forest)
- HoloCure Hard stages unlock after clears and come with recommended upgrade levels (Lv5–8) and coin multipliers (x1.4–x1.9). Hardcore (1 HP) is a free toggle — [HoloCure Stage](https://holocure.wiki.gg/wiki/Stage)
- DRG:S: higher Hazard unlocks by completing missions at the previous level — [Ludo.guide](https://www.ludo.guide/guide/deep-rock-galactic-survivor/getting-started/game-overview-ui/hazard-levels-and-difficulty-scaling). Players still say the low tiers are hard: "Haz 2 outrageously difficult, it's honestly not fun" (snippet; thread is one of [this](https://steamcommunity.com/app/2321470/discussions/0/6292161380815773812/?ctp=3) or [this](https://steamcommunity.com/app/2321470/discussions/0/6292161380806441869)), and "The game is more difficult than other survivor-type games" — [Steam DRG:S thread](https://steamcommunity.com/app/2321470/discussions/0/7607215003621904597)
- HoT Agony is per stage, unlocked by beating that map's final boss, and scales with kill speed (snippet) — [Prima Games](https://primagames.com/gaming/halls-of-torment-what-is-agony-mode)
- Soulstone: players call high-Curse density and AoE spam a turn-off (snippet; Steam forum threads, exact URL unverified, e.g., [Steam Soulstone thread](https://steamcommunity.com/app/2066020/discussions/0/3725071921958800457))

### Inferences
- Tier 0 in these games is deliberately easy: Brotato D0 has no elites, 20MTD D0 no modifiers, and VS has no Curse at base. Hardcore depth comes from cumulative, optional modifiers. A VS player's "too hard with Curse/Charm, too easy without" suggests tiers need intermediate steps; big single jumps leave gaps.
- Tiers that remove player options (20MTD fewer choices or less XP) are a lever that directly targets "skills all learned early" (inference).

### Gaps
- No published data on what share of players use each tier (completion rates per Danger or Darkness).
- No DRG:S numeric definition of Hazard tiers.

## 6. How developers tune balance: models, TTK targets, bots, GDC talks and postmortems

### Takeaway
Booth's L4D talk is the strongest primary source on method: crude metrics plus simple rules give good pacing, and the Director changes frequency, not amplitude. For the survivors-likes themselves (poncle, Blobfish, Chasing Carrots, Funday), I found no public GDC talk or postmortem with balance spreadsheets or bot simulations. What exists is generic: spreadsheet DPS/TTK matrices, an "enemy HP spawned per second ≈ player DPS" rule of thumb, and Machinations-style models.

### Cited Findings
- Booth: "Algorithm adjusts pacing, not difficulty — Amplitude (difficulty) is not changed, frequency (pacing) is"; "Simple algorithms can generate compelling pacing schedules"; "Survivor Intensity estimation is crude, yet the resulting pacing works" — [Booth](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)
- Spreadsheet method: put weapon DPS next to cost and time-to-kill per enemy tier. Use one global multiplier cell instead of many manual edits. Track derived values (DPS, effective HP, TTK matrices) rather than raw stats — [bugnet.io blog](https://bugnet.io/blog/balancing-your-game-with-spreadsheets)
- Reverse-engineering: pick a target hit count (e.g., kill in about 10 hits) and work backward. A spreadsheet "can't capture the intended feel of each enemy type" (snippet) — [threadreader thread](https://threadreaderapp.com/thread/1301990872645468160.html)
- Machinations community model: test enemy HP tiers (normal/strong/elite/boss) with exponential per-minute HP over a 15-minute run, tracking TTK by weapon — [Machinations example](https://machinations.io/community/vofkamain/create-a-game-balance-d8ea5823510311f190390abc5ce0dcc9)
- Reddit rule of thumb: match enemy HP spawned per second to player DPS (snippet; third-party mirror) — [Reddit snapshot](https://reddit.sentinel-team.org/posts/1pszqx8/snapshots/2025-12-22T18%3A20%3A48.256768Z)
- HoT: the devs named VS as the biggest influence and 20MTD as the first genre game that got them thinking. They chose Godot, and started concept work in October 2022 — [Wikipedia: Halls of Torment](https://en.wikipedia.org/wiki/Halls_of_Torment). A W4 Games interview with Chasing Carrots exists but returned HTTP 404 when fetched.
- Brotato designer Thomas Gervraud's stated goal was to combine survivor-likes with "auto-chess style shop mechanics" for synergy builds. No balance-method statements found — [Game Developer press release](https://www.gamedeveloper.com/press-release/brotato-10-release)

### Inferences
- One quantitative method fits the evidence: model per-night "enemy HP arriving per second" vs. expected player DPS at that night's power. Keep the ratio below 1 in the first minute and let it pass 1 only at the planned peak. VS's Min-alive quota and Brotato's 100 cap are runtime safety valves for the same balance. This is untested inference.
- An automated bot run (e.g., a stand-still or kite bot logging time-to-clear, damage taken, and level per night) is the cheap version of Booth's "crude intensity estimate". No survivors-like dev publicly documented doing this.

### Gaps
- No GDC talk or written postmortem found from poncle (VS), Blobfish (Brotato), Chasing Carrots (HoT), Funday Games (DRG:S), Kay Yu (HoloCure), flanne (20MTD), Game Smithing (Soulstone), or Habby (Survivor.io) that documents balance spreadsheets, TTK targets, or simulations. Searches surfaced only press releases, business-focused interviews (e.g., Funday's CCO saying "innovation for innovation's sake is too expensive"), and reviews.
- The W4 Games / Chasing Carrots interview (Godot-specific, possibly relevant to enemy-count performance) could not be fetched (404).
