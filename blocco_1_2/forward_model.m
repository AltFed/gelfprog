function result = forward_model(P, params)
% Forward bolometer model:  P [W]  ->  DeltaT [K]  ->  DeltaV [V]
%
% Inputs:
%   P       : absorbed power, scalar or array [W]
%   params  : struct from bolometer_params()
%
% Outputs:
%   result.DeltaT       temperature rise above T0          [K]
%   result.DeltaR       resistance change                  [Ohm]
%   result.DeltaV_ideal ideal (no-noise) voltage signal    [V]
%   result.DeltaV       output voltage (clipped at V_sat)  [V]
%   result.is_saturated logical array, true where clipping occurred
%   result.P_sat        power level at which V_sat is reached [W]
%
% Physics:
%   P = G * DeltaT   (steady-state thermal balance)
%   DeltaR = R0 * alpha * DeltaT   (TCR)
%   DeltaV = I_bias * DeltaR       (current bias)

    % step 1: thermal
    result.DeltaT = P / params.G;

    % step 2: resistance
    result.DeltaR = params.R0 * params.alpha .* result.DeltaT;

    % step 3: ideal voltage
    result.DeltaV_ideal = params.I_bias .* result.DeltaR;

    % step 4: saturation (thermal damage or amplifier rail)
    thermal_sat      = result.DeltaT > params.dT_max;
    electric_sat     = abs(result.DeltaV_ideal) > params.V_sat;
    result.is_saturated = thermal_sat | electric_sat;

    result.DeltaV = result.DeltaV_ideal;
    result.DeltaV(result.is_saturated) = ...
        sign(result.DeltaV_ideal(result.is_saturated)) * params.V_sat;

    result.P_sat = params.V_sat * params.G / (params.I_bias * params.R0 * params.alpha);
end
