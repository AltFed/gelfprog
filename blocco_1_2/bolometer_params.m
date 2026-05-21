function params = bolometer_params()
% Returns a struct with bolometer parameters.
%
% Physical model:   P -> DeltaT = P/G -> DeltaR = R0*alpha*DeltaT
%                   -> DeltaV = I_bias * DeltaR

    params.R0      = 100;       % resistance at base temp     [Ohm]
    params.alpha   = 3.9e-3;   % TCR (Platinum)              [1/K]
    params.G       = 1e-4;     % thermal conductance         [W/K]
    params.C       = 1e-6;     % thermal capacitance         [J/K]
    params.I_bias  = 1e-3;     % bias current                [A]
    params.T0      = 300;      % base temperature            [K]
    params.V_sat   = 1.0;      % amplifier saturation level  [V]
    params.dT_max  = 50;       % max safe temperature rise   [K]
    params.BW      = 1e3;      % measurement bandwidth       [Hz]

    params.V_noise = 1e-5;     % generic rms noise amplitude [V]

    params.tau = params.C / params.G;
end
