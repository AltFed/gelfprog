# Bolometer Simulator — Contesto del Progetto

## Obiettivo
Simulare un bolometro resistivo (tipo gold-foil / metal-foil usato in JET, FTU, ITER)
che misura la potenza radiata da un plasma di fusione.

Il flusso fisico è:
```
P [W]  →  ΔT [K]  →  ΔR [Ω]  →  ΔV [V]  →  +noise  →  P_ricost [W]
```

## Fisica del Bolometro

### 1. Da Potenza a Temperatura
In regime stazionario (equazione termica semplificata):
```
P = G * ΔT   →   ΔT = P / G
```
- `P`   : potenza assorbita [W]
- `G`   : conduttanza termica [W/K]
- `ΔT`  : incremento di temperatura rispetto a T₀ [K]
- `C`   : capacità termica [J/K]  (usata per la dinamica: τ = C/G)

### 2. Da Temperatura a Resistenza
Effetto TCR (Temperature Coefficient of Resistance):
```
ΔR = R₀ * α * ΔT
```
- `R₀`  : resistenza a T₀ [Ω]
- `α`   : TCR [1/K]  (positivo per metalli, negativo per semiconduttori)

### 3. Da Resistenza a Tensione
Polarizzazione con corrente costante I_bias:
```
ΔV = I_bias * ΔR = I_bias * R₀ * α * ΔT
```

### 4. Sensibilità
```
S = ΔV / P = I_bias * R₀ * α / G   [V/W]
```
Aumentare R₀, α, I_bias o diminuire G → maggiore sensibilità.

### 5. Saturazione
- Se ΔT > T_max  →  sensore danneggiato / comportamento non lineare
- Se ΔV > V_sat  →  saturazione elettronica dell'amplificatore

## Struttura File

| File                    | Blocco | Stato | Descrizione                                      |
|-------------------------|--------|-------|--------------------------------------------------|
| `bolometer_params.m`    | 1      | ✅    | Struct con parametri di default + noise params   |
| `forward_model.m`       | 1      | ✅    | P → ΔT → ΔV (forward model fisico)              |
| `add_noise_to_signal.m` | 2      | ✅    | Aggiunge rumore a ΔV (Johnson + amplif. + ADC)  |
| `reconstruct_power.m`   | 3      | ✅    | ΔV_noisy → P_ricost (inversione + MC stats)     |
| `run_power_sweep.m`     | 4      | ✅    | Sweep log [P_min,P_max], plot 3 pannelli         |
| `sensitivity_analysis.m`| 5      | ✅    | Sweep R₀,α,G,I_bias → S, NEP, P_sat, DR         |
| `main.m`                | 6      | ✅    | Script master: params + sweep + sens + summary   |

## Parametri di Default (regime tipico metal-foil bolometer)

| Parametro | Simbolo | Valore default | Unità  |
|-----------|---------|----------------|--------|
| Resistenza| R₀      | 100            | Ω      |
| TCR       | α       | 3.9e-3         | 1/K    |
| Cond. term.| G      | 1e-4           | W/K    |
| Corrente  | I_bias  | 1e-3           | A      |
| Temp. base| T₀      | 300            | K      |
| Cap. term.| C       | 1e-6           | J/K    |
| Sat. tens.| V_sat   | 1.0            | V      |
| Max ΔT    | ΔT_max  | 50             | K      |

## Regimi Attesi nel Power Sweep
- **Bassa potenza** (<< NEP): ΔV < noise → P_ricost dominato da rumore
- **Potenza media** (~ NEP a ~ P_sat): buona ricostruzione, SNR > 1
- **Alta potenza** (>> P_sat): ΔV saturato → P_ricost limitato a P_sat

## Note Implementative
- Rumore principale: Johnson noise `Vn = sqrt(4 * kB * T * R₀ * BW)`
- Range potenza in sweep: logaritmico da 1e-9 W a 1e-1 W
- Aggiornare questo file ad ogni modifica rilevante

## Noise Budget (parametri default)

| Sorgente          | Formula                                  | Valore tipico |
|-------------------|------------------------------------------|---------------|
| Johnson           | `sqrt(4·kB·T0·R0·BW)`                   | ~4.1e-8 V     |
| Amplificatore     | `e_n · sqrt(BW)`  (e_n=10 nV/√Hz)       | ~3.2e-7 V     |
| ADC quantizzazione| `(V_range/2^N) / sqrt(12)`  (16-bit, 2V)| ~8.8e-6 V     |
| **Totale**        | somma in quadratura                      | **~8.8e-6 V** |
| **NEP**           | `V_noise / S`                            | **~2.3e-6 W** |

La sorgente dominante con i parametri default è la quantizzazione ADC.
Per ridurre il NEP: aumentare bit ADC, ridurre V_ADC_range, o aumentare S.

## Ricostruzione (Block 3)

- Inversione diretta: `P_rec = ΔV_noisy / S`
- Con N_MC realizzazioni → distribuzione di P_rec per ogni punto di potenza
- Classificazione regime per ogni punto:
  - `noise` : |mean(ΔV)| < V_noise  (SNR < 1)
  - `ok`    : SNR ≥ 1  e  |ΔV| < 0.99·V_sat
  - `saturated` : |ΔV| ≥ 0.99·V_sat
- `P_std ≈ NEP` (verificato): la dispersione Monte Carlo coincide con il NEP analitico
- `P_ci95` = intervallo di confidenza 95% (t-distribution per N finito)

## Power Sweep (Block 4) — run_power_sweep(params, options)

Esegue la pipeline completa su un range logaritmico di potenza e produce 3 pannelli:

| Pannello | Contenuto |
|----------|-----------|
| 1 (log-log) | P_rec vs P_true, 3 colori per regime, banda CI95, linee NEP e P_sat |
| 2 (log-log) | SNR vs P_true, linea SNR=1 |
| 3 (log-lin) | Curva di trasferimento ΔV(P): ideale vs clippata, V_noise e V_sat |

Opzioni configurabili: `P_min`, `P_max`, `N_points`, `N_MC`, `do_plot`, `save_fig`, `fig_path`.

Risultati con parametri default (120 punti, N_MC=1000):
- Noise-dominated: 45 punti (P < ~NEP = 2.26e-6 W)
- Reconstructable:  67 punti
- Saturated:         8 punti (P > ~P_sat = 0.256 W)

## Sensitivity Analysis (Block 5) — sensitivity_analysis(params, options)

Varia un parametro alla volta su range logaritmico (×0.05 ÷ ×20 dal valore base).
Metriche calcolate per ogni punto: S [V/W], NEP [W], P_sat [W], DR [dB].

### Risultato fisico chiave
```
DR = P_sat / NEP = (V_sat/S) / (V_noise/S) = V_sat / V_noise
```
**DR è indipendente da S**: variare R₀, α, G, I_bias muove NEP e P_sat nella stessa direzione,
lasciando il dynamic range invariato. Con i parametri default: **DR ≈ 101.1 dB**.

Eccezione parziale: aumentare R₀ → Johnson noise V_J ~ √R₀ cresce, V_noise aumenta
leggermente → DR cala (ma di soli ~0.003 dB su range ×400 di R₀, poiché ADC domina).

### Come migliorare la sensibilità
- Aumentare S → NEP scende, P_sat scende → DR invariato
- Per espandere DR: migliorare l'ADC (più bit o range ridotto) o abbassare e_n

### Figure prodotte
- `bolometer_sensitivity.png`    — griglia 4×4: ogni riga un parametro, ogni colonna una metrica
- `bolometer_sensitivity_DR.png` — DR normalizzato per tutti i parametri in un unico plot

## Come eseguire il simulatore

```matlab
cd bolometer/
main          % run completo con parametri default
```

Per personalizzare i parametri del bolometro, editare la sezione `CUSTOM_PARAMS` in `main.m`:
```matlab
CUSTOM_PARAMS = {'R0', 200, 'G', 5e-5, 'I_bias', 2e-3};
```

Per disabilitare una sezione (es. solo sweep senza sensitivity):
```matlab
RUN_SENS = false;
```

Per richiamare i moduli singolarmente:
```matlab
p   = bolometer_params('R0', 200);
fwd = forward_model(P_array, p);
nr  = add_noise_to_signal(fwd.DeltaV_ideal, p, 1000);
rec = reconstruct_power(nr.DeltaV_noisy, p, P_array);
sw  = run_power_sweep(p);
sen = sensitivity_analysis(p);
```

---
*Ultimo aggiornamento: Block 6 completato — simulatore completo e funzionante*
