function params = bolometer_params(varargin)
% Returns a struct with bolometer parameters.
% Usage:
%   p = bolometer_params()               % default values
%   p = bolometer_params('R0', 200, 'G', 5e-5)  % override specific fields
%
% Physical model:   P -> DeltaT = P/G -> DeltaR = R0*alpha*DeltaT
%                   -> DeltaV = I_bias * DeltaR
% Sensitivity:      S = DeltaV/P = I_bias * R0 * alpha / G  [V/W]

    % --- default parameters (typical metal-foil bolometer) ---
    params.R0      = 100;       % resistance at base temp     [Ohm]
    params.alpha   = 3.9e-3;    % TCR (gold: ~3.4e-3, Pt: ~3.9e-3)  [1/K]
    params.G       = 1e-4;      % thermal conductance         [W/K]
    params.C       = 1e-6;      % thermal capacitance         [J/K]
    params.I_bias  = 1e-3;      % bias current                [A]
    params.T0      = 300;       % base temperature            [K]
    params.V_sat   = 1.0;       % amplifier saturation level  [V]
    params.dT_max  = 50;        % max safe temperature rise   [K]
    params.BW      = 1e3;       % measurement bandwidth       [Hz]

    % --- noise parameters ---
    params.e_n        = 10e-9;  % amplifier voltage noise density [V/sqrt(Hz)]
    params.N_bits     = 16;     % ADC resolution                  [bits]
    params.V_ADC_range= 2.0;    % ADC full-scale range (peak-to-peak) [V]
    params.N_MC       = 1000;   % Monte Carlo realizations (for Block 3)

    % --- derived quantities ---
    params.tau     = params.C / params.G;   % thermal time constant [s]
    params.S       = params.I_bias * params.R0 * params.alpha / params.G; % sensitivity [V/W]

    % --- override with name-value pairs ---
    for k = 1:2:length(varargin)
        field = varargin{k};
        value = varargin{k+1};
        if ~isfield(params, field)
            error('bolometer_params: unknown field "%s"', field);
        end
        params.(field) = value;
    end

    % recompute derived quantities after any override
    params.tau = params.C / params.G;
    params.S   = params.I_bias * params.R0 * params.alpha / params.G;
end
