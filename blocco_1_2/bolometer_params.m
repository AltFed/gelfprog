function params = bolometer_params(varargin)
% Restituisce uno struct con tutti i parametri del bolometro.
% Uso:
%   p = bolometer_params()               % valori di default
%   p = bolometer_params('R0', 200, 'G', 5e-5)  % modifica un campo specifico
%
% Modello fisico:   P -> DeltaT = P/G -> DeltaR = R0*alpha*DeltaT
%                   -> DeltaV = I_bias * DeltaR
% Sensibilita':     S = DeltaV/P = I_bias * R0 * alpha / G  [V/W]

    % --- parametri fisici del bolometro (valori tipici per un sensore a foglio metallico) ---
    params.R0      = 100;       % resistenza a temperatura di riferimento  [Ohm]
    params.alpha   = 3.9e-3;    % coefficiente termico della resistenza TCR (Pt: ~3.9e-3)  [1/K]
    params.G       = 1e-4;      % conduttanza termica                      [W/K]
    params.C       = 1e-6;      % capacita' termica                        [J/K]
    params.I_bias  = 1e-3;      % corrente di polarizzazione               [A]
    params.T0      = 300;       % temperatura di riferimento               [K]
    params.V_sat   = 1.0;       % tensione di saturazione dell'amplificatore  [V]
    params.dT_max  = 50;        % massimo incremento di temperatura sicuro [K]
    params.BW      = 1e3;       % larghezza di banda della misura          [Hz]

    % --- parametri di rumore ---
    params.e_n        = 10e-9;  % densita' di rumore dell'amplificatore [V/sqrt(Hz)]
    params.N_bits     = 16;     % risoluzione dell'ADC                   [bit]
    params.V_ADC_range= 2.0;    % fondo scala dell'ADC (picco-picco)     [V]
    params.N_MC       = 1000;   % numero di realizzazioni Monte Carlo (usato nel blocco 3)

    % --- grandezze derivate (calcolate automaticamente) ---
    params.tau     = params.C / params.G;   % costante di tempo termica [s]
    params.S       = params.I_bias * params.R0 * params.alpha / params.G; % sensibilita' [V/W]

    % --- sovrascrittura dei parametri tramite coppie nome-valore ---
    for k = 1:2:length(varargin)
        field = varargin{k};
        value = varargin{k+1};
        if ~isfield(params, field)
            error('bolometer_params: unknown field "%s"', field);
        end
        params.(field) = value;
    end

    % ricalcolo delle grandezze derivate dopo ogni modifica
    params.tau = params.C / params.G;
    params.S   = params.I_bias * params.R0 * params.alpha / params.G;
end
