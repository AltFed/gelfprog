% Smoke-test for Block 5 (sensitivity analysis).
% Run from the bolometer/ directory.

p = bolometer_params();

opt.do_plot  = true;
opt.save_fig = true;
opt.fig_path = 'bolometer_sensitivity.png';
opt.N_sweep  = 60;

res = sensitivity_analysis(p, opt);

fprintf('=== Sensitivity analysis (base configuration) ===\n');
fprintf('  S     = %.4f  V/W\n',   res.base_S);
fprintf('  NEP   = %.4e  W\n',     res.base_NEP);
fprintf('  P_sat = %.4e  W\n',     res.base_Psat);
fprintf('  DR    = %.1f  dB\n\n',  res.base_DR);

fprintf('%-10s  %-8s  %-12s  %-12s  %-12s  %-10s\n', ...
    'Param','x_base','S [V/W]','NEP [W]','P_sat [W]','DR [dB]');
for i = 1:numel(res.sweeps)
    sw = res.sweeps(i);
    % pick value at base (midpoint of sweep = base)
    mid = round(length(sw.x_vals)/2);
    fprintf('%-10s  %-8.3g  %-12.4f  %-12.4e  %-12.4e  %-10.1f\n', ...
        sw.name, sw.base, sw.S_vals(mid), sw.NEP_vals(mid), ...
        sw.Psat_vals(mid), sw.DR_vals(mid));
end
fprintf('\nFigures saved.\n');
