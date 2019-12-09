#include <stddef.h>

/* C API */
#ifdef __cplusplus
extern "C" {
#endif

struct CPoint {
    double x, y;
};

void remove_points_in_triangle(struct CPoint *points, long *points_nr,
        struct CPoint p1, struct CPoint p2, struct CPoint p3);

void remove_points_min_max(struct CPoint *points, long *points_nr, double min, double max);

#ifdef __cplusplus
}
#endif /* __cplusplus */

/* C++ only */
#ifdef __cplusplus
#define UP 1
#define DOWN -1

struct Line;

struct Point {
    double x, y;

    Point(): x(0), y(0) {}
    Point(double x, double y) : x(x), y(y) {}
    Point(CPoint const& cpoint): x(cpoint.x), y(cpoint.y) {}
    Point& operator=(Point const &other) = default;

    bool operator==(Point const& other) const;
    bool operator<(Point const& other) const;

    double distance_to_line(Line const& line) const;
};

struct Line {
    double a, b, c; // a*x + b*y + c
    Line (Point const& p1, Point const& p2);
};
#endif /* __cplusplus */
