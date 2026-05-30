// Insights/Stats and Profile/Settings

function InsightsScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} eyebrow="14. Mai · diese Woche" title="Insights"
        action={<CircleBtn theme={t}>{I.filter(16)}</CircleBtn>}/>

      {/* Time toggle */}
      <div style={{ padding: '0 20px 14px', display: 'flex', gap: 6 }}>
        {['Woche','Monat','3M','Jahr'].map((r, i) => (
          <button key={r} style={{
            flex: 1, height: 32, borderRadius: 999,
            background: i === 0 ? t.text : 'transparent',
            color: i === 0 ? t.bg : t.textMid,
            border: i === 0 ? 'none' : `1px solid ${t.border}`,
            fontFamily: 'Geist Mono, monospace', fontSize: 11, fontWeight: 500, letterSpacing: 0.4,
          }}>{r}</button>
        ))}
      </div>

      <div style={{ padding: '0 20px 100px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        {/* Big hero: streak */}
        <div style={{ background: t.text, color: t.bg, borderRadius: 22, padding: 18, position: 'relative', overflow: 'hidden' }}>
          <div style={{ fontSize: 11, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 1, opacity: 0.6 }}>Streak · aktiv</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6 }}>
            <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 60, fontWeight: 500, letterSpacing: -2.4, lineHeight: 1, fontVariantNumeric: 'tabular-nums' }}>12</span>
            <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 14, opacity: 0.6 }}>Wochen</span>
          </div>
          <div style={{ display: 'flex', gap: 4, marginTop: 16 }}>
            {Array.from({ length: 12 }).map((_, i) => (
              <div key={i} style={{ flex: 1, height: 18, borderRadius: 3, background: i === 11 ? t.accent : 'rgba(255,255,255,0.22)' }}></div>
            ))}
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontFamily: 'Geist Mono, monospace', fontSize: 10, opacity: 0.5 }}>
            <span>KW 8</span><span>KW 20</span>
          </div>
        </div>

        {/* PR row */}
        <SectionHead theme={t}>Persönliche Bestleistungen</SectionHead>
        <div style={{ marginTop: -8, display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { ex: 'Bankdrücken', v: '90 kg', sub: '5×5 · neu', new: true },
            { ex: '5K Lauf', v: '24:42', sub: '−18s' },
            { ex: 'Deadlift', v: '140 kg', sub: '1RM-Schätz.' },
          ].map((p, i) => (
            <div key={i} style={{ background: t.surface, border: `1px solid ${t.border}`, borderRadius: 14, padding: '14px 16px', display: 'flex', alignItems: 'center' }}>
              <div style={{ width: 32, height: 32, borderRadius: 8, background: p.new ? t.accent : t.surface2, color: p.new ? t.accentText : t.text, display: 'flex', alignItems: 'center', justifyContent: 'center', marginRight: 12 }}>
                {I.bolt(16)}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: 'Geist, system-ui', fontSize: 14, fontWeight: 500 }}>{p.ex}</div>
                <div style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace', marginTop: 2 }}>{p.sub}</div>
              </div>
              <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 16, fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>{p.v}</div>
            </div>
          ))}
        </div>

        {/* Volume per muscle */}
        <Card theme={t} pad={16} style={{ marginTop: 6 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <span style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>Volumen / Muskelgruppe</span>
            <span style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>kg · KW20</span>
          </div>
          <div style={{ marginTop: 14, display: 'flex', flexDirection: 'column', gap: 10 }}>
            {[
              { l: 'Brust',     v: 4820, max: 5000, pct: 0.96 },
              { l: 'Rücken',    v: 5240, max: 5500, pct: 0.95 },
              { l: 'Beine',     v: 6120, max: 6500, pct: 0.94 },
              { l: 'Schultern', v: 1640, max: 2200, pct: 0.74 },
              { l: 'Arme',      v: 1340, max: 1800, pct: 0.74 },
            ].map(r => (
              <div key={r.l}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontFamily: 'Geist Mono, monospace', fontSize: 11, color: t.textMid, marginBottom: 4 }}>
                  <span style={{ fontFamily: 'Geist, system-ui' }}>{r.l}</span>
                  <span style={{ color: t.text, fontVariantNumeric: 'tabular-nums' }}>{r.v.toLocaleString('de-DE')}</span>
                </div>
                <div style={{ height: 6, background: t.surface2, borderRadius: 3, overflow: 'hidden' }}>
                  <div style={{ width: `${r.pct * 100}%`, height: '100%', background: r.pct > 0.9 ? t.accent : t.text, borderRadius: 3 }}></div>
                </div>
              </div>
            ))}
          </div>
        </Card>

        {/* AI Insight */}
        <Card theme={t} pad={16} style={{ borderColor: t.accent, background: t.surface }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
            <div style={{ width: 6, height: 6, borderRadius: 3, background: t.accent }}></div>
            <span style={{ fontSize: 10, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 1, color: t.accent, fontWeight: 600 }}>Beobachtung</span>
          </div>
          <div style={{ fontFamily: 'Geist, system-ui', fontSize: 15, lineHeight: 1.45, color: t.text }}>
            Dein Volumen für Schultern ist 3 Wochen flach. Pack einen Zusatzsatz auf Seitheben drauf?
          </div>
        </Card>
      </div>

      <TabBar active="me" theme={t}/>
    </Screen>
  );
}


function ProfileScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} title="Profil"
        action={<CircleBtn theme={t}>{I.settings(18)}</CircleBtn>}/>

      {/* User card */}
      <div style={{ padding: '0 20px 16px' }}>
        <Card theme={t} pad={18}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ width: 64, height: 64, borderRadius: 32, background: t.text, color: t.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Geist, system-ui', fontSize: 22, fontWeight: 600 }}>LB</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: 'Geist, system-ui', fontSize: 18, fontWeight: 600, letterSpacing: -0.4 }}>Lena Brunner</div>
              <div style={{ fontSize: 12, color: t.textMuted, fontFamily: 'Geist Mono, monospace', marginTop: 2 }}>lena@trackify.app</div>
              <div style={{ marginTop: 8, display: 'inline-flex', alignItems: 'center', gap: 6, padding: '3px 8px', background: t.accent, color: t.accentText, borderRadius: 4, fontSize: 10, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 0.6, fontWeight: 600 }}>{I.bolt(12)} Pro</div>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 0, marginTop: 16, borderTop: `1px solid ${t.border}`, paddingTop: 14 }}>
            {[
              { l: 'Workouts', v: '148' },
              { l: 'Läufe', v: '32' },
              { l: 'Streak', v: '12W' },
            ].map((s, i) => (
              <div key={s.l} style={{ textAlign: 'center', borderLeft: i === 0 ? 'none' : `1px solid ${t.border}` }}>
                <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 20, fontWeight: 500, fontVariantNumeric: 'tabular-nums', letterSpacing: -0.5 }}>{s.v}</div>
                <div style={{ fontSize: 10, color: t.textMuted, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 0.8, marginTop: 2 }}>{s.l}</div>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Settings groups */}
      <div style={{ padding: '0 20px 100px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        <SettingsGroup theme={t} label="Persönlich" items={[
          { l: 'Ziele & Plan', r: 'Muskelaufbau' },
          { l: 'Einheiten', r: 'kg · km · cm' },
          { l: 'Verbundene Geräte', r: 'Apple Watch' },
        ]}/>
        <SettingsGroup theme={t} label="App" items={[
          { l: 'Erscheinungsbild', r: 'Auto', toggle: false },
          { l: 'Erinnerungen', r: '08:00', toggle: true },
          { l: 'Live-Aktivitäten', r: 'an', toggle: true },
        ]}/>
        <SettingsGroup theme={t} label="Konto" items={[
          { l: 'Datenexport' },
          { l: 'Datenschutz' },
          { l: 'Abmelden', danger: true },
        ]}/>
        <div style={{ textAlign: 'center', fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace', padding: 12, letterSpacing: 0.8 }}>
          TRACKIFY · v2.4.1 (build 482)
        </div>
      </div>

      <TabBar active="me" theme={t}/>
    </Screen>
  );
}

function SettingsGroup({ theme, label, items }) {
  const t = theme;
  return (
    <div>
      <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.8, fontFamily: 'Geist Mono, monospace', padding: '0 4px 8px' }}>{label}</div>
      <div style={{ background: t.surface, borderRadius: 18, border: `1px solid ${t.border}`, overflow: 'hidden' }}>
        {items.map((it, i, arr) => (
          <div key={i} style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', borderBottom: i === arr.length - 1 ? 'none' : `1px solid ${t.border}` }}>
            <div style={{ flex: 1, fontFamily: 'Geist, system-ui', fontSize: 14, color: it.danger ? t.danger : t.text }}>{it.l}</div>
            {it.toggle !== undefined ? (
              <div style={{ width: 40, height: 24, borderRadius: 12, background: it.toggle ? t.accent : t.surface2, position: 'relative', transition: 'background .2s' }}>
                <div style={{ position: 'absolute', top: 2, left: it.toggle ? 18 : 2, width: 20, height: 20, borderRadius: 10, background: t.bg, transition: 'left .2s' }}></div>
              </div>
            ) : (
              <>
                {it.r && <span style={{ fontSize: 13, color: t.textMid, marginRight: 6, fontFamily: 'Geist Mono, monospace' }}>{it.r}</span>}
                <span style={{ color: t.textMuted }}>{I.chev(13, 'right')}</span>
              </>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, { InsightsScreen, ProfileScreen, SettingsGroup });
