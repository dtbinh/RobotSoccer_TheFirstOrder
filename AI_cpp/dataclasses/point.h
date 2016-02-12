#ifndef POINT_H
#define POINT_H

#include <string>
#include <cstddef>

enum robotType {ally1_rt, ally2_rt, enemy1_rt, enemy2_rt, none_rt};

class Point
{
public:
    double x;
    double y;
    //Point Functions
    Point(): x(0), y(0) {}
    Point(double x, double y): x(x), y(y) {}
    std::string toString();
};

#endif // POINT_H