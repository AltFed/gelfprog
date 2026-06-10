function result = power_density(T, ~)

    h  = 6.626e-34;   % costante di Planck [J*s]
    c  = 3e8;         % velocita' della luce [m/s]
    kB = 1.381e-23;   % costante di Boltzmann [J/K]

    % range di frequenze: NIR -> raggi X  (3e14 -> 3e18 Hz)
    f = logspace(log10(3e14), log10(3e18), 500)';

    % radianza spettrale di Planck
    B = (2 * h * f.^3 / c^2) ./ (exp(h * f / (kB * T)) - 1);

    % assorbanza del platino
    A = platinum_absorptance(f);

    % integrale numerico (regola dei trapezi in spazio lineare)
    integrand = B .* A;
    P_abs = trapz(f, integrand);

    result.P_abs     = P_abs;
    result.f         = f;
    result.B         = B;
    result.A         = A;
    result.integrand = integrand;
end
