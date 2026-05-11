function results = sensitivity_analysis(base_params, options)
% Sensitivity analysis: sweeps one parameter at a time and shows how
% S (sensitivity), NEP, P_sat, and the dynamic range change.
%
% Usage:
%   results = sensitivity_analysis()
%   results = sensitivity_analysis(p)
%   results = sensitivity_analysis(p, 'save_fig', true, 'fig_path', 'sens.png')
%
% For each parameter {R0, alpha, G, I_bias} a range of values is swept
% while all others are kept at their base value.
% Each sweep produces: S [V/W], NEP [W], P_sat [W], dynamic range [dB].
%
% A 4x4 figure grid is produced:
%   rows  : parameters (R0, alpha, G, I_bias)
%   cols  : S, NEP, P_sat, dynamic range

    if nargin < 1 || isempty(base_params)
        base_params = bolometer_params();
    end

    opt.do_plot  = true;
    opt.save_fig = false;
    opt.fig_path = 'bolometer_sensitivity.png';
    opt.N_sweep  = 50;

    if nargin >= 2
        fields = fieldnames(options);
        for k = 1:numel(fields)
            opt.(fields{k}) = options.(fields{k});
        end
    end

    % --- define parameter sweeps (log range around base value) ---
    sweep_defs = struct( ...
        'name',   {'R0',         'alpha',      'G',          'I_bias'}, ...
        'label',  {'R_0 [\Omega]', '\alpha [1/K]', 'G [W/K]', 'I_{bias} [A]'}, ...
        'base',   {base_params.R0, base_params.alpha, base_params.G, base_params.I_bias}, ...
        'lo_fac', {0.05, 0.05, 0.05, 0.05}, ...   % lower bound = base * lo_fac
        'hi_fac', {20,   20,   20,   20  }  ...   % upper bound = base * hi_fac
    );

    N_params = numel(sweep_defs);
    N        = opt.N_sweep;
    kB       = 1.380649e-23;

    % preallocate output tables
    for i = 1:N_params
        sweep_defs(i).x_vals = logspace( ...
            log10(sweep_defs(i).base * sweep_defs(i).lo_fac), ...
            log10(sweep_defs(i).base * sweep_defs(i).hi_fac), N);
        sweep_defs(i).S_vals  = zeros(1, N);
        sweep_defs(i).NEP_vals= zeros(1, N);
        sweep_defs(i).Psat_vals = zeros(1, N);
        sweep_defs(i).DR_vals = zeros(1, N);   % dynamic range [dB]
    end

    % --- compute metrics for each sweep ---
    for i = 1:N_params
        pname = sweep_defs(i).name;
        for j = 1:N
            p = base_params;
            p.(pname) = sweep_defs(i).x_vals(j);
            % recompute derived fields
            p.tau = p.C / p.G;
            p.S   = p.I_bias * p.R0 * p.alpha / p.G;

            % noise (same as add_noise_to_signal)
            V_J  = sqrt(4 * kB * p.T0 * p.R0 * p.BW);
            V_A  = p.e_n * sqrt(p.BW);
            LSB  = p.V_ADC_range / 2^p.N_bits;
            V_Q  = LSB / sqrt(12);
            V_n  = sqrt(V_J^2 + V_A^2 + V_Q^2);

            NEP  = V_n / p.S;
            Psat = p.V_sat / p.S;
            DR   = 20 * log10(Psat / NEP);   % dynamic range in dB

            sweep_defs(i).S_vals(j)    = p.S;
            sweep_defs(i).NEP_vals(j)  = NEP;
            sweep_defs(i).Psat_vals(j) = Psat;
            sweep_defs(i).DR_vals(j)   = DR;
        end
    end

    results.sweeps     = sweep_defs;
    results.base_params= base_params;

    % --- base values for reference markers ---
    base_S   = base_params.S;
    V_J0  = sqrt(4 * kB * base_params.T0 * base_params.R0 * base_params.BW);
    V_A0  = base_params.e_n * sqrt(base_params.BW);
    LSB0  = base_params.V_ADC_range / 2^base_params.N_bits;
    V_Q0  = LSB0 / sqrt(12);
    V_n0  = sqrt(V_J0^2 + V_A0^2 + V_Q0^2);
    base_NEP  = V_n0 / base_S;
    base_Psat = base_params.V_sat / base_S;
    base_DR   = 20 * log10(base_Psat / base_NEP);

    results.base_S    = base_S;
    results.base_NEP  = base_NEP;
    results.base_Psat = base_Psat;
    results.base_DR   = base_DR;

    if opt.do_plot
        results.fig = plot_sensitivity(results, opt);
        if opt.save_fig
            exportgraphics(results.fig, opt.fig_path, 'Resolution', 150);
            fprintf('Figure saved to %s\n', opt.fig_path);
        end
    end
end

% -------------------------------------------------------------------------
function fig = plot_sensitivity(res, opt)

    sw    = res.sweeps;
    N_par = numel(sw);

    col_titles = {'Sensitivity  S [V/W]', 'NEP [W]', ...
                  'P_{sat} [W]',           'Dynamic Range [dB]'};
    metrics    = {'S_vals', 'NEP_vals', 'Psat_vals', 'DR_vals'};
    base_vals  = [res.base_S, res.base_NEP, res.base_Psat, res.base_DR];
    y_log      = [true, true, true, false];   % log scale for S, NEP, Psat

    colors = lines(N_par);

    fig = figure('Name', 'Bolometer Sensitivity Analysis', ...
                 'Position', [50 50 1300 900], 'Color', 'w');

    for row = 1:N_par
        for col = 1:4
            ax = subplot(N_par, 4, (row-1)*4 + col);
            hold on; grid on; box on;

            x = sw(row).x_vals;
            y = sw(row).(metrics{col});

            % base value vertical marker
            xline(sw(row).base, '--k', 'LineWidth', 1, 'HandleVisibility', 'off');

            % horizontal reference (base metric)
            yline(base_vals(col), ':k', 'LineWidth', 1, 'HandleVisibility', 'off');

            plot(x, y, '-', 'Color', colors(row,:), 'LineWidth', 2);

            % highlight base point
            plot(sw(row).base, base_vals(col), 'ko', ...
                'MarkerFaceColor', colors(row,:), 'MarkerSize', 7, ...
                'HandleVisibility', 'off');

            set(ax, 'XScale', 'log');
            if y_log(col)
                set(ax, 'YScale', 'log');
            end

            if row == 1
                title(col_titles{col}, 'FontWeight', 'bold');
            end
            if col == 1
                ylabel(sw(row).label, 'FontWeight', 'bold');
            end
            if row == N_par
                xlabel(sw(row).label);
            end
        end
    end

    sgtitle(sprintf(['Sensitivity Analysis  |  Base: S=%.2f V/W, ' ...
        'NEP=%.2e W, P_{sat}=%.2e W, DR=%.0f dB'], ...
        res.base_S, res.base_NEP, res.base_Psat, res.base_DR), ...
        'FontSize', 11, 'FontWeight', 'bold');

    % --- extra figure: overlay of DR for all params on one plot ---
    fig2 = figure('Name', 'Dynamic Range comparison', ...
                  'Position', [80 80 620 420], 'Color', 'w');
    hold on; grid on; box on;
    leg_entries = cell(1, N_par);
    for row = 1:N_par
        x_norm = sw(row).x_vals / sw(row).base;   % normalised to base value
        plot(x_norm, sw(row).DR_vals, '-', 'Color', colors(row,:), 'LineWidth', 2);
        leg_entries{row} = sw(row).label;
    end
    xline(1, '--k', 'LineWidth', 1, 'HandleVisibility', 'off');
    yline(base_vals(4), ':k', 'LineWidth', 1, 'HandleVisibility', 'off');
    set(gca, 'XScale', 'log');
    xlabel('Parameter value / base value');
    ylabel('Dynamic Range [dB]');
    title('Dynamic Range vs normalised parameter');
    legend(leg_entries, 'Location', 'best', 'FontSize', 9);

    if opt.save_fig
        exportgraphics(fig2, strrep(opt.fig_path, '.png', '_DR.png'), 'Resolution', 150);
    end
end
