function [dots, times] = flowDots(varargin)
% Moving Dots Stimulus
% Outputs are shuffled dot struct array in order of presentation and the times
% relative to the startTime of each stimulus interval.

% NEED PIXEL/DEG RATIO
pix2deg = 10;
display.dist = 60;

Params = inputParser;
addParameter(Params,'stimdur',1,@isnumeric) % in s
addParameter(Params,'ITI',0.5,@isnumeric) % inter-trial-interval
addParameter(Params,'nreps',10,@isnumeric)
addParameter(Params,'shuffle',1,@isnumeric) % shuffle trials flag
addParameter(Params,'refangle',45,@isnumeric) % ref angle for size/speed inputs
addParameter(Params,'dims',[-90, 90, -50, 50] ,@isvector) % left, right, bottom, top

addParameter(Params,'size',{},@isvector) % ref size at refangle
addParameter(Params,'speed',{},@isvector) %ref speed at refangle
addParameter(Params,'density',{},@isvector) %this is dots/deg^2 -> might want area coverage.
addParameter(Params,'coherence',1,@isvector) % vector of values between 0 and 1
addParameter(Params,'colour',[255 255 255],@isvector)
addParameter(Params,'flow',1,@isnumeric) % 1 for expanding, -1 for contracting

parse(Params,varargin{:})

dotcolour = Params.Results.colour;
refangle = Params.Results.refangle;
stimdur = Params.Results.stimdur;
ITI = Params.Results.ITI;
shuffle = Params.Results.shuffle;
coherence = Params.Results.coherence;

%% create dots structs for each trial
% initialise dot structs with constant parameters
dots(1).nDots = NaN;
dots(1).speed = NaN;
dots(1).direction = Params.Results.flow; % do for expand/contract
dots(1).lifetime = NaN; % infinite lifetime atm.
dots(1).apDims = Params.Results.dims; % left,right,bottom,top [90,90,40,40]
dots(1).center = [0,0];
dots(1).color = dotcolour;
dots(1).size = NaN;
dots(1).coherence = NaN;

% area of aperture (pi*r(1)*r(2)) - dont think theres any need to split
apArea = 0.5*pi*dots.apDims(1)*dots.apDims(3)... % bottom half
    + 0.5*pi*dots.apDims(2)*dots.apDims(4); % top half

% deal with user inputs (variable parameters)
nreps = Params.Results.nreps;
size = Params.Results.size;
speed = Params.Results.speed;
density = Params.Results.density;
%convert ref inputs to moving dot function inputs
numdots = round(density.*apArea);
speed = angv2linv(speed,display.dist,refangle); % create input speeds for moving dot function
size = angv2linv(size,display.dist,refangle); % create input sizes for moving dot function

nUniqueTrials = length(speed)*length(density)*length(size)*length(coherence); % no of unique trials
dots = repmat(dots,1,nUniqueTrials); % create base structs w/ constant params

% fill in variable parameters (user inputs)
trialidx = 0;
for cohidx = 1:length(coherence)
    for speedidx = 1:length(speed)
        for sizeidx = 1:length(size)
            for numdotsidx = 1:length(numdots)
                trialidx = trialidx + 1;
                dots(trialidx).speed = speed(speedidx);
                dots(trialidx).size = size(sizeidx);
                dots(trialidx).nDots = numdots(numdotsidx);
                dots(trialidx).density = density(numdotsidx);
                dots(trialidx).coherence = coherence(cohidx);
            end
        end
    end
end
% repeat depending on nreps input
dots = repmat(dots,1,nreps);

if shuffle == 1
    ridx = randperm(length(dots));
    for i = length(dots):-1:1
        dots_shuf(i) = dots(ridx(i));
    end
    dots = dots_shuf;
end

%% display struct

display.dist = 60; % need to input;
display.width = 100;
display.skipChecks = 1;
display.screenNum = 2; % 0 for mac, 1 for external
display.bkColor = [128,128,128];
display.fixation.color = {[0,0,0],[0,0,0]};
display.fixation.mask = 3;

try
    display.skipChecks =1;
    display.bkColor = [128,128,128];
    display = OpenWindow(display);
    HideCursor;
    Screen('Flip',display.windowPtr);
    pause(0.2)
catch ME
    Screen('CloseAll');
    rethrow(ME)
end
display.pix2deg = display.resolution(1)/180;
%% run the dots
times = NaN*ones(length(dots),2);
startTime = GetSecs;

for trialidx = 1:length(dots)
    %[times(trialidx,:)] = movingDotsDome(display,dots(trialidx),stimdur);
    %[times(trialidx,:)] = movingDotsDomeNOISEstr(display,dots(trialidx),stimdur);
    [times(trialidx,:)] = movingDotsDomeNOISErnd(display,dots(trialidx),stimdur);
%     waitTill(ITI);
pause(1)
end

times = times-startTime; % remove if you want comp time

% convert dot parameters back to user input values.
for i = length(dots):-1:1
    dots(i).speed = linv2angv(dots(i).speed,display.dist,refangle);
    dots(i).size = linv2angv(dots(i).size,display.dist,refangle);
end
sca
