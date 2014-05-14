function signalOut = fastconv(signal, impulseResponse)
%% FASTCONV Computes fast convolution between two signals using the fft

signalLength = length(signal);
irLength = length(impulseResponse);
convLength = signalLength + irLength - 1;

signal = [signal; zeros(convLength - signalLength, 1)];
impulseResponse = [impulseResponse; zeros(convLength - irLength, 1)];

signalOut = ifft(fft(signal) .* fft(impulseResponse));
signalOut = signalOut(1 : convLength);

end