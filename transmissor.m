function [y,msg,quadro] = transmissor(msg, RB, Fp, Fa)

%%%%%%%%%%%%%%%%%%%%%%  Entrada do transmissor   %%%%%%%%%%%%%%%%
%   msg -- Dados a serem transmitidos
%   RB  -- Taxa de bits
%   Fp  -- Frequencia da portadora
%   Fa  -- Frequencia de amostragem da placa de som
%%%%%%%%%%%%%%%%%%%%%%  Saida do transmissor   %%%%%%%%%%%%%%%%%%
%   y      -- Sinal modulado (amostras de audio)
%   msg    -- Quadro completo em bits (PRE | SFD | tamanho | dados | CRC | PRE)
%   quadro -- Bits protegidos pelo CRC (tamanho | dados | CRC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

OCTAVE = exist('OCTAVE_VERSION', 'builtin') ~= 0; % 1 no Octave, 0 no MATLAB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Exemplo de uso
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% msg = "ABC";
% TB = 100;
% Fp = 2000;
% Fa = 8000;
% sinal_gerado = transmissor(msg, TB, Fp, Fa)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Transmissao do sinal usando a placa de som        %
% soundsc(sinal_gerado,Fa);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Pacotes de software
if OCTAVE == 1
pkg load communications;
pkg load signal;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Inicio
% converte o texto para um vetor de bits
if OCTAVE == 1
l = length(msg);        % tamanho da mensagem em bits
msg = double(msg);      % converte texto em decimal
% monta mensagem em quadro de bits
% primeiros 8 bits sao o tamanho do quadro
msg = reshape(de2bi([l msg],8)',1,8*(l+1));
else
% Garante a conversão para vetor de caracteres (evita o problema das aspas duplas)
msg_char = char(msg);

l = length(msg_char);          % Agora l será 3 (correto)
msg_ascii = double(msg_char);  % Agora retornará [79 76 65] (correto)

% Monta o quadro de bits sem erros
bits_matriz = de2bi([l msg_ascii], 8)';
msg = reshape(bits_matriz, 1, 8*(l+1));
%msg = [1 0 1 0 0 1 0 1];
%l = 8;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  CRC-16 (deteccao de erros)                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
msg = crc_gen(msg);   % anexa 16 bits de CRC ao [tamanho | dados]
quadro = msg;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Preambulo do quadro                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PRE = [ones(1,10) upsample(ones(1,15),2)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Marcador de inicio do quadro  (SFD)           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SFD = [1 1 0 0 1 1 1 0 0 0 1 1 1 1 0 0 0 0 1 1 1 0 0 0 1 1 0 0 1 0 1 0];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Enquadramento                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
msg = [PRE SFD msg PRE];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Codificacao polar em banda base             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [-1,1];
y = s(msg+1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Numero de simbolos                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(['Tamanho do quadro: ' num2str(length(y)) ' simbolos'])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Filtragem para formatacao de pulso          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r = 0.5;                              % Fator de decaimento (roll-off)
if OCTAVE == 1
RB_f = Fa/floor(Fa/RB);               % Ajuste da taxa de bits
num = rcosine(RB_f,Fa,'default',r);   % Projeto do filtro RC (raised-cosine filter)
y = rcosflt(y,RB_f,Fa,'filter',num)'; % Filtragem RC
else % MATLAB
sps = floor(Fa/RB);
h = rcosdesign(r, 6, sps);      % Raised cosine FIR filter design
%fvtool(h, 'Analysis', 'impulse')   % Visualize the filter
y = upfirdn(y, h, sps);
%plot(x)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Modulacao em Banda Passante                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = (0:length(y) - 1)/Fa;
y = y.*cos(2*pi*Fp*t);              % Modulacao BPSK

end





