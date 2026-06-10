function result = add_noise_to_signal(DeltaV, params)

    DeltaV = DeltaV(:);

    result.DeltaV_noisy = DeltaV + params.V_noise * randn(size(DeltaV));
    result.V_noise      = params.V_noise;
    result.SNR          = abs(DeltaV) / params.V_noise;
    result.NEP          = params.V_noise * params.G / (params.I_bias * params.R0 * params.alpha);
end
