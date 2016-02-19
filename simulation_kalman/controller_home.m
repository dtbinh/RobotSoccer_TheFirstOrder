% main control code 
%
%
% Modified: 
%   2/11/2014 - R. Beard
%   2/18/2014 - R. Beard
%   2/24/2014 - R. Beard
%   1/4/2016  - R. Beard
%   2/11/2016 - R. Beard - added Kalman filter
%   2/17/2016 - R. Beard - added compensation for camera delay
%

% this first function catches simulink errors and displays the line number
function v_c=controller_home(uu,P)
    try
        v_c=controller_home_(uu,P);
    catch e
        msgString = getReport(e);
        fprintf(2,'\n%s\n',msgString);
        rethrow(e);
    end
end

% main control function
function out=controller_home_(uu,P)
    [robot, opponent, ball, t] = utility_process_input(uu,P);
    
    persistent v_command
    if t==0,
        v_command = [zeros(3,1), zeros(3,1)];
    end
    
    robot    = utility_kalman_filter_robot(robot,v_command,t,P);
    opponent = utility_kalman_filter_opponent(opponent,t,P);
    ball     = utility_kalman_filter_ball(ball,t,P);

    % robot #1 positions itself behind ball and rushes the goal.
    v1 = play_rush_goal(robot(1), ball, P);
 
    % robot #2 stays on line, following the ball, facing the goal
    v2 = skill_follow_ball_on_line(robot(2), ball, -2*P.field_width/3, P);

    
    % output velocity commands to robots
    v1 = utility_saturate_velocity(v1,P);
    v2 = utility_saturate_velocity(v2,P);
    v_command = [v1, v2];
    %out = [v1; v2];    
    out = [v1; v2; ball.position; reshape(ball.S(1:2,1:2),4,1)]; % uncomment to show ball estimate
    %out = [v1; v2; opponent(1).position; reshape(opponent(1).S(1:2,1:2),4,1)]; % uncomment to show opponent  estimate
    %out = [v1; v2; robot(1).position; reshape(robot(1).S(1:2,1:2),4,1)]; % uncomment to show robotestimate
end

%-----------------------------------------
% play - rush goal
%   - go to position behind ball
%   - if ball is between robot and goal, go to goal
% NOTE:  This is a play because it is built on skills, and not control
% commands.  Skills are built on control commands.  A strategy would employ
% plays at a lower level.  For example, switching between offense and
% defense would be a strategy.
function v = play_rush_goal(robot, ball, P)
  
  % normal vector from ball to goal
  n = P.goal-ball.position;
  n = n/norm(n);
  % compute position 10cm behind ball, but aligned with goal.
  position = ball.position - 0.2*n;
    
  if norm(position-robot.position)<.21,
      v = skill_go_to_point(robot, P.goal, P);
  else
      v = skill_go_to_point(robot, position, P);
  end

end

%-----------------------------------------
% skill - follow ball on line
%   follows the y-position of the ball, while maintaining x-position at
%   x_pos.  Angle always faces the goal.

function v=skill_follow_ball_on_line(robot, ball, x_pos, P)

    % control x position to stay on current line
    vx = -P.control_k_vx*(robot.position(1)-x_pos);
    
    % control y position to match the ball's y-position
    vy = -P.control_k_vy*(robot.position(2)-ball.position(2));

    % control angle to -pi/2
    theta_d = atan2(P.goal(2)-robot.position(2), P.goal(1)-robot.position(1));
    omega = -P.control_k_phi*(robot.angle - theta_d); 
    
    v = [vx; vy; omega];
end

%-----------------------------------------
% skill - go to point
%   follows the y-position of the ball, while maintaining x-position at
%   x_pos.  Angle always faces the goal.

function v=skill_go_to_point(robot, point, P)

    % control x position to stay on current line
    vx = -P.control_k_vx*(robot.position(1)-point(1));
    
    % control y position to match the ball's y-position
    vy = -P.control_k_vy*(robot.position(2)-point(2));

    % control angle to -pi/2
    theta_d = atan2(P.goal(2)-robot.position(2), P.goal(1)-robot.position(1));
    omega = -P.control_k_phi*(robot.angle - theta_d); 
    
    v = [vx; vy; omega];
end

%------------------------------------------
% utility - process input and create robot, opponent, ball structures
%
function [robot, opponent, ball, t] = utility_process_input(uu,P)
    persistent old_robot_position_camera
    persistent old_robot_angle_camera 
    persistent old_opponent_position_camera
    persistent old_opponent_angle_camera 
    persistent old_ball_position_camera
    % current time
    t = uu(end);
    % initialize persistent variables. These are used to detect new 
    %   camera measurements
    if t==0,  
        old_robot_position_camera    = -999*ones(2,P.num_robots);
        old_robot_angle_camera       = -999*ones(1,P.num_robots);
        old_opponent_position_camera = -999*ones(2,P.num_robots);
        old_opponent_angle_camera    = -999*ones(1,P.num_robots);
        old_ball_position_camera     = -999*ones(2,1);
    end        
    % robots - own team
    for i=1:P.num_robots,
        % measurements from camera
        position_camera = [uu(1+3*(i-1));uu(2+3*(i-1))];
        angle_camera = uu(3+3*(i-1));
        % update measurements to current input if
        %  the camera measurements have changed
        % 
        if (max(position_camera~=old_robot_position_camera(:,i)))...
            | (angle_camera~=old_robot_angle_camera(i)),
                robot(i).position_camera = position_camera;
                robot(i).angle_camera = angle_camera;
                robot(i).camera_flag = 1;
        else 
                robot(i).camera_flag = 0;
         end
     end
    NN = 3*P.num_robots;
    % robots - opponent
    for i=1:P.num_robots,
        % measurements from camera
        position_camera = [uu(1+3*(i-1)+NN); uu(2+3*(i-1)+NN)];
        angle_camera = uu(3+3*(i-1)+NN);
        % update measurements to current input if
        %  the camera measurements have changed
        % 
        if (max(position_camera~=old_opponent_position_camera(:,i)))...
            | (angle_camera~=old_opponent_angle_camera(i)),
                opponent(i).position_camera = position_camera;
                opponent(i).angle_camera = angle_camera;
                opponent(i).camera_flag = 1;
        else 
                opponent(i).camera_flag = 0;
         end
     end

    NN = NN + 3*P.num_robots;
    % ball
    position_camera = [uu(1+NN);uu(2+NN)];
    if (max(position_camera~=old_ball_position_camera)),
            ball.position_camera = position_camera;
            ball.camera_flag = 1;
    else 
            ball.camera_flag = 0;
    end
    NN = NN + 2;
    % score: own team is score(1), opponent is score(2)
    score = [uu(1+NN); uu(2+NN)];
    NN = NN + 2;
    % current time
    %t      = uu(1+NN);
end


%------------------------------------------
% utility - saturate_velocity
% 	saturate the commanded velocity 
%
function v = utility_saturate_velocity(v,P)
    if v(1) >  P.robot_max_vx,    v(1) =  P.robot_max_vx;    end
    if v(1) < -P.robot_max_vx,    v(1) = -P.robot_max_vx;    end
    if v(2) >  P.robot_max_vy,    v(2) =  P.robot_max_vy;    end
    if v(2) < -P.robot_max_vy,    v(2) = -P.robot_max_vy;    end
    if v(3) >  P.robot_max_omega, v(3) =  P.robot_max_omega; end
    if v(3) < -P.robot_max_omega, v(3) = -P.robot_max_omega; end
end

%------------------------------------------
% utility - kalman filter for own team
%
function robot = utility_kalman_filter_robot(robot,v_command,t,P)
    persistent xhat
    persistent S
    for n=1:P.num_robots,    
        if t==0,  % initialize filter
            xhat(:,n) = [...
                0;... % initial guess at x-position of ownteam i
                0;... % initial guess at y-position of ownteam i
                0;... % initial guess at angle of ownteam i
                ];
        S(:,:,n) = diag([...
            P.field_width/2;... % initial variance of x-position of ownteam i
            P.field_width/2;... % initial variance of y-position of ownteam i 
            (5*pi/180)^2;... % initial variance of angle of ownteam i 
            ]);
        end
    
        % prediction step between measurements
        N = 10;
        for i=1:N,
            f = v_command(:,n);
            xhat(:,n) = xhat(:,n) + (P.control_sample_rate/N)*f;
            S(:,:,n) = S(:,:,n) + (P.control_sample_rate/N)*(P.Q_ownteam);
        end
 
        % correction step at measurement
        if robot(n).camera_flag,  % only update when the camera flag is one indicating a new measurement
            y_pred = xhat(:,n);  % predicted measurement
            L = S(:,:,n)/(P.R_ownteam+S(:,:,n));
            S(:,:,n) = (eye(3)-L)*S(:,:,n);
            xhat(:,n) = xhat(:,n) + L*( [robot(n).position_camera;robot(n).angle_camera]-y_pred);
        end
    
        % output current estimate of state
        robot(n).position = xhat(1:2,n);
        robot(n).angle    = xhat(3,n);
        robot(n).S        = S(:,:,n);
    end    
end

%------------------------------------------
% utility - kalman filter for opponent team
%
function opponent = utility_kalman_filter_opponent(opponent,t,P)
    persistent xhat
    persistent xhat_delayed
    persistent S
    persistent S_delayed
    for n=1:P.num_robots,    
        if t==0,  % initialize filter
            xhat(:,n) = [...
                0;... % initial guess at x-position of opponent i
                0;... % initial guess at y-position of opponent i
                0;... % initial guess at angle of opponent i
                0;... % initial guess at x-velocity of opponent i
                0;... % initial guess at y-velocity of opponent i
                0;... % initial guess at angular velocity of opponent i
                0;... % initial guess at x-acceleration of opponent i
                0;... % initial guess at y-acceleration of opponent i
                0;... % initial guess at angular acceleration of opponent i
                ];
            xhat_delayed(:,n)=xhat(:,n);
            S(:,:,n) = diag([...
                P.field_width/2;... % initial variance of x-position of opponent i
                P.field_width/2;... % initial variance of y-position of opponent i 
                (5*pi/180)^2;... % initial variance of angle of opponent i 
                .01;... % initial variance of x-velocity of opponent i 
                .01;... % initial variance of y-velocity of opponent i
                .01;... % initial variance of angular velocity of opponent i
                .001;... % initial variance of x-acceleration of opponent i 
                .001;... % initial variance of y-acceleration of opponent i
                .001;... % initial variance of angular acceleration of opponent i
                ]);
            S_delayed(:,:,n)=S(:,:,n);
        end
    
        % prediction step between measurements
        N = 10;
        for i=1:N,
            xhat(:,n) = xhat(:,n) + (P.control_sample_rate/N)*P.A_opponent*xhat(:,n);
            S(:,:,n) = S(:,:,n) + (P.control_sample_rate/N)*(P.A_opponent*S(:,:,n)+S(:,:,n)*P.A_opponent'+P.Q_opponent);
        end
 
        % correction step at measurement
        if opponent(n).camera_flag, % only update when the camera flag is one indicating a new measurement
            % case 1 does not compensate for camera delay
            % case 2 compensates for fixed camera delay
            switch 2
                case 1,
                    y = [opponent(n).position_camera;opponent(n).angle_camera]; % measurement
                    y_pred = P.C_opponent*xhat(:,n);  % predicted measurement
                    L = S(:,:,n)*P.C_opponent'/(P.R_opponent+P.C_opponent*S(:,:,n)*P.C_opponent');
                    S(:,:,n) = (eye(9)-L*P.C_opponent)*S(:,:,n);
                    xhat(:,n) = xhat(:,n) + L*(y-y_pred);
                case 2,
                    y = [opponent(n).position_camera;opponent(n).angle_camera]; % measurement
                    y_pred = P.C_opponent*xhat_delayed(:,n);  % predicted measurement
                    L = S_delayed(:,:,n)*P.C_opponent'/(P.R_opponent+P.C_opponent*S_delayed(:,:,n)*P.C_opponent');
                    S_delayed(:,:,n) = (eye(9)-L*P.C_opponent)*S_delayed(:,:,n);
                    xhat_delayed(:,n) = xhat_delayed(:,n) + L*(y-y_pred);
                    for i=1:N*(P.camera_sample_rate/P.control_sample_rate),
                        xhat_delayed(:,n) = xhat_delayed(:,n) + (P.control_sample_rate/N)*(P.A_opponent*xhat_delayed(:,n));
                        S_delayed(:,:,n) = S_delayed(:,:,n) + (P.control_sample_rate/N)*(P.A_opponent*S_delayed(:,:,n)+S_delayed(:,:,n)*P.A_opponent'+P.Q_opponent);
                    end
                    xhat(:,n) = xhat_delayed(:,n);
                    S(:,:,n)    = S_delayed(:,:,n);
            end
        end
    
        % output current estimate of state
        opponent(n).position         = xhat(1:2,n);
        opponent(n).angle            = xhat(3,n);
        opponent(n).velocity         = xhat(4:5,n);
        opponent(n).angular_velocity = xhat(6,n);
        opponent(n).S                = S(:,:,n);
    end
end

%------------------------------------------
% utility - kalman filter for ball
%
function ball = utility_kalman_filter_ball(ball,t,P)
    persistent xhat
    persistent xhat_delayed
    persistent S
    persistent S_delayed
    
    if t==0,  % initialize filter
        xhat = [...
            0;... % initial guess at x-position of ball
            0;... % initial guess at y-position of ball
            0;... % initial guess at x-velocity of ball
            0;... % initial guess at y-velocity of ball
            0;... % initial guess at x-acceleration of ball
            0;... % initial guess at y-acceleration of ball
            0;... % initial guess at x-jerk of ball
            0;... % initial guess at y-jerk of ball
            ];
        xhat_delayed = xhat;
        S = diag([...
            P.field_width/2;... % initial variance of x-position of ball
            P.field_width/2;... % initial variance of y-position of ball 
            .01;... % initial variance of x-velocity of ball 
            .01;... % initial variance of y-velocity of ball
            .001;... % initial variance of x-acceleration of ball 
            .001;... % initial variance of y-acceleration of ball
            .0001;... % initial variance of x-jerk of ball 
            .0001;... % initial variance of y-jerk of ball
            ]);
        S_delayed=S;
    end
    
    % prediction step between measurements
    N = 10;
    for i=1:N,
        xhat = xhat + (P.control_sample_rate/N)*P.A_ball*xhat;
        S = S + (P.control_sample_rate/N)*(P.A_ball*S+S*P.A_ball'+P.Q_ball);
    end
 
    % correction step at measurement
    if ball.camera_flag, % only update when the camera flag is one indicating a new measurement
        % case 1 does not compensate for camera delay
        % case 2 compensates for fixed camera delay
        switch 2
            case 1,
                y = ball.position_camera; % actual measurement
                y_pred = P.C_ball*xhat;  % predicted measurement
                L = S*P.C_ball'/(P.R_ball+P.C_ball*S*P.C_ball');
                S = (eye(8)-L*P.C_ball)*S;
                xhat = xhat + L*(y-y_pred);
            case 2,
                y = ball.position_camera; % actual measuremnt
                y_pred = P.C_ball*xhat_delayed;  % predicted measurement
                L = S_delayed*P.C_ball'/(P.R_ball+P.C_ball*S_delayed*P.C_ball');  
                S_delayed = (eye(8)-L*P.C_ball)*S_delayed;
                xhat_delayed = xhat_delayed + L*(y-y_pred);
                for i=1:N*(P.camera_sample_rate/P.control_sample_rate),
                    xhat_delayed = xhat_delayed + (P.control_sample_rate/N)*(P.A_ball*xhat_delayed);
                    S_delayed = S_delayed + (P.control_sample_rate/N)*(P.A_ball*S_delayed+S_delayed*P.A_ball'+P.Q_ball);
                end
                xhat = xhat_delayed;
                S    = S_delayed;
        end
    end
    
    % output current estimate of state
    ball.position     = xhat(1:2);
    ball.velocity     = xhat(3:4);
    ball.acceleration = xhat(5:6);
    ball.jerk         = xhat(7:8);
    ball.S            = P.S_ball;
end

  