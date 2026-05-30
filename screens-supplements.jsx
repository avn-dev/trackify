// Supplement / medication tracking — overview, detail, add

function SupplementOverviewScreen() {
  const t = useTheme();
  const blocks = [
    {
      time: 'Morgens', clock: '07:30', taken: 3, total: 4,
      items: [
        { name: 'Vitamin D3 + K2',  dose: '4000 IE / 200 µg', kind: 'sup', taken: true, food: true },
        { name: 'Omega-3',          dose: '2 Kapseln',         kind: 'sup', taken: true, food: true },
        { name: 'Magnesium',        dose: '400 mg',            kind: 'sup', taken: true, food: false },
        { name: 'Eisen-Bisglycinat', dose: '25 mg',            kind: 'sup', taken: false, food: false, note: 'nüchtern' },
      ],
    },
    {
      time: 'Mittags', clock: '13:00', taken: 0, total: 1,
      items: [
        { name: 'Kreatin Monohydrat', dose: '5 g', kind: 'sup', taken: false, food: false, current: true },
      ],
    },
    {
      time: 'Abends', clock: '19:30', taken: 0, total: 2,
      items: [
        { name: 'Zink + Selen', dose: '15 mg / 100 µg', kind: 'sup', taken: false, food: true },
        { name: 'Ibuprofen',    dose: '400 mg',          kind: 'med', taken: false, food: true, note: 'b. Bedarf' },
      ],
    },
    {
      time: 'Vor Schlaf', clock: '22:30', taken: 0, total: 1,
      items: [
        { name: 'Ashwagandha', dose: '600 mg', kind: 'sup', taken: false, food: false },
      ],
    },
  ];

  const takenToday = blocks.reduce((a, b) => a + b.taken, 0);
  const totalToday = blocks.reduce((a, b) => a + b.total, 0);

  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} eyebrow="14. Mai · heute" title="Supplements"
        action={<CircleBtn theme={t}>{I.plus(18)}</CircleBtn>}/>

      {/* Daily adherence card */}
      <div style={{ padding: '0 20px 16px' }}>
        <Card theme={t} pad={18}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>Heute eingenommen</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 8 }}>
                <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 40, fontWeight: 500, letterSpacing: -1.4, fontVariantNumeric: 'tabular-nums' }}>{takenToday}</span>
                <span style={{ fontSize: 16, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>/ {totalToday}</span>
              </div>
              <div style={{ fontSize: 12, color: t.accent, fontFamily: 'Geist Mono, monospace', marginTop: 4 }}>↑ 14T Streak</div>
            </div>
            <DonutMini theme={t} value={takenToday} total={totalToday}/>
          </div>

          {/* 14-day adherence */}
          <div style={{ marginTop: 16, display: 'flex', gap: 4 }}>
            {[1,1,1,1,1,1,0.8,1,1,1,1,0.6,1,1,0.4].map((v, i, arr) => (
              <div key={i} style={{ flex: 1, height: 22, borderRadius: 3,
                background: i === arr.length - 1 ? t.surface2 : (v < 0.5 ? t.danger : (v < 0.95 ? '#f5b13a' : t.accent)),
                border: i === arr.length - 1 ? `1px dashed ${t.borderStrong}` : 'none',
                boxSizing: 'border-box',
              }}></div>
            ))}
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontFamily: 'Geist Mono, monospace', fontSize: 9, color: t.textMuted }}>
            <span>−14T</span><span>heute</span>
          </div>
        </Card>
      </div>

      {/* Time-blocked schedule */}
      <div style={{ padding: '0 20px 100px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        {blocks.map((b, bi) => (
          <div key={b.time}>
            <div style={{ padding: '0 4px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 10 }}>
                <span style={{ fontFamily: 'Geist, system-ui', fontSize: 17, fontWeight: 600, letterSpacing: -0.3 }}>{b.time}</span>
                <span style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace', letterSpacing: 0.6 }}>{b.clock}</span>
              </div>
              <span style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace', letterSpacing: 0.6 }}>{b.taken}/{b.total}</span>
            </div>
            <Card theme={t} pad={0}>
              {b.items.map((it, i) => (
                <SupplementRow key={it.name} it={it} theme={t} last={i === b.items.length - 1}/>
              ))}
            </Card>
          </div>
        ))}

        {/* Stock alert */}
        <Card theme={t} pad={14} style={{ borderColor: t.borderStrong, background: t.surface }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
            <div style={{ width: 6, height: 6, borderRadius: 3, background: '#f5b13a' }}></div>
            <span style={{ fontSize: 10, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 1, color: '#f5b13a', fontWeight: 600 }}>Bestand</span>
          </div>
          <div style={{ fontFamily: 'Geist, system-ui', fontSize: 14, color: t.text, lineHeight: 1.4 }}>
            <span style={{ fontFamily: 'Geist Mono, monospace' }}>Omega-3</span> reicht noch <span style={{ color: t.text, fontWeight: 500 }}>6 Tage</span>. Vor Schlaf bestellen?
          </div>
        </Card>
      </div>

      <TabBar active="body" theme={t}/>
    </Screen>
  );
}

function DonutMini({ theme, value, total }) {
  const t = theme;
  const r = 28, c = 2 * Math.PI * r;
  const pct = total ? value / total : 0;
  return (
    <div style={{ width: 72, height: 72, position: 'relative', flexShrink: 0 }}>
      <svg width="72" height="72" viewBox="0 0 72 72">
        <circle cx="36" cy="36" r={r} fill="none" stroke={t.surface2} strokeWidth="5"/>
        <circle cx="36" cy="36" r={r} fill="none" stroke={t.accent} strokeWidth="5" strokeLinecap="round"
          strokeDasharray={`${pct * c} ${c}`} transform="rotate(-90 36 36)"/>
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column' }}>
        <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 13, fontWeight: 500, color: t.text, fontVariantNumeric: 'tabular-nums', letterSpacing: -0.3 }}>{Math.round(pct * 100)}<span style={{ fontSize: 8, color: t.textMuted }}>%</span></span>
      </div>
    </div>
  );
}

function SupplementRow({ it, theme, last }) {
  const t = theme;
  return (
    <div style={{
      padding: '12px 14px', display: 'grid',
      gridTemplateColumns: '36px 1fr auto 32px', gap: 10, alignItems: 'center',
      borderBottom: last ? 'none' : `1px solid ${t.border}`,
      background: it.current ? t.surface : 'transparent',
    }}>
      {/* Pill icon by kind */}
      <div style={{
        width: 36, height: 36, borderRadius: 10,
        background: it.taken ? t.accent : (it.kind === 'med' ? '#3a3a3d22' : t.surface2),
        color: it.taken ? t.accentText : t.text,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {it.kind === 'med' ? <PillIcon size={18}/> : <CapsuleIcon size={18}/>}
      </div>

      <div style={{ minWidth: 0 }}>
        <div style={{ fontFamily: 'Geist, system-ui', fontSize: 14, fontWeight: 500, color: it.taken ? t.textMuted : t.text, textDecoration: it.taken ? 'line-through' : 'none' }}>
          {it.name}
        </div>
        <div style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace', marginTop: 2, display: 'flex', gap: 6, alignItems: 'center' }}>
          <span>{it.dose}</span>
          {it.food && <><span style={{ opacity: 0.4 }}>·</span><span>mit Essen</span></>}
          {it.note && <><span style={{ opacity: 0.4 }}>·</span><span style={{ color: it.taken ? t.textMuted : t.text }}>{it.note}</span></>}
        </div>
      </div>

      <div>
        {it.kind === 'med' && !it.taken && (
          <span style={{ fontSize: 9, padding: '2px 6px', borderRadius: 4, background: '#3a3a3d22', color: t.textMid, fontFamily: 'Geist Mono, monospace', letterSpacing: 0.6, textTransform: 'uppercase' }}>RX</span>
        )}
      </div>

      <button style={{
        width: 28, height: 28, borderRadius: 8, border: 'none', padding: 0,
        background: it.taken ? t.accent : t.surface2,
        color: it.taken ? t.accentText : t.textMuted,
        display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        boxShadow: it.taken ? 'none' : `inset 0 0 0 1px ${t.borderStrong}`,
      }}>{it.taken ? I.check(14) : null}</button>
    </div>
  );
}

function CapsuleIcon({ size = 18 }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round">
    <rect x="3" y="9" width="18" height="6" rx="3" transform="rotate(-30 12 12)" fill="currentColor" opacity="0.18"/>
    <rect x="3" y="9" width="18" height="6" rx="3" transform="rotate(-30 12 12)" stroke="currentColor"/>
    <line x1="12" y1="6.5" x2="12" y2="17.5" transform="rotate(-30 12 12)"/>
  </svg>;
}

function PillIcon({ size = 18 }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
    <circle cx="12" cy="12" r="8"/>
    <line x1="6.5" y1="12" x2="17.5" y2="12"/>
  </svg>;
}


function SupplementDetailScreen() {
  const t = useTheme();
  // Vitamin D3 example
  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} back="Supplements" eyebrow="Vitamin · täglich" title="Vitamin D3 + K2"
        action={<CircleBtn theme={t}>{I.more(16)}</CircleBtn>}/>

      {/* Top adherence + stock row */}
      <div style={{ padding: '0 20px 14px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <Card theme={t} pad={14}>
          <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.5, fontFamily: 'Geist Mono, monospace' }}>Adhärenz · 30T</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 6 }}>
            <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 30, fontWeight: 500, letterSpacing: -1, fontVariantNumeric: 'tabular-nums' }}>96</span>
            <span style={{ fontSize: 14, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>%</span>
          </div>
          <div style={{ fontSize: 11, color: t.accent, fontFamily: 'Geist Mono, monospace', marginTop: 4 }}>29 / 30 Tage</div>
        </Card>
        <Card theme={t} pad={14}>
          <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.5, fontFamily: 'Geist Mono, monospace' }}>Bestand</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 6 }}>
            <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 30, fontWeight: 500, letterSpacing: -1, fontVariantNumeric: 'tabular-nums' }}>84</span>
            <span style={{ fontSize: 14, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>Kapseln</span>
          </div>
          <div style={{ fontSize: 11, color: t.textMid, fontFamily: 'Geist Mono, monospace', marginTop: 4 }}>≈ 84 Tage</div>
        </Card>
      </div>

      {/* 30-day calendar grid */}
      <div style={{ padding: '0 20px 16px' }}>
        <Card theme={t} pad={16}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
            <span style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>30 Tage</span>
            <span style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>Apr → Mai</span>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(15, 1fr)', gap: 4 }}>
            {/* 30 days; 1 missed */}
            {Array.from({ length: 30 }).map((_, i) => {
              const missed = i === 12;
              const future = i > 28;
              return (
                <div key={i} style={{
                  aspectRatio: '1 / 1', borderRadius: 4,
                  background: future ? 'transparent' : (missed ? t.danger : t.accent),
                  border: future ? `1px dashed ${t.border}` : 'none',
                  opacity: future ? 0.5 : 1,
                }}></div>
              );
            })}
          </div>
          <div style={{ marginTop: 12, display: 'flex', gap: 14, fontSize: 11, color: t.textMid, fontFamily: 'Geist Mono, monospace' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: t.accent }}></span>genommen</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: t.danger }}></span>verpasst</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}><span style={{ width: 8, height: 8, borderRadius: 2, border: `1px dashed ${t.border}` }}></span>geplant</div>
          </div>
        </Card>
      </div>

      {/* Schedule */}
      <div style={{ padding: '0 20px 16px' }}>
        <SectionHead theme={t} action="Bearbeiten" style={{ padding: 0, marginBottom: 10 }}>Plan</SectionHead>
        <Card theme={t} pad={0}>
          {[
            { k: 'Dosis',       v: '4000 IE D3 · 200 µg K2' },
            { k: 'Häufigkeit',  v: 'Täglich · 07:30' },
            { k: 'Einnahme',    v: 'Mit Essen' },
            { k: 'Form',        v: 'Kapsel' },
            { k: 'Erinnerung',  v: 'an · 07:30' },
          ].map((r, i, arr) => (
            <div key={r.k} style={{ padding: '12px 14px', display: 'flex', borderBottom: i === arr.length - 1 ? 'none' : `1px solid ${t.border}` }}>
              <span style={{ flex: 1, fontFamily: 'Geist, system-ui', fontSize: 13, color: t.text }}>{r.k}</span>
              <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 12, color: t.textMid }}>{r.v}</span>
            </div>
          ))}
        </Card>
      </div>

      {/* History */}
      <div style={{ padding: '0 20px 100px' }}>
        <SectionHead theme={t}>Letzte Einnahmen</SectionHead>
        <Card theme={t} pad={0}>
          {[
            { d: 'Heute · 07:32', status: 'ok' },
            { d: 'Gestern · 07:28', status: 'ok' },
            { d: '12. Mai · 07:45', status: 'ok' },
            { d: '11. Mai · —', status: 'missed', label: 'verpasst' },
            { d: '10. Mai · 07:31', status: 'ok' },
          ].map((h, i, arr) => (
            <div key={i} style={{ padding: '12px 14px', display: 'flex', alignItems: 'center', borderBottom: i === arr.length - 1 ? 'none' : `1px solid ${t.border}` }}>
              <div style={{ width: 6, height: 6, borderRadius: 3, background: h.status === 'ok' ? t.accent : t.danger, marginRight: 12 }}></div>
              <span style={{ flex: 1, fontFamily: 'Geist Mono, monospace', fontSize: 12, color: t.textMid, letterSpacing: 0.4 }}>{h.d}</span>
              {h.status === 'missed' && <span style={{ fontSize: 10, color: t.danger, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 0.6 }}>{h.label}</span>}
              {h.status === 'ok' && <span style={{ color: t.accent }}>{I.check(14)}</span>}
            </div>
          ))}
        </Card>
      </div>

      <TabBar active="body" theme={t}/>
    </Screen>
  );
}


function SupplementAddScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} back="Supplements" title="Neu hinzufügen"/>

      <div style={{ padding: '0 20px 100px', display: 'flex', flexDirection: 'column', gap: 14 }}>

        {/* Kind picker */}
        <div>
          <SectionHead theme={t} style={{ padding: 0, marginBottom: 10 }}>Art</SectionHead>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
            {[
              { k: 'sup', label: 'Supplement', sub: 'Vitamine · Mineralien', icon: <CapsuleIcon size={18}/>, active: true },
              { k: 'med', label: 'Medikament', sub: 'Rx · OTC', icon: <PillIcon size={18}/> },
              { k: 'herb', label: 'Pflanzlich', sub: 'Tee · Tinktur', icon: I.flame(18) },
            ].map(o => (
              <button key={o.k} style={{
                background: o.active ? t.text : t.surface,
                color: o.active ? t.bg : t.text,
                border: o.active ? 'none' : `1px solid ${t.border}`,
                borderRadius: 16, padding: '12px 10px',
                display: 'flex', flexDirection: 'column', gap: 8, textAlign: 'left',
                fontFamily: 'Geist, system-ui',
              }}>
                <div style={{ width: 28, height: 28, borderRadius: 8, background: o.active ? t.accent : t.surface2, color: o.active ? t.accentText : t.text, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{o.icon}</div>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 600 }}>{o.label}</div>
                  <div style={{ fontSize: 10, color: o.active ? 'rgba(11,11,12,0.6)' : t.textMuted, fontFamily: 'Geist Mono, monospace', marginTop: 2, letterSpacing: 0.4 }}>{o.sub}</div>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Form */}
        <div>
          <SectionHead theme={t} style={{ padding: 0, marginBottom: 10 }}>Details</SectionHead>
          <Card theme={t} pad={0}>
            <FormRow theme={t} label="Name" value="Vitamin D3 + K2"/>
            <FormRow theme={t} label="Dosis" value="4000" unit="IE"/>
            <FormRow theme={t} label="Form" value="Kapsel" chev/>
            <FormRow theme={t} label="Bestand" value="84" unit="Kapseln" last/>
          </Card>
        </div>

        {/* Schedule */}
        <div>
          <SectionHead theme={t} style={{ padding: 0, marginBottom: 10 }}>Wann</SectionHead>
          <Card theme={t} pad={0}>
            {/* Frequency pills */}
            <div style={{ padding: '14px 14px 8px' }}>
              <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace', marginBottom: 8 }}>Häufigkeit</div>
              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                {[
                  { l: 'Täglich', a: true },
                  { l: 'Bestimmte Tage' },
                  { l: 'Zyklisch' },
                  { l: 'Bei Bedarf' },
                ].map(f => (
                  <span key={f.l} style={{
                    padding: '7px 12px', borderRadius: 999, fontSize: 12,
                    background: f.a ? t.text : 'transparent',
                    color: f.a ? t.bg : t.textMid,
                    border: f.a ? 'none' : `1px solid ${t.border}`,
                    fontFamily: 'Geist, system-ui', fontWeight: 500,
                  }}>{f.l}</span>
                ))}
              </div>
            </div>
            <div style={{ height: 1, background: t.border }}></div>
            {/* Time slots */}
            <div style={{ padding: '14px 14px 12px' }}>
              <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace', marginBottom: 10 }}>Zeitpunkte</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                {[
                  { time: '07:30', label: 'Morgens', a: true },
                  { time: '13:00', label: 'Mittags' },
                  { time: '19:30', label: 'Abends' },
                  { time: '22:30', label: 'Vor Schlaf' },
                ].map(s => (
                  <div key={s.time} style={{
                    padding: '10px 12px', borderRadius: 12,
                    border: `1px solid ${s.a ? t.accent : t.border}`,
                    background: s.a ? `${t.accent}10` : 'transparent',
                    display: 'flex', alignItems: 'center', gap: 12,
                  }}>
                    <div style={{
                      width: 18, height: 18, borderRadius: 5,
                      background: s.a ? t.accent : 'transparent',
                      border: s.a ? 'none' : `1px solid ${t.borderStrong}`,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      color: t.accentText,
                    }}>{s.a ? I.check(12) : null}</div>
                    <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 14, fontWeight: 500, color: t.text, fontVariantNumeric: 'tabular-nums' }}>{s.time}</span>
                    <span style={{ fontFamily: 'Geist, system-ui', fontSize: 12, color: t.textMid }}>{s.label}</span>
                  </div>
                ))}
              </div>
            </div>
          </Card>
        </div>

        {/* Options */}
        <div>
          <SectionHead theme={t} style={{ padding: 0, marginBottom: 10 }}>Optionen</SectionHead>
          <Card theme={t} pad={0}>
            <ToggleRow theme={t} label="Mit Essen einnehmen" on/>
            <ToggleRow theme={t} label="Erinnerung senden" on/>
            <ToggleRow theme={t} label="Bestand nachverfolgen" on last/>
          </Card>
        </div>
      </div>

      <div style={{ position: 'absolute', bottom: 30, left: 20, right: 20 }}>
        <PrimaryButton theme={t} full>{I.check(16)} Hinzufügen</PrimaryButton>
      </div>
    </Screen>
  );
}

function FormRow({ theme, label, value, unit, chev, last }) {
  const t = theme;
  return (
    <div style={{ padding: '14px 14px', display: 'flex', alignItems: 'center', borderBottom: last ? 'none' : `1px solid ${t.border}` }}>
      <span style={{ flex: 1, fontFamily: 'Geist, system-ui', fontSize: 13, color: t.textMid }}>{label}</span>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
        <span style={{ fontFamily: value && /^\d/.test(value) ? 'Geist Mono, monospace' : 'Geist, system-ui', fontSize: 14, color: t.text, fontVariantNumeric: 'tabular-nums' }}>{value}</span>
        {unit && <span style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>{unit}</span>}
        {chev && <span style={{ color: t.textMuted, marginLeft: 4 }}>{I.chev(12, 'right')}</span>}
      </div>
    </div>
  );
}

function ToggleRow({ theme, label, on, last }) {
  const t = theme;
  return (
    <div style={{ padding: '14px 14px', display: 'flex', alignItems: 'center', borderBottom: last ? 'none' : `1px solid ${t.border}` }}>
      <span style={{ flex: 1, fontFamily: 'Geist, system-ui', fontSize: 14, color: t.text }}>{label}</span>
      <div style={{ width: 40, height: 24, borderRadius: 12, background: on ? t.accent : t.surface2, position: 'relative' }}>
        <div style={{ position: 'absolute', top: 2, left: on ? 18 : 2, width: 20, height: 20, borderRadius: 10, background: t.bg }}></div>
      </div>
    </div>
  );
}

Object.assign(window, { SupplementOverviewScreen, SupplementDetailScreen, SupplementAddScreen });
