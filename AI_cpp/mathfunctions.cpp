#include "mathfunctions.h"

Point calc::directionToPredict(FieldObject startobj, FieldObject destobj, double time){
    return calc::directionToPoint(startobj.location,
                                  calc::predictLocation(destobj, time));
}

Point calc::directionToPoint(Point startobj, Point destobj){
    return Point(destobj.x - startobj.x,
                 destobj.y - startobj.y);
}


Point calc::predictLocation(FieldObject myobj, double time){
    return Point(myobj.location.x + myobj.velocity.x*time,
                 myobj.location.y + myobj.velocity.y*time);
}

double calc::angleDifference(double currentTheta, double desiredTheta){
    double angle = currentTheta - desiredTheta;
    if (angle < -180) {
        angle = -(360-abs(angle));
    } else if (angle > 180) {
        angle = 360 - angle;
    } else {
        angle = -angle;
    }
    return angle;
}

Point calc::getVelocity(FieldObject newobj, FieldObject oldobj){
    double x_vel = newobj.location.x - oldobj.location.x;
    double y_vel = newobj.location.y - oldobj.location.y;
    return Point(x_vel, y_vel);
}

double calc::radToDeg(double radians){
    return(radians*180)/PI;
}

double calc::getVectorAngle(Point vector){
    //need to first determine quadrant
    double vecAngle = 0;
    //top
    if(vector.y >= 0){
         //top right
         if(vector.x > 0){
            vecAngle = calc::radToDeg(atan2(vector.y, vector.x));
         }else{//top left
            vecAngle = calc::radToDeg(atan2(vector.y, vector.x));
         }
    }else {//bottom quadrant
         //bottom right
         if(vector.x > 0){
            vecAngle = 360+calc::radToDeg(atan2(vector.y, vector.x));
         }else{//bottom left
            vecAngle = 360+calc::radToDeg(atan2(vector.y, vector.x));
         }
    }
    return vecAngle;
}

//####PLAY THRESHOLD FUNCTIONS####//
bool calc::atLocation(Point robot, Point point){
    if(robot.x != robot.x && robot.y != robot.y){return false;}
    double xValues = robot.x-point.x;
    xValues *= xValues;
    double yValues = robot.y-point.y;
    yValues *= yValues;
    double distance_sqrd = xValues+yValues;
    //std::cout << "distance_sqrd == " << distance_sqrd << std::endl;
    if(distance_sqrd > DISTANCE_ERR)
        return false;
    else
        return true;
}

bool calc::atLocation(double robot_coord, double p_coord){
    double distance_sqrd = robot_coord - p_coord;
    distance_sqrd *= distance_sqrd;
    if(distance_sqrd > DISTANCE_ERR)
        return false;
    else
        return true;
}

bool calc::ballFetched(Robot ally, FieldObject ball){
    //Point dist = calc::directionToPoint(ally.location, ball.location);
    //ball should be less than 4cm in front of robot x check
    //ball should be in the center of the robot with error of 4
    //angle should be towards the ball
    Point fetchballpoint(ball.location.x-FETCHBALL_OFFSET,ball.location.y);
    return calc::atLocation(ally.location, fetchballpoint);

//    if(dist.x > BALLFETCHED_ERR || dist.y > BALLFETCHED_ERR ||
//            abs(calc::getVectorAngle(dist) - ally.theta) > ANGLE_ERR) {
//        return false;
//    }

}

bool calc::ballAimed(Robot ally, FieldObject ball){
    //for ball to be aimed. the robots angle needs to match
    //the angle created by the ball and the Goal. need to match
    Point oppGoal = Point(40, 0);
    Point allyBallVector = calc::directionToPoint(ally.location, ball.location);
    Point allyGoalVector = calc::directionToPoint(ally.location, oppGoal);
    if(abs(ally.theta - calc::getVectorAngle(allyBallVector)) < ANGLE_ERR ||
            abs(ally.theta - calc::getVectorAngle(allyGoalVector)) < ANGLE_ERR ||
            abs(calc::getVectorAngle(allyBallVector)-calc::getVectorAngle(allyGoalVector)) < ANGLE_ERR){
        return true;
    }else
        return false;
}

bool calc::ballKicked(Robot ally, Point kp){
    return calc::atLocation(ally.location, kp);
}
