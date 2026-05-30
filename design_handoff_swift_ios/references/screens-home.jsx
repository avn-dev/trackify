// Home / Dashboard screen

function HomeScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      {/* Top bar */}
      <div style={{ padding: '54px 20px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <div style={{ fontSize: 12, color: t.textMuted, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 0.8 }}>Mittwoch · 14. Mai</div>
          <div style={{ fontFamily: 'Geist, system-ui', fontSize: 26, fontWeight: 600, letterSpacing: -0.8, marginTop: 2 }}>Hey, Lena.</div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <CircleBtn theme={t}>{I.bell(18)}</CircleBtn>
          <div style={{ width: 40, height: 40, borderRadius: 20, background: t.surface2, border: `1px solid ${t.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Geist, system-ui', fontSize: 14, color: t.text, fontWeight: 600 }}>LB</div>
        </div>
      </div>

      <div style={{ padding: '20px 20px 100px', display: 'flex', flexDirection: 'column', gap: 14 }}>

        {/* Today's training card — hero */}
        <div style={{ background: t.text, color: t.bg, borderRadius: 24, padding: 20, position: 'relative', overflow: 'hidden' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: 11, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 1, opacity: 0.6 }}>Heute · Tag A</span>
            <span style={{ background: t.accent, color: t.accentText, fontSize: 10, fontWeight: 600, padding: '4px 8px', borderRadius: 6, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 0.6 }}>Push</span>
          </div>
          <div style={{ fontFamily: 'Geist, system-ui', fontSize: 26, fontWeight: 600, letterSpacing: -0.6, marginTop: 14, lineHeight: 1.1 }}>Brust · Schulter · Trizeps</div>
          <div style={{ display: 'flex', gap: 18, marginTop: 16, fontFamily: 'Geist Mono, monospace', fontSize: 12, opacity: 0.7 }}>
            <span>6 Übungen</span><span>·</span><span>~58 Min</span><span>·</span><span>22 Sätze</span>
          </div>
          <button style={{ marginTop: 18, background: t.accent, color: t.accentText, border: 'none', borderRadius: 14, height: 46, width: '100%', fontFamily: 'Geist, system-ui', fontSize: 15, fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
            {I.play(14)} Workout starten
          </button>
        </div>

        {/* Weekly stat row */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <Card theme={t} pad={16}>
            <div style={{ display: 'flex', justifyContent: 'space-between', color: t.textMuted, fontSize: 11, textTransform: 'uppercase', letterSpacing: 0.5, fontFamily: 'Geist Mono, monospace' }}>
              <span>Diese Woche</span>{I.dumbbell(14)}
            </div>
            <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 28, fontWeight: 500, letterSpacing: -1, marginTop: 8, fontVariantNumeric: 'tabular-nums' }}>
              3<span style={{ color: t.textMuted, fontSize: 14 }}> / 4</span>
            </div>
            <div style={{ fontSize: 11, color: t.textMid, marginTop: 4 }}>Workouts</div>
            <div style={{ marginTop: 12, display: 'flex', gap: 4 }}>
              {['Mo','Di','Mi','Do','Fr','Sa','So'].map((d, i) => (
                <div key={d} style={{ flex: 1, textAlign: 'center' }}>
                  <div style={{ height: 24, borderRadius: 4, background: [0,2,3].includes(i) ? t.accent : (i === 4 ? t.borderStrong : t.surface2), border: i === 4 ? `1px dashed ${t.borderStrong}` : 'none', boxSizing: 'border-box' }}></div>
                  <div style={{ fontSize: 9, color: t.textMuted, marginTop: 4, fontFamily: 'Geist Mono, monospace' }}>{d[0]}</div>
                </div>
              ))}
            </div>
          </Card>
          <Card theme={t} pad={16}>
            <div style={{ display: 'flex', justifyContent: 'space-between', color: t.textMuted, fontSize: 11, textTransform: 'uppercase', letterSpacing: 0.5, fontFamily: 'Geist Mono, monospace' }}>
              <span>Volumen</span>{I.trend(14, true)}
            </div>
            <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 28, fontWeight: 500, letterSpacing: -1, marginTop: 8, fontVariantNumeric: 'tabular-nums' }}>
              18.420<span style={{ color: t.textMuted, fontSize: 14 }}> kg</span>
            </div>
            <div style={{ fontSize: 11, color: t.accent, marginTop: 4, fontFamily: 'Geist Mono, monospace' }}>↑ 14% vs. Vorw.</div>
            <div style={{ marginTop: 8 }}>
              <LineChart theme={t} width={150} height={36} showAxis={false} accent data={[{y:12},{y:14},{y:13},{y:17},{y:16},{y:19},{y:21}]} />
            </div>
          </Card>
        </div>

        {/* Quick-track row */}
        <SectionHead theme={t} action="Alle">Schnell tracken</SectionHead>
        <div style={{ padding: '0 20px', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginTop: -8, marginLeft: -20, marginRight: -20, paddingLeft: 20, paddingRight: 20 }}>
          {[
            { icon: I.run(20), label: 'Lauf', sub: 'Live' },
            { icon: I.scale(20), label: 'Gewicht', sub: 'eintragen' },
            { icon: I.ruler(20), label: 'Maße', sub: '+ Wert' },
          ].map((q, i) => (
            <button key={i} style={{
              background: t.surface, border: `1px solid ${t.border}`, borderRadius: 18,
              padding: '14px 12px', textAlign: 'left', display: 'flex', flexDirection: 'column', gap: 8,
              color: t.text, fontFamily: 'Geist, system-ui', cursor: 'pointer',
            }}>
              <div style={{ width: 32, height: 32, borderRadius: 10, background: t.surface2, display: 'flex', alignItems: 'center', justifyContent: 'center', color: t.text }}>{q.icon}</div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 600 }}>{q.label}</div>
                <div style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>{q.sub}</div>
              </div>
            </button>
          ))}
        </div>

        {/* Body metric trend mini */}
        <Card theme={t} pad={16} style={{ marginTop: 6 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 6 }}>
            <div>
              <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.5, fontFamily: 'Geist Mono, monospace' }}>Körpergewicht · 30T</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 6 }}>
                <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 30, fontWeight: 500, letterSpacing: -1, fontVariantNumeric: 'tabular-nums' }}>72,4</span>
                <span style={{ fontSize: 13, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>kg</span>
                <span style={{ fontSize: 12, color: t.danger, marginLeft: 6, fontFamily: 'Geist Mono, monospace' }}>↓ 1,2</span>
              </div>
            </div>
            <button style={{ background: t.surface2, border: 'none', borderRadius: 999, color: t.text, padding: '6px 12px', fontSize: 12, fontFamily: 'Geist, system-ui' }}>+ Eintragen</button>
          </div>
          <LineChart theme={t} width={326} height={88} showAxis={false} data={[
            {y: 73.6},{y: 73.4},{y: 73.5},{y: 73.1},{y: 72.9},{y: 72.7},{y: 73.0},{y: 72.6},{y: 72.5},{y: 72.4}
          ]} />
        </Card>
      </div>

      <TabBar active="home" theme={t} />
    </Screen>
  );
}

function CircleBtn({ theme, children }) {
  return (
    <button style={{
      width: 40, height: 40, borderRadius: 20,
      background: theme.surface2, border: `1px solid ${theme.border}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: theme.text, cursor: 'pointer',
    }}>{children}</button>
  );
}

Object.assign(window, { HomeScreen, CircleBtn });
