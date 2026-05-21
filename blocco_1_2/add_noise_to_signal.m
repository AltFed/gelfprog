function result = add_noise_to_signal(DeltaV, params)
% Aggiunge rumore gaussiano generico al segnale di tensione del bolometro.
%
% Ingressi:
%   DeltaV  : segnale di tensione (dopo saturazione), array 1D [V]
%   params  : struct restituito da bolometer_params()
%
% Uscite:
%   result.DeltaV_noisy   segnale rumoroso [V]
%   result.V_noise        rumore rms       [V]
%   result.SNR            SNR per ogni punto = |DeltaV| / V_noise
%   result.NEP            potenza equivalente al rumore [W]

    DeltaV = DeltaV(:);

    result.DeltaV_noisy = DeltaV + params.V_noise * randn(size(DeltaV));
    result.V_noise      = params.V_noise;
    result.SNR          = abs(DeltaV) / params.V_noise;
    result.NEP          = params.V_noise * params.G / (params.I_bias * params.R0 * params.alpha);
end
