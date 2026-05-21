function result = forward_model(P, params)
% Modello diretto del bolometro:  P [W]  ->  DeltaT [K]  ->  DeltaV [V]
%
% Ingressi:
%   P       : potenza assorbita, scalare o array  [W]
%   params  : struct restituito da bolometer_params()
%
% Uscite (struct result):
%     .DeltaT       incremento di temperatura rispetto a T0  [K]
%     .DeltaR       variazione di resistenza                 [Ohm]
%     .DeltaV_ideal segnale di tensione ideale (senza rumore) [V]
%     .DeltaV       tensione in uscita (clippata a V_sat)    [V]
%     .is_saturated array logico, true dove DeltaT > dT_max o |DeltaV| > V_sat
%     .P_sat        potenza di saturazione                   [W]
%     .S            sensibilita' usata                       [V/W]
%
% Fisica:
%   Bilancio termico stazionario:  P = G * DeltaT
%   Variazione resistenza (TCR):   DeltaR = R0 * alpha * DeltaT
%   Tensione (corrente di bias):   DeltaV = I_bias * DeltaR
%   => DeltaV = (I_bias * R0 * alpha / G) * P = S * P

    % --- passo 1: bilancio termico, calcolo dell'incremento di temperatura ---
    result.DeltaT = P / params.G;

    % --- passo 2: variazione di resistenza tramite il coefficiente TCR ---
    result.DeltaR = params.R0 * params.alpha .* result.DeltaT;

    % --- passo 3: tensione ideale con corrente di polarizzazione costante ---
    result.DeltaV_ideal = params.I_bias .* result.DeltaR;
    % equivalente a: result.DeltaV_ideal = params.S * P

    % --- passo 4: saturazione ---
    % la saturazione avviene in due casi:
    %   (a) danno termico: DeltaT > dT_max  => clamp forzato
    %   (b) saturazione elettronica: |DeltaV| > V_sat => amplificatore al rail
    thermal_sat   = result.DeltaT  > params.dT_max;
    electric_sat  = abs(result.DeltaV_ideal) > params.V_sat;
    result.is_saturated = thermal_sat | electric_sat;

    result.DeltaV = result.DeltaV_ideal;
    result.DeltaV(result.is_saturated) = sign(result.DeltaV_ideal(result.is_saturated)) * params.V_sat;

    % --- informazioni aggiuntive salvate nello struct ---
    result.S     = params.S;
    result.P_sat = params.V_sat / params.S;  % potenza alla quale si raggiunge la saturazione
end
