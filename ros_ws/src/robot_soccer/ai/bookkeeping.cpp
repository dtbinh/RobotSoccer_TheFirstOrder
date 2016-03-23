#include "bookkeeping.h"

//## FIELD INFO & OBJECTS ##//
Point center(0,0);
Point enemyGoal(GOAL_XLOCATION,0);
Point allyGoal(-GOAL_XLOCATION,0);
Point start1Location(-40,0);
Point start2Location(-40,0);
FieldCoord field;


//## VISION DATA ##//
bool visionUpdated;
robot_soccer::visiondata vision_msg;
GameStatus visionStatus_msg;

//## CONTROL DATA ##//
bool sendCmd_Rob1(true);
bool sendCmd_Rob2(false);
robot_soccer::controldata cmdRob1;
robot_soccer::controldata cmdRob2;

//## DEBUG DATA ##//
bool newDebugCmd = false;
robot_soccer::controldata debugCmd;


//## FILTER DATA ##//
GameStatus predicted;
bool predictedUpdated(false);

//#### FIELDGET FUNCTIONS ####//
FieldObject* fieldget::getBall(){
    return &field.currentStatus.ball;
}

Point fieldget::getBallLoc(){
    return field.currentStatus.ball.location;
}

Robot* fieldget::getRobot(robotType type){
    Robot *rob;
    switch(type){
        case robotType::ally1:
            rob = &field.currentStatus.ally1;
            break;
        case robotType::ally2:
            rob = &field.currentStatus.ally2;
            break;
        case robotType::enemy1:
            rob = &field.currentStatus.enemy1;
            break;
        case robotType::enemy2:
            rob = &field.currentStatus.enemy2;
            break;
        default:
            printf("bookkeeping:atLocation:: ERR you didn't provide a valid robot\n");
            break;
    }
    return rob;
}

Point fieldget::getRobotLoc(robotType type){
    return fieldget::getRobot(type)->location;
}


//#### BOOK KEEPING CALC FUNCTIONS ####//
bool bkcalc::atLocation(robotType type, Point point){
    bool atlocation = false;
    switch(type){
        case robotType::ally1:
            atlocation = calc::atLocation(field.currentStatus.ally1.location, point);
            break;
        case robotType::ally2:
            atlocation = calc::atLocation(field.currentStatus.ally2.location, point);
            break;
        default:
            printf("bookkeeping:atLocation:: ERR you didn't provide a valid robot\n");
            break;
    }
    return atlocation;
}

bool bkcalc::ballKicked(robotType type, Point kp){
    bool ballkicked = false;
    switch(type){
        case robotType::ally1:
            ballkicked = calc::ballKicked(field.currentStatus.ally1, kp);
            break;
        case robotType::ally2:
            ballkicked = calc::ballKicked(field.currentStatus.ally2, kp);
            break;
        default:
            printf("bookkeeping:ballKicked: ERR you didn't provide a valid robot\n");
            break;
    }
    return ballkicked;
}

bool bkcalc::ballFetched(robotType type){
    bool ballfetched = false;
    switch(type){
        case robotType::ally1:
            ballfetched = calc::ballFetched(field.currentStatus.ally1, field.currentStatus.ball);
            std::cout << "ROBOT1" << std::endl;
            break;
        case robotType::ally2:
            ballfetched = calc::ballFetched(field.currentStatus.ally2, field.currentStatus.ball);
            break;
        default:
            printf("bookkeeping:ballfetched: ERR you didn't provide a valid robot %d\n", type);
            break;
    }
    return ballfetched;
}

bool bkcalc::ballKickZone(robotType type){
    bool ballkickZone = false;
    Point ball = field.currentStatus.ball.location;
    switch(type){
        case robotType::ally1:
        {
            std::cout << "ballkickZone::ally1" << std::endl;
            Point perCenter(field.currentStatus.ally1.location.x+PERIMETER_XOFFSET,field.currentStatus.ally1.location.y);
            ballkickZone = calc::withinPerimeter(perCenter, ball);
            break;
        }
        case robotType::ally2:
            std::cout << "ballkickZone::ally2" << std::endl;
            ballkickZone = calc::withinPerimeter(field.currentStatus.ally2.location, ball);
            break;
        default:
            printf("bookkeeping:atLocation:: ERR you didn't provide a valid robot\n");
            break;
    }
    return ballkickZone;
}

double bkcalc::getAngleTo(robotType type, Point point){
    Point dir;
    switch(type){
        case robotType::ally1:
            dir = calc::directionToPoint(field.currentStatus.ally1.location, point);
            break;
        case robotType::ally2:
            dir = calc::directionToPoint(field.currentStatus.ally2.location, point);
            break;
        default:
            printf("bookkeeping:getAngleTo: ERR you didn't provide a valid robot %d\n", type);
            break;
    }
    return calc::getVectorAngle(dir);
}

Point bkcalc::kickPoint(robotType type){
    Point result;
    /*Point kickerLoc;
    Point dir;
    switch(type){
        case robotType::ally1:
            kickerLoc = field.currentStatus.ally1.location;
            break;
        case robotType::ally2:
            kickerLoc = field.currentStatus.ally2.location;
            break;
        default:
            printf("bookkeeping:ballfetched: ERR you didn't provide a valid robot\n");
            break;
    }
    dir = calc::directionToPoint(kickerLoc,field.currentStatus.ball.location);
    result = Point(kickerLoc.x+KICK_FACTOR*dir.x,kickerLoc.y+KICK_FACTOR*dir.y);*/
    result = field.currentStatus.ball.location;
    if(!calc::withinField(result)){
        result = calc::getNewPoint(result);
    }
    return result;
}

bool bkcalc::ballAimed(robotType type){
    Robot* kicker;
    switch(type){
        case robotType::ally1:
            kicker = &field.currentStatus.ally1;
            break;
        case robotType::ally2:
            kicker = &field.currentStatus.ally2;
            break;
        default:
            printf("bookkeeping:ballfetched: ERR you didn't provide a valid robot\n");
            break;
    }
    return calc::ballAimed(*kicker, field.currentStatus.ball, enemyGoal);
}

bool bkcalc::ballThreat(){
//   std::cout << "####bkcalc::ballThreat####" << std::endl;
return ((field.currentStatus.ball.velocity.x < 0 && field.currentStatus.ball.location.x < 0));
}