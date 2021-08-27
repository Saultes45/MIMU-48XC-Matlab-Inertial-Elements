%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Get data from the MIMU in real time via USB or BLE 3.0 (UART COM)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Metadata
% Written by    : Nathanaël Esnault
% Verified by   : N/A
% Creation date : 2021-05-10
% Version       : 0.1 (finished on ...)
% Modifications :
% Known bugs    :

%% Functions associated with this code :

%% Possible Improvements

%% TODO
% functions needed
% calculate checksum
% calculate bitmask with designated IMU
% check ACK + SD present

% data that can be saved: raw serial, binary data from IMU, workspace as a
% mat, specific variables as mat, figures (PNG+FIG)


%% Temp: parameters


CommandsList;

% Place where the Matlab-generated raw serial data log will be placed
SerialFileLogName       = [cd '\Data\RawSerial\' RunID '_SerialData.txt'];
SerialFileBinName       = [cd '\Data\BinaryData\' RunID '_SerialData.bin'];

MIMU_UseSD      = 0; % for output rate divider
scale_acc       = 1/2048*9.80665;
scale_gyro      = 1/16.4;
scale_temp      = 1.0/340.0; %will come from IMU
scale_temppr    = 1.0/480; %will come from pressure sensor
scale_mag       = 0.6;


%% Output data rate divider

ODRSelector;

if ~occured_error
    
    %% Create folder for serial comm logs
    try
        
        % Creating a "Data folder"
        %-------------------------
        if ~exist([cd '\Data'],'dir')
            mkdir([cd '\Data']);
            Message(1,Do.MessageLog,0,'Data folder created', 'OK', RunID);
        end
        
        % Creating a "Test folder"
        %-------------------------
        if ~exist([cd '\Data\Test-' RunID],'dir')
            mkdir([cd '\Data\Test-' RunID]);
            Message(1,Do.MessageLog,0,'Test folder (within the ''Data'' folder) has been created', 'OK', RunID);
        end
        
        % Creating a "RawSerial folder"
        %------------------------------
        if ~exist([cd '\Data\RawSerial'],'dir')
            mkdir([cd '\Data\RawSerial']);
            Message(1,Do.MessageLog,0,'Raw Serial data folder (within the ''Data'' folder) has been created', 'OK', RunID);
        end
        
        % Creating a "BinSerial folder"
        %------------------------------
        if ~exist([cd '\Data\BinSerial'],'dir')
            mkdir([cd '\Data\BinSerial']);
            Message(1,Do.MessageLog,0,'Binary Serial data folder (within the ''Data'' folder) has been created', 'OK', RunID);
        end
        
    catch error
        disp(error);
        occured_error = 1;
        Message(1,Do.MessageLog,0,'Saving destination folders couldn''t be created', 'KO', RunID);
    end
    
    %% Check COM port avaiblability if ~isvalid(serialObject)
    AvailableToolBoxes = ver; % We do the check onl if the tool box is avalailable
    if ~isempty(find(strcmp({AvailableToolBoxes.Name},'Instrument Control Toolbox'), 1))
        serialInfo = instrhwinfo('serial');
        if ~any(strcmp(serialInfo.AvailableSerialPorts, MIMUCOMPort))
            Message(1,Do.MessageLog,0,['The specified COM port ' MIMUCOMPort ' cannot be opened'], 'KO', RunID);
            button = questdlg(['The specified COM port ' MIMUCOMPort ' cannot be opened, Would you like to select an other COM port ?'],...
                'Problem opening the COM port','Sure','No, Abort Aquitition','Sure');
            if strcmp(button, 'Sure') %the user want to select an other COM port
                Message(1,Do.MessageLog,0,'User want to select an other COM port', 'UDEF', RunID);
                %find all the available COM Port
                
                if isempty(serialInfo.AvailableSerialPorts)
                    msgbox('No other COM port are available','Error','Warn');
                    Message(1,Do.MessageLog,0,'No other COM port are available', 'KO', RunID);
                    occured_error = 1;
                else
                    [selection,ok] = listdlg('PromptString','Select a COM port:',...
                        'SelectionMode','single',...
                        'ListString',serialInfo.AvailableSerialPorts);
                    if ok == 1
                        MIMUCOMPort = char(serialInfo.AvailableSerialPorts(selection));
                        Message(1,Do.MessageLog,0,['User selected : ' MIMUCOMPort], 'OK', RunID);
                    else
                        Message(1,Do.MessageLog,0,'The user misselected something', 'KO', RunID);
                        occured_error = 1;
                    end
                end
            else
                occured_error = 1;
            end
            
        end
        
    else
        msgbox('It is impossible to check the availability of the COM Port because you don''t have the correct toolbox','Error','Warn');
        Message(1,Do.MessageLog,0,'It is impossible to check the availability of the COM Port because you don''t have the correct toolbox', 'KO', RunID);
    end
    
    %% COM port configuration
    MIMU				= serial(MIMUCOMPort);
    MIMU.BaudRate 		= MIMU_baudrate;
    MIMU.Terminator 	= 'CR';
    MIMU.DataBits 		= 8;
    MIMU.ByteOrder      = 'littleEndian';
    MIMU.RecordDetail 	= 'verbose';
    MIMU.RecordName     = [cd '\' SerialFileLogName];
    MIMU.Timeout 		= 3; % in [s]
    set(MIMU,'InputBufferSize', MIMU_InputBufferSize);% A large buffer size is required
    
    %% Aquisition Loop
    Message(1,Do.MessageLog,0,['Trying to open COM : ' num2str(MIMU.Name) ' with ' num2str(MIMU.BaudRate) ' bauds'],'UDEF', RunID);
    
    try
        fopen(MIMU);
        Message(1,Do.MessageLog,0,['Successful open of : ' num2str(MIMU.Name) ' with ' num2str(MIMU.BaudRate) ' bauds'],'OK', RunID);
        if Do.RecordRawSerial
            record(MIMU,'on');
            Message(1,Do.MessageLog,0,'Begining the writing in the serial log file', 'UDEF', RunID);
        else
            Message(1,Do.MessageLog,0,'Recording in the serial log file is off', 'UDEF', RunID);
        end
        if Do.MessageVerbose == 0
            Message(1,Do.MessageLog,0,'Verbose is off so you won''t see any "OK" message during aquisition', 'UDEF', RunID);
        end
        
        % Flush all data from both the input and output buffers of the specified serial port
        %         flush(MIMU);
        % Flush serial ports (The MIMU team's way)
        while MIMU.BytesAvailable
            fread(MIMU,MIMU.BytesAvailable,'uint8');
        end
        Message(1,Do.MessageLog,0,'Input+Output buffer have been flushed', 'UDEF', RunID);
        
        % Open binary file for saving inertial data
        binFile = fopen(SerialFileBinName, 'w');
        
        % Request raw inertial data
        %         imu_mask = [255 255 255 255];
        command = [mimuCommandHeader.RawRealTime  MIMUbitmask(3,11) MIMU_ODR_divider]; % 3 = center, 11 = top+bottom
        command = [command MIMUchecksum(command)]; % apend the 2-byte checksum
        command = [48 19 0 0 67];
        fwrite(MIMU,command,'uint8');
        
        %check we have recieved the ACK
        [tline,count] = fread(MIMU,4,'uint8');
        
        if count > 0
            Message(1,Do.MessageLog,0,['Reply from MIMU: ' strjoin(string(tline),' - ')], 'UDEF', RunID);
            if length(tline) >= length(desired_answer)
                if strcmp(tline(1:length(desired_answer)), desired_answer) %check if desired_answer is in the answer)
                    disp(['Log creation command acknowledged']);
                    command_successfull = 1;
                end
                flushinput(BLE); % It is only really necessary if the module is going to flood the PC Rx buffer
            else
                disp([num2str(count) ' bytes received but the desired answer (' desired_answer ') was not among thoses'])
            end
        else
            disp(['Message sent but no answer within the serial timeout period: ' num2str(BLE.Timeout) '[s]'])
            % throw an exception to sto any remaining process (especially
            % the plots)
            ME = MException('MIMU:KnockKonckNoAnswer', ...
            'Command sent the MMIMU but no answer');
            throw(ME);
        end
        
        
        % Open dummy figure with pushbutton such that logging can be aborted
        abort_request = 0;
        figure();
        uicontrol('style','push','string','Abort data logging','callback','abort=1;');
        drawnow
        
        % Log data until the cancel pushbutton is pressed or the max time has
        % elapsed
        while abort_request == 0
            if MIMU.BytesAvailable > 0
                fwrite(binFile,fread(MIMU,MIMU.BytesAvailable,'uint8'),'uint8'); % Whatever we get from the serial is loged in the .bin file
            end
            drawnow % make sure the cancel window is visible
        end
        
        
    catch error
        Message(1,Do.MessageLog,0,'The following error happened during the aquisition loop:', 'KO', RunID);
        Message(1,Do.MessageLog,0,[error.identifier ' @ ' num2str(error.stack(1).line)], 'KO', RunID);
        occured_error = 1;
    end
    
    fclose(MIMU); % Close the serial port
    Message(1,1,0,[MIMU.Port ' has been closed'],'OK', RunID);
    
    if Do.RecordRawSerial
        record(MIMU,'off');
        Message(1,1,0,'Serial port recording has been switched off','OK', RunID);
    end
    
    delete(MIMU); % Delete the serial port object it cannot be open by inadvertence later
    clearvars MIMU;
    
end % ODR selection occured_error = 1;


% END OF SCRIPT

%% Projections to top frame
% Gyr/Acc (SWD->ENU)
RotationMatrix_GyrAcc_BottomtoTop = [...
    [0 -1  0];...
    [-1 0 0];...
    [0 0 -1] ...
    ];

% Mag (SEU->ESD)
RotationMatrix_Mag_BottomtoTop = [...
    [+1 0 0];...
    [0 +1 0];...
    [0 0 -1] ...
    ];

%% Projection to body frame (NED) as orientated by Nathan's
% Gyr/Acc (SWD->NED)
RotationMatrix_GyrAcc_ToptoBody = [...
    [0 +1  0];...
    [+1 0 0];...
    [0 0 -1] ...
    ];

% Mag (ESD->NED)
RotationMatrix_Mag_ToptoBody = [...
    [0 -1  0];...
    [+1 0 0];...
    [0 0 +1] ...
    ];

% % % %% Aquisition
% % %
% % % % Open serial port
% % % com = serial(...
% % %     MIMU_comport,...
% % %     'BaudRate',     MIMU_baudrate,...
% % %     'Terminator',   'CR',...
% % %     'ByteOrder',    'littleEndian'...
% % %     );
% % %
% % % serial('COM3','InputBufferSize',500000);
% % % fopen(com);
% % %
% % % % Open binary file for saving inertial data
% % % filename = ['osmium_data - ' 'RealTime' '.bin'];
% % % file = fopen(filename, 'w');
% % %
% % % % Flush serial ports
% % % while com.BytesAvailable
% % %     fread(com,com.BytesAvailable,'uint8');
% % % end
% % %
% % % % Request raw inertial data
% % % % nr_imus=4;
% % % % nr_imus=32;
% % % header = 43;
% % % % MIMU_ODR_divider = 2;
% % % % imu_mask = [0 0 0 15];
% % % imu_mask = [255 255 255 255];
% % % command = [header imu_mask MIMU_ODR_divider];
% % % command = [command (sum(command)-mod(sum(command),256))/256 mod(sum(command),256)];
% % % fwrite(com,command,'uint8');
% % % fread(com,4,'uint8');
% % %
% % % % Open dummy figure with pushbutton such that logging can be aborted
% % % abort_request = 0;
% % % figure(97);
% % % uicontrol('style','push','string','Abort data logging','callback','abort=1;');
% % % drawnow
% % %
% % % % Logg data until pushbutton pressed
% % % while abort_request==0
% % %     if com.BytesAvailable>0
% % %         fwrite(file,fread(com,com.BytesAvailable,'uint8'),'uint8');
% % %     end
% % %     drawnow
% % % end
% % %
% % % % Stop output
% % % fwrite(com,[34 0 34],'uint8');
% % %
% % % % Close serial port and file
% % % fclose(com);
% % % fclose(file);
% % % close(gcf)
% % %
% % % % Parse data and delete logging file
% % % [inertial_data,temp_data,calib_mag_data,fused_calib_mag_data,time_stamps,raw_data]= osmium_parse_bin(filename,uint8(nbr_IMUs));
% % % delete(filename);
% % %
% % % % Plot data in SI units
% % %
% % % % scale_pressure = 1.0/4096;
% % % % figure(1),clf, hold on
% % % %     plot(double(pressure_data)'*scale_pressure,'b-')
% % % % grid on
% % % % title('Pressure');
% % % % xlabel('sample number')
% % % % ylabel(' [mBar] ');
% % %
% % % inertial_data_double = double(inertial_data);
% % % % scale_acc  = 1/2048*9.80665;
% % % % scale_gyro = 1/16.4;
% % %
% % %
% % % %% Plots
% % %
% % % % Accelerometers
% % % % --------------
% % % for i=0:nbr_IMUs-1
% % %     figure()
% % %     plot(inertial_data_double(i*6+1,:)'*scale_acc,'b-')
% % %     hold on
% % %     plot(inertial_data_double(i*6+2,:)'*scale_acc,'g-')
% % %     hold on
% % %     plot(inertial_data_double(i*6+3,:)'*scale_acc,'r-')
% % %     grid on
% % %     title(['imu acc',num2str(i)]);
% % %     xlabel('sample number')
% % %     ylabel('a [m/s^2]');
% % % end
% % %
% % %
% % % % Gyroscopes
% % % % ----------
% % % for i=0:nbr_IMUs-1
% % %     figure()
% % %     plot(inertial_data_double(i*6+4,:)'*scale_gyro,'b-')
% % %     hold on
% % %     plot(inertial_data_double(i*6+5,:)'*scale_gyro,'g-')
% % %     hold on
% % %     plot(inertial_data_double(i*6+6,:)'*scale_gyro,'r-')
% % %     grid on
% % %     title(['IMU gyr',num2str(i)]);
% % %     xlabel('Sample number')
% % %     ylabel('Rate of turn [deg/s]');
% % % end
% % %
% % %
% % % % scale_temp = 1.0/340.0;%will come from IMU
% % % % scale_temppr = 1.0/480;%will come from pressure sensor
% % % temp_data_double = double(temp_data);
% % %
% % % % Temperature
% % % % -----------
% % % figure()
% % % for i = 1:32
% % %     plot(temp_data_double(i,:)'*scale_temp+35)
% % %     %     plot(double(temppr_data)'*scale_temppr+42.5,'r-')
% % % end
% % % grid on
% % % title('Temperature readings');
% % % xlabel('Sample number')
% % % ylabel('Temperature [°C]');
% % %
% % %
% % % % Plot data in SI units
% % % % scale_mag = 0.6;
% % % correct_data = scale_mag*double(calib_mag_data);
% % %
% % % % Magnetometers
% % % % -------------
% % % for i=0:nbr_IMUs-1
% % %     %for i=20
% % %     figure(),clf, hold on
% % %     plot(correct_data(i*3+1,:)'*scale_mag,'b-')
% % %     plot(correct_data(i*3+2,:)'*scale_mag,'g-')
% % %     plot(correct_data(i*3+3,:)'*scale_mag,'r-')
% % %     grid on
% % %     title(['magno',num2str(i)]);
% % %     xlabel('sample number')
% % %     ylabel('Field [microT]');
% % % end
% % %
% % % %Fuse data from all 4 IMUs
% % % mag_x = (correct_data(1,:) - correct_data(5,:) + correct_data(7,:) - correct_data(11,:))/4;
% % % mag_y = (correct_data(2,:) - correct_data(4,:) + correct_data(8,:) - correct_data(10,:))/4;
% % % mag_z = (correct_data(3,:) - correct_data(6,:) + correct_data(9,:) - correct_data(12,:))/4;
% % %
% % % % Magnetometers
% % % % -------------
% % % figure(99)
% % % plot(mag_x,'-b')
% % % plot(mag_y,'-g')
% % % plot(mag_z,'-r')
% % % grid on
% % % title('Fused Magnetometer Readings(Fused On Application platform)');
% % % xlabel('Sample No');
% % % ylabel('Magnetometer Reading');
% % %
% % % % figure(100),clf,hold on
% % % % plot(fused_calib_mag_data(1,:)'*scale_mag,'-b')
% % % % plot(fused_calib_mag_data(2,:)'*scale_mag,'-g')
% % % % plot(fused_calib_mag_data(3,:)'*scale_mag,'-r')
% % % % grid on
% % % % title('Fused Magnetometer Readings(Fused On OSMIUM)');
% % % % xlabel('Sample No');
% % % % ylabel('Magnetometer Reading');
% % %
% % % field1 = sqrt(correct_data(1,:).^2+correct_data(2,:).^2+correct_data(3,:).^2);
% % % field2 = sqrt(correct_data(4,:).^2+correct_data(5,:).^2+correct_data(6,:).^2);
% % % field3 = sqrt(correct_data(7,:).^2+correct_data(8,:).^2+correct_data(9,:).^2);
% % % field4 = sqrt(correct_data(10,:).^2+correct_data(11,:).^2+correct_data(12,:).^2);
% % %
% % % fuse_after_root = (field1+field2+field3+field4)/4;
% % % %fuse_after_root = (field1+field2+field4)/3;
% % % %fuse_before_root = sqrt(mag_x.^2+mag_y.^2+mag_z.^2);
% % %
% % % figure(101),clf, hold on
% % % plot(fuse_after_root,'r-');
% % % grid on
% % % title('Field IMU 1,2,3,4 fused after root');
% % %
% % % figure(102),clf, hold on
% % % subplot(2,1,1);
% % % plot(double(time_stamps)'/64e6,'b-');
% % % grid on
% % % title('Time stamps');
% % % xlabel('sample number')
% % % ylabel('[s]');
% % % subplot(2,1,2);
% % % dt = diff(double(time_stamps)');
% % % %plot(dt,'b-');
% % % for i=1:numel(dt)
% % %     if dt(i)<0
% % %         dt(i) = dt(i)+2^32;
% % %     end
% % % end
% % % plot(dt/64e6,'b-');
% % % grid on
% % % title('Time differentials');
% % % xlabel('sample number')
% % % ylabel('[s]');
