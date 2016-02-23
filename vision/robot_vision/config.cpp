#include "config.h"

namespace config {

cv::Point2f fieldCenter_px;
double cmPerPixelConversionFactor;
bool invertX;

int cropTop;
int cropBottom;
int cropLeft;
int cropRight;

HsvColorSubSpace ballColor;
int ballArea;

int teamRobotCount;
HsvColorSubSpace teamRobotPrimaryColor;
int teamRobotLargeArea;
int teamRobotSmallArea;

int opponentRobotCount;
HsvColorSubSpace opponentRobotPrimaryColor;
int opponentRobotLargeArea;
int opponentRobotSmallArea;

const HsvColorSubSpace green({60,90},{30,145},{180,255});
const HsvColorSubSpace blue({80,100},{30,235},{170,255});
const HsvColorSubSpace purple({120,140},{30,90},{200,250});
const HsvColorSubSpace red({175,179},{30,200},{200,255});
const HsvColorSubSpace orange({0,30},{50,190},{150,255});
const HsvColorSubSpace pink({140,175},{30,150},{200,255});
const HsvColorSubSpace yellow({10,45},{0,90},{225,255});


std::string cameraUrl;

} // namespace config
