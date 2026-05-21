function result = add_noise_to_signal(DeltaV, params, N_realizations)
% Aggiunge rumore realistico al segnale di tensione ideale del bolometro.
%
% Tre sorgenti di rumore indipendenti (sommate in quadratura):
%   1. Rumore di Johnson  : V_J  = sqrt(4 * kB * T0 * R0 * BW)
%   2. Rumore amplificatore: V_A  = e_n * sqrt(BW)
%   3. Rumore quantizzazione ADC: V_Q = LSB / sqrt(12),  LSB = V_ADC_range / 2^N_bits
%
% Ingressi:
%   DeltaV        : segnale di tensione ideale, array 1D di lunghezza M  [V]
%   params        : struct restituito da bolometer_params()
%   N_realizations: (opzionale) numero di copie rumorose da generare
%                   default = 1  (singola realizzazione)
%
% Uscite:
%   result.DeltaV_noisy   segnale rumoroso [M x N_realizations]
%   result.V_J            rumore di Johnson rms            [V]
%   result.V_A            rumore dell'amplificatore rms    [V]
%   result.V_Q            rumore di quantizzazione ADC rms [V]
%   result.V_noise_total  rumore totale rms                [V]
%   result.SNR            rapporto segnale/rumore per ogni punto (|DeltaV| / V_noise)
%   result.NEP            potenza equivalente al rumore = V_noise_total / S  [W]

    if nargin < 3
        N_realizations = 1;
    end

    kB = 1.380649e-23;  % costante di Boltzmann [J/K]

    % --- 1. Rumore di Johnson (agitazione termica nella resistenza) ---
    V_J = sqrt(4 * kB * params.T0 * params.R0 * params.BW);

    % --- 2. Rumore dell'amplificatore ---
    V_A = params.e_n * sqrt(params.BW);

    % --- 3. Rumore di quantizzazione dell'ADC ---
    LSB = params.V_ADC_range / 2^params.N_bits;
    V_Q = LSB / sqrt(12);

    % --- rumore totale: sorgenti indipendenti, si sommano in quadratura ---
    V_noise = sqrt(V_J^2 + V_A^2 + V_Q^2);

    % --- generazione delle realizzazioni Monte Carlo ---
    % DeltaV deve essere un vettore colonna; il rumore e' gaussiano bianco con std = V_noise
    DeltaV = DeltaV(:);    % forza vettore colonna
    M = length(DeltaV);
    noise_matrix = V_noise * randn(M, N_realizations);
    DeltaV_noisy = DeltaV + noise_matrix;   % matrice [M x N_realizations]

    % clipping al fondo scala dell'ADC (saturazione in lettura)
    V_half = params.V_ADC_range / 2;
    DeltaV_noisy = max(-V_half, min(V_half, DeltaV_noisy));

    % --- grandezze diagnostiche ---
    SNR = abs(DeltaV) / V_noise;   % SNR per ogni punto [lineare]
    NEP = V_noise / params.S;       % potenza equivalente al rumore [W]

    % --- raccolta dei risultati nello struct ---
    result.DeltaV_noisy   = DeltaV_noisy;
    result.V_J            = V_J;
    result.V_A            = V_A;
    result.V_Q            = V_Q;
    result.V_noise_total  = V_noise;
    result.SNR            = SNR;
    result.NEP            = NEP;
end
