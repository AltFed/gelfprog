% ==========================================================================
%  TEST BLOCCO 3 — Densita' di potenza del corpo nero
%  Eseguire da dentro la cartella blocco_1_2_3/
%
%  Blocco 3: B(f,T) * A(f) integrato su df -> P_abs
%            Rapporto P_abs / P_emit al variare di T
% ==========================================================================

clear; clc;

fprintf('========================================\n');
fprintf('  TEST BLOCCO 3 — Corpo Nero\n');
fprintf('========================================\n\n');

p = bolometer_params();

T_nom_eV = 85;
T_source  = T_nom_eV * 11604;   % 85 eV in Kelvin
pd = power_density(T_source, p);

P_emit_nom = trapz(pd.f, pd.B);
P_eff_nom  = p.tau_plasma * pd.P_abs;   % potenza effettiva dopo attenuazione plasma
ratio_nom  = P_eff_nom / P_emit_nom;

fprintf('Temperatura sorgente : %.2e K  (%.0f eV)\n', T_source, T_nom_eV);
fprintf('Trasmittanza plasma  : %.2f\n',               p.tau_plasma);
fprintf('Potenza emessa       : %.4e W/m^2/sr\n',     P_emit_nom);
fprintf('Potenza assorbita    : %.4e W/m^2/sr\n',     pd.P_abs);
fprintf('Potenza effettiva    : %.4e W/m^2/sr\n',     P_eff_nom);
fprintf('Frazione eff.        : %.2f %%\n\n',         ratio_nom * 100);

% --- figura 1: radianza, assorbanza, integrando ---
figure('Name','Blocco 3 - Densita di potenza', ...
       'Position',[100 100 1200 420], 'Color','w');

f_lim = [3e14, 3e18];

ax1 = subplot(1,3,1);
loglog(pd.f, pd.B, 'b-', 'LineWidth', 2);
xlim(f_lim);
xlabel('Frequenza [Hz]'); ylabel('B(f,T)  [W/m^2/sr/Hz]');
title(sprintf('Planck  T = %.0f eV', T_nom_eV), 'Color','k');
grid on; box on;
set(ax1, 'Color','w', 'XColor','k', 'YColor','k', 'GridColor',[0.8 0.8 0.8]);

ax2 = subplot(1,3,2);
semilogx(pd.f, pd.A, 'r-', 'LineWidth', 2);
xlim(f_lim); ylim([0 1]);
xlabel('Frequenza [Hz]'); ylabel('A(f)  [-]');
title('Assorbanza Platino', 'Color','k');
grid on; box on;
set(ax2, 'Color','w', 'XColor','k', 'YColor','k', 'GridColor',[0.8 0.8 0.8]);

ax3 = subplot(1,3,3);
loglog(pd.f, pd.integrand, 'Color',[0 0.6 0.8], 'LineWidth', 2);
xlim(f_lim);
xlabel('Frequenza [Hz]'); ylabel('B \cdot A  [W/m^2/sr/Hz]');
title(sprintf('Integrando  P_{abs} = %.2e W/m^2/sr', pd.P_abs), 'Color','k');
grid on; box on;
set(ax3, 'Color','w', 'XColor','k', 'YColor','k', 'GridColor',[0.8 0.8 0.8]);

exportgraphics(gcf, 'blocco3_risultati.png', 'Resolution', 150);

% --- loop su variazioni di temperatura ---
dT_eV = [-30, -20, -10, 0, +10, +20, +30];
T_vec = (T_nom_eV + dT_eV) * 11604;

P_abs_vec  = zeros(size(T_vec));
P_emit_vec = zeros(size(T_vec));

for i = 1:length(T_vec)
    pd_i = power_density(T_vec(i), p);
    P_abs_vec(i)  = pd_i.P_abs;
    P_emit_vec(i) = trapz(pd_i.f, pd_i.B);
end

P_eff_vec = p.tau_plasma * P_abs_vec;
ratio_vec = P_eff_vec ./ P_emit_vec;

fprintf('%-10s %-8s %-18s %-18s %-18s %-10s\n', ...
    'dT [eV]', 'T [eV]', 'P_emit [W/m2/sr]', 'P_abs [W/m2/sr]', 'P_eff [W/m2/sr]', 'eta_eff [%]');
fprintf('%s\n', repmat('-', 1, 88));
for i = 1:length(dT_eV)
    fprintf('%-10d %-8d %-18.4e %-18.4e %-18.4e %-10.2f\n', ...
        dT_eV(i), T_nom_eV + dT_eV(i), P_emit_vec(i), P_abs_vec(i), P_eff_vec(i), ratio_vec(i)*100);
end

% --- figura 2: frazione assorbita vs temperatura ---
figure('Name','Blocco 3 - Assorbimento vs T', ...
       'Position',[100 100 700 480], 'Color','w');

hold on; grid on; box on;
plot(dT_eV, ratio_vec * 100, 'b-o', 'LineWidth', 2, 'MarkerSize', 7, ...
     'MarkerFaceColor','b');
plot(0, ratio_nom * 100, 'ro', 'LineWidth', 2, 'MarkerSize', 10, ...
     'MarkerFaceColor','r', 'HandleVisibility','off');
xline(0, 'k--', 'LineWidth', 1, 'HandleVisibility','off');

xlabel('\DeltaT [eV]', 'FontSize', 12);
ylabel('\eta_{eff} = \tau \cdot P_{abs} / P_{emit}  [%]', 'FontSize', 12);
title(sprintf('Efficienza effettiva  (\\tau = %.1f,  T_{nom} = %d eV)', ...
      p.tau_plasma, T_nom_eV), 'Color','k', 'FontSize', 12);

ax = gca;
set(ax, 'Color','w', 'XColor','k', 'YColor','k', 'GridColor',[0.8 0.8 0.8], ...
    'FontSize', 11);

xticks(dT_eV);
xticklabels(arrayfun(@(x) sprintf('%+d', x), dT_eV, 'UniformOutput', false));

legend(sprintf('\\eta_{eff}  (\\tau=%.1f)', p.tau_plasma), ...
    'Location','northwest', 'FontSize', 10, 'TextColor','k', 'Color','w', 'EdgeColor','k');

exportgraphics(gcf, 'blocco3_assorbimento.png', 'Resolution', 150);

fprintf('\nFigure salvate: blocco3_risultati.png, blocco3_assorbimento.png\n');
fprintf('========================================\n');
