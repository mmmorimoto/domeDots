function [time]=driftGrating_new(angle, cyclespersecond, f, drawmask, gratingsize, position, duration, geometrycorrection,wait)

% Optional parameters:
%
% angle = Angle of the grating with respect to the vertical direction.
% cyclespersecond = Speed of grating in cycles per second.
% f = Frequency of grating in cycles per pixel.
% drawmask = If set to 1, a gaussian aperture is drawn over the grating.
% gratingsize = Visible size of grating in screen pixels.
% position = 1:40deg(MLaxis),0deg(DVaxis),2:80deg(MLaxis),0deg(DVaxis),3:60deg(MLaxis),35deg(DVaxis)
% duration = suration of the presentation of patch in sec
% geometrycorrection = 1: with meshmapping, else no transformation

% Modified from DriftDemo2
% MM 2018 Feb

%% Initialize parameters 
    if nargin < 5
        gratingsize = [];
    end

    if isempty(gratingsize)
        % By default the visible grating is 400 pixels by 400 pixels in size:
        gratingsize = 400;
    end

    if nargin < 4
        drawmask = [];
    end

    if isempty(drawmask)
        % By default, we mask the grating by a gaussian transparency mask:
        drawmask=1;
    end;

    if nargin < 3
        f = [];
    end

    if isempty(f)
        % Grating cycles/pixel: By default 0.05 cycles per pixel.
        f=0.05;
    end;

    if nargin < 2
        cyclespersecond = [];
    end

    if isempty(cyclespersecond)
        % Speed of grating in cycles per second: 1 cycle per second by default.
        cyclespersecond=1;
    end;

    if nargin < 1
        angle = [];
    end

    if isempty(angle)
        % Angle of the grating: We default to 30 degrees.
        angle=30;
    end;

movieDurationSecs=duration;   % Abort demo after 20 seconds.

% Define Half-Size of the grating image.
texsize=gratingsize / 2;

%% Silence the screen message
Screen('Preference', 'Verbosity', 0);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebugLevel',0);

%%
try
	%% Screen setting
    % Check that OpenGL based Psychtoolbox is installed
	AssertOpenGL;
	
	% Get the list of screens and choose the one with the highest screen number.
	screens=Screen('Screens');
	screenNumber=max(screens);
    
    %% Set Mesh Mapping and flip whole image
    if geometrycorrection==1
        PsychImaging('PrepareConfiguration');        
        transformFile = 'Z:\Code\MeshMapping\MeshMapping_Tron1.mat';
            PsychImaging('AddTask', 'AllViews', 'GeometryCorrection', transformFile);
    %         PsychImaging('AddTask', 'AllViews', 'FlipHorizontal');
    else
         PsychImaging('PrepareConfiguration'); 
    end

    %% Color value setting
    % Find the color values which correspond to white and black
	white=WhiteIndex(screenNumber);
	black=BlackIndex(screenNumber);
    
    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
	gray=round((white+black)/2);

    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. 
    if gray == white
		gray=white / 2;
    end
    
    % Contrast 'inc'rement range for given white and gray values:
	inc=white-gray;

    % Open a double buffered fullscreen window and set default background
	% color to gray:
    %[w screenRect]=Screen('OpenWindow',screenNumber, gray);
	[w screenRect]=PsychImaging('OpenWindow',screenNumber, gray);
    
    if drawmask
        % Enable alpha blending for proper combination of the gaussian aperture
        % with the drifting sine grating:
        Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    end
    %% Calculate parameters of the grating:
    
    % First we compute pixels per cycle, rounded up to full pixels, as we
    % need this to create a grating of proper size below:
    p=ceil(1/f);
    
    % Also need frequency in radians:
    fr=f*2*pi;
    
    % This is the visible size of the grating. It is twice the half-width
    % of the texture plus one pixel to make sure it has an odd number of
    % pixels and is therefore symmetric around the center of the texture:
    visiblesize=2*texsize+1;

    % Create one single static grating image:
    %
    % We only need a texture with a single row of pixels(i.e. 1 pixel in height) to
    % define the whole grating! If the 'srcRect' in the 'Drawtexture' call
    % below is "higher" than that (i.e. visibleSize >> 1), the GPU will
    % automatically replicate pixel rows. This 1 pixel height saves memory
    % and memory bandwith, ie. it is potentially faster on some GPUs.
    %
    % However it does need 2 * texsize + p columns, i.e. the visible size
    % of the grating extended by the length of 1 period (repetition) of the
    % sine-wave in pixels 'p':
    x = meshgrid(-texsize:texsize + p, 1);
    
    % Compute actual cosine grating:
    grating=gray + inc*cos(fr*x);

    % Store 1-D single row grating in texture:
    gratingtex=Screen('MakeTexture', w, grating);

    % Create a single gaussian transparency mask and store it to a texture:
    % The mask must have the same size as the visible size of the grating
    % to fully cover it. Here we must define it in 2 dimensions and can't
    % get easily away with one single row of pixels.
    %
    % We create a  two-layer texture: One unused luminance channel which we
    % just fill with the same color as the background color of the screen
    % 'gray'. The transparency (aka alpha) channel is filled with a
    % gaussian (exp()) aperture mask:
    % m is a factor to match the gaussian mask to grating size (visible patch)
    m=400/gratingsize;
    mask=ones(2*texsize+1, 2*texsize+1, 2) * gray;
    [x,y]=meshgrid(-1*texsize:1*texsize,-1*texsize:1*texsize);
    mask(:, :, 2)=white * (1 - exp(-((x/90*m).^2)-((y/90*m).^2)));
    masktex=Screen('MakeTexture', w, mask);

    %% Query maximum useable priorityLevel on this system:
	priorityLevel=MaxPriority(w); %#ok<NASGU>

    % We don't use Priority() in order to not accidentally overload older
    % machines that can't handle a redraw every 40 ms. If your machine is
    % fast enough, uncomment this to get more accurate timing.
    % Priority(priorityLevel);

    %% Query duration of one monitor refresh interval:
    ifi=Screen('GetFlipInterval', w);
    
    % Translate that into the amount of seconds to wait between screen
    % redraws/updates:
    
    % waitframes = 1 means: Redraw every monitor refresh. If your GPU is
    % not fast enough to do this, you can increment this to only redraw
    % every n'th refresh. All animation paramters will adapt to still
    % provide the proper grating. However, if you have a fine grating
    % drifting at a high speed, the refresh rate must exceed that
    % "effective" grating speed to avoid aliasing artifacts in time, i.e.,
    % to make sure to satisfy the constraints of the sampling theorem
    % (See Wikipedia: "Nyquist?Shannon sampling theorem" for a starter, if
    % you don't know what this means):
    waitframes = 1;
    
    % Translate frames into seconds for screen update interval:
    waitduration = waitframes * ifi;
    
    % Recompute p, this time without the ceil() operation from above.
    % Otherwise we will get wrong drift speed due to rounding errors!
    p=1/f;  % pixels/cycle    

    % Translate requested speed of the grating (in cycles per second) into
    % a shift value in "pixels per frame", for given waitduration: This is
    % the amount of pixels to shift our srcRect "aperture" in horizontal
    % directionat each redraw:
    shiftperframe= cyclespersecond * p * waitduration;
    
%% Animation
    % Get local rectangle coordinate of screen
    rect=Screen('Rect', w);
    % Draw black rectangle to mark center of screen
    Screen('FillRect', w, black, [rect(3)/2-5,rect(4)/2-5,rect(3)/2+5,rect(4)/2+5]);
        
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp as timing baseline for our redraw loop:
    Screen('Flip', w);
    WaitSecs(5);
    
    % Loop for each location
    % Definition of the drawn rectangle on the screen:
    % Compute it to  be the visible size of the grating, centered on the
    % screen:
    for j=1:length (position)
        pos=position(j); 
        switch pos
            case 1
                shiftx=200; shifty=200;
            case 2
                shiftx=400; shifty=200;
            case 3
                shiftx=300; shifty=27;
            otherwise
                disp('invalid position')
        end
     
    dstRect=[0 0 visiblesize visiblesize];
    dstRect=CenterRect(dstRect, screenRect);
    dstRect = OffsetRect(dstRect,shiftx,shifty);
    
    % Loop for each angle
    for k=1:length(angle)
    vbl=GetSecs;
    time(k,1)=GetSecs;
    
    % We run at most 'movieDurationSecs' seconds if user doesn't abort via keypress.
    vblendtime = vbl + movieDurationSecs;
    i=0;
    
    % Animationloop:
        while(vbl < vblendtime)
        % Shift the grating by "shiftperframe" pixels per frame:
        xoffset = mod(i*shiftperframe,p);
        i=i+1;
        
        % Define shifted srcRect that cuts out the properly shifted rectangular
        % area from the texture: 
        srcRect=[xoffset 0 xoffset + visiblesize visiblesize];
        
        % Draw grating texture, rotated by "angle":
        Screen('DrawTexture', w, gratingtex, srcRect, dstRect, angle(k));
            if drawmask==1
                % Draw gaussian mask over grating:
                Screen('DrawTexture', w, masktex, [0 0 visiblesize visiblesize], dstRect, angle(k));
            end;
            
        % Draw white rectangle at bottom right corner
        Screen('FillRect', w, white, [rect(3)-50,rect(4)-50,rect(3),rect(4)]);    

        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
        
            % Abort demo if any key is pressed:
            if KbCheck
                break;
            end;
        
        end
        time(k,2)=GetSecs;
        Screen('Flip',w);
%         % Draw black rectangle at bottom right corner
%         Screen('FillRect', w, black, [rect(3)-50,rect(4)-50,rect(3),rect(4)]); 
        
    end
    WaitSecs(wait);
    end
    
    WaitSecs(4);
    %time(:,3)= time(:,2)-time(:,1);        
    % Restore normal priority scheduling in case something else was set
    % before:
    Priority(0);
	
	%The same commands wich close onscreen and offscreen windows also close
	%textures.
	sca;

catch
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
    sca;
    Priority(0);
    psychrethrow(psychlasterror);
end %try..catch..

% We're done!
return;
