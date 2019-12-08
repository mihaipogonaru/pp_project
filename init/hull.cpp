#include <set>
#include <iostream>
#include <limits>
#include <cmath>

#include "hull.h"

using namespace std; 

bool Point::operator<(const Point &other) const 
{
    if (x == other.x)
       return y < other.y;
    return x < other.x;
}

double Point::distance_to_line(Line &line) const
{
    double point = abs(line.a * x + line.b * y + line.c);
    return point / sqrt(line.a * line.a + line.b * line.b);
} 

Line::Line (Point &p1, Point &p2)
{
    a = p1.y - p2.y;
    b = p2.x - p1.x;
    c = (-b) * p1.y + (-a) * p1.x;
}

ostream& operator<<(ostream& os, const Point& point)
{
        return os << point.x << " " << point.y;
}

set<Point> results;

void generate_random_points(set<Point> &points, int points_length)
{
    int x, y;

    while(points.size() != points_length) {
        x = rand();
        y = rand();

        points.insert(Point(x, y));
    }

}


void print_points(set<Point> points)
{
    for (Point const& point : points) 
        cout << point << endl; 
}


double get_distance_between_point_and_line(Point p1, Point p2, Point p) 
{ 
    //Line line(p1, p2);
    //return p.distance_to_line(line);
    return abs((p.y - p1.y) * (p2.x - p1.x) - 
               (p2.y - p1.y) * (p.x - p1.x));
} 


int find_side_of_point(Point p1, Point p2, Point p) 
{ 
    int val = (p.y - p1.y) * (p2.x - p1.x) - 
              (p2.y - p1.y) * (p.x - p1.x); 
  
    if (val > 0) 
        return UP; 
    
    if (val < 0) 
        return DOWN;

    return 0; 
}


Point* get_farthest_point(set<Point> points, Point point_min,
    Point point_max, int side)
{
    Point *farthest_point = new Point;
    double max_distance = 0;

    for (Point point : points) {
        if (find_side_of_point(point_min, point_max, point) != side)
            continue;


        double distance = get_distance_between_point_and_line(point_min,
                          point_max, point);


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


float sign (Point p1, Point p2, Point p3)
{
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}


bool point_is_in_triangle (Point point, Point p1, Point p2, Point p3)
{
    float d1, d2, d3;
    bool has_neg, has_pos;

    d1 = sign(point, p1, p2);
    d2 = sign(point, p2, p3);
    d3 = sign(point, p3, p1);

    has_neg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    has_pos = (d1 > 0) || (d2 > 0) || (d3 > 0);

    return !(has_neg && has_pos);
}


void quick_hull_helper(set<Point> &points, Point point_min, Point point_max)
{
    if (points.empty())
        return;

    Point *pu = get_farthest_point(points, point_min, point_max, UP);
    Point *pb = get_farthest_point(points, point_min, point_max, DOWN);


    if (pu != NULL) {
        results.insert(*pu);
        points.erase(*pu);

        for (Point const& point : points) {
            if (point_is_in_triangle(point, *pu, point_min, point_max))
                points.erase(point);
        }
    }

    if (pb != NULL) {
        results.insert(*pb);
        points.erase(*pb);

        for (Point const& point : points) {
            if (point_is_in_triangle(point, *pb, point_min, point_max))
                points.erase(point);
        }
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


void quick_hull(set<Point> &points)
{
    int x_min = numeric_limits<int>::max();
    int x_max = numeric_limits<int>::min();
    
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

    for (Point const& point : points) {
        if (point.x == x_min) {
            results.insert(point);
            continue;
	}

        if (point.x == x_max) {
            results.insert(point);
        }
    }

    for (auto &point : results) {
        points.erase(point);
    }

    cout << "HELP" << endl;
    quick_hull_helper(points, point_min, point_max);

}

  
int main(int argc, char **argv) 
{
    int points_length;
    set<Point> points;

    if (argc != 2) {
        cout << "Please give one argument (the number of random points \
                    that will be generated)" << endl;
        exit(-1);
    }

    points_length = atoi(argv[1]);

    cout << points_length << endl;
    generate_random_points(points, points_length);
    cout << "GEN" << endl;
    quick_hull(points);
    cout << "QUICK" << endl;
    print_points(results);

    return 0; 
} 
