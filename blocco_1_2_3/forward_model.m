function result = forward_model(P, params)
% Modello diretto del bolometro:  P [W]  ->  DeltaT [K]  ->  DeltaV [V]
%
% Ingressi:
%   P       : potenza assorbita, scalare o array [W]
%   params  : struct restituito da bolometer_params()
%
% Uscite:
%   result.DeltaT       incremento di temperatura rispetto a T0  [K]
%   result.DeltaR       variazione di resistenza                  [Ohm]
%   result.DeltaV_ideal tensione ideale (senza rumore)           [V]
%   result.DeltaV       tensione in uscita (clippata a V_sat)    [V]
%   result.is_saturated array logico, true dove avviene saturazione
%   result.P_sat        potenza alla quale si raggiunge V_sat    [W]
%
% Fisica:
%   P = G * DeltaT   (bilancio termico in regime stazionario)
%   DeltaR = R0 * alpha * DeltaT   (TCR: variazione resistenza con T)
%   DeltaV = I_bias * DeltaR       (corrente di bias costante)

    % passo 1: bilancio termico -> incremento di temperatura
    result.DeltaT = P / params.G;

    % passo 2: variazione di resistenza tramite TCR
    result.DeltaR = params.R0 * params.alpha .* result.DeltaT;

    % passo 3: tensione ideale con corrente di bias costante
    result.DeltaV_ideal = params.I_bias .* result.DeltaR;

    % passo 4: saturazione (danno termico oppure amplificatore al rail)
    thermal_sat      = result.DeltaT > params.dT_max;
    electric_sat     = abs(result.DeltaV_ideal) > params.V_sat;
    result.is_saturated = thermal_sat | electric_sat;

    result.DeltaV = result.DeltaV_ideal;
    result.DeltaV(result.is_saturated) = ...
        sign(result.DeltaV_ideal(result.is_saturated)) * params.V_sat;

    result.P_sat = params.V_sat * params.G / (params.I_bias * params.R0 * params.alpha);
end
