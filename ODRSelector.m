%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Selects an outout rate divider
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Metadata
% Written by    : Nathanaël Esnault
% Verified by   : N/A
% Creation date : 2021-08-27
% Version       : 0.1 (finished on ...)
% Modifications :
% Known bugs    :

%% Functions associated with this code :

%% Possible Improvements

%% TODO

%% Code

MIMU_ODR_SD    = [200 100 50 25 12.5 6.25 3.25];
MIMU_ODR_noSD  = [562.5 281.25 140.625 70.3125 35.156 17.578 8.789];

% | Output Rate Divider | Output Data Rate (Hz) (SD) | Output Data Rate (Hz) (no SD) |
% |:-------------------:|:--------------------------:|-------------------------------|
% |          1          |             200            |             562.5             |
% |          2          |             100            |             281.25            |
% |          3          |             50             |            140.625            |
% |          4          |             25             |            70.3125            |
% |          5          |            12.5            |             35.156            |
% |          6          |            6.25            |             17.578            |
% |          7          |            3.25            |             8.789             |

% If the output rate divider is 32 then there will be a single packet output

% check the desired ODR is possible
%----------------------------------

if isequal(size(MIMU_ODR_divider), [1 ,1])% check size
    if ~isinteger(MIMU_ODR_divider)% check type
        if any(MIMU_ODR_divider == [1:7 32])% check acceptable values
            if MIMU_UseSD
                MIMU_ODR = MIMU_ODR_SD(MIMU_ODR_divider);
                Message(1,Do.MessageLog,0,'The user said we use SD' , 'UDEF', RunID);
            else
                MIMU_ODR = MIMU_ODR_noSD(MIMU_ODR_divider);
                Message(1,Do.MessageLog,0,'The user said we don''t use the SD' , 'UDEF', RunID);
            end
             Message(1,Do.MessageLog,0,['The selected data output rate is: ' num2str(MIMU_ODR) '[Hz]'], 'OK', RunID);
        else
            Message(1,Do.MessageLog,0,'The desired ODR divider is not in the acceptable range: 1 2 3 4 5 6 7 32' , 'KO', RunID);
            occured_error = 1;
        end
    else
        Message(1,Do.MessageLog,0,'The desired ODR divider should be an integer' , 'KO', RunID);
        occured_error = 1;
    end
else
    Message(1,Do.MessageLog,0,'The desired ODR divider should be of size 1' , 'KO', RunID);
    occured_error = 1;
end