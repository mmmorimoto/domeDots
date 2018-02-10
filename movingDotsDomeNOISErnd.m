function [time] = movingDotsDomeNOISErnd(display,dots,duration)

% The 'dots' structure must have the following parameters:
%
%   nDots            Number of dots in the field
%   speed            Speed of the dots (degrees/second)
%   direction        Direction 0-360 clockwise from upward
%   lifetime         Number of frames for each dot to live
%   apertureSize     [x,y] size of elliptical aperture (degrees)
%   center           [x,y] Center of the aperture (degrees)
%   color            Color of the dot field [r,g,b] from 0-255
%   size             Size of the dots (in deg)
%   coherence        Coherence from 0 (incoherent) to 1 (coherent)
%
% The 'display' structure requires the fields:
%    width           Width of screen (cm)
%    dist            Distance from screen (cm)
% And can also use the fields:
%    skipChecks      If 1, turns off timing checks and verbosity (default 0)
%    fixation        Information about fixation (see 'insertFixation.m')
%    screenNum       screen number
%    bkColor         background color (default is [0,0,0])
%    windowPtr       window pointer, set by 'OpenWindow'
%    frameRate       frame rate, set by 'OpenWindow'
%    resolution      pixel resolution, set by 'OpenWindow'

nDots = sum([dots.nDots]);
colors = zeros(3,nDots);
sizes = zeros(1,nDots);

%Generate a random order to draw the dots so that one field won't occlude
%another field. ONLY NECESSARY IF using multiple fields simultaneously.
%order=  randperm(nDots);

Screen('BlendFunction', display.windowPtr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

%% Intitialize the dot positions and define some other initial parameters

%count = 1;
for i = 1
    %Calculate the left, right top and bottom of each aperture (in degrees)
    l(i) = dots(i).center(1)+dots.apDims(1);
    r(i) = dots(i).center(1)+dots.apDims(2);
    b(i) = dots(i).center(2)+dots.apDims(3);
    t(i) = dots(i).center(2)+dots.apDims(4);
    
    %Generate random starting positions
    dots(i).x = (rand(1,dots(i).nDots)-.5)*dots(i).apDims(1).*1.95 + dots(i).center(1);
    dots(i).y = (rand(1,dots(i).nDots)-.5)*dots(i).apDims(4).*1.95 + dots(i).center(2);
    
    % random starting lifetimes
    %dots(i).life =    ceil(rand(1,dots(i).nDots)*dots(i).lifetime);
    
    %Fill in the 'colors' and 'sizes' vectors for this field
    %id = count:(count+dots(i).nDots-1);  %index into the nDots length vector for this field
    %colors(:,order(id)) = repmat(dots(i).color(:),1,dots(i).nDots);
    %sizes(order(id)) = repmat(dots(i).size,1,dots(i).nDots);
    %count = count+dots(i).nDots;
end

pixpos.x = zeros(1,nDots);
pixpos.y = zeros(1,nDots);
clear goodDots
goodDots = false(zeros(1,nDots));

%Calculate total number of temporal frames
nFrames = round(duration*display.frameRate);

% create indexing for incoherent dots
dots(i).dx(1:nDots) = NaN;
dots(i).dy(1:nDots) = NaN;
nCoherent = ceil(dots(i).coherence*dots(i).nDots);  %Start w/ all random directions
inCoherent = dots(i).nDots - nCoherent;



%% Loop through the frames
pause(0.00001)
time(1) = GetSecs;
for frameNum=1:nFrames
    %count = 1;
    for i=1:length(dots)  %Loop through the fields (probably just 1)
        
        % could this be streamlined??
        dots(i).velx = linv2angv(dots(i).speed,display.dist,dots(i).x-dots(i).center(1)); %angular vel
        dots(i).vely = linv2angv(dots(i).speed,display.dist,dots(i).y-dots(i).center(2)); % in deg/s
        dots(i).vel = sqrt(((dots(i).velx).^2)+((dots(i).vely).^2));
        
        dots(i).dx = dots(i).direction*dots(i).vel...
            .*(dots(i).x./(sqrt(((dots(i).x).^2)+(dots(i).y).^2)))/display.frameRate;
        dots(i).dy = dots(i).direction*dots(i).vel...
            .*(dots(i).y./(sqrt(((dots(i).x).^2)+(dots(i).y).^2)))/display.frameRate;
        
        dots(i).dx(1:inCoherent) = randn(1,inCoherent);
        dots(i).dy(1:inCoherent) = randn(1,inCoherent);
        
        %Update the dot position's in degs
        dots(i).x = dots(i).x + dots(i).dx;
        dots(i).y = dots(i).y + dots(i).dy;
        
        % find dots outside aperture, symmetrical currently, might want to change for top/bottom
        badDots = (((dots(i).x-dots(i).center(1)).^2)/(dots(i).apDims(1))^2 + ...
            ((dots(i).y-dots(i).center(2)).^2)/(dots(i).apDims(4))^2) > 1;
        
        dots(i).x(badDots) = (rand(1,sum(badDots))-.5).*abs(dots(i).apDims(1).*1) + dots(i).center(1); %.*1 to stop clustering at perim.
        dots(i).y(badDots) = (rand(1,sum(badDots))-.5).*abs(dots(i).apDims(4).*1) + dots(i).center(2); % random replace within inner area

        % Convert deg positions to pixels
        pixpos.x = dots(i).x.*(display.pix2deg)+ display.resolution(1)/2; %angle2pix(display,dots(i).x)+ display.resolution(1)/2;
        pixpos.y = dots(i).y.*(display.pix2deg)+ display.resolution(2)/2; %angle2pix(display,dots(i).y)+ display.resolution(2)/2;
        
        % sizes of dots based on position
        dots(i).sizx = linv2angv(dots(i).size,display.dist,dots(i).x-dots(i).center(1));
        dots(i).sizy = linv2angv(dots(i).size,display.dist,dots(i).y-dots(i).center(2));
        sizes = display.pix2deg.*sqrt(((dots(i).sizx).^2)+((dots(i).sizy).^2)); %should be right
        sizes(sizes<1)=1; 
        
        % not necessary anymore...using  badDots instead
        %goodDots = (((dots(i).x-dots(i).center(1)).^2)/(dots(i).apDims(1))^2 + ...
        %    ((dots(i).y-dots(i).center(2)).^2)/(dots(i).apDims(4))^2) < 1;
        %count = count+dots(i).nDots;
    end
    
    %Draw all fields at once - THIS ONE WORKS
    Screen('DrawDots',display.windowPtr,[pixpos.x;pixpos.y],...
        sizes, dots.color,[0,0],3);
    
    Screen('Flip',display.windowPtr);
end
time(2) = GetSecs;
%clear the screen and leave the fixation point

Screen('Flip',display.windowPtr);

end

%% Extras

        % Dot lifetimes + deaths + replacement
        %dots(i).life = dots(i).life+1; %Increment the 'life' of each dot
        %Find the 'dead' dots
        %deadDots = mod(dots(i).life,dots(i).lifetime)==0; %Find the 'dead' dots
        %Replace the positions of the dead dots to random locations
        %dots(i).x(deadDots) = (rand(1,sum(deadDots))-.5)*dots(i).apertureSize(1)...
        %+ dots(i).center(1);
        %dots(i).y(deadDots) = (rand(1,sum(deadDots))-.5)*dots(i).apertureSize(2)...
        %+ dots(i).center(2);
        
        % ignore unless using multiple apertures simultaenously
        %id = order(count:(count+dots(i).nDots-1));
