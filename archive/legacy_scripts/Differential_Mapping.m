function R = Differential_Mapping(N_mod,L_symbol,N_user,N_symbol,data_raw);
% N_mod = size(Symbol_premod,1);
% R = zeros(L_symbol*N_user,N_symbol);
data = cell(1,N_symbol/2);
for i0 = 1:N_symbol/2 % t = N_symbol/2(2t+1 = 1,3,5,7,9)
   data{i0} = num2str(data_raw(:,2*N_mod*(i0-1)+1:2*N_mod*i0));
end
% data = [num2str(zeros(L_symbol,2)),data];
switch N_mod
    %BPSK
     case 1
         for t = 1:N_symbol/2
             for idata = 1:L_symbol*N_user
                 if strcmp(data{t}(idata,:),'0  0') 
                     R{t}(idata,:)='-1 0';
                 elseif strcmp(data{t}(idata,:),'1  0') 
                     R{t}(idata,:)='0 -1';
                 elseif strcmp(data{t}(idata,:),'1  1') 
                      R{t}(idata,:)='1  0';
                 else 
                     R{t}(idata,:)=data{t}(idata,:);
                 end

             end
         end
        

%      case 2
%          for L = 1:size(Symbol_premod,2)
%              if Symbol_premod(:,L)==00
%                  Symbol_Dimod(:,L)=
% 
%              elseif Symbol_premod(:,L)==01
% 
%              elseif Symbol_premod(:,L)==10
% 
%              else
% 
%              end
% 
%          end


end