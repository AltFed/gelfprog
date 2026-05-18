% =========================================================================
%  BOLOMETER SIMULATOR — main.m
%  Pipeline: P [W]  →  ΔT  →  ΔV  →  +noise  →  P_reconstructed
%
%  Run this file from the bolometer/ directory.
%  Toggle the RUN_* flags below to enable/disable each section.
% =========================================================================

clear; close all; clc;

% -------------------------------------------------------------------------
%  USER SETTINGS — edit here
% -------------------------------------------------------------------------

% --- Bolometer parameters (leave empty {} to use defaults) ---
% Example overrides:  'R0', 200, 'G', 5e-5, 'I_bias', 2e-3
CUSTOM_PARAMS = {};   % e.g. {'R0', 200, 'G', 5e-5}

% --- Power sweep settings ---
SWEEP.P_min    = 1e-9;   % minimum power [W]
SWEEP.P_max    = 1e0;    % maximum power [W]
SWEEP.N_points = 120;    % number of log-spaced points
SWEEP.N_MC     = 1000;   % Monte Carlo realizations per point
SWEEP.do_plot  = true;
SWEEP.save_fig = true;
SWEEP.fig_path = 'bolometer_sweep.png';

% --- Sensitivity analysis settings ---
SENS.do_plot   = true;
SENS.save_fig  = true;
SENS.fig_path  = 'bolometer_sensitivity.png';
SENS.N_sweep   = 60;

% --- Which sections to run ---
RUN_SWEEP = true;
RUN_SENS  = true;

% -------------------------------------------------------------------------
%  INIT
% -------------------------------------------------------------------------

fprintf('\n');
fprintf('========================================================\n');
fprintf('  BOLOMETER SIMULATOR\n');
fprintf('  Physics: P -> DeltaT=P/G -> DeltaR=R0*a*DeltaT\n');
fprintf('        -> DeltaV=I_bias*DeltaR  ->  S=DeltaV/P\n');
fprintf('========================================================\n\n');

% build parameter struct
if isempty(CUSTOM_PARAMS)
    p = bolometer_params();
else
    p = bolometer_params(CUSTOM_PARAMS{:});
end

print_params(p);

% -------------------------------------------------------------------------
%  SECTION 1 — POWER SWEEP
% -------------------------------------------------------------------------

if RUN_SWEEP
    fprintf('\n--- Running power sweep (%d points, N_MC=%d) ---\n', ...
        SWEEP.N_points, SWEEP.N_MC);

    sweep = run_power_sweep(p, SWEEP);

    fprintf('\n  Results:\n');
    fprintf('    NEP           = %.4e W\n',  sweep.rec.NEP);
    fprintf('    P_sat         = %.4e W\n',  sweep.fwd.P_sat);
    fprintf('    Noise points  = %d / %d\n', sum(sweep.mask_noise), SWEEP.N_points);
    fprintf('    OK points     = %d / %d\n', sum(sweep.mask_ok),    SWEEP.N_points);
    fprintf('    Sat. points   = %d / %d\n', sum(sweep.mask_sat),   SWEEP.N_points);
    fprintf('    RMSE (ok)     = %.4e W\n',  sweep.rec.RMSE);
    fprintf('    Figure saved  : %s\n',       SWEEP.fig_path);
end

% -------------------------------------------------------------------------
%  SECTION 2 — SENSITIVITY ANALYSIS
% -------------------------------------------------------------------------

if RUN_SENS
    fprintf('\n--- Running sensitivity analysis ---\n');

    sens = sensitivity_analysis(p, SENS);

    kB   = 1.380649e-23;
    V_J  = sqrt(4*kB*p.T0*p.R0*p.BW);
    V_A  = p.e_n * sqrt(p.BW);
    LSB  = p.V_ADC_range / 2^p.N_bits;
    V_Q  = LSB / sqrt(12);
    V_n  = sqrt(V_J^2 + V_A^2 + V_Q^2);

    fprintf('\n  Noise budget:\n');
    fprintf('    Johnson        V_J = %.4e V  (%4.1f%%)\n', V_J, 100*V_J^2/V_n^2);
    fprintf('    Amplifier      V_A = %.4e V  (%4.1f%%)\n', V_A, 100*V_A^2/V_n^2);
    fprintf('    ADC quant.     V_Q = %.4e V  (%4.1f%%)\n', V_Q, 100*V_Q^2/V_n^2);
    fprintf('    Total          V_n = %.4e V\n', V_n);
    fprintf('\n  Key metrics:\n');
    fprintf('    S   = %.4f V/W\n',   sens.base_S);
    fprintf('    NEP = %.4e W\n',     sens.base_NEP);
    fprintf('    DR  = %.1f dB\n',    sens.base_DR);
    fprintf('\n  NOTE: DR = V_sat/V_noise is independent of S.\n');
    fprintf('  To improve DR: use higher-bit ADC or lower e_n amplifier.\n');
    fprintf('    Figures saved : %s / %s\n', SENS.fig_path, ...
        strrep(SENS.fig_path, '.png', '_DR.png'));
end

% -------------------------------------------------------------------------
%  FINAL SUMMARY
% -------------------------------------------------------------------------

fprintf('\n========================================================\n');
fprintf('  SUMMARY\n');
fprintf('  S      = %8.4f  V/W    (sensitivity)\n',      p.S);

if RUN_SWEEP
    fprintf('  NEP    = %8.4e  W      (noise equivalent power)\n', sweep.rec.NEP);
    fprintf('  P_sat  = %8.4e  W      (saturation power)\n',       sweep.fwd.P_sat);
end
if RUN_SENS
    fprintf('  DR     = %8.1f  dB     (dynamic range)\n',          sens.base_DR);
end
fprintf('========================================================\n\n');

% =========================================================================

function print_params(p)
    fprintf('Bolometer parameters:\n');
    fprintf('  R0      = %8.1f   Ohm   (resistance)\n',     p.R0);
    fprintf('  alpha   = %8.4e  1/K   (TCR)\n',             p.alpha);
    fprintf('  G       = %8.4e  W/K   (thermal conductance)\n', p.G);
    fprintf('  C       = %8.4e  J/K   (thermal capacitance)\n', p.C);
    fprintf('  tau     = %8.4e  s     (time constant = C/G)\n', p.tau);
    fprintf('  I_bias  = %8.4e  A     (bias current)\n',     p.I_bias);
    fprintf('  T0      = %8.1f   K     (base temperature)\n', p.T0);
    fprintf('  V_sat   = %8.3f   V     (amplifier saturation)\n', p.V_sat);
    fprintf('  BW      = %8.1f   Hz    (bandwidth)\n',       p.BW);
    fprintf('  e_n     = %8.4e  V/rtHz (amplifier noise)\n', p.e_n);
    fprintf('  ADC     = %d bit, range=%.1f V\n', p.N_bits, p.V_ADC_range);
    fprintf('  -->\n');
    fprintf('  S       = %8.4f   V/W   (sensitivity = I_bias*R0*alpha/G)\n', p.S);
    fprintf('  P_sat   = %8.4e  W     (= V_sat/S)\n', p.V_sat/p.S);
end
