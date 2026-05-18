function result = add_noise_to_signal(DeltaV, params)
% Adds generic Gaussian noise to the bolometer voltage signal.
%
% Inputs:
%   DeltaV  : voltage signal (after saturation), 1-D array [V]
%   params  : struct from bolometer_params()
%
% Outputs:
%   result.DeltaV_noisy   noisy signal [V]
%   result.V_noise        noise rms    [V]
%   result.SNR            per-point SNR = |DeltaV| / V_noise
%   result.NEP            noise equivalent power [W]

    DeltaV = DeltaV(:);

    result.DeltaV_noisy = DeltaV + params.V_noise * randn(size(DeltaV));
    result.V_noise      = params.V_noise;
    result.SNR          = abs(DeltaV) / params.V_noise;
    result.NEP          = params.V_noise * params.G / (params.I_bias * params.R0 * params.alpha);
end
