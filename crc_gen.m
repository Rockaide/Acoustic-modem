function quadro = crc_gen(bits)
%%%%%%%%%%%%%%%%%%%%%%  Gerador de CRC-16   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   bits   -- vetor de bits (0/1) a ser protegido
%   quadro -- [bits CRC], com os 16 bits de CRC anexados ao final
%
% Polinomio gerador: z^16 + z^15 + z^2 + 1
% MATLAB: usa comm.CRCGenerator (Communications Toolbox).
% Octave: divisao polinomial em modulo 2 com registrador iniciado em zero,
% que gera os mesmos bits que a funcao do MATLAB.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

OCTAVE = exist('OCTAVE_VERSION', 'builtin') ~= 0; % 1 no Octave, 0 no MATLAB

bits = double(bits(:)');                    % garante vetor linha

if OCTAVE == 1
  G = [1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1]; % coeficientes de z^16 ate z^0
  n = length(G) - 1;                        % grau do polinomio = bits de CRC
  resto = [bits zeros(1,n)];                % multiplica a mensagem por z^n
  for k = 1:length(bits)
    if resto(k) == 1
      resto(k:k+n) = xor(resto(k:k+n), G);  % subtracao em modulo 2
    end
  end
  quadro = [bits resto(end-n+1:end)];
else % MATLAB
  crcGen = comm.CRCGenerator('Polynomial', 'z^16 + z^15 + z^2 + 1');
  % A funcao step exige um vetor coluna, por isso usamos a transposta (')
  quadro = step(crcGen, bits')';
end

end
