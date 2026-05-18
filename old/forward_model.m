function result = forward_model(P, params)
% Forward bolometer model:  P [W]  ->  DeltaT [K]  ->  DeltaV [V]
%
% Inputs:
%   P       : absorbed power, scalar or array [W]
%   params  : struct from bolometer_params()
%
% Outputs:
%   result  : struct with fields
%     .DeltaT       temperature rise above T0          [K]
%     .DeltaR       resistance change                  [Ohm]
%     .DeltaV_ideal ideal (no-noise) voltage signal    [V]
%     .DeltaV       output voltage (clipped at V_sat)  [V]
%     .is_saturated logical array, true where ΔT > dT_max or |ΔV| > V_sat
%     .P_sat        saturation power level             [W]
%     .S            sensitivity used                   [V/W]
%
% Physics:
%   Steady-state thermal balance:  P = G * DeltaT
%   Resistance change (TCR):       DeltaR = R0 * alpha * DeltaT
%   Voltage (current bias):        DeltaV = I_bias * DeltaR
%   => DeltaV = (I_bias * R0 * alpha / G) * P = S * P

    % --- step 1: thermal ---
    result.DeltaT = P / params.G;

    % --- step 2: resistance ---
    result.DeltaR = params.R0 * params.alpha .* result.DeltaT;

    % --- step 3: ideal voltage ---
    result.DeltaV_ideal = params.I_bias .* result.DeltaR;
    % equivalently: result.DeltaV_ideal = params.S * P

    % --- step 4: saturation ---
    % saturation can come from:
    %   (a) thermal damage: DeltaT > dT_max  => hard clamp
    %   (b) electronics:    |DeltaV| > V_sat => amplifier rail
    thermal_sat   = result.DeltaT  > params.dT_max;
    electric_sat  = abs(result.DeltaV_ideal) > params.V_sat;
    result.is_saturated = thermal_sat | electric_sat;

    result.DeltaV = result.DeltaV_ideal;
    result.DeltaV(result.is_saturated) = sign(result.DeltaV_ideal(result.is_saturated)) * params.V_sat;

    % --- metadata ---
    result.S     = params.S;
    result.P_sat = params.V_sat / params.S;  % power at which V_sat is reached
end
