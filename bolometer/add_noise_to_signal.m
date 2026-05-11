function result = add_noise_to_signal(DeltaV, params, N_realizations)
% Adds realistic noise to the ideal bolometer voltage signal DeltaV.
%
% Three independent noise sources (added in quadrature):
%   1. Johnson noise   : V_J  = sqrt(4 * kB * T0 * R0 * BW)
%   2. Amplifier noise : V_A  = e_n * sqrt(BW)
%   3. ADC quant. noise: V_Q  = LSB / sqrt(12),  LSB = V_ADC_range / 2^N_bits
%
% Inputs:
%   DeltaV        : ideal voltage signal, 1-D array of length M  [V]
%   params        : struct from bolometer_params()
%   N_realizations: (optional) number of noisy copies to generate
%                   default = 1  (single realization)
%
% Outputs:
%   result.DeltaV_noisy   [M x N_realizations] noisy signal
%   result.V_J            Johnson noise rms            [V]
%   result.V_A            amplifier noise rms          [V]
%   result.V_Q            ADC quantization noise rms   [V]
%   result.V_noise_total  total rms noise              [V]
%   result.SNR            signal-to-noise ratio per input point (ideal |DeltaV| / V_noise)
%   result.NEP            noise equivalent power = V_noise_total / S  [W]

    if nargin < 3
        N_realizations = 1;
    end

    kB = 1.380649e-23;  % Boltzmann constant [J/K]

    % --- 1. Johnson (thermal) noise ---
    % comes from the resistive element at temperature T0
    V_J = sqrt(4 * kB * params.T0 * params.R0 * params.BW);

    % --- 2. Amplifier voltage noise ---
    V_A = params.e_n * sqrt(params.BW);

    % --- 3. ADC quantization noise ---
    LSB = params.V_ADC_range / 2^params.N_bits;
    V_Q = LSB / sqrt(12);

    % --- total noise (independent sources → quadrature sum) ---
    V_noise = sqrt(V_J^2 + V_A^2 + V_Q^2);

    % --- generate noisy realizations ---
    % DeltaV is a column, noise is white Gaussian with std = V_noise
    DeltaV = DeltaV(:);    % ensure column
    M = length(DeltaV);
    noise_matrix = V_noise * randn(M, N_realizations);
    DeltaV_noisy = DeltaV + noise_matrix;   % [M x N_realizations]

    % clip to ADC range (saturation at readout stage)
    V_half = params.V_ADC_range / 2;
    DeltaV_noisy = max(-V_half, min(V_half, DeltaV_noisy));

    % --- diagnostics ---
    SNR = abs(DeltaV) / V_noise;   % per-point SNR [linear]
    NEP = V_noise / params.S;       % noise equivalent power [W]

    % --- pack output ---
    result.DeltaV_noisy   = DeltaV_noisy;
    result.V_J            = V_J;
    result.V_A            = V_A;
    result.V_Q            = V_Q;
    result.V_noise_total  = V_noise;
    result.SNR            = SNR;
    result.NEP            = NEP;
end
