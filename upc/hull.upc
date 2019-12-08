#include <stdio.h>
#include <upc.h>
#include <upc_strict.h>

#include "hull.h"
#include "hull.hpp"

shared long points_size;

shared [] struct CPoint * shared points;
shared [0] struct CPoint * shared result;

int get_points_size(char const *file)
{
    FILE *f;
    int err = 0;
    char buf[40];
    
    f = fopen(file, "r");
    if (!f) {
        err = -1;
        goto out;
    }
    
    points_size = 0;
    while (fgets(buf, sizeof(buf), f) != NULL)
        points_size++;

out:
    fclose(f);
    return 0;
}

int read_points(char const *file)
{
    FILE *f;
    int i, err = 0;
    struct CPoint point;
    
    f = fopen(file, "r");
    if (!f) {
        err = -1;
        goto out;
    }
    
    upc_forall (i = 0; i < points_size; ++i; MAIN) {
        fscanf(f, "%lld %lld", &point.x, &point.y);
        points[i] = point;
    }

out:
    fclose(f);
    return err;
}

static void print_err(char const *err)
{
    if (MYTHREAD == MAIN)
        fprintf(stderr, "%s", err);
}

int main(int argc, char *argv[])
{
    printf("Hello from thread %i/%i %lu\n", MYTHREAD, THREADS, UPC_MAX_BLOCK_SIZE);
    
    if (argc != 2) {
        print_err("Please provide the input file\n");
        return -1;
    }
    
    if (MYTHREAD == MAIN) {
        if (get_points_size(argv[1])) {
            print_err("Error getting file size\n");
            return -1;
        }
    }
    upc_barrier;
    
    points = upc_all_alloc(points_size, sizeof(struct CPoint));
    if (!points) {
        print_err("Error allocating points\n");
        return -1;
    }
    
    printf("%ld\n", upc_blocksizeof(*points));
    
    if (MYTHREAD == MAIN) {
        if (read_points(argv[1])) {
            print_err("Error reading points\n");
            return -1;
        }
    }
    upc_barrier;

    if (MYTHREAD == MAIN) {
        //print_points((struct CPoint *) points, points_size);
        upc_free(points);
    }

    return 0;
}
