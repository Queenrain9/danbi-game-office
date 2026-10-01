# One-Way Wizard — First Build Expected Result Derivation v0.1

Source: frozen `rules-v0.2.json` (validation reference hash `30e8fd88…f79a13`)

No full-game behavioral simulation is claimed. Expected values are derived from the frozen numeric rule table.

- Fixed tick: 1/60s → 60 ticks per simulated second.
- Wrap fixture: x=.99, heading0, speed=.22, step=.10 → .99+.022=1.012 → wrap to .012. Lifetime 18-.10=17.9.
- Mana: a valid cast changes 4→3. With no further spending, the next 4.0s regeneration returns it to4.
- Cap8: a ninth Bolt is rejected before cost.
- Redirect: heading0 +90° clockwise =90°.
- Split side: positive cross → parent+30°; negative cross → parent-30°. Child inherits remaining lifetime/damage/empowered flag.
- Merge fixture: headings0° and30° → circular mean15°; lifetimes10/12 → min(12+4,18)=16; damage2; empowered.
- Wave2 schedule contains7 enemies and the final scheduled spawn time is9.6s.

These expectations are copied into the locked RULE test. Human feel/readability questions remain outside this derivation.
