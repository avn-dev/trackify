// Body metrics: weight trend, body fat trend, measurements

function WeightScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} back="Körper" eyebrow="Körpergewicht" title="72,4 kg"
        action={<CircleBtn theme={t}>{I.plus(18)}</CircleBtn>}/>

      {/* range toggle */}
      <div style={{ padding: '0 20px 14px', display: 'flex', gap: 6 }}>
        {['1W','1M','3M','1J','Alles'].map((r, i) => (
          <button key={r} style={{
            flex: 1, height: 32, borderRadius: 999,
            background: i === 2 ? t.text : 'transparent',
            color: i === 2 ? t.bg : t.textMid,
            border: i === 2 ? 'none' : `1px solid ${t.border}`,
            fontFamily: 'Geist Mono, monospace', fontSize: 11, fontWeight: 500, letterSpacing: 0.4,
          }}>{r}</button>
        ))}
      </div>

      <div style={{ padding: '0 20px 16px' }}>
        <Card theme={t} pad={16}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 4 }}>
            <div>
              <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>3 Monate · Trend</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 6 }}>
                <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 26, fontWeight: 500, letterSpacing: -0.8, fontVariantNumeric: 'tabular-nums' }}>−2,8</span>
                <span style={{ fontSize: 12, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>kg</span>
              </div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>Ziel</div>
              <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 14, color: t.accent, marginTop: 6 }}>70,0 kg</div>
            </div>
          </div>
          <div style={{ marginTop: 10 }}>
            <LineChart theme={t} width={326} height={148} showAxis baseline={70} data={[
              {y: 75.2, label: 'Feb'},{y: 75.0},{y: 74.6},{y: 74.4},{y: 74.0, label: 'Mär'},
              {y: 73.8},{y: 73.5},{y: 73.2},{y: 73.4, label: 'Apr'},{y: 73.1},
              {y: 72.9},{y: 72.7},{y: 72.6, label: 'Mai'},{y: 72.4, dot: true}
            ]}/>
          </div>
        </Card>
      </div>

      {/* Stats row */}
      <div style={{ padding: '0 20px 18px', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10 }}>
        <Card theme={t} pad={14}><Stat theme={t} label="Aktuell" value="72,4" unit="kg"/></Card>
        <Card theme={t} pad={14}><Stat theme={t} label="7T Ø" value="72,8" unit="kg"/></Card>
        <Card theme={t} pad={14}><Stat theme={t} label="BMI" value="22,4"/></Card>
      </div>

      <SectionHead theme={t} action="Alle">Einträge</SectionHead>
      <div style={{ padding: '0 20px 100px', display: 'flex', flexDirection: 'column', gap: 6 }}>
        {[
          { d: 'Heute · 07:14', v: '72,4', delta: '−0,2', neg: true },
          { d: 'Gestern · 07:22', v: '72,6', delta: '−0,1', neg: true },
          { d: '11. Mai · 07:05', v: '72,7', delta: '+0,1', neg: false },
          { d: '10. Mai · 07:30', v: '72,6', delta: '−0,3', neg: true },
        ].map((e, i) => (
          <div key={i} style={{ padding: '12px 14px', display: 'flex', alignItems: 'center', borderBottom: `1px solid ${t.border}` }}>
            <div style={{ flex: 1, fontFamily: 'Geist Mono, monospace', fontSize: 12, color: t.textMid, textTransform: 'uppercase', letterSpacing: 0.6 }}>{e.d}</div>
            <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 16, fontWeight: 500, color: t.text, fontVariantNumeric: 'tabular-nums', marginRight: 10 }}>{e.v}<span style={{ color: t.textMuted, fontSize: 11, marginLeft: 2 }}>kg</span></div>
            <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 12, color: e.neg ? t.accent : t.danger, fontVariantNumeric: 'tabular-nums', width: 44, textAlign: 'right' }}>{e.delta}</div>
          </div>
        ))}
      </div>

      <TabBar active="body" theme={t}/>
    </Screen>
  );
}


function BodyFatScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} back="Körper" eyebrow="Körperfett · Caliper" title="14,8 %"
        action={<CircleBtn theme={t}>{I.plus(18)}</CircleBtn>}/>

      {/* Ring stat */}
      <div style={{ padding: '0 20px 16px' }}>
        <Card theme={t} pad={20} style={{ display: 'flex', gap: 18, alignItems: 'center' }}>
          <BodyFatRing theme={t} value={14.8}/>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>Letzte Messung</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 6 }}>
              <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 32, fontWeight: 500, letterSpacing: -1.2, fontVariantNumeric: 'tabular-nums' }}>14,8</span>
              <span style={{ fontSize: 14, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>%</span>
            </div>
            <div style={{ fontSize: 12, color: t.accent, fontFamily: 'Geist Mono, monospace', marginTop: 4 }}>↓ 1,6% / 3 Mon.</div>
            <div style={{ fontSize: 11, color: t.textMuted, marginTop: 4, fontFamily: 'Geist Mono, monospace' }}>Athletisch · 18-29J</div>
          </div>
        </Card>
      </div>

      {/* Trend */}
      <div style={{ padding: '0 20px 16px' }}>
        <Card theme={t} pad={16}>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>Verlauf · 6 Monate</div>
            <div style={{ display: 'flex', gap: 4 }}>
              {['6M','1J'].map((r, i) => (
                <span key={r} style={{ fontSize: 11, fontFamily: 'Geist Mono, monospace', padding: '2px 8px', borderRadius: 4, color: i === 0 ? t.text : t.textMuted, background: i === 0 ? t.surface2 : 'transparent' }}>{r}</span>
              ))}
            </div>
          </div>
          <div style={{ marginTop: 10 }}>
            <LineChart theme={t} width={326} height={130} showAxis data={[
              {y: 17.2, label: 'Dez'},{y: 17.0},{y: 16.6, label: 'Jan'},{y: 16.4},
              {y: 16.0, label: 'Feb'},{y: 15.8},{y: 15.5, label: 'Mär'},{y: 15.2},
              {y: 15.0, label: 'Apr'},{y: 14.8, label: 'Mai', dot: true},
            ]}/>
          </div>
        </Card>
      </div>

      {/* Method */}
      <div style={{ padding: '0 20px 100px' }}>
        <SectionHead theme={t}>Methode</SectionHead>
        <Card theme={t} pad={0}>
          {[
            { l: 'Caliper · 4-Punkt', v: '14,8 %', d: 'Heute', a: true },
            { l: 'Bioimpedanz (BIA)', v: '15,1 %', d: '08. Mai' },
            { l: 'Bilder-Schätzung', v: '15 %', d: '01. Mai' },
          ].map((m, i, arr) => (
            <div key={m.l} style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', borderBottom: i === arr.length - 1 ? 'none' : `1px solid ${t.border}` }}>
              <div style={{ width: 8, height: 8, borderRadius: 4, background: m.a ? t.accent : t.borderStrong, marginRight: 12 }}></div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: 'Geist, system-ui', fontSize: 14, fontWeight: 500 }}>{m.l}</div>
                <div style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace', marginTop: 2 }}>{m.d}</div>
              </div>
              <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 14, fontVariantNumeric: 'tabular-nums' }}>{m.v}</div>
            </div>
          ))}
        </Card>
      </div>

      <TabBar active="body" theme={t}/>
    </Screen>
  );
}

function BodyFatRing({ theme, value }) {
  const t = theme;
  const r = 38, c = 2 * Math.PI * r;
  const pct = (value - 5) / 25; // 5-30% range
  return (
    <div style={{ width: 96, height: 96, position: 'relative', flexShrink: 0 }}>
      <svg width="96" height="96" viewBox="0 0 96 96">
        <circle cx="48" cy="48" r={r} fill="none" stroke={t.surface2} strokeWidth="6"/>
        <circle cx="48" cy="48" r={r} fill="none" stroke={t.accent} strokeWidth="6" strokeLinecap="round"
          strokeDasharray={`${pct * c} ${c}`} transform="rotate(-90 48 48)"/>
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column' }}>
        <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 20, fontWeight: 500, color: t.text, fontVariantNumeric: 'tabular-nums', letterSpacing: -0.8 }}>{value}</span>
        <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 9, color: t.textMuted, marginTop: -2 }}>%</span>
      </div>
    </div>
  );
}


function MeasurementsScreen() {
  const t = useTheme();
  const parts = [
    { label: 'Brust', v: '102,4', d: '+0,8', pos: { top: 184, left: 200 } },
    { label: 'Bizeps', v: '38,2', d: '+0,5', pos: { top: 220, left: 60 } },
    { label: 'Taille', v: '78,5', d: '−1,2', neg: true, pos: { top: 270, left: 200 } },
    { label: 'Hüfte', v: '95,0', d: '−0,4', neg: true, pos: { top: 320, left: 60 } },
    { label: 'Ober­schenkel', v: '58,8', d: '+0,6', pos: { top: 380, left: 200 } },
    { label: 'Wade', v: '38,4', d: '+0,2', pos: { top: 470, left: 60 } },
  ];
  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} back="Körper" title="Körpermaße"
        action={<CircleBtn theme={t}>{I.plus(18)}</CircleBtn>}/>

      {/* Human silhouette + tags */}
      <div style={{ position: 'relative', height: 540, margin: '0 20px', background: t.surface, borderRadius: 28, border: `1px solid ${t.border}`, overflow: 'hidden' }}>
        <BodySilhouette theme={t}/>
        {parts.map((p, i) => (
          <div key={p.label} style={{
            position: 'absolute', top: p.pos.top, left: p.pos.left,
            background: t.bg, border: `1px solid ${t.borderStrong}`, borderRadius: 12,
            padding: '8px 10px', minWidth: 110,
            fontFamily: 'Geist, system-ui',
          }}>
            <div style={{ fontSize: 10, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>{p.label}</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 3, marginTop: 2 }}>
              <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 17, fontWeight: 500, fontVariantNumeric: 'tabular-nums', letterSpacing: -0.5 }}>{p.v}</span>
              <span style={{ fontSize: 10, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>cm</span>
              <span style={{ marginLeft: 'auto', fontFamily: 'Geist Mono, monospace', fontSize: 10, color: p.neg ? t.danger : t.accent }}>{p.d}</span>
            </div>
          </div>
        ))}
        {/* connectors */}
        <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none' }}>
          <g stroke={t.borderStrong} strokeWidth="1" strokeDasharray="2 3" fill="none">
            <path d="M196 195 L186 195"/>
            <path d="M170 232 L156 232"/>
            <path d="M196 282 L186 282"/>
            <path d="M170 332 L156 332"/>
            <path d="M196 392 L186 392"/>
            <path d="M170 482 L156 482"/>
          </g>
        </svg>
      </div>

      <div style={{ padding: '18px 20px 100px' }}>
        <SectionHead theme={t} action="Verlauf">Diese Woche</SectionHead>
        <Card theme={t} pad={14}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
            <KV theme={t} k="Schulter" v="118,2" delta="+0,4"/>
            <KV theme={t} k="Unterarm" v="29,8" delta="+0,1"/>
            <KV theme={t} k="Nacken" v="38,0" delta="0,0"/>
            <KV theme={t} k="Knöchel" v="22,4" delta="−0,2" neg/>
          </div>
        </Card>
      </div>

      <TabBar active="body" theme={t}/>
    </Screen>
  );
}

function KV({ theme, k, v, delta, neg }) {
  const t = theme;
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '8px 8px', borderRadius: 8 }}>
      <div>
        <div style={{ fontSize: 10, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>{k}</div>
        <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 16, fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>{v}<span style={{ color: t.textMuted, fontSize: 10, marginLeft: 2 }}>cm</span></div>
      </div>
      <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 11, color: neg ? t.danger : (delta === '0,0' ? t.textMuted : t.accent) }}>{delta}</div>
    </div>
  );
}

function BodySilhouette({ theme }) {
  const t = theme;
  // Simple stylized humanoid outline
  return (
    <svg style={{ position: 'absolute', left: '50%', top: 40, transform: 'translateX(-50%)' }} width="170" height="460" viewBox="0 0 170 460" fill="none">
      <g stroke={t.borderStrong} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" fill={t.surface2}>
        {/* head */}
        <ellipse cx="85" cy="34" rx="22" ry="26"/>
        {/* neck */}
        <path d="M76 58 L74 70 Q85 76 96 70 L94 58"/>
        {/* torso */}
        <path d="M50 78 Q60 70 74 70 Q85 76 96 70 Q110 70 120 78 L128 130 Q132 180 122 230 Q116 260 110 280 L60 280 Q54 260 48 230 Q38 180 42 130 Z"/>
        {/* arms */}
        <path d="M50 78 Q34 100 32 130 Q28 170 30 200 Q32 220 36 235 Q44 244 50 230 Q52 200 54 170 Q56 140 56 110"/>
        <path d="M120 78 Q136 100 138 130 Q142 170 140 200 Q138 220 134 235 Q126 244 120 230 Q118 200 116 170 Q114 140 114 110"/>
        {/* legs */}
        <path d="M62 280 Q56 340 54 400 Q54 430 60 442 Q70 446 78 442 Q82 430 84 400 Q84 340 82 280"/>
        <path d="M88 280 Q86 340 86 400 Q88 430 92 442 Q100 446 110 442 Q116 430 116 400 Q114 340 108 280"/>
      </g>
      {/* measurement markers */}
      <g stroke={t.accent} strokeWidth="1.5" fill="none">
        <ellipse cx="85" cy="120" rx="46" ry="6"/>     {/* chest */}
        <ellipse cx="85" cy="180" rx="40" ry="5"/>     {/* waist */}
        <ellipse cx="85" cy="240" rx="44" ry="6"/>     {/* hips */}
        <ellipse cx="40" cy="160" rx="14" ry="4" transform="rotate(20 40 160)"/>  {/* L bicep */}
        <ellipse cx="73" cy="320" rx="13" ry="4"/>     {/* L thigh */}
        <ellipse cx="73" cy="420" rx="10" ry="3"/>     {/* L calf */}
      </g>
    </svg>
  );
}

Object.assign(window, { WeightScreen, BodyFatScreen, MeasurementsScreen });
