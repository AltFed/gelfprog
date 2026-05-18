# Blocco 1 & 2 — Bolometro Simulato

## Obiettivo

Questi due blocchi costituiscono la base del simulatore di bolometro.
Partendo da una potenza in ingresso, si ottiene la variazione di tensione
misurata dal sensore (modello diretto), a cui viene poi aggiunto rumore
realistico.

---

## Blocco 1 — Forward Model

**File:** `bolometer_params.m`, `forward_model.m`

### Catena fisica implementata

```
P [W]  →  ΔT = P / G  →  ΔR = R₀·α·ΔT  →  ΔV = I_bias·ΔR
```

| Passo | Equazione | Variabile |
|-------|-----------|-----------|
| Bilancio termico (regime staz.) | `ΔT = P / G` | `G` = conduttanza [W/K] |
| Variazione resistenza (TCR) | `ΔR = R₀·α·ΔT` | `α` = TCR [1/K] |
| Lettura con corrente di bias | `ΔV = I_bias·ΔR` | `I_bias` [A] |
| **Sensibilità** | `S = ΔV/P = I_bias·R₀·α/G` | `S` [V/W] |

La funzione `forward_model` gestisce anche la **saturazione** in due casi:
- Termica: `ΔT > ΔT_max` (sensore danneggiato)
- Elettronica: `|ΔV| > V_sat` (amplificatore al rail)

### Parametri default

| Parametro | Simbolo | Valore | Unità |
|-----------|---------|--------|-------|
| Resistenza | R₀ | 100 | Ω |
| TCR (Pt) | α | 3.9×10⁻³ | 1/K |
| Cond. termica | G | 1×10⁻⁴ | W/K |
| Corrente bias | I_bias | 1×10⁻³ | A |
| Temp. base | T₀ | 300 | K |
| Sat. tensione | V_sat | 1.0 | V |
| **Sensibilità** | **S** | **3.90** | **V/W** |
| **P_sat = V_sat/S** | | **0.256** | **W** |

### Uso

```matlab
p   = bolometer_params();                    % parametri default
p2  = bolometer_params('R0', 200, 'G', 5e-5); % con override

fwd = forward_model(P_array, p);
% fwd.DeltaT       → temperatura [K]
% fwd.DeltaV_ideal → tensione ideale [V]
% fwd.DeltaV       → tensione clippata [V]
% fwd.is_saturated → maschera punti saturi
```

---

## Blocco 2 — Modulo Rumore

**File:** `add_noise_to_signal.m`

### Tre sorgenti indipendenti (somma in quadratura)

| Sorgente | Formula | Valore default |
|----------|---------|----------------|
| Johnson (termico) | `V_J = √(4·kB·T₀·R₀·BW)` | ~4.1×10⁻⁸ V |
| Amplificatore | `V_A = e_n·√BW` (e_n=10 nV/√Hz) | ~3.2×10⁻⁷ V |
| ADC quantizzazione | `V_Q = (V_range/2^N)/√12` (16-bit) | ~8.8×10⁻⁶ V |
| **Totale** | somma in quadratura | **~8.8×10⁻⁶ V** |
| **NEP = V_noise/S** | | **~2.26×10⁻⁶ W** |

> **La sorgente dominante è l'ADC** (99.9% della varianza).

### Uso con Monte Carlo

```matlab
% N = numero di realizzazioni (per analisi statistica)
nr = add_noise_to_signal(fwd.DeltaV_ideal, p, 1000);
% nr.DeltaV_noisy  → matrice [M × N] segnali rumorosi
% nr.V_noise_total → rumore totale rms [V]
% nr.SNR           → SNR per punto [lineare]
% nr.NEP           → NEP [W]
```

### Comportamento atteso

| Potenza | SNR | Regime |
|---------|-----|--------|
| P ≪ NEP | < 1 | **Rumore dominante** — P_rec inutilizzabile |
| NEP < P < P_sat | ≫ 1 | **Ricostruibile** — buona misura |
| P > P_sat | — | **Saturato** — amplificatore al rail |

---

## Come eseguire il test

```matlab
cd blocco_1_2/
test_blocchi_1_2
```

Il test stampa il budget del rumore, la tabella SNR per 5 potenze,
verifica la consistenza `σ(P_rec) ≈ NEP` e salva la figura
`blocchi_1_2_risultati.png`.

---

## File in questa cartella

| File | Blocco | Descrizione |
|------|--------|-------------|
| `bolometer_params.m` | 1 | Parametri fisici e di rumore |
| `forward_model.m` | 1 | P → ΔT → ΔR → ΔV con saturazione |
| `add_noise_to_signal.m` | 2 | Rumore Johnson + amplif. + ADC, Monte Carlo |
| `test_blocchi_1_2.m` | 1+2 | Test unificato con figura riassuntiva |
| `README.md` | — | Questo file |
