%% Linear speed to angular velocity calc

function w_deg = linv2angv(linspeed, dist, AngleFromCentreDeg)

dx_dt = linspeed; %(cm/s)
% distance to screen (cm)
theta_deg = 90-AngleFromCentreDeg; % convert to theta from perpendicular

theta_rad = deg2rad(theta_deg); % convert angle to radians

dtheta_dt = ((cos(theta_rad).^2)./dist).*dx_dt;
w_deg = rad2deg(dtheta_dt);

end



