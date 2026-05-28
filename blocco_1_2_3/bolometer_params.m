function params = bolometer_params()
% Restituisce uno struct con tutti i parametri del bolometro.
%
% Modello fisico:   P -> DeltaT = P/G -> DeltaR = R0*alpha*DeltaT
%                   -> DeltaV = I_bias * DeltaR

    params.R0      = 100;       % resistenza a temperatura base         [Ohm]
    params.alpha   = 3.9e-3;   % coefficiente termico TCR (Platino)    [1/K]
    params.G       = 1e-4;     % conduttanza termica                   [W/K]
    params.C       = 1e-6;     % capacita' termica                     [J/K]
    params.I_bias  = 1e-3;     % corrente di polarizzazione            [A]
    params.T0      = 300;      % temperatura di riferimento            [K]
    params.V_sat   = 1.0;      % tensione di saturazione amplificatore [V]
    params.dT_max  = 50;       % massimo incremento termico sicuro     [K]
    params.BW      = 1e3;      % larghezza di banda                    [Hz]

    params.V_noise = 1e-5;     % rumore rms generico                   [V]

    params.tau = params.C / params.G;
end
