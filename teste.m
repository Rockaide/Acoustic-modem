msg = "OLA";
RB = 100;       % taxa de bits
Fp = 2000;      % frequencia da portadora
Fa = 8000;      % taxa de amostragem da placa de som
disp(["Mensagem transmitida: " msg]);
[ytx,~,quadro_tx] = transmissor(msg, RB, Fp, Fa);
[m,l,quadro_rx] = receptor_2(ytx', RB, Fp, Fa);
compara_bits(quadro_tx, quadro_rx);
%x = bi2de(reshape(m,8,l)')';

x = bi2de(reshape(m,8,l)')';
msg = char(x);
disp(["Mensagem recebida: " msg]);


