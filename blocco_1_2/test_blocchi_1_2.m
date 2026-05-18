% ==========================================================================
%  TEST BLOCCHI 1 e 2 — Bolometro Simulato
%  Eseguire da dentro la cartella blocco_1_2/
%
%  Blocco 1: Forward model  P -> DeltaT -> DeltaR -> DeltaV
%  Blocco 2: Modulo rumore  DeltaV + noise (Johnson + amplif. + ADC)
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

fprintf('Parametri bolometro (default):\n');
fprintf('  R0      = %.1f   Ohm\n',   p.R0);
fprintf('  alpha   = %.2e  1/K   (TCR Platino)\n', p.alpha);
fprintf('  G       = %.2e  W/K   (conduttanza termica)\n', p.G);
fprintf('  I_bias  = %.2e  A\n',      p.I_bias);
fprintf('  T0      = %.0f     K\n',   p.T0);
fprintf('  V_sat   = %.2f    V     (saturazione amplificatore)\n', p.V_sat);
fprintf('  dT_max  = %.0f     K     (max delta temperatura)\n',   p.dT_max);
fprintf('  BW      = %.0f    Hz\n',   p.BW);
fprintf('\n  --> Sensibilita''  S = I_bias*R0*alpha/G = %.4f V/W\n', p.S);
fprintf('  --> P_sat = V_sat/S                    = %.4e W\n\n', p.V_sat/p.S);

% test su 5 potenze di riferimento
P_test = [1e-9, 1e-7, 1e-5, 1e-3, 1e-1]';
fwd = forward_model(P_test, p);

fprintf('  %-12s %-12s %-14s %-12s %-10s\n', ...
    'P [W]', 'DeltaT [K]', 'DeltaV_ideal [V]', 'DeltaV [V]', 'Saturato');
fprintf('  %s\n', repmat('-', 1, 64));
for i = 1:length(P_test)
    fprintf('  %-12.2e %-12.4f %-16.4e %-12.4e %-10s\n', ...
        P_test(i), fwd.DeltaT(i), fwd.DeltaV_ideal(i), ...
        fwd.DeltaV(i), mat2str(fwd.is_saturated(i)));
end

% verifica analitica: DeltaV = S * P (zona lineare)
ok_mask  = ~fwd.is_saturated;
err_rel  = max(abs(fwd.DeltaV(ok_mask) - p.S * P_test(ok_mask)) ...
               ./ (p.S * P_test(ok_mask)));
fprintf('\n  Errore relativo max (punti non saturi): %.2e', err_rel);
if err_rel < 1e-10
    fprintf('  --> OK (uscita lineare verificata)\n');
else
    fprintf('  --> ATTENZIONE: errore fuori tolleranza\n');
end

% --------------------------------------------------------------------------
%  BLOCCO 2: aggiunta del rumore
% --------------------------------------------------------------------------
fprintf('\n--- BLOCCO 2: Modulo Rumore ---\n\n');

rng(42);   % seed fisso per riproducibilita'
nr = add_noise_to_signal(fwd.DeltaV_ideal, p, 1000);

fprintf('  Budget del rumore:\n');
fprintf('    Johnson (termico) V_J = %.4e V  (%5.1f%% della varianza)\n', ...
    nr.V_J, 100 * nr.V_J^2 / nr.V_noise_total^2);
fprintf('    Amplificatore     V_A = %.4e V  (%5.1f%% della varianza)\n', ...
    nr.V_A, 100 * nr.V_A^2 / nr.V_noise_total^2);
fprintf('    ADC quant.        V_Q = %.4e V  (%5.1f%% della varianza)\n', ...
    nr.V_Q, 100 * nr.V_Q^2 / nr.V_noise_total^2);
fprintf('    ----------------------------------------\n');
fprintf('    Totale      V_noise   = %.4e V\n', nr.V_noise_total);
fprintf('    NEP = V_noise / S     = %.4e W\n\n', nr.NEP);

fprintf('  SNR per punto di potenza:\n');
fprintf('  %-12s %-14s %-8s %-12s\n', 'P [W]', 'DeltaV_ideal', 'SNR', 'Regime');
fprintf('  %s\n', repmat('-', 1, 50));
for i = 1:length(P_test)
    snr = nr.SNR(i);
    if snr < 1
        reg = 'RUMORE';
    elseif fwd.is_saturated(i)
        reg = 'SATURATO';
    else
        reg = 'OK';
    end
    fprintf('  %-12.2e %-14.4e %-8.2f %-12s\n', ...
        P_test(i), fwd.DeltaV_ideal(i), snr, reg);
end

% verifica: std(P_rec_MC) deve approssimare il NEP
P_rec_all = nr.DeltaV_noisy / p.S;   % inversione semplice su tutte le MC
P_std_mc  = std(P_rec_all, 0, 2);    % std su colonne (realizzazioni MC)
fprintf('\n  Verifica sigma_P_rec ~= NEP (punto P=1e-3 W):\n');
fprintf('    sigma_P_rec (MC, 1000 real.) = %.4e W\n', P_std_mc(4));
fprintf('    NEP analitico                = %.4e W\n', nr.NEP);
ratio = P_std_mc(4) / nr.NEP;
fprintf('    Rapporto sigma/NEP           = %.3f', ratio);
if abs(ratio - 1) < 0.1
    fprintf('  --> OK (< 10%% di scarto)\n');
else
    fprintf('  --> ATTENZIONE\n');
end

% --------------------------------------------------------------------------
%  FIGURA riassuntiva
% --------------------------------------------------------------------------
fprintf('\n--- Generazione figura riassuntiva ---\n');
figure('Name','Blocchi 1-2: Forward Model + Rumore', ...
       'Position',[100 100 1000 600], 'Color','w');

P_sweep = logspace(-9, 0, 200)';
fwd_sw  = forward_model(P_sweep, p);
rng(0);
nr_sw   = add_noise_to_signal(fwd_sw.DeltaV_ideal, p, 500);

% --- pannello sx: curva di trasferimento ---
ax1 = subplot(1,2,1);
hold on; grid on; box on;

plot(P_sweep, fwd_sw.DeltaV_ideal, 'b-', 'LineWidth', 2, ...
    'DisplayName', '\DeltaV ideale');
plot(P_sweep, fwd_sw.DeltaV,       'k-', 'LineWidth', 1.5, ...
    'DisplayName', '\DeltaV (clip)');
yline( nr_sw.V_noise_total, 'r:', 'LineWidth', 1.5, ...
    'Label', 'V_{noise}', 'HandleVisibility', 'off');
yline(-nr_sw.V_noise_total, 'r:', 'LineWidth', 1.5, 'HandleVisibility', 'off');
yline( p.V_sat, 'm-.', 'LineWidth', 1.5, ...
    'Label', 'V_{sat}', 'HandleVisibility', 'off');

set(ax1, 'XScale', 'log');
xlabel('P_{true} [W]'); ylabel('\DeltaV [V]');
title('Curva di trasferimento');
legend('Location', 'northwest', 'FontSize', 9);

% --- pannello dx: SNR vs P ---
ax2 = subplot(1,2,2);
hold on; grid on; box on;

SNR_sw = nr_sw.SNR;
sat_m  = fwd_sw.is_saturated;
ok_m   = ~sat_m & SNR_sw >= 1;
ns_m   = ~sat_m & SNR_sw < 1;

loglog(P_sweep(ns_m), SNR_sw(ns_m), 'ro', 'MarkerSize', 3, ...
    'MarkerFaceColor', 'r', 'DisplayName', 'Rumore dom.');
loglog(P_sweep(ok_m), SNR_sw(ok_m), 'gs', 'MarkerSize', 3, ...
    'MarkerFaceColor', 'g', 'DisplayName', 'Ricostruibile');
loglog(P_sweep(sat_m), SNR_sw(sat_m), '^', 'Color', [0.9 0.5 0], ...
    'MarkerSize', 4, 'MarkerFaceColor', [0.9 0.5 0], 'DisplayName', 'Saturato');

yline(1, '--k', 'LineWidth', 1.2, 'Label', 'SNR = 1', ...
    'HandleVisibility', 'off');

set(ax2, 'XScale', 'log', 'YScale', 'log');
xlabel('P_{true} [W]'); ylabel('SNR  [lineare]');
title(sprintf('SNR  |  NEP = %.2e W  |  P_{sat} = %.2e W', ...
    nr_sw.NEP, fwd_sw.P_sat));
legend('Location', 'northwest', 'FontSize', 9);

exportgraphics(gcf, 'blocchi_1_2_risultati.png', 'Resolution', 150);

fprintf('\n========================================\n');
fprintf('  TEST COMPLETATO\n');
fprintf('  NEP   = %.4e W\n', nr_sw.NEP);
fprintf('  P_sat = %.4e W\n', fwd_sw.P_sat);
fprintf('  S     = %.4f    V/W\n', p.S);
fprintf('  Figura salvata: blocchi_1_2_risultati.png\n');
fprintf('========================================\n');
