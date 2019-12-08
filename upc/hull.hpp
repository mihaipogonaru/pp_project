#include <stddef.h>

/* C API */
#ifdef __cplusplus
extern "C" {
#endif

struct CPoint {
    long long x, y;
};

void print_points(struct CPoint const *cpoints, size_t len);

#ifdef __cplusplus
}
#endif /* __cplusplus */

/* C++ only */
#ifdef __cplusplus
#define UP 1
#define DOWN -1

struct Line;

struct Point {
    long long x, y;

    Point(): x(0), y(0) {}
    Point(long long x, long long y) : x(x), y(y) {}
    Point(CPoint const& cpoint): x(cpoint.x), y(cpoint.y) {}
    Point& operator=(Point const &other) = default;

    bool operator==(Point const& other) const;
    bool operator<(Point const& other) const;

    double distance_to_line(Line const& line) const;
};

struct Line {
    long long a, b, c; // a*x + b*y + c
    Line (Point const& p1, Point const& p2);
};
#endif /* __cplusplus */
