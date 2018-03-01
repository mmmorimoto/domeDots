

%% Silence the screen message
Screen('Preference', 'Verbosity', 0);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebugLevel',0);

%% Screen setting
    % Check that OpenGL based Psychtoolbox is installed
	AssertOpenGL;
	
	% Get the list of screens and choose the one with the highest screen number.
	screens=Screen('Screens');
	screenNumber=max(screens);
    
    %% Set Mesh Mapping and flip whole image
    PsychImaging('PrepareConfiguration');        
    transformFile = 'C:\Home\Code\SaleemLab-VR\VRCentral\gen\MeshMapping_Tron.mat';
        PsychImaging('AddTask', 'AllViews', 'GeometryCorrection', transformFile);
%         PsychImaging('AddTask', 'AllViews', 'FlipHorizontal');

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
    
     %% Query maximum useable priorityLevel on this system:
	priorityLevel=MaxPriority(w); %#ok<NASGU>

    % We don't use Priority() in order to not accidentally overload older
    % machines that can't handle a redraw every 40 ms. If your machine is
    % fast enough, uncomment this to get more accurate timing.
    %Priority(priorityLevel);