% Smoke-test for Block 4 (power sweep + plot).
% Run from the bolometer/ directory.
% Saves figure to disk so it can be verified headlessly.

p = bolometer_params();

opt.P_min    = 1e-9;
opt.P_max    = 1e0;
opt.N_points = 120;
opt.N_MC     = 1000;
opt.do_plot  = true;
opt.save_fig = true;
opt.fig_path = 'bolometer_sweep.png';

sw = run_power_sweep(p, opt);

% summary stats
n_noise = sum(sw.mask_noise);
n_ok    = sum(sw.mask_ok);
n_sat   = sum(sw.mask_sat);
total   = length(sw.P_true);

fprintf('=== Sweep summary (%d points) ===\n', total);
fprintf('  Noise-dominated : %3d points  (P < %.2e W)\n', n_noise, ...
    max(sw.P_true(sw.mask_noise), [], 'all'));
fprintf('  Reconstructable : %3d points\n', n_ok);
fprintf('  Saturated       : %3d points  (P > %.2e W)\n', n_sat, ...
    min(sw.P_true(sw.mask_sat), [], 'all'));
fprintf('  NEP             = %.4e W\n',  sw.rec.NEP);
fprintf('  P_sat           = %.4e W\n',  sw.fwd.P_sat);
fprintf('  RMSE (ok pts)   = %.4e W\n',  sw.rec.RMSE);
fprintf('\nFigure saved: %s\n', opt.fig_path);
