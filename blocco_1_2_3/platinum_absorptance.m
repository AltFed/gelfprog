function A = platinum_absorptance(f)

    % punti chiave (frequenza [Hz], assorbanza)
    f_data = [3e14,  6e14,  1.5e15, 3e15,  3e16,  3e17,  3e18];
    A_data = [0.20,  0.30,  0.50,   0.65,  0.80,  0.95,  0.99];

    % interpolazione lineare in spazio log-log
    A = interp1(log10(f_data), A_data, log10(f), 'linear', 'extrap');
    A = max(0, min(1, A));   % clamp in [0, 1]
end
