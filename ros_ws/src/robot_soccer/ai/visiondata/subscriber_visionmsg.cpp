#include "subscriber_visionmsg.h"

void visionCallback(const robot_soccer::visiondata& msg){
    visionStatus_msg = msg;
    vision_msg = msg;
    visionUpdated = true;
}
