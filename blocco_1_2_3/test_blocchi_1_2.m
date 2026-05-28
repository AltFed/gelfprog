% ==========================================================================
%  TEST BLOCCHI 1 e 2 — Bolometro Simulato
%  Eseguire da dentro la cartella blocco_1_2/
%
%  Blocco 1: Forward model  P -> DeltaT -> DeltaR -> DeltaV (con saturazione)
%  Blocco 2: Rumore generico gaussiano via Monte Carlo
% ==========================================================================

clear; clc;

fprintf('========================================\n');
fprintf('  TEST BLOCCHI 1 e 2 — Bolometro\n');
fprintf('========================================\n\n');

% --------------------------------------------------------------------------
%  BLOCCO 1: parametri e modello diretto
% --------------------------------------------------------------------------
fprintf('--- BLOCCO 1: Parametri e Forward Model ---\n\n');

p = bolometer_params();

fprintf('Parametri bolometro:\n');
fprintf('  R0      = %.1f   Ohm\n',   p.R0);
fprintf('  alpha   = %.2e  1/K\n',    p.alpha);
fprintf('  G       = %.2e  W/K\n',    p.G);
fprintf('  I_bias  = %.2e  A\n',      p.I_bias);
fprintf('  T0      = %.0f     K\n',   p.T0);
fprintf('  V_sat   = %.2f    V\n',    p.V_sat);
fprintf('  dT_max  = %.0f     K\n\n', p.dT_max);

% test su 5 potenze di riferimento
P_test = [1e-9, 1e-7, 1e-5, 1e-3, 1e-1]';
fwd = forward_model(P_test, p);

fprintf('  %-12s %-12s %-16s %-12s %-10s\n', ...
    'P [W]', 'DeltaT [K]', 'DeltaV_ideal [V]', 'DeltaV [V]', 'Saturato');
fprintf('  %s\n', repmat('-', 1, 64));
for i = 1:length(P_test)
    fprintf('  %-12.2e %-12.4f %-16.4e %-12.4e %-10s\n', ...
        P_test(i), fwd.DeltaT(i), fwd.DeltaV_ideal(i), ...
        fwd.DeltaV(i), mat2str(fwd.is_saturated(i)));
end

fprintf('\n  P_sat = %.4e W\n', fwd.P_sat);

% --------------------------------------------------------------------------
%  BLOCCO 2: rumore generico (Monte Carlo)
% --------------------------------------------------------------------------
fprintf('\n--- BLOCCO 2: Rumore Generico (Monte Carlo) ---\n\n');

rng(67);
nr = add_noise_to_signal(fwd.DeltaV, p);

fprintf('  V_noise = %.4e V\n', nr.V_noise);
fprintf('  NEP     = %.4e W\n\n', nr.NEP);

fprintf('  %-12s %-14s %-8s %-12s\n', 'P [W]', 'DeltaV [V]', 'SNR', 'Regime');
fprintf('  %s\n', repmat('-', 1, 50));
for i = 1:length(P_test)
    snr = nr.SNR(i);
    if fwd.is_saturated(i)
        reg = 'SATURATO';
    elseif snr < 1
        reg = 'RUMORE';
    else
        reg = 'OK';
    end
    fprintf('  %-12.2e %-14.4e %-8.2f %-12s\n', ...
        P_test(i), fwd.DeltaV(i), snr, reg);
end

% --------------------------------------------------------------------------
%  FIGURA riassuntiva
% --------------------------------------------------------------------------
fprintf('\n--- Generazione figura ---\n');
figure('Name','Blocchi 1-2: Forward Model + Rumore', ...
       'Position',[100 100 1100 500], 'Color','w');

P_sweep = logspace(-9, 0, 200)';
fwd_sw  = forward_model(P_sweep, p);
rng(0);
nr_sw   = add_noise_to_signal(fwd_sw.DeltaV, p);

sat_m = fwd_sw.is_saturated;
ok_m  = ~sat_m & nr_sw.SNR >= 1;
ns_m  = ~sat_m & nr_sw.SNR <  1;

ax_style = {'Color','w','XColor','k','YColor','k','GridColor',[0.8 0.8 0.8]};

% pannello sx: segnale ideale (no clip, arancione continua oltre V_sat)
ax1 = subplot(1,2,1);
hold on; grid on; box on;

loglog(P_sweep(ns_m),  abs(fwd_sw.DeltaV_ideal(ns_m)),  'r-',  'LineWidth', 2, 'DisplayName', 'Rumore dom.');
loglog(P_sweep(ok_m),  abs(fwd_sw.DeltaV_ideal(ok_m)),  'g-',  'LineWidth', 2, 'DisplayName', 'Ricostruibile');
loglog(P_sweep(sat_m), abs(fwd_sw.DeltaV_ideal(sat_m)), '-',   'LineWidth', 2, 'Color', [0.9 0.5 0], 'DisplayName', 'Saturato (ideale)');
yline(p.V_noise, 'r:',  'LineWidth', 1.5, 'Label', 'V_{noise}', 'HandleVisibility', 'off');
yline(p.V_sat,   'm-.', 'LineWidth', 1.5, 'Label', 'V_{sat}',   'HandleVisibility', 'off');

set(ax1, 'XScale','log', 'YScale','log', ax_style{:});
xlabel('P_{true} [W]'); ylabel('|\DeltaV| [V]');
title('Segnale ideale', 'Color','k');
legend('Location','northwest', 'FontSize',9, 'TextColor','k');

% pannello dx: segnale reale (saturato a V_sat, rumoroso scatter)
ax2 = subplot(1,2,2);
hold on; grid on; box on;

loglog(P_sweep(ns_m),  abs(nr_sw.DeltaV_noisy(ns_m)),  'r.',  'MarkerSize', 5, 'DisplayName', 'Rumore dom.');
loglog(P_sweep(ok_m),  abs(nr_sw.DeltaV_noisy(ok_m)),  'g-',  'LineWidth', 2,  'DisplayName', 'Ricostruibile');
loglog(P_sweep(sat_m), abs(nr_sw.DeltaV_noisy(sat_m)), '-',   'LineWidth', 2,  'Color', [0.9 0.5 0], 'DisplayName', 'Saturato');
yline(p.V_noise, 'r:',  'LineWidth', 1.5, 'Label', 'V_{noise}', 'HandleVisibility', 'off');
yline(p.V_sat,   'm-.', 'LineWidth', 1.5, 'Label', 'V_{sat}',   'HandleVisibility', 'off');

set(ax2, 'XScale','log', 'YScale','log', ax_style{:});
xlabel('P_{true} [W]'); ylabel('|\DeltaV| [V]');
title('Segnale reale (saturazione + rumore)', 'Color','k');
legend('Location','northwest', 'FontSize',9, 'TextColor','k');

exportgraphics(gcf, 'blocchi_1_2_risultati.png', 'Resolution', 150);

fprintf('\n========================================\n');
fprintf('  TEST COMPLETATO\n');
fprintf('  NEP     = %.4e W\n', nr_sw.NEP);
fprintf('  P_sat   = %.4e W\n', fwd_sw.P_sat);
fprintf('  V_noise = %.4e V\n', p.V_noise);
fprintf('  Figura salvata: blocchi_1_2_risultati.png\n');
fprintf('========================================\n');
