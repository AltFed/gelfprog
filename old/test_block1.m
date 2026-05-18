% Quick smoke-test for Block 1 (forward model).
% Run from the bolometer/ directory.

p = bolometer_params();

fprintf('=== Bolometer parameters ===\n');
fprintf('  R0     = %.1f Ohm\n',  p.R0);
fprintf('  alpha  = %.2e 1/K\n',  p.alpha);
fprintf('  G      = %.2e W/K\n',  p.G);
fprintf('  I_bias = %.2e A\n',    p.I_bias);
fprintf('  S      = %.4f V/W\n',  p.S);
fprintf('  tau    = %.2e s\n',    p.tau);
fprintf('  P_sat  ~ %.4f W  (V_sat/S)\n\n', p.V_sat / p.S);

P_test = [1e-9, 1e-6, 1e-3, 1e-1];
r = forward_model(P_test, p);

fprintf('=== Forward model test ===\n');
fprintf('%-12s %-12s %-12s %-12s %-10s\n', ...
    'P [W]', 'DeltaT [K]', 'DeltaR [Ohm]', 'DeltaV [V]', 'Saturated');
for i = 1:length(P_test)
    fprintf('%-12.2e %-12.4f %-12.6f %-12.6f %-10s\n', ...
        P_test(i), r.DeltaT(i), r.DeltaR(i), r.DeltaV(i), ...
        mat2str(r.is_saturated(i)));
end
