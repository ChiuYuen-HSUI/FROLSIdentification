%% This function performs the identification of a NARX model that represents the dynamic of residue obtained during the identification 
%of a system with signal1 as input and signal2 as output
% signal1 is the input signal. It can contain multiple trials of the same system. Each trial must be in one column of the signal1 matrix.
% signal2 is the output signal. It can contain multiple trials of the same system. Each trial must be in one column of the signal2 matrix. 
%Each column of signal2 must be correspondent to the same column number of signal1
% degree is the maximal polynomial degree that you want the FROLS method to look for (it has been tested until the 9th degree)
% mu is the maximal lag of the input signal
% my is the maximal lag of the output signal
% me is the maximal lag of the residue signal
% delay is how much lags you want to not consider in the input terms. It comes from a previous knowledge of your system
% dataLength is the number of steps of each column of the signal1 and 2 matrices to consider during the identification of the system.
%Normally a very high number do not leads to good results. 400 to 600 should be fine.
% divisions is the number of data parts (of dataLength length) to consider from each trial (each column) of the signals.
% pho is the stop criteria 
% a is a vector with the coefficients of the chosen terms during the identification of the system
% la is a vector with the indices of the chosen terms during the identification of the system
% Dn is a vector in which each element is a string with a term found during the residue idetification. u is the input signal, y is the output signal
%and e is the residue signal
% an is a vector with the coefficients of the chosen terms during the identification of the residue
% ln is a vector with the indices of the chosen terms during the identification of the residue

function [Dn, an, ln] = NARXNoiseModelIdentification(signal1, signal2, degree, mu, my, me, delay, dataLength, divisions, pho,  a, la)
   
    global l q g err An s ESR beta M0 D;

    subjects = size(signal1, 2);
    
   %% 
   
   k = 1;
   for i = 1:subjects
       for j = 1:divisions
           begin = randi([1 length(signal1) - dataLength - 1], 1);
           u(:,k) = (signal1(begin+1:begin + dataLength));
           y(:,k) = (signal2(begin+1:begin + dataLength));
           [yest xi(:,k)] = osa(u(:,k), y(:,k), a, la, degree, mu, my, delay);
           [pn(:,:,k), D]= buildPNoiseMatrix(u(mu+1:end, k), y(my:end, k), xi(:, k), degree, mu, my, me, delay);
           xi_output(:,k) = xi(max([mu my me]) + 1:end, k);
           k = k + 1;
       end
   end
   
   % noiseidentification of model 1 to 2
   q = []; err=[]; An=[]; g=[];beta= [];
   s = 1;
   ESR = 1;
   M = size(pn,3);
   N = size(pn,1);
   l = zeros(1,M);

   
   %%
   V = ver;
   parallel = 0;
   for i = 1:length(V)
      if (strcmp(V(i).Name,'Parallel Computing Toolbox'))
          parallel = 1;
      end
   end
   if parallel
      matlabpool open 6 
      mfrols_par(pn, xi_output, 1e-5, pho, 0);
      matlabpool close
   else
       mfrols(pn, xi_output, 1e-5, pho, 0);
   end
%%
   err=err(1:M0)';
   l=l(1:M0)';
   ln = l;
   Dn=D(l)';
   for i = 1:subjects
    an(:,i) = mean(beta(:,(i-1)*divisions+1:i*divisions), 2);
   end     
end
