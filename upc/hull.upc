#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <upc.h>
#include <upc_strict.h>

#include "hull.h"
#include "hull.hpp"

shared long points_size;
shared long points_per_th;
shared size_t points_bytes;
shared size_t points_bytes_per_th;

/* Remaining number of points per th */
shared long points_nr[THREADS];

/* Points per th */
shared [] struct CPoint * shared points[THREADS];

/* Up/down points per th (the points exchanged at each iteration) */
shared [] struct CPoint * shared points_ud[THREADS][2];

size_t result_nr;
struct CPoint result[2000];

static void print_err_exit(char const *err)
{
    fprintf(stderr, "%s", err);
    upc_global_exit(-1);
}

static inline void add_result(struct CPoint p)
{
    if (result_nr == sizeof(result))
        print_err_exit("Too many result points\n");
        
    result[result_nr++] = p;
    //printf("ADDED %lf %lf\n", result[result_nr - 1].x, result[result_nr - 1].y);
}
static void print_result()
{
    int i;

    for (i = 0; i < result_nr; ++i)
        printf("%0.6lf %0.6lf\n", result[i].x, result[i].y);
}

static int get_points_size(char const *file)
{
    FILE *f;
    char buf[100];
    
    f = fopen(file, "r");
    if (!f)
        return -1;
    
    points_size = 0;
    while (fgets(buf, sizeof(buf), f) != NULL)
        points_size++;

    points_per_th = points_size / THREADS;
    points_bytes = points_size * sizeof(struct CPoint);
    points_bytes_per_th = points_per_th * sizeof(struct CPoint);
    fclose(f);

    return 0;
}

static void alloc_points()
{
    points[MYTHREAD] = upc_alloc(points_bytes_per_th);
    if (!points[MYTHREAD])
        print_err_exit("Error allocating points\n");
    points_nr[MYTHREAD] = points_per_th;
}

static int read_points_and_send(char const *file)
{
    FILE *f;
    int i, j, err = 0;
    struct CPoint * rpoints;

    f = fopen(file, "r");
    if (!f)
        return -1;
    
    rpoints = malloc(points_bytes_per_th);
    if (!rpoints) {
        err = -1;
        goto out;
    }

    for (i = 0; i < THREADS; ++i) {
        for (j = 0; j < points_per_th; ++j)
            fscanf(f, "%lf %lf", &rpoints[j].x, &rpoints[j].y);

        upc_memput(points[i], rpoints, points_bytes_per_th);
    }
    free(rpoints);

out:
    fclose(f);

    return err;
}

static void compute_min_max_point()
{
    int i;
    int min = 0, max = 0;
    
    for (i = 1; i < points_nr[MYTHREAD]; ++i) {
        if (points[MYTHREAD][i].x - points[MYTHREAD][min].x < 0)
            min = i;
        if (points[MYTHREAD][i].x - points[MYTHREAD][max].x > 0)
            max = i;
    }

    points_ud[MYTHREAD][DOWN_I] = &points[MYTHREAD][min];
    points_ud[MYTHREAD][UP_I] = &points[MYTHREAD][max];
}

static void compute_global_min_max()
{
    int i, j;

    /*for (i = 0; i < THREADS; ++i) {
        printf("%lu (%lu): \n", i, points_nr[i]);
        for (j = 0; j < points_nr[i]; ++j)
            printf("(%lf %lf) ", points[i][j].x, points[i][j].y);
        printf("\n");
        if (points_ud[i][0])
            printf("(%lf %lf)\n", points_ud[i][0]->x, points_ud[i][0]->y);
        if (points_ud[i][1])
            printf("(%lf %lf)\n", points_ud[i][1]->x, points_ud[i][1]->y);
    }*/

    for (i = 1; i < THREADS; ++i) {
        if (points_ud[i][DOWN_I] != NULL) {
            if (points_ud[MAIN][DOWN_I] == NULL)
                points_ud[MAIN][DOWN_I] = points_ud[i][DOWN_I];
            else if (points_ud[i][DOWN_I]->x - points_ud[MAIN][DOWN_I]->x < 0)
                points_ud[MAIN][DOWN_I] = points_ud[i][DOWN_I];
        }
        
        if (points_ud[i][UP_I] != NULL) {
            if (points_ud[MAIN][UP_I] == NULL)
                points_ud[MAIN][UP_I] = points_ud[i][UP_I];
            else if (points_ud[i][UP_I]->x - points_ud[MAIN][UP_I]->x > 0)
                points_ud[MAIN][UP_I] = points_ud[i][UP_I];
        }
    }
    
    /*if (points_ud[MAIN][0])
        printf("(%lf %lf)\n", points_ud[MAIN][0]->x, points_ud[MAIN][0]->y);
    if (points_ud[MAIN][1])
        printf("(%lf %lf)\n", points_ud[MAIN][1]->x, points_ud[MAIN][1]->y);
    printf("\n\n");*/
}

static double get_distance_between_point_and_line(
                struct CPoint p,
                struct CPoint p1, 
                struct CPoint p2)
{
    return fabs((p.x - p1.x) * (p2.y - p1.y) -
                (p.y - p1.y) * (p2.x - p1.x));
}

static inline int find_side_of_point(
                struct CPoint p,
                struct CPoint p1, 
                struct CPoint p2)
{ 
    double val = (p.x - p1.x) * (p2.y - p1.y) -
                 (p.y - p1.y) * (p2.x - p1.x);

    if (val > 0)
        return UP;

    if (val < 0)
        return DOWN;

    return 0;
}

static void get_farthest_points(struct CPoint min, struct CPoint max)
{
    int i, side, index[2];
    double distance, max_distance[2];
    
    index[DOWN_I] = index[UP_I] = 0;
    max_distance[DOWN_I] = max_distance[UP_I] = 0;

    for (i = 0; i < points_nr[MYTHREAD]; ++i) {
        side = find_side_of_point(points[MYTHREAD][i], min, max);

        /* If point is on line continue */
        if (side == 0)
            continue;
        /* The function returns -1 for DOWN */
        if (side == DOWN)
            side = DOWN_I;
        else
            side = UP_I;

        distance =
            get_distance_between_point_and_line(points[MYTHREAD][i], min, max);

        if (distance - max_distance[side] > 0) {
            max_distance[side] = distance;
            index[side] = i;
        }
    }

    if (max_distance[DOWN_I] > 0) 
        points_ud[MYTHREAD][DOWN_I] = &points[MYTHREAD][index[DOWN_I]];
    else
        points_ud[MYTHREAD][DOWN_I] = NULL;
        
    if (max_distance[UP_I] > 0) 
        points_ud[MYTHREAD][UP_I] = &points[MYTHREAD][index[UP_I]];
    else
        points_ud[MYTHREAD][UP_I] = NULL;
}

static void get_global_farthest_points(struct CPoint min, struct CPoint max)
{
    int i, j, index[2];
    double distance, max_distance[2];
    
    index[DOWN_I] = index[UP_I] = 0;
    max_distance[DOWN_I] = max_distance[UP_I] = 0;

    /*for (i = 0; i < THREADS; ++i) {
        printf("%lu (%lu): \n", i, points_nr[i]);
        for (j = 0; j < points_nr[i]; ++j)
            printf("(%lf %lf) ", points[i][j].x, points[i][j].y);
        printf("\n");
        if (points_ud[i][0])
            printf("(%lf %lf)\n", points_ud[i][0]->x, points_ud[i][0]->y);
        if (points_ud[i][1])
            printf("(%lf %lf)\n", points_ud[i][1]->x, points_ud[i][1]->y);
    }*/

    for (i = 0; i < THREADS; ++i) {
        for (j = DOWN_I; j<= UP_I; ++j) {
            if (points_ud[i][j]) {
                distance = get_distance_between_point_and_line(*points_ud[i][j],
                                                               min, max);
    
                if (distance - max_distance[j] > 0) {
                    max_distance[j] = distance;
                    index[j] = i;
                }
            }
        }
    }

    if (max_distance[DOWN_I] > 0) 
        points_ud[MAIN][DOWN_I] = points_ud[index[DOWN_I]][DOWN_I];
    else
        points_ud[MAIN][DOWN_I] = NULL;
        
    if (max_distance[UP_I] > 0) 
        points_ud[MAIN][UP_I] = points_ud[index[UP_I]][UP_I];
    else
        points_ud[MAIN][UP_I] = NULL;
        
    /*if (points_ud[MAIN][0])
        printf("(%lf %lf)\n", points_ud[MAIN][0]->x, points_ud[MAIN][0]->y);
    if (points_ud[MAIN][1])
        printf("(%lf %lf)\n", points_ud[MAIN][1]->x, points_ud[MAIN][1]->y);*/
}

static void quickhull_helper(struct CPoint min, struct CPoint max, int side)
{
    int i, sidei;
    struct CPoint point;
    
    get_farthest_points(min, max);
    upc_barrier;
    
    if (MYTHREAD == MAIN)
        get_global_farthest_points(min, max);
    upc_barrier;
    
    sidei = side == DOWN ? DOWN_I : UP_I;
    if (points_ud[MAIN][sidei] == NULL) {
        upc_barrier;
        return;
    }
    upc_barrier;

    point = *points_ud[MAIN][sidei];
    if (MYTHREAD == MAIN)
        add_result(point);

    /*remove_points_in_triangle((struct CPoint *) points[MYTHREAD], (long *) &points_nr[MYTHREAD],
                              point, min, max);*/

    quickhull_helper(point, min, -find_side_of_point(point, min, max));
    quickhull_helper(point, max, -find_side_of_point(point, max, min));
}

static void quickhull()
{
    struct CPoint min, max;

    compute_min_max_point();
    upc_barrier;

    if (MYTHREAD == MAIN) {
        compute_global_min_max();
        add_result(*points_ud[MAIN][DOWN_I]);
        add_result(*points_ud[MAIN][UP_I]);

        /*printf("%lf %lf : %lf %lf\n",
                points_ud[MYTHREAD][0]->x,
                points_ud[MYTHREAD][0]->y,
                points_ud[MYTHREAD][1]->x,
                points_ud[MYTHREAD][1]->y);*/
    }
    upc_barrier;
    
    min = *points_ud[MAIN][DOWN_I];
    max = *points_ud[MAIN][UP_I];
    upc_barrier;

    quickhull_helper(min, max, UP);
    quickhull_helper(min, max, DOWN);
}

int main(int argc, char *argv[])
{
    int i;

    printf("Hello from thread %i/%i %lu\n", MYTHREAD, THREADS, UPC_MAX_BLOCK_SIZE);
    
    if (argc != 2) {
        if (MYTHREAD == MAIN)
            print_err_exit("Please provide the input file\n");
    }
    upc_barrier;
    
    if (MYTHREAD == MAIN) {
        if (get_points_size(argv[1]))
            print_err_exit("Error getting points number\n");
        
        if (points_size % THREADS)
            print_err_exit("Error points number must be a multiple of threads number\n");
    }
    upc_barrier;
    
    alloc_points();
    upc_barrier;
    
    if (MYTHREAD == MAIN) {
        if (read_points_and_send(argv[1]))
            print_err_exit("Error reading points\n");
        printf("Read %lu points\n", points_size);
    }
    upc_barrier;

    /*
    printf("%lu: %lu %lu %lu %lu\n", MYTHREAD,
        upc_blocksizeof(points[MYTHREAD]),
        upc_elemsizeof(points[MYTHREAD]),
        upc_localsizeof(points[MYTHREAD]),
        points_per_th);

    for (i = 0; i < points_per_th; ++i)
        printf("%lu (%d): %lu\n", MYTHREAD, i, upc_threadof(&points[MYTHREAD][i]));*/

    upc_barrier;

    quickhull();
    upc_barrier;
    upc_free(points[MYTHREAD]);

    if (MYTHREAD == MAIN)
        print_result();

    return 0;
}
