function [x,l] = receptor_2(yrx, TB, Fp, Fa)
%%%%%%%%%%%%%%%%%%%%%%  Entrada do receptor   %%%%%%%%%%%%%%%%
%   yrx -- sinal de audio capturado
%   TB  -- Taxa de bits
%   Fp  -- Frequencia da portadora
%   Fa  -- Frequencia de amostragem da placa de som
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Exemplo de uso
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TB = 100;
% Fp = 2000;
% Fa = 8000;
% y = record(10,Fa); % grava 10s de audio
% sinal_recebido = receptor(y,TB, Fp, Fa)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Pacotes de software
%pkg load signal;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Sincronizacao com Costas Loop   	    %
% https://en.wikipedia.org/wiki/Costas_loop %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y = yrx;							% sinal a ser sincronizado
t = (0:length(y) - 1)/Fa;           % instantes de amostragem
fle=64;                             % ordem do filtro
h=fir1(fle,0.001);                  % LPF design
mu=0.03;                            % Tamanho do passo do algoritmo
theta=zeros(1,length(t));           % Inicializar vetor de estimativa
theta(1) = 0;                       % fase inicial
zs=zeros(1,fle+1);zc=zeros(1,fle+1);% buffers para LPFs
for k=1:length(t)-1
  zs=[zs(2:fle+1), 2*y(k)*sin(2*pi*Fp*t(k)+theta(k))];
  zc=[zc(2:fle+1), 2*y(k)*cos(2*pi*Fp*t(k)+theta(k))];
% nova saida dos filtros
  lpfs=fliplr(h)*zs';

  lpfc=fliplr(h)*zc';
  theta(k+1)=theta(k)-mu*lpfs*lpfc; % Atualizacao do algoritmo
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               Demodulacao                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

y = y.*cos(2*pi*Fp*t + theta)';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Sincronizacao de simbolo                               %
% ref: https://paginas.fe.up.pt/~sam/textos/Sincronizacao.pdf %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
yf = y;
st = ceil((Fa/TB)); t = st;         % Instante de amostragem
d = 1;                              % cedo e tarde
err = 0.01;                         % erro permitido
si = ones(1,ceil(length(yf)/(st-1)));% indice de amostragem
for ix = 1:length(si)
    dif=abs(yf(t-d))-abs(yf(t+d));
    if dif > err
        t = t - 1;
    elseif dif < -err
        t = t + 1;
    end
    si(ix) = t;
    t = t + st;
    if t > length(yf) - st + 1, break, end
end
si = si(~(si > length(yf)));
y = yf(si);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Decodificacao                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x = y > 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Sincronizacao do quadro                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SFD = [1 1 0 0 1 1 1 0 0 0 1 1 1 1 0 0 0 0 1 1 1 0 0 0 1 1 0 0 1 0 1 0];
xc = xcorr(SFD*2 -1,double(x)*2 - 1);
[a,b] = max(abs(xc));
if a < length(SFD)*0.9
  disp('Muitos erros para decodificar os dados');
end
if xc(b) < 0
    x = ~x;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Remover cabecalho SFD                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
b = length(x) - b + length(SFD);
x = x(b+1:end);

if length(x) < 8
    disp('Erro: Pacote recebido é muito pequeno.');
    x = []; l = 0;
    return;
end

% Lê o primeiro byte, que indica o número de bytes da mensagem (l)
l = bi2de(x(1:8)'); 

% O pacote esperado agora possui: 
% 8 bits (tamanho) + (l * 8) bits (mensagem) + 16 bits (CRC)
total_bits = (l + 1)*8 + 16; 

if length(x) < total_bits
    disp('Aviso: Quadro truncado (faltam bits para completar a mensagem e o CRC).');
    rx_frame = x(1:end); % Tenta prosseguir com o que foi recebido
else
    rx_frame = x(1:total_bits); % Pega exatamente o pacote fechado
end

% --- VERIFICAÇÃO DO CRC ---
% Cria o detector usando o mesmo polinômio do transmissor
crcDet = comm.CRCDetector('Polynomial', 'z^16 + z^15 + z^2 + 1');

% A função step exige um vetor coluna, por isso transpomos com '
[dados_sem_crc, err] = step(crcDet, double(rx_frame(:))); 
dados_sem_crc = dados_sem_crc'; % Volta para vetor linha

% Alerta de erro
if err
    disp('ALERTA: Erro de CRC! A mensagem foi corrompida durante a transmissão.');
else
    disp('CRC OK: Mensagem recebida com integridade.');
end

% O vetor dados_sem_crc contém [Tamanho(8 bits) | Mensagem (l*8 bits)]
% Retorna apenas os bits da mensagem (ignorando o primeiro byte de tamanho)
if length(dados_sem_crc) >= 9
    x = dados_sem_crc(9:end); 
else
    x = [];
end

%l = bi2de(x(1:8)'); % primeiro byte eh o numero de bytes da mensagem
%x = x(9:min(end,(l+1)*8)); % retorna a mensagem recebida
