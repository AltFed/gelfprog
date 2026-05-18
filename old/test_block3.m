% Smoke-test for Block 3 (reconstruction module).
% Run from the bolometer/ directory.

rng(42);
p = bolometer_params();

P_true = [1e-9, 1e-7, 1e-5, 1e-3, 5e-2]';

% forward model
fwd = forward_model(P_true, p);

% add noise — N_MC realizations
N_MC = p.N_MC;
nr   = add_noise_to_signal(fwd.DeltaV_ideal, p, N_MC);

% reconstruct
rec = reconstruct_power(nr.DeltaV_noisy, p, P_true);

fprintf('=== Reconstruction results (N_MC = %d) ===\n', N_MC);
fprintf('NEP = %.4e W\n\n', rec.NEP);
fprintf('%-12s %-12s %-12s %-12s %-10s %-10s\n', ...
    'P_true [W]', 'P_mean [W]', 'P_std [W]', 'CI95 [W]', 'Rel.Err', 'Regime');
for i = 1:length(P_true)
    if ~rec.is_saturated(i) && ~rec.is_noise_dom(i)
        rel = abs(rec.P_mean(i) - P_true(i)) / P_true(i);
        rel_str = sprintf('%.3f', rel);
    else
        rel_str = '---';
    end
    fprintf('%-12.2e %-12.4e %-12.4e %-12.4e %-10s %-10s\n', ...
        P_true(i), rec.P_mean(i), rec.P_std(i), rec.P_ci95(i), ...
        rel_str, rec.regime{i});
end

fprintf('\nRMSE (valid points) = %.4e W\n', rec.RMSE);

% verify MC std matches analytical prediction: std(P_rec) = V_noise/S / sqrt(1)
% for a single-point distribution, std across MC ~ V_noise/S
expected_std = rec.NEP;
fprintf('\nExpected P_std (~ NEP) = %.4e W\n', expected_std);
fprintf('Measured P_std at mid-range point (P=1e-5): %.4e W\n', rec.P_std(3));
