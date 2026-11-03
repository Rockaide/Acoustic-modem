function [dados, err] = crc_check(quadro)
%%%%%%%%%%%%%%%%%%%%%%  Verificador de CRC-16   %%%%%%%%%%%%%%%%%%%%%%%%%%%
%   quadro -- [dados CRC] recebidos
%   dados  -- quadro sem os 16 bits de CRC
%   err    -- 1 se o CRC nao confere (erro detectado), 0 se confere
%
% MATLAB: usa comm.CRCDetector (Communications Toolbox).
% Octave: recalcula o CRC dos dados com crc_gen e compara com o recebido.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

OCTAVE = exist('OCTAVE_VERSION', 'builtin') ~= 0; % 1 no Octave, 0 no MATLAB
n = 16;                                     % bits de CRC (grau do polinomio)

quadro = double(quadro(:)');
if length(quadro) <= n
  dados = [];
  err = 1;
  return;
end

if OCTAVE == 1
  dados = quadro(1:end-n);
  esperado = crc_gen(dados);
  err = any(esperado(end-n+1:end) ~= quadro(end-n+1:end));
else % MATLAB
  crcDet = comm.CRCDetector('Polynomial', 'z^16 + z^15 + z^2 + 1');
  % A funcao step exige um vetor coluna, por isso usamos a transposta (')
  [dados, err] = step(crcDet, quadro');
  dados = dados';
end

end
