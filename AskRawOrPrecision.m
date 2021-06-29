%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Pop up a small window and ask which aquisition mode
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Metadata
% Written by    : Nathanaël Esnault
% Verified by   : N/A
% Creation date : 2021-11-05
% Version       : 0.1 (finished on ...)
% Modifications :
% Known bugs    :

%% Functions associated with this code :

%% Possible Improvements


%% TODO

%%
Data_Type_Mode = menu ('Chose data type mode','Raw', 'Processed', 'Cancel');

if  Data_Type_Mode ~= 0
    switch Data_Type_Mode
        case 1 %% Raw
            Message(1,Do.MessageLog  ,0,'Data_Processing_Mode : Real Time', 'UDEF', RunID);
            
        case 2 %% Processed
            Message(1,Do.MessageLog  ,0,'Data_Processing_Mode : Log on SD card', 'UDEF', RunID);
            
        case 3 %% Cancel
            Message(1,Do.MessageLog  ,0,'User asked to cancel' , 'UDEF', RunID);
            
            %The previous statement avoid an error if
            %(DisplayFinalGraph == 1 AND the user cancelled the menu SO the varaibles to display wouldn't exist)
            
    end% end for the switch on data aquisition method
else
    Message(1,Do.MessageLog,0,'No selection was made' , 'UDEF', RunID);
    occured_error = 1;
end