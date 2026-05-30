// Splash, Onboarding, Login, Register

function SplashScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 32 }}>
        <Logomark theme={t} size={108} />
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontFamily: 'Geist, system-ui', fontSize: 36, fontWeight: 600, letterSpacing: -1.4 }}>Trackify</div>
          <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 11, color: t.textMuted, marginTop: 8, letterSpacing: 1.2, textTransform: 'uppercase' }}>train · run · measure</div>
        </div>
      </div>
      <div style={{ position: 'absolute', bottom: 56, left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: 6 }}>
        {[0,1,2].map(i => <div key={i} style={{ width: 6, height: 6, borderRadius: 3, background: i === 0 ? t.accent : t.borderStrong }} />)}
      </div>
    </Screen>
  );
}

function Logomark({ theme, size = 56 }) {
  const t = theme;
  return (
    <svg width={size} height={size} viewBox="0 0 100 100">
      <rect x="0" y="0" width="100" height="100" rx="28" fill={t.text}/>
      <path d="M22 62 L40 44 L52 56 L78 30" stroke={t.accent} strokeWidth="6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
      <circle cx="78" cy="30" r="5" fill={t.accent}/>
    </svg>
  );
}

function OnboardingScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      <div style={{ position: 'absolute', top: 64, left: 20, right: 20, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 11, color: t.textMuted, letterSpacing: 1, textTransform: 'uppercase' }}>02 / 03</div>
        <button style={{ background: 'transparent', border: 'none', color: t.textMid, fontFamily: 'Geist, system-ui', fontSize: 14 }}>Überspringen</button>
      </div>
      {/* Visual */}
      <div style={{ position: 'absolute', top: 120, left: 0, right: 0, display: 'flex', justifyContent: 'center' }}>
        <div style={{
          width: 280, height: 260, borderRadius: 32, background: t.surface,
          border: `1px solid ${t.border}`, padding: 22, display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 1, fontFamily: 'Geist Mono, monospace' }}>Volumen · 4 Wochen</span>
            <span style={{ fontSize: 11, color: t.accent, fontFamily: 'Geist Mono, monospace', display: 'inline-flex', alignItems: 'center', gap: 2 }}>↑ 14%</span>
          </div>
          <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 44, fontWeight: 500, letterSpacing: -1.4, color: t.text, fontVariantNumeric: 'tabular-nums' }}>
            18.420<span style={{ fontSize: 16, color: t.textMuted, marginLeft: 6 }}>kg</span>
          </div>
          <LineChart theme={t} width={236} height={88} showAxis={false} data={[
            {y: 12}, {y: 14}, {y: 13}, {y: 17}, {y: 16}, {y: 19}, {y: 18}, {y: 22}, {y: 21}, {y: 25}
          ]} accent />
        </div>
      </div>
      {/* Copy */}
      <div style={{ position: 'absolute', bottom: 156, left: 24, right: 24 }}>
        <h2 style={{ margin: 0, fontFamily: 'Geist, system-ui', fontSize: 30, fontWeight: 600, letterSpacing: -1, lineHeight: 1.1, color: t.text }}>
          Sieh dein Training. Schwarz auf weiß.
        </h2>
        <p style={{ margin: '12px 0 0', color: t.textMid, fontSize: 15, lineHeight: 1.45 }}>
          Volumen, RIR, 1RM-Schätzung – alles automatisch ausgewertet, ohne Tabellen-Gefummel.
        </p>
      </div>
      {/* Pagination + CTA */}
      <div style={{ position: 'absolute', bottom: 60, left: 24, right: 24, display: 'flex', alignItems: 'center', gap: 16 }}>
        <div style={{ display: 'flex', gap: 6 }}>
          {[0,1,2].map(i => <div key={i} style={{ width: i === 1 ? 22 : 6, height: 6, borderRadius: 3, background: i === 1 ? t.accent : t.borderStrong, transition: 'all .2s' }} />)}
        </div>
        <div style={{ flex: 1 }} />
        <button style={{
          width: 64, height: 52, borderRadius: 26, background: t.accent,
          color: t.accentText, border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{I.arrow(18)}</button>
      </div>
    </Screen>
  );
}

function LoginScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      <div style={{ padding: '68px 24px 0' }}>
        <Logomark theme={t} size={42} />
        <h1 style={{ margin: '32px 0 6px', fontFamily: 'Geist, system-ui', fontSize: 34, fontWeight: 600, letterSpacing: -1.2, lineHeight: 1.05 }}>Willkommen<br/>zurück.</h1>
        <p style={{ margin: 0, color: t.textMuted, fontSize: 15 }}>Schön, dass du wieder da bist.</p>

        <div style={{ marginTop: 32, display: 'flex', flexDirection: 'column', gap: 12 }}>
          <FieldRow theme={t} label="E-Mail" value="lena@trackify.app" />
          <FieldRow theme={t} label="Passwort" value="••••••••" trailing={<button style={{ background: 'transparent', border: 'none', color: t.textMid, fontSize: 13, fontFamily: 'Geist, system-ui' }}>vergessen?</button>} secure />
        </div>

        <div style={{ marginTop: 20 }}>
          <PrimaryButton theme={t} full>Login {I.arrow(16)}</PrimaryButton>
        </div>

        <Divider theme={t} label="oder weiter mit" />

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <GhostButton theme={t} full>{I.google(18)} Mit Google fortfahren</GhostButton>
          <GhostButton theme={t} full>{I.apple(18, t.text)} Mit Apple fortfahren</GhostButton>
        </div>
      </div>
      <div style={{ position: 'absolute', bottom: 44, left: 0, right: 0, textAlign: 'center', fontSize: 14, color: t.textMid }}>
        Noch keinen Account? <span style={{ color: t.text, fontWeight: 500 }}>Registrieren</span>
      </div>
    </Screen>
  );
}

function RegisterScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      <div style={{ padding: '68px 24px 0' }}>
        <button style={{ background: 'transparent', border: 'none', color: t.textMid, padding: 0, display: 'flex', alignItems: 'center', gap: 4 }}>
          {I.chev(14, 'left')} <span style={{ fontFamily: 'Geist, system-ui', fontSize: 14 }}>Zurück</span>
        </button>
        <h1 style={{ margin: '24px 0 6px', fontFamily: 'Geist, system-ui', fontSize: 34, fontWeight: 600, letterSpacing: -1.2, lineHeight: 1.05 }}>Erstell dir<br/>deinen Account.</h1>
        <p style={{ margin: 0, color: t.textMuted, fontSize: 15 }}>30 Sekunden. Versprochen.</p>

        <div style={{ marginTop: 28, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <FieldRow theme={t} label="Name" value="Lena Brunner" />
          <FieldRow theme={t} label="E-Mail" value="lena@trackify.app" />
          <FieldRow theme={t} label="Passwort" value="" placeholder="Min. 8 Zeichen" secure />
          <label style={{ marginTop: 6, display: 'flex', alignItems: 'flex-start', gap: 10, color: t.textMid, fontSize: 13, lineHeight: 1.4 }}>
            <div style={{ width: 18, height: 18, borderRadius: 5, background: t.accent, color: t.accentText, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, marginTop: 1 }}>{I.check(12)}</div>
            Ich akzeptiere die <span style={{ color: t.text, textDecoration: 'underline' }}>AGB</span> & <span style={{ color: t.text, textDecoration: 'underline' }}>Datenschutz</span>.
          </label>
        </div>

        <div style={{ marginTop: 18 }}>
          <PrimaryButton theme={t} full>Konto erstellen {I.arrow(16)}</PrimaryButton>
        </div>

        <Divider theme={t} label="oder" />

        <div style={{ display: 'flex', gap: 10 }}>
          <GhostButton theme={t} full style={{ flex: 1 }}>{I.google(18)} Google</GhostButton>
          <GhostButton theme={t} full style={{ flex: 1 }}>{I.apple(18, t.text)} Apple</GhostButton>
        </div>
      </div>
    </Screen>
  );
}

function FieldRow({ theme, label, value, placeholder, secure, trailing }) {
  const t = theme;
  return (
    <div style={{
      background: t.surface, borderRadius: 16, padding: '12px 16px',
      border: `1px solid ${t.border}`,
      display: 'flex', alignItems: 'center', gap: 8,
    }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.5, fontWeight: 500, fontFamily: 'Geist Mono, monospace' }}>{label}</div>
        <div style={{ marginTop: 4, fontFamily: 'Geist, system-ui', fontSize: 16, color: value ? t.text : t.textMuted, letterSpacing: secure && value ? 2 : -0.1 }}>
          {value || placeholder}
        </div>
      </div>
      {trailing}
    </div>
  );
}

function Divider({ theme, label }) {
  const t = theme;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '22px 0' }}>
      <div style={{ flex: 1, height: 1, background: t.border }} />
      <span style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 1, fontFamily: 'Geist Mono, monospace' }}>{label}</span>
      <div style={{ flex: 1, height: 1, background: t.border }} />
    </div>
  );
}

Object.assign(window, { SplashScreen, OnboardingScreen, LoginScreen, RegisterScreen, Logomark });
