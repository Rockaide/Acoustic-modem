clear all; clc;

OCTAVE = 0;

if OCTAVE == 1
pkg load communications;
end

RB = 100; % taxa de bits (bps)
Fp = 2000; 
Fa = 8000;

on = 1; % controle se opera ou nao em tempo real

filename = 'sinal/sinal_rx_manual.wav';

if on == 1
    % captura do sinal de audio
    NS = 0;             % nivel de sinal
    NS_min = 0.08;       % nivel de sensibilidade - ajustar conforme necessario
    t_captura = 4;      % tempo de captura do sinal
    
    % Cria o objeto gravador de áudio
    % (Frequência de amostragem = Fa, 16 bits, 1 canal/mono)
    recObj = audiorecorder(Fa, 16, 1); 
    
    while NS < NS_min
        disp('Gravando áudio...');
        
        % Inicia a gravação e bloqueia o MATLAB até terminar o tempo (t_captura)
        recordblocking(recObj, t_captura);
        
        % Obtém a matriz de dados do áudio gravado
        y = getaudiodata(recObj);
        disp(NS)
        plot(y);
        if ~isempty(y)
            NS = max(y);
        end
    end
    
    disp(['Valor de deteccao do sinal: ' num2str(NS)]);
    
    
    % salva arquivo com sinal para usar no receptor
    audiowrite(filename, y, Fa);
else
    [y, fs] = audioread(filename);
    plot(y);
end

% retorna a mensagem em bits e o tamanho dela
[m,l] = receptor_2(y, RB, Fp, Fa);


% conversao de bits para texto
x = bi2de(reshape(m,8,l)')';
msg = char(x);
disp(["Tamanho da mensagem recebida: " num2str(l) " bytes"]);
disp(["Mensagem recebida: " msg]);


