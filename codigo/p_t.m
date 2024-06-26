function retval = p_t (t, T, b1_4)
  deltat = b1_4(2) - b1_4(1);
  sigma = sqrt(0.05 * deltat);
  epsilon = 1e-10;  % Pequeño valor para evitar probabilidades cero

 G = @(x) ((1 / (sigma * sqrt(2 * pi))) * exp(-x.^2 / (2 * sigma^2)))/(1/(sqrt(2*pi)*sigma)) + epsilon; %G arreglada

  p = [0.4, 0.15, 0.3, 0.15];
  sum = 0;

  for i = 1:numel(b1_4)
    sum += p(mod(i - 1, numel(p)) + 1) * G(mod(t, T) - b1_4(i));
##    sum += G(mod(t,T)-b1_4(i)); %opcion con igual amplitud en todos los subbeats
  end
  retval = 0.25 * sum;


endfunction

