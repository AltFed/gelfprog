% Smoke-test for Block 2 (noise module).
% Run from the bolometer/ directory.

p = bolometer_params();

% forward model over a small set of powers
P_test = [1e-9, 1e-7, 1e-5, 1e-3, 1e-1];
fwd = forward_model(P_test, p);

% single-realization noise
noise_res = add_noise_to_signal(fwd.DeltaV_ideal, p, 1);

fprintf('=== Noise budget ===\n');
fprintf('  Johnson noise   V_J  = %.4e V\n', noise_res.V_J);
fprintf('  Amplifier noise V_A  = %.4e V\n', noise_res.V_A);
fprintf('  ADC quant. noise V_Q = %.4e V\n', noise_res.V_Q);
fprintf('  Total noise     V_n  = %.4e V\n', noise_res.V_noise_total);
fprintf('  NEP                  = %.4e W\n\n', noise_res.NEP);

fprintf('=== Signal vs Noise ===\n');
fprintf('%-12s %-14s %-14s %-8s %-8s\n', ...
    'P [W]', 'DeltaV_ideal', 'DeltaV_noisy', 'SNR', 'Regime');
for i = 1:length(P_test)
    snr = noise_res.SNR(i);
    if snr < 1
        regime = 'NOISE';
    elseif fwd.is_saturated(i)
        regime = 'SAT';
    else
        regime = 'OK';
    end
    fprintf('%-12.2e %-14.4e %-14.4e %-8.2f %-8s\n', ...
        P_test(i), fwd.DeltaV_ideal(i), noise_res.DeltaV_noisy(i), snr, regime);
end

% check multi-realization shape
r100 = add_noise_to_signal(fwd.DeltaV_ideal, p, 100);
fprintf('\nMulti-realization: size(DeltaV_noisy) = [%d x %d]  (expected [%d x 100])\n', ...
    size(r100.DeltaV_noisy, 1), size(r100.DeltaV_noisy, 2), length(P_test));
