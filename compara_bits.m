function [n_erros, ber, pos] = compara_bits(bits_tx, bits_rx, figura)
%%%%%%%%%%%%%%%%%  Comparacao entre bits transmitidos e recebidos  %%%%%%%%
%   bits_tx -- sequencia transmitida (referencia)
%   bits_rx -- sequencia recuperada no receptor
%   figura  -- (opcional) 1 para gerar o grafico da comparacao
%
%   n_erros -- numero de bits errados (bits que nao chegaram contam como erro)
%   ber     -- taxa de erro de bit = n_erros / numero de bits transmitidos
%   pos     -- indices dos bits errados
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
  figura = 0;
end

bits_tx = double(bits_tx(:)');
bits_rx = double(bits_rx(:)');
N = length(bits_tx);
n = min(N, length(bits_rx));                % trecho que pode ser comparado

pos = find(bits_tx(1:n) ~= bits_rx(1:n));
pos = [pos, n+1:N];                         % bits faltando no fim contam como erro
n_erros = length(pos);
ber = n_erros / N;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Tabela byte a byte                           %
%   '-' = bit nao recebido ; 'x' = bit errado    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\n------ Comparacao de bits (TX x RX) ------\n');
fprintf('Byte |    TX    |    RX    |  Erros\n');
for k = 1:ceil(N/8)
  idx = (k-1)*8+1 : min(k*8, N);
  tx_s = sprintf('%d', bits_tx(idx));
  rx_s = repmat('-', 1, length(idx));
  rec = idx(idx <= n);
  rx_s(1:length(rec)) = sprintf('%d', bits_rx(rec));
  marca = repmat('.', 1, length(idx));
  marca(ismember(idx, pos)) = 'x';
  fprintf('%4d | %-8s | %-8s | %s\n', k, tx_s, rx_s, marca);
end
fprintf('Bits transmitidos: %d | recebidos: %d | errados: %d', N, length(bits_rx), n_erros);
if n < N
  fprintf(' (%d nao recebidos)', N - n);
end
fprintf('\nBER = %.4f\n', ber);
fprintf('------------------------------------------\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Grafico                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if figura
  rx_plot = nan(1, N);
  rx_plot(1:n) = bits_rx(1:n);
  figure;
  subplot(2,1,1);
  stem(1:N, bits_tx, 'filled');
  ylim([-0.2 1.3]);
  title('Bits transmitidos');
  subplot(2,1,2);
  stem(1:N, rx_plot, 'filled');
  hold on;
  if ~isempty(pos)
    plot(pos, 1.15*ones(size(pos)), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
  end
  hold off;
  ylim([-0.2 1.3]);
  title(sprintf('Bits recebidos (%d erros, BER = %.4f)', n_erros, ber));
  xlabel('Indice do bit');
end

end
