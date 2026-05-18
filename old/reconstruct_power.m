function result = reconstruct_power(DeltaV_noisy, params, P_true)
% Reconstructs absorbed power from noisy bolometer voltage via inversion.
%
% Inversion:   P_reconstructed = DeltaV_noisy / S
%   where S = I_bias * R0 * alpha / G  [V/W]
%
% Works with multiple Monte Carlo realizations: if DeltaV_noisy is [M x N],
% the reconstruction is applied to all N copies and statistics are reported.
%
% Inputs:
%   DeltaV_noisy : noisy voltage, [M x N_real] or [M x 1]           [V]
%   params       : struct from bolometer_params()
%   P_true       : (optional) true power array [M x 1], used for error metrics
%
% Outputs:
%   result.P_mean        mean reconstructed power across realizations [M x 1] [W]
%   result.P_std         std  reconstructed power across realizations [M x 1] [W]
%   result.P_ci95        95% confidence interval half-width           [M x 1] [W]
%   result.P_all         all reconstructions                          [M x N] [W]
%   result.is_saturated  logical [M x 1], true where |DeltaV| ~ V_sat
%   result.is_noise_dom  logical [M x 1], true where SNR < 1 (mean signal < noise floor)
%   result.regime        string cell array [M x 1]: 'noise'/'ok'/'saturated'
%   result.RMSE          (only if P_true given) root-mean-square error [W]
%   result.rel_error     (only if P_true given) |P_mean - P_true| / P_true

    DeltaV_noisy = reshape(DeltaV_noisy, [], size(DeltaV_noisy, 2));
    M     = size(DeltaV_noisy, 1);
    N     = size(DeltaV_noisy, 2);
    S     = params.S;

    % --- core inversion ---
    P_all = DeltaV_noisy / S;   % [M x N]

    % --- statistics across realizations ---
    P_mean = mean(P_all, 2);    % [M x 1]
    P_std  = std(P_all,  0, 2); % [M x 1]

    % 95% CI: use t-distribution for finite N, normal for large N
    if N > 1
        t95   = tinv(0.975, N - 1);
        P_ci95 = t95 * P_std / sqrt(N);
    else
        P_ci95 = zeros(M, 1);
    end

    % --- regime classification (based on mean signal) ---
    % noise floor estimated from params
    kB          = 1.380649e-23;
    V_J         = sqrt(4 * kB * params.T0 * params.R0 * params.BW);
    V_A         = params.e_n * sqrt(params.BW);
    LSB         = params.V_ADC_range / 2^params.N_bits;
    V_Q         = LSB / sqrt(12);
    V_noise     = sqrt(V_J^2 + V_A^2 + V_Q^2);

    sat_thresh        = 0.99 * params.V_sat;   % within 1% of rail
    mean_abs_DeltaV   = abs(mean(DeltaV_noisy, 2));  % mean over realizations

    is_saturated = mean_abs_DeltaV >= sat_thresh;
    is_noise_dom = mean_abs_DeltaV <  V_noise;        % SNR < 1

    regime = repmat({'ok'}, M, 1);
    regime(is_noise_dom)  = {'noise'};
    regime(is_saturated)  = {'saturated'};

    % --- pack base output ---
    result.P_mean       = P_mean;
    result.P_std        = P_std;
    result.P_ci95       = P_ci95;
    result.P_all        = P_all;
    result.is_saturated = is_saturated;
    result.is_noise_dom = is_noise_dom;
    result.regime       = regime;
    result.V_noise      = V_noise;
    result.NEP          = V_noise / S;

    % --- optional error metrics vs true power ---
    if nargin >= 3 && ~isempty(P_true)
        P_true = P_true(:);
        valid  = ~is_saturated & ~is_noise_dom;
        if any(valid)
            result.RMSE      = sqrt(mean((P_mean(valid) - P_true(valid)).^2));
            result.rel_error = abs(P_mean - P_true) ./ abs(P_true);
        else
            result.RMSE      = NaN;
            result.rel_error = NaN(M, 1);
        end
    end
end
