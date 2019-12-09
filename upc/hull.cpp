#include <iostream>
#include <fstream>
#include <string>
#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>
#include <set>

#include "hull.hpp"

using namespace std; 

bool Point::operator==(const Point &other) const
{
    return x == other.x && y == other.y;
}

bool Point::operator<(const Point &other) const 
{
    if (x == other.x)
       return y < other.y;
    return x < other.x;
}

double Point::distance_to_line(Line const& line) const
{
    double point = abs(line.a * x + line.b * y + line.c);
    return point / sqrt(line.a * line.a + line.b * line.b);
} 

istream& operator>>(istream& is, Point& point)
{
    return is >> point.x >> point.y;
}

ostream& operator<<(ostream& os, const Point& point)
{
    return os << point.x << " " << point.y;
}

Line::Line (Point const& p1, Point const& p2)
{
    a = p1.y - p2.y;
    b = p2.x - p1.x;
    c = p1.x * p2.y - p1.y * p2.x;
}

vector<Point> results;

double get_distance_between_point_and_line(Point const& p, Point const& p1, Point const& p2)
{ 
    Line line(p1, p2);
    return p.distance_to_line(line);
} 

int find_side_of_point(Point const& p, Point const& p1, Point const& p2)
{ 
    long long val = (p.x - p1.x) * (p2.y - p1.y) -
                    (p.y - p1.y) * (p2.x - p1.x);

    if (val > 0)
        return UP;

    if (val < 0)
        return DOWN;

    return 0;
}

Point* get_farthest_point(vector<Point> &points, Point const& point_min, Point const& point_max, int side)
{
    double max_distance = 0;
    Point *farthest_point = new Point;

    for (Point point : points) {
        if (find_side_of_point(point, point_min, point_max) != side)
            continue;

        double distance =
                get_distance_between_point_and_line(point, point_min, point_max);

        if (distance > max_distance) {
            max_distance = distance;
            *farthest_point = point;
        }
    }

    if (max_distance > 0) 
        return farthest_point;

    delete farthest_point;
    return NULL;
}

double sign(Point const& p1, Point const& p2, Point const& p3)
{
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

bool point_is_in_triangle(Point const& point, Point const& p1, Point const& p2, Point const& p3)
{
    double d1, d2, d3;
    bool has_neg, has_pos;

    d1 = sign(point, p1, p2);
    d2 = sign(point, p2, p3);
    d3 = sign(point, p3, p1);

    has_neg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    has_pos = (d1 > 0) || (d2 > 0) || (d3 > 0);

    return !(has_neg && has_pos);
}

void quick_hull_helper(vector<Point> &points, Point const& point_min, Point const& point_max)
{
    if (points.empty())
        return;

    Point *pu = get_farthest_point(points, point_min, point_max, UP);
    Point *pb = get_farthest_point(points, point_min, point_max, DOWN);

    if (pu != NULL) {
        results.push_back(*pu);

        points.erase(
                std::remove_if(
                        points.begin(), points.end(),
                        [=](Point const& point) -> bool {
                            return point == *pu ||
                                    point_is_in_triangle(point, *pu, point_min, point_max);
                        }),
                points.end());
    }

    if (pb != NULL) {
        results.push_back(*pb);

        points.erase(
                std::remove_if(
                        points.begin(), points.end(),
                        [=](Point const& point) -> bool {
                            return point == *pb ||
                                    point_is_in_triangle(point, *pb, point_min, point_max);
                        }),
                points.end());
    }

    if (points.empty())
        return;

    if (pu != NULL) {
        quick_hull_helper(points, *pu, point_min);
        quick_hull_helper(points, *pu, point_max);
        delete pu;
    }

    if (pb != NULL) {
        quick_hull_helper(points, *pb, point_min);
        quick_hull_helper(points, *pb, point_max);
        delete pb;
    }
}

void quick_hull(vector<Point> &points)
{
    long long x_min = numeric_limits<long long>::max();
    long long x_max = numeric_limits<long long>::min();

    Point point_min;
    Point point_max;

    for (Point const& point : points) {
        if (point.x < x_min) {
            x_min = point.x;
            point_min = point;
        }

        if (point.x > x_max) {
            x_max = point.x;
            point_max = point;
        }
    }

    std::copy_if(points.begin(), points.end(), std::back_inserter(results),
            [=](Point const& point) -> bool {
                return point.x == x_max || point.x == x_min;
            });

    points.erase(
            std::remove_if(
                    points.begin(), points.end(),
                    [=](Point const& point) -> bool {
                        return point.x == x_max || point.x == x_min;
                    }),
            points.end());

    quick_hull_helper(points, point_min, point_max);
}

void print_points(struct CPoint const *cpoints, size_t len)
{
    vector<Point> points(cpoints, cpoints + len);

    for (Point const& point : points)
        cout << point << endl;
}

void generate_random_points(unsigned points_length, string file)
{
    long long x, y;
    ofstream f(file);
    set<Point> points;

    while (points.size() != points_length) {
        x = rand();
        y = rand();

        auto p = points.insert(Point(x, y));
        if (p.second)
            f << x <<  " " << y << endl;
    }
}

void read_points(vector<Point> &points, string file)
{
    Point p;
    ifstream f(file);

    while (f >> p)
        points.push_back(p);
}