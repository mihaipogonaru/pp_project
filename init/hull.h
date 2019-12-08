#define UP 1
#define DOWN -1

struct Line;

struct Point 
{ 
    int x, y;

    Point(): x(0), y(0) {}

    Point(int x, int y) : x(x), y(y) {}

    bool operator<(const Point &other) const;
    double distance_to_line(Line &line) const;
};

struct Line
{
    int a, b, c; // a*x + b*y + c
    Line (Point &p1, Point &p2);
};
