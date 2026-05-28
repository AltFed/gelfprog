% ==========================================================================
%  TEST BLOCCO 3 — Densita' di potenza del corpo nero
%  Eseguire da dentro la cartella blocco_1_2_3/
%
%  Blocco 3: B(f,T) * A(f) integrato su df -> P_abs
% ==========================================================================

clear; clc;

fprintf('========================================\n');
fprintf('  TEST BLOCCO 3 — Corpo Nero\n');
fprintf('========================================\n\n');

p = bolometer_params();

T_source = 85 * 11604;   % 85 eV in Kelvin
pd = power_density(T_source, p);

fprintf('Temperatura sorgente : %.2e K  (%.0f eV)\n', T_source, T_source/11604);
fprintf('Potenza assorbita    : %.4e W/m^2/sr\n\n',   pd.P_abs);

% --- figura ---
figure('Name','Blocco 3 - Densita di potenza', ...
       'Position',[100 100 1200 420], 'Color','w');

f_lim = [3e14, 3e18];

f_lim = [3e14, 3e18];

% pannello 1: radianza di Planck
ax1 = subplot(1,3,1);
loglog(pd.f, pd.B, 'b-', 'LineWidth', 2);
xlim(f_lim);
xlabel('Frequenza [Hz]'); ylabel('B(f,T)  [W/m^2/sr/Hz]');
title(sprintf('Planck  T = %.0f eV', T_source/11604), 'Color','k');
grid on; box on;
set(ax1, 'Color','w', 'XColor','k', 'YColor','k', 'GridColor',[0.8 0.8 0.8]);

% pannello 2: assorbanza platino
ax2 = subplot(1,3,2);
semilogx(pd.f, pd.A, 'r-', 'LineWidth', 2);
xlim(f_lim); ylim([0 1]);
xlabel('Frequenza [Hz]'); ylabel('A(f)  [-]');
title('Assorbanza Platino', 'Color','k');
grid on; box on;
set(ax2, 'Color','w', 'XColor','k', 'YColor','k', 'GridColor',[0.8 0.8 0.8]);

% pannello 3: integrando B*A
ax3 = subplot(1,3,3);
loglog(pd.f, pd.integrand, 'Color',[0 0.6 0.8], 'LineWidth', 2);
xlim(f_lim);
xlabel('Frequenza [Hz]'); ylabel('B \cdot A  [W/m^2/sr/Hz]');
title(sprintf('Integrando  P_{abs} = %.2e W/m^2/sr', pd.P_abs), 'Color','k');
grid on; box on;
set(ax3, 'Color','w', 'XColor','k', 'YColor','k', 'GridColor',[0.8 0.8 0.8]);

exportgraphics(gcf, 'blocco3_risultati.png', 'Resolution', 150);

fprintf('Figura salvata: blocco3_risultati.png\n');
fprintf('========================================\n');
