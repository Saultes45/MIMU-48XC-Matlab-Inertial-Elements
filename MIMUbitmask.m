%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Creates a bitmask for telling the MIMU which IMU we want the data from
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Metadata
% Written by    : Nathanaël Esnault
% Verified by   : N/A
% Creation date : 2021-05-11
% Version       : 0.1 (finished on ...)
% Modifications :
% Known bugs    :

%% Functions associated with this code :

%% Possible Improvements

%% TODO
%list of possible cases
% have a enable top, bottom, top and bottom, none

%% List of all the IMUs

% from 'MIMU4844/48XC – Integration Guide' p7

% top -> bottom (acc + gyro + mag)

% bottom -> top (acc + gyro + mag)

% IMUs’ numbering & orientation as appear from the top side of the board. IMUs on top and bottom are exactly
% mirrored. This means that the “dot” indication marks of the top and bottom IMUs are aligned. Red: Representing
% IMUs on top side of the board. Green: IMUs on bottom side of the board. This image is as appears from the top. Top:
% The side of the board which has USB connectors.

% indx_top = sort([16 18 00 02 20 22 04 06 24 26 08 10 28 30 12 14]);
% indx_bottom = sort([17 19 01 03 21 23 05 07 25 27 09 11 29 31 13 15]);
%
% indx_IMU_top = 0:2:30;
% indx_IMU_bottom = 1:2:31;
% nbr_imu = sum(length(indx_top) + length(indx_IMU_bottom));

% if you want to find the index of the bottom knowing the top:
% indx_bottom = indx_top + 1

% indx_corners_top = [16 22 14 28]; % TL TR BR BL
% indx_corners_bottom = indx_corners_top + 1;

% indx_center_top = [22 04 08 26]; % TL TR BR BL
% indx_corners_bottom = indx_corners_top + 1;


%                         TOP SIDE VIEW
% <- Left (Nothing)  Right (10-pin connector + 2 USBs) ->
% +--------+ +--------+ +--------+ +--------+
% ¦   16  °¦ ¦   18  °¦ ¦   00  °¦ ¦   02  °¦ <--- Top
% ¦        ¦ ¦        ¦ ¦        ¦ ¦        ¦
% ¦        ¦ ¦        ¦ ¦        ¦ ¦        ¦
% ¦   17   ¦ ¦   19   ¦ ¦   01   ¦ ¦   03   ¦ <--- Bottom
% +--------+ +--------+ +--------+ +--------+
%
% +--------+ +--------+ +--------+ +--------+
% ¦   20  °¦ ¦   22  °¦ ¦   04  °¦ ¦   06  °¦
% ¦        ¦ ¦        ¦ ¦        ¦ ¦        ¦
% ¦        ¦ ¦        ¦ ¦        ¦ ¦        ¦
% ¦   21   ¦ ¦   23   ¦ ¦   05   ¦ ¦   07   ¦
% +--------+ +--------+ +--------+ +--------+
%
% +--------+ +--------+ +--------+ +--------+
% ¦   24  °¦ ¦   26  °¦ ¦   08  °¦ ¦   10  °¦
% ¦        ¦ ¦        ¦ ¦        ¦ ¦        ¦
% ¦        ¦ ¦        ¦ ¦        ¦ ¦        ¦
% ¦   25   ¦ ¦   27   ¦ ¦   09   ¦ ¦   11   ¦
% +--------+ +--------+ +--------+ +--------+
%
% +--------+ +--------+ +--------+ +--------+
% ¦   28  °¦ ¦   30  °¦ ¦   12  °¦ ¦   14  °¦
% ¦        ¦ ¦        ¦ ¦        ¦ ¦        ¦
% ¦        ¦ ¦        ¦ ¦        ¦ ¦        ¦
% ¦   29   ¦ ¦   31   ¦ ¦   13   ¦ ¦   15   ¦
% +--------+ +--------+ +--------+ +--------+


%% Code

function bitmask_decimal = MIMUbitmask(config, topbottom)

% none 00
% top only 01
% bottom only 10
% top+bottom 11

nbr_possible_IMUs = 32;
bitmask_binary = zeros(nbr_possible_IMUs,1); % will be transposed later

if config ~= 0 && topbottom ~= 0
    
    % define them here only after first check
    indx_all_top        = 0:2:30; % ascending, ie not harware-tied
    indx_corners_top    = [16 22 14 28]; % TL TR BR BL
    indx_center_top     = [22 04 08 26]; % TL TR BR BL
    
    list_enabled_IMUs = [];
    
    ena_top = mod(topbottom, 10) == 1;
    ena_bottom = ((topbottom - ena_top) == 10);
    
    switch config        
        case 1 %all
            list_enabled_IMUs = [indx_all_top     .* ena_top (indx_all_top+1)     .* ena_bottom];
        case 2 % corners
            list_enabled_IMUs = [indx_corners_top .* ena_top (indx_corners_top+1) .* ena_bottom];
        case 3 % centers
            list_enabled_IMUs = [indx_center_top  .* ena_top (indx_center_top+1)  .* ena_bottom];
        otherwise
            % nothing neede, default config will take care of it
    end
    
    
    % Remove unwanted indexes from the list
    [~, indx_to_remove] = find(list_enabled_IMUs == 0);
    list_enabled_IMUs(indx_to_remove) = [];
    % list_enabled_IMUs(24+1:31+1) = 1;% take into account the offset of 0
    bitmask_binary(list_enabled_IMUs) = 1;
    
end % no else needed as the default configuration is none

% Divide the bitmask into 4 packets (4 bytes) because the transfer size is uint8
bitmask_decimal = fliplr([...
    binaryVectorToDecimal(fliplr(bitmask_binary(1:8)'))...
    binaryVectorToDecimal(fliplr(bitmask_binary(9:16)'))...
    binaryVectorToDecimal(fliplr(bitmask_binary(17:24)'))...
    binaryVectorToDecimal(fliplr(bitmask_binary(25:32)'))...
    ]); % MSB + transpose


end



% END OF SCRIPT