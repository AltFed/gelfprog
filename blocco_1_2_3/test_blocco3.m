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
% range fisico: divertore freddo -> SOL caldo
T_eV  = [10, 30, 55, 70, 85, 100, 115, 150, 200, 300];
T_vec = T_eV * 11604;

P_abs_vec  = zeros(size(T_vec));
P_emit_vec = zeros(size(T_vec));

for i = 1:length(T_vec)
    pd_i = power_density(T_vec(i), p);
    P_abs_vec(i)  = pd_i.P_abs;
    P_emit_vec(i) = trapz(pd_i.f, pd_i.B);
end

P_eff_vec = p.tau_plasma * P_abs_vec;
ratio_vec = P_eff_vec ./ P_emit_vec;

% indice del punto nominale nel vettore
idx_nom = find(T_eV == T_nom_eV);

fprintf('%-8s %-18s %-18s %-18s %-10s\n', ...
    'T [eV]', 'P_emit [W/m2/sr]', 'P_abs [W/m2/sr]', 'P_eff [W/m2/sr]', 'eta_eff [%]');
fprintf('%s\n', repmat('-', 1, 78));
for i = 1:length(T_eV)
    marker = '';
    if T_eV(i) == T_nom_eV, marker = ' <- nominale'; end
    fprintf('%-8d %-18.4e %-18.4e %-18.4e %-10.2f%s\n', ...
        T_eV(i), P_emit_vec(i), P_abs_vec(i), P_eff_vec(i), ratio_vec(i)*100, marker);
end

% --- figura 2: frazione assorbita vs temperatura ---
figure('Name','Blocco 3 - Assorbimento vs T', ...
       'Position',[100 100 700 480], 'Color','w');

hold on; grid on; box on;
plot(T_eV, ratio_vec * 100, 'b-o', 'LineWidth', 2, 'MarkerSize', 7, ...
     'MarkerFaceColor','b', 'DisplayName', sprintf('\\eta_{eff}  (\\tau=%.1f)', p.tau_plasma));
if ~isempty(idx_nom)
    plot(T_eV(idx_nom), ratio_vec(idx_nom)*100, 'ro', 'LineWidth', 2, ...
         'MarkerSize', 11, 'MarkerFaceColor','r', 'DisplayName', ...
         sprintf('T_{nom} = %d eV', T_nom_eV));
end

% annotazioni zone fisiche
xregion(1,  40,  'FaceColor',[0.9 0.95 1], 'FaceAlpha',0.4, 'HandleVisibility','off');
xregion(40, 200, 'FaceColor',[1 0.95 0.85],'FaceAlpha',0.4, 'HandleVisibility','off');
xregion(200,350, 'FaceColor',[1 0.85 0.85],'FaceAlpha',0.4, 'HandleVisibility','off');
text(15,  ratio_vec(1)*100+1,   'Divertore', 'FontSize',9, 'Color',[0.3 0.3 0.7]);
text(80,  ratio_vec(4)*100+1,   'SOL',       'FontSize',9, 'Color',[0.7 0.5 0.1]);
text(210, ratio_vec(end-1)*100+1,'Pedestal', 'FontSize',9, 'Color',[0.7 0.1 0.1]);

xlabel('T_{sorgente} [eV]', 'FontSize', 12);
ylabel('\eta_{eff} = \tau \cdot P_{abs} / P_{emit}  [%]', 'FontSize', 12);
title(sprintf('Efficienza effettiva vs temperatura  (\\tau = %.1f)', p.tau_plasma), ...
      'Color','k', 'FontSize', 12);

ax = gca;
set(ax, 'Color','w', 'XColor','k', 'YColor','k', 'GridColor',[0.8 0.8 0.8], ...
    'FontSize', 11);

xticks(T_eV);
xticklabels(arrayfun(@(x) sprintf('%d', x), T_eV, 'UniformOutput', false));

legend('Location','northwest', 'FontSize', 10, 'TextColor','k', 'Color','w', 'EdgeColor','k');

exportgraphics(gcf, 'blocco3_assorbimento.png', 'Resolution', 150);

fprintf('\nFigure salvate: blocco3_risultati.png, blocco3_assorbimento.png\n');
fprintf('========================================\n');
