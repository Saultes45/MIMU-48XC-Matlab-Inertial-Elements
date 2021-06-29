%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Proposes different options for the user to chose from
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Metadata
% Written by    : Nathanaël Esnault
% Verified by   : N/A
% Creation date : 2021-10-05
% Version       : 0.1 (finished on ...)
% Modifications :
% Known bugs    :

%% Functions associated with this code :

%% Possible Improvements

%% Ressources
% https://inertialelements.com/resources.html


%% TODO


%% Cleaning + testID;
close all;
clc
clear;
%this test ID
formatOut = 'yyyy-mm-dd--HH-MM-SS-FFF';
RunID = datestr(now,formatOut);

%% Initialisations
occured_error = 0;

%% Start using the log file
Do.MessageLog           = 0; % Do NOT log
Message(1,1,1,'Asking for new file', 'UDEF',RunID); % Creating a new log file (by using the third "1" in the function parameters)
Message(1,Do.MessageLog,0,['Local directory is : ' cd ], 'UDEF', RunID); % Loging the current directory

%% Parameters

GetParameters;


%% Work Matlab has to do (should be in the .ini)
Do.SaveFigures              = 0; % Not programmed
Do.GenerateStatistics       = 1; % Not programmed
Do.GenerateReport           = 0; % Not programmed
Do.SavePNGPlots             = 0; % Not programmed
Do.SaveData                 = 0; % Not programmed
Do.SaveDataAsTxT            = 0; % Not programmed
Do.Plots                    = 1; % Not programmed
Do.DockWindows              = 1; % Not programmed
Do.ApplyLowPassFilter       = 1; % Not programmed
Do.SaveCalibratedAsMat      = 0; % Not programmed
Do.GenerateSimulinkData     = 0; % Not programmed
Do.ZuptGyro                 = 0; % Not programmed
Do.SLERPsmoothing           = 0; % Not programmed
Do.RecordRawSerial          = 1;
Do.MessageVerbose           = 1;

%% Something

if Do.DockWindows
    set(0,'DefaultFigureWindowStyle','docked');
end

%% Menu: Asking User to chose data aquisition mode

if occured_error == 0
    Data_Processing_Mode = menu ('Chose data aquisition mode','Real Time', 'Log on SD card', 'Retrieve from SD card','Cancel');
    % Real Time/Replay(Matlab Aquisition Files)/SD card(from boat)/GPS only
    % RMC/RT long aquisition/Delta t find/Cancel
    
    if  Data_Processing_Mode ~= 0
        switch Data_Processing_Mode
            case 1 %% Real Time
                Message(1,Do.MessageLog,0,'Data_Processing_Mode : Real Time', 'UDEF', RunID);
                
                %                 Bathymetry_RT_Mode;
                AskRawOrPrecision;
                RealTimeACQ;
                
            case 2 %% Replay
                Message(1,Do.MessageLog,0,'Data_Processing_Mode : Log on SD card', 'UDEF', RunID);
                
                %                 Bathymetry_Replay_Mode;
                
            case 3 %% SD card
                Message(1,Do.MessageLog,0,'Data_Processing_Mode : Retrieve from SD card', 'UDEF', RunID);
                
                %                 Bathmetry_SD_Card;
                
            case 7 %% Cancel
                Message(1,Do.MessageLog,0,'User asked to cancel' , 'UDEF', RunID);
                occured_error = 1;
                %The previous statement avoid an error if
                %(DisplayFinalGraph == 1 AND the user cancelled the menu SO the varaibles to display wouldn't exist)
                
        end% end for the switch on data aquisition method
    else
        Message(1,Do.MessageLog,0,'No selection was made' , 'KO', RunID);
        occured_error = 1;
    end
    
    
end % initial occured_error check;



Message(1,Do.MessageLog,0,'End of the main Matlab script' , 'UDEF', RunID);
%END OF SCRIPT