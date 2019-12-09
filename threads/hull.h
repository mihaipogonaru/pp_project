#define UP 1
#define DOWN -1

struct Line;

struct Point {
    double x, y;

    Point(): x(0), y(0) {}
    Point(double x, double y) : x(x), y(y) {}
    Point& operator=(Point const &other) = default;

    bool operator==(Point const& other) const;
    bool operator<(Point const& other) const;

    double distance_to_line(Line const& line) const;
};

struct Line {
    double a, b, c; // a*x + b*y + c
    Line (Point const& p1, Point const& p2);
};
