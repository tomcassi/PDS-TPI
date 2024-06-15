%necesita el paquete io: pkg install -forge io
####pkg install -forge io
##pkg load io;
pkg load signal
clc; clear all; close all;

resultados = cell(1,25);

%cargar canciones
canciones = cargar_canciones();
##canciones = {"Metronomo70BPM.mp3"}


%ELEGIR SOLO CANCIONES DE 1:20 MINUTOS O MAS
t_ini = 50;

##  columna_nombre='B';
##  columna_BPMDetectado='E';
##  columna_TiempoEmpleado='G';
fragmento_contador=0;

for cancion=1:5
    disp("CANCION");
    resultados(1) = canciones{cancion};
    archivo_audio = strcat("../samples/",canciones{cancion})
      for fragmento=5:5:30  %cambiando para ver si carga en seg 5
        fragmento_contador = fragmento_contador + 1;
        disp(sprintf("FRAGMENTO CONTADOR %d", fragmento_contador));

        t_fin = t_ini+fragmento;

        % Cargar la cantidad de minutos especificados
        info = audioinfo(archivo_audio);
        duracion_segundos = t_fin - t_ini;
        muestra_ini = fix(t_ini * info.SampleRate);
        muestra_fin = fix(t_fin * info.SampleRate);
        [y, Fs] = audioread(archivo_audio, [muestra_ini muestra_fin]);
        t = t_ini:1/Fs:t_fin;

        %Convierto audio stereo a mono
        if size(y ,2) == 2
          y = (y(:,1) + y(:,2)) / 2;
        endif

        tam_ventana = 0.01;% en segundos (10 ms)
        tam_ventana_m = fix(tam_ventana * Fs); %tamaño de la ventana en muestras

        ## Funcion de compresion
        C = @(x) sqrt(x);

        num_ventanas = fix(length(y) / tam_ventana_m);

        fragmentos = zeros(num_ventanas, tam_ventana_m);

        for i = 1:num_ventanas
          fragmentos(i,:) = y((i-1)*tam_ventana_m + 1 : i*tam_ventana_m);
        endfor

        fft_resultados = zeros(num_ventanas, tam_ventana_m);

        for i = 1:num_ventanas
          fft_resultados(i, :) = C(abs(fft(fragmentos(i,:)))); #las filas son 10ms, hace la fft cada 10ms
        endfor

        %----- Calculo del flujo de la energia ------
        % Encontrar los índices correspondientes a 100 Hz y 10000 Hz
        frecuencia_100Hz = 100;
        frecuencia_10000Hz = 10000;

        indice_100Hz = round(frecuencia_100Hz * tam_ventana_m / Fs);
        indice_10000Hz = round(frecuencia_10000Hz * tam_ventana_m / Fs);

        E_hat = zeros(num_ventanas - 1, 1); % Se resta 1 porque se calcula la diferencia entre frames sucesivos

        j=(indice_100Hz + 1):indice_10000Hz;

        for i = 2:num_ventanas
          E_hat(i-1) = sum(fft_resultados(i,j) - fft_resultados(i-1, j));
        endfor

        % Rectificacion media onda
        E = max(E_hat, 0);

        f_m = info.SampleRate; %frecuencia de muestreo

        % =========================== Identificacion de Picos Significativos ===============================
        [peaks, peak_locs] = findpeaks(E);

        % Establecer un umbral como un porcentaje del máximo pico encontrado
        umbral = 0.5; % Por ejemplo, seleccionamos picos que estén por encima del 50% del máximo pico

        % Calculamos el máximo pico
        max_peak = max(peaks);

        % Filtramos los picos significativos que superan el umbral
        picos_significativos = peak_locs(peaks >= umbral * max_peak);
        valores_significativos = peaks(peaks >= umbral * max_peak);

        tiempo_picos = (t_ini + 0.01) + picos_significativos * 0.01; % Convertimos los índices de picos a tiempo


        Tempos = [70:140];
        Swings = [0:0.1:0.4];


        %========================== sin aproximacion inicial ======================

        switch fragmento
          case 5
              col_sin_aprox = 2;
          case 10
              col_sin_aprox = 6;
          case 15
              col_sin_aprox = 10;
          case 20
              col_sin_aprox = 14;
          case 25
              col_sin_aprox = 18;
          case 30
              col_sin_aprox = 22;
        end
        tic();
        [T,S,b1,likelihood] = mejor_T_S_b1 (Tempos, Swings, t_ini, t_fin, tiempo_picos);
        tiempo = toc();
        resultados(col_sin_aprox) = T;
        resultados(col_sin_aprox+1) = tiempo;


        %========================= con aproximacion inicial (ARRANCAR RELOJ) ========================
         switch fragmento
          case 5
              col_con_aprox = 4;
          case 10
              col_con_aprox = 8;
          case 15
              col_con_aprox = 12;
          case 20
              col_con_aprox = 16;
          case 25
              col_con_aprox = 20;
          case 30
              col_con_aprox = 24;
        end
        tic();
        % Calculamos los intervalos de tiempo entre los picos consecutivos
        intervalos_tiempo = diff(picos_significativos) * 0.01; % Convertimos los índices de picos a tiempo y calculamos los intervalos en segundos

        % Calculamos el promedio de los intervalos de tiempo
        promedio_intervalo_tiempo = mean(intervalos_tiempo);

        % Convertimos el intervalo de tiempo promedio a BPM
        bpm_aprox = round(60 / promedio_intervalo_tiempo);

        [T,S,b1,likelihood] = mejor_T_S_b1_con_aprox (Tempos, Swings, t_ini, t_fin, tiempo_picos, bpm_aprox);
        tiempo = toc();
        resultados(col_con_aprox) = T;
        resultados(col_con_aprox+1) = tiempo;
    endfor

   % Guardar los resultados en el archivo Excel en las celdas específicas
  filename = "../estadisticas.xlsx";
  sheet = 'Sheet1';
  row = cancion + 4; % Ajustar esta fila según sea necesario

  % Escribir los datos en las celdas específicas
  xlswrite(filename, resultados(1), sheet, strcat('B', num2str(row))); % Canción

    % Escribir los datos para cada fragmento (5, 10, 15, 20, 25, 30)
    for i = 0:5
        col_sin_aprox = 2 + i * 4;
        col_con_aprox = col_sin_aprox + 2;

        xlswrite(filename, resultados{col_sin_aprox}, sheet, strcat(char('E' + i*6), num2str(row))); % BPM detectado (sin aproximación inicial)
        xlswrite(filename, resultados{col_sin_aprox + 1}, sheet, strcat(char('F' + i*6), num2str(row))); % Tiempo empleado (sin aproximación inicial)
        % Acierto se deja vacío intencionalmente

        xlswrite(filename, resultados{col_con_aprox}, sheet, strcat(char('H' + i*6), num2str(row))); % BPM detectado (con aproximación inicial)
        xlswrite(filename, resultados{col_con_aprox + 1}, sheet, strcat(char('I' + i*6), num2str(row))); % Tiempo empleado (con aproximación inicial)
        % Acierto se deja vacío intencionalmente
    end
endfor


##resultados = cell(1,25);
##resultados{1} = 'nombre';
##resultados{2} = 1;
##resultados{3} = 1;
##resultados{4} = 1;
##resultados{5} = 1;
##resultados{6} = 1;
##resultados{7} = 1;
##resultados{8} = 1;
##resultados{9} = 1;
##resultados{10} = 1;
##resultados{11} = 1;
##resultados{12} = 1;
##resultados{13} = 1;
##resultados{14} = 1;
##resultados{15} = 1;
##resultados{16} = 1;
##resultados{17} = 1;
##resultados{18} = 1;
##resultados{19} = 1;
##resultados{20} = 1;
##resultados{21} = 1;
##resultados{22} = 1;
##resultados{23} = 1;
##resultados{24} = 1;
##resultados{25} = 1;

##  pkg load io
##
##  filename = "../estadisticas.xlsx";
##  data = "prueba";
##
##
##  xlswrite(filename, data, 'Sheet1', 'A1');

