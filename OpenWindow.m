function display = OpenWindow(display)
%display = OpenWindow([display])
%
%Calls the psychtoolbox command "Screen('OpenWindow') using the 'display'
%structure convention.
%
%Inputs:
%   display             A structure containing display information with fields:
%       screenNum       Screen Number (default is 0)
%       bkColor         Background color (default is black: [0,0,0])
%       skipChecks      Flag for skpping screen synchronization (default is 0, or don't check)
%                       When set to 1, vbl sync check will be skipped,
%                       along with the text and annoying visual (!) warning
%
%Outputs:
%   display             Same structure, but with additional fields filled in:
%       windowPtr       Pointer to window, as returned by 'Screen'
%       frameRate       Frame rate in Hz, as determined by Screen('GetFlipInterval')
%       resolution      [width,height] of screen in pixels
%       center          [x,y] center of screeen in pixels 
%
%Note: for full functionality, the additional fields of 'display' should be
%filled in:
%
%       dist             distance of viewer from screen (cm)
%       width            width of screen (cm)

%Written 11/13/07 by gmb
% 9/17/09 gmb zre added the 'center' field in ouput of display structure.

if ~exist('display','var')
    display.screenNum = 0;
end

if ~isfield(display,'screenNum')
    display.screenNum = 0;
end

if ~isfield(display,'bkColor')
    display.bkColor = [0,0,0]; %black
end

if ~isfield(display,'skipChecks')
    display.skipChecks = 0;
end

if display.skipChecks
    Screen('Preference', 'Verbosity', 0);
    Screen('Preference', 'SkipSyncTests',1);
    Screen('Preference', 'VisualDebugLevel',0);
    
end

Screen('Preference', 'SuppressAllWarnings', 1);
if ispc
    [a,b]=system('hostname');
    if strcmp(b(1:end-1), 'saleem08')
        %Adding the meshmapping
%         RigInfo.dirScreenCalib = 'C:\Home\Code\SaleemLab-VR\VRCentral\gen\';%'C:\Home\Code\VR-Stimulus-master\Linear Track Behav - 2pNew - Dev Version - Copy\'%'C:\Users\Aman\AppData\Roaming\Psychtoolbox\GeometryCalibration\';%'C:\Users\experimenter\AppData\Roaming\Psychtoolbox\GeometryCalibration\';
%                     RigInfo.filenameScreenCalib =  'MeshMapping_VR.mat';%'geometricC
PsychImaging('PrepareConfiguration');        
transformFile = 'C:\Home\Code\SaleemLab-VR\VRCentral\gen\MeshMapping_VR.mat';
        PsychImaging('AddTask', 'AllViews', 'GeometryCorrection', transformFile);
        PsychImaging('AddTask', 'AllViews', 'FlipHorizontal');
        [display.windowPtr, res] = PsychImaging('OpenWindow', display.screenNum,display.bkColor);
    else
        [display.windowPtr,res]=Screen('OpenWindow',display.screenNum,display.bkColor);
    end
else
    [display.windowPtr,res]=Screen('OpenWindow',display.screenNum,display.bkColor);
end
%Set the display parameters 'frameRate' and 'resolution'
display.frameRate = 1/Screen('GetFlipInterval',display.windowPtr); %Hz

if ~isfield(display,'resolution')
    display.resolution = res([3,4]);
end

display.center = floor(display.resolution/2);