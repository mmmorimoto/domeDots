function linv = angv2linv(dthetadeg,dist,AngleFromCentreDeg)
% dx/dt = y/cos^2(theta) * dtheta/dt;

theta = deg2rad(90-AngleFromCentreDeg); % convert to rad and ref from perpendicular
dthetarad = deg2rad(dthetadeg); % covert dtheta input to rads

linv = (dist./(cos(theta).^2)).*dthetarad; % calculate relevant linear speed

