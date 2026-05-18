function sweep = run_power_sweep(params, options)
% Full bolometer pipeline over a logarithmic power range.
%
% Usage:
%   sweep = run_power_sweep()
%   sweep = run_power_sweep(p)
%   sweep = run_power_sweep(p, 'P_min', 1e-10, 'P_max', 1e0, 'N_points', 120, ...
%                              'N_MC', 2000, 'plot', true, 'save_fig', false)
%
% Pipeline per ogni punto di potenza:
%   P_true  ->  forward_model  ->  DeltaV_ideal
%           ->  add_noise_to_signal (N_MC realiz.)  ->  DeltaV_noisy
%           ->  reconstruct_power  ->  P_rec (mean, std, CI95)
%
% Output struct sweep con tutti i risultati + handle figura.

    if nargin < 1 || isempty(params)
        params = bolometer_params();
    end

    % --- parse options ---
    opt.P_min    = 1e-9;
    opt.P_max    = 1e0;
    opt.N_points = 100;
    opt.N_MC     = params.N_MC;
    opt.do_plot  = true;
    opt.save_fig = false;
    opt.fig_path = 'bolometer_sweep.png';

    if nargin >= 2
        fields = fieldnames(options);
        for k = 1:numel(fields)
            opt.(fields{k}) = options.(fields{k});
        end
    end

    % --- power grid (logarithmic) ---
    P_true = logspace(log10(opt.P_min), log10(opt.P_max), opt.N_points)';

    % --- forward model ---
    fwd = forward_model(P_true, params);

    % --- noise ---
    rng(0, 'twister');   % reproducible
    nr = add_noise_to_signal(fwd.DeltaV_ideal, params, opt.N_MC);

    % --- reconstruction ---
    rec = reconstruct_power(nr.DeltaV_noisy, params, P_true);

    % --- regime masks ---
    mask_noise = strcmp(rec.regime, 'noise');
    mask_ok    = strcmp(rec.regime, 'ok');
    mask_sat   = strcmp(rec.regime, 'saturated');

    % --- pack sweep ---
    sweep.P_true      = P_true;
    sweep.fwd         = fwd;
    sweep.noise       = nr;
    sweep.rec         = rec;
    sweep.mask_noise  = mask_noise;
    sweep.mask_ok     = mask_ok;
    sweep.mask_sat    = mask_sat;
    sweep.params      = params;
    sweep.opt         = opt;

    if opt.do_plot
        sweep.fig = plot_sweep(sweep);
        if opt.save_fig
            exportgraphics(sweep.fig, opt.fig_path, 'Resolution', 150);
            fprintf('Figure saved to %s\n', opt.fig_path);
        end
    end
end

% -------------------------------------------------------------------------
function fig = plot_sweep(sw)
% Three-panel figure showing the full sweep result.

    P      = sw.P_true;
    P_mean = sw.rec.P_mean;
    P_std  = sw.rec.P_std;
    P_ci95 = sw.rec.P_ci95;
    NEP    = sw.rec.NEP;
    P_sat  = sw.fwd.P_sat;
    S      = sw.params.S;

    mn = sw.mask_noise;
    ok = sw.mask_ok;
    st = sw.mask_sat;

    % colours
    C_noise = [0.85 0.20 0.10];
    C_ok    = [0.10 0.65 0.20];
    C_sat   = [0.90 0.55 0.00];
    C_true  = [0.20 0.20 0.80];

    fig = figure('Name', 'Bolometer Power Sweep', ...
                 'Position', [80 80 1100 820], 'Color', 'w');

    % ---- Panel 1: P_rec vs P_true (log-log) --------------------------------
    ax1 = subplot(3,1,1);
    hold on; grid on; box on;

    % CI95 band for ok region
    if any(ok)
        P_ok   = P(ok);
        lo     = max(P_mean(ok) - P_ci95(ok), 1e-15);
        hi     = P_mean(ok) + P_ci95(ok);
        fill([P_ok; flipud(P_ok)], [lo; flipud(hi)], C_ok, ...
            'FaceAlpha', 0.20, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end

    % reference diagonal (ideal reconstruction)
    plot(P, P, '--', 'Color', C_true, 'LineWidth', 1.2, 'DisplayName', 'P_{true}');

    % NEP and P_sat reference lines (excluded from legend, labelled directly)
    yline(NEP,   ':', 'Color', C_noise, 'LineWidth', 1.5, ...
        'Label', sprintf('NEP = %.2e W', NEP), 'LabelHorizontalAlignment', 'left', ...
        'HandleVisibility', 'off');
    xline(P_sat, ':', 'Color', C_sat,   'LineWidth', 1.5, ...
        'Label', sprintf('P_{sat} = %.2e W', P_sat), 'LabelVerticalAlignment', 'bottom', ...
        'HandleVisibility', 'off');

    % reconstructed power by regime
    if any(mn)
        % noise-dominated: P_mean can be negative on log axis → floor at NEP/10
        P_mn_plot = max(abs(P_mean(mn)), NEP / 10);
        plot(P(mn), P_mn_plot, 'o', ...
            'Color', C_noise, 'MarkerFaceColor', C_noise, 'MarkerSize', 4, ...
            'LineWidth', 0.8, 'DisplayName', 'Noise-dom. (|P_{rec}|)');
    end
    if any(ok)
        errorbar(P(ok), P_mean(ok), P_ci95(ok), 's', ...
            'Color', C_ok, 'MarkerFaceColor', C_ok, 'MarkerSize', 4, ...
            'LineWidth', 0.8, 'CapSize', 3, 'DisplayName', 'Reconstructed');
    end
    if any(st)
        plot(P(st), abs(P_mean(st)), '^', ...
            'Color', C_sat, 'MarkerFaceColor', C_sat, 'MarkerSize', 5, ...
            'DisplayName', 'Saturated');
    end

    set(ax1, 'XScale', 'log', 'YScale', 'log');
    xlabel('P_{true} [W]');
    ylabel('P_{rec} [W]');
    title(sprintf('Bolometer sweep  |  S = %.2f V/W  |  NEP = %.2e W  |  N_{MC} = %d', ...
        S, NEP, sw.opt.N_MC));
    legend('Location', 'northwest', 'FontSize', 8);

    % ---- Panel 2: SNR (log-log) vs P_true ----------------------------------
    ax2 = subplot(3,1,2);
    hold on; grid on; box on;

    SNR = sw.noise.SNR;
    SNR_plot = max(SNR, 1e-3);   % floor to keep log scale tidy
    if any(mn), loglog(P(mn), SNR_plot(mn), 'o', 'Color', C_noise, 'MarkerFaceColor', C_noise, 'MarkerSize', 4, 'DisplayName', 'Noise-dom.'); end
    if any(ok),    loglog(P(ok), SNR_plot(ok), 's', 'Color', C_ok,    'MarkerFaceColor', C_ok,    'MarkerSize', 4, 'DisplayName', 'OK');         end
    if any(st),    loglog(P(st), SNR_plot(st), '^', 'Color', C_sat,   'MarkerFaceColor', C_sat,   'MarkerSize', 5, 'DisplayName', 'Saturated');   end

    yline(1, '--k', 'LineWidth', 1.2, 'Label', 'SNR = 1', 'HandleVisibility', 'off');
    xlabel('P_{true} [W]');
    ylabel('SNR');
    title('Signal-to-Noise Ratio vs Input Power');
    legend('Location', 'northwest', 'FontSize', 8);

    % ---- Panel 3: DeltaV transfer curve (ideal vs clipped) -----------------
    ax3 = subplot(3,1,3);
    hold on; grid on; box on;

    plot(P, sw.fwd.DeltaV_ideal, '--', 'Color', C_true, 'LineWidth', 1.5, ...
        'DisplayName', '\DeltaV ideal');
    plot(P, sw.fwd.DeltaV,       '-',  'Color', [0 0 0], 'LineWidth', 1.5, ...
        'DisplayName', '\DeltaV (clipped)');

    % noise floor band and saturation level (labelled directly, not in legend)
    yline( sw.noise.V_noise_total, ':', 'Color', C_noise, 'LineWidth', 1.2, ...
        'Label', 'V_{noise}', 'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
    yline(-sw.noise.V_noise_total, ':', 'Color', C_noise, 'LineWidth', 1.2, 'HandleVisibility', 'off');
    yline( sw.params.V_sat, '-.',  'Color', C_sat, 'LineWidth', 1.2, ...
        'Label', 'V_{sat}', 'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');

    set(ax3, 'XScale', 'log');
    xlabel('P_{true} [W]');
    ylabel('\DeltaV [V]');
    title('Bolometer Transfer Curve');
    legend('Location', 'northwest', 'FontSize', 8);

    linkaxes([ax1 ax2 ax3], 'x');
    % linkaxes resets XScale to linear — restore log scale explicitly
    xlim(ax1, [sw.opt.P_min, sw.opt.P_max]);
    set(ax1, 'XScale', 'log');
    set(ax2, 'XScale', 'log', 'YScale', 'log');
    set(ax3, 'XScale', 'log');
end
