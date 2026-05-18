# Blocco 1 & 2 — Bolometro Simulato

## Obiettivo

Blocco 1: modello diretto che converte la potenza assorbita in tensione di uscita.
Blocco 2: aggiunta di rumore generico gaussiano al segnale.

---

## Blocco 1 — Forward Model

**File:** `bolometer_params.m`, `forward_model.m`

### Catena fisica

```
P [W]  →  ΔT = P / G  →  ΔR = R₀·α·ΔT  →  ΔV = I_bias·ΔR
```

| Passo | Equazione |
|-------|-----------|
| Bilancio termico (regime stazionario) | `ΔT = P / G` |
| Variazione resistenza (TCR) | `ΔR = R₀·α·ΔT` |
| Lettura con corrente di bias | `ΔV = I_bias·ΔR` |

La funzione gestisce anche la **saturazione** in due casi:
- Termica: `ΔT > ΔT_max` (sensore danneggiato)
- Elettronica: `|ΔV| > V_sat` (amplificatore al rail)

### Parametri default

| Parametro | Simbolo | Valore | Unità |
|-----------|---------|--------|-------|
| Resistenza | R₀ | 100 | Ω |
| TCR (Pt) | α | 3.9×10⁻³ | 1/K |
| Conduttanza termica | G | 1×10⁻⁴ | W/K |
| Capacità termica | C | 1×10⁻⁶ | J/K |
| Corrente bias | I_bias | 1×10⁻³ | A |
| Temperatura base | T₀ | 300 | K |
| Saturazione tensione | V_sat | 1.0 | V |
| Saturazione termica | ΔT_max | 50 | K |
| Banda | BW | 1×10³ | Hz |

### Uso

```matlab
p   = bolometer_params();
fwd = forward_model(P_array, p);
% fwd.DeltaT       → temperatura [K]
% fwd.DeltaV_ideal → tensione ideale [V]
% fwd.DeltaV       → tensione con saturazione [V]
% fwd.is_saturated → maschera punti saturi
% fwd.P_sat        → potenza di saturazione [W]
```

---

## Blocco 2 — Modulo Rumore

**File:** `add_noise_to_signal.m`

Il rumore è modellato come un unico termine gaussiano di ampiezza `V_noise` (generico, senza decomposizione fisica).

| Parametro | Valore default |
|-----------|----------------|
| V_noise (rms) | 1×10⁻⁵ V |
| NEP = V_noise · G / (I_bias·R₀·α) | ~2.56×10⁻⁶ W |

### Uso

```matlab
nr = add_noise_to_signal(fwd.DeltaV, p);
% nr.DeltaV_noisy → segnale con rumore [V]
% nr.V_noise      → ampiezza rumore rms [V]
% nr.SNR          → SNR per punto [lineare]
% nr.NEP          → rumore equivalente in potenza [W]
```

### Regimi

| Regime | Condizione |
|--------|-----------|
| Rumore dominante | SNR < 1 |
| Ricostruibile | SNR ≥ 1 e non saturato |
| Saturato | ΔT > ΔT_max oppure \|ΔV\| > V_sat |

---

## Come eseguire

```matlab
cd blocco_1_2/
test_blocchi_1_2
```

Produce una figura con due pannelli: segnale ideale e segnale reale (saturazione + rumore), salvata in `blocchi_1_2_risultati.png`.

---

## File

| File | Blocco | Descrizione |
|------|--------|-------------|
| `bolometer_params.m` | 1 | Parametri fisici del bolometro |
| `forward_model.m` | 1 | P → ΔT → ΔR → ΔV con saturazione |
| `add_noise_to_signal.m` | 2 | Rumore gaussiano generico |
| `test_blocchi_1_2.m` | 1+2 | Test con figura riassuntiva |
