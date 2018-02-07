# domeDots

IMPORTANT: pix2deg (ie number of pixels per deg) must be entered at top of flowDots function. This can be calculated as display.resolution(1)/angular width of the projection in the dome if required.

flowDots is the function to call. See function for optional inputs.

movingDotsDome/movingDotsDomeNOISErnd/movingDotsDomeNOISEstr are the actual stimulus functions. Select/unselect desired function within flowDots function (comment/uncomment). rnd and str are versions which enable different coherence levels. rnd vers. has noise dots moving randomly every frame; str vers. has noise dots moving in same random direction for duration of stimulus.

linv2angv and angv2linv are support functions.

Requires PsychToolbox (most likely the latest version is necessary).
