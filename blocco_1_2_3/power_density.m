function result = power_density(T, ~)
% Calcola la potenza assorbita dal bolometro dalla radiazione di corpo nero.
%
% Metodo:
%   1. Genera un vettore di frequenze f in [f_min, f_max]
%   2. Calcola la radianza spettrale di Planck B(f, T)  [W/m^2/sr/Hz]
%   3. Moltiplica per l'assorbanza del platino A(f)
%   4. Integra numericamente su df -> P_abs  [W/m^2/sr]
%
% Formula di Planck:
%   B(f, T) = (2*h*f^3 / c^2) / (exp(h*f / (kB*T)) - 1)
%
% Ingressi:
%   T      : temperatura del corpo nero [K]
%   params : struct da bolometer_params() (non usato nel calcolo,
%            passato per coerenza con gli altri blocchi)
%
% Uscita:
%   result.P_abs     potenza assorbita [W/m^2/sr]
%   result.f         vettore di frequenze usato [Hz]
%   result.B         radianza spettrale di Planck [W/m^2/sr/Hz]
%   result.A         assorbanza del platino []
%   result.integrand B .* A  [W/m^2/sr/Hz]

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
