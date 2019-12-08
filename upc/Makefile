all: hull

hull: hull.o hull_cpp.o
	$(UPCC) -link-with=mpicxx -g -o $@ $^ -lpthread

hull.o: hull.upc
	$(UPCC) -c -g -o $@ $^ -lpthread

hull_cpp.o: hull.cpp
	g++ -c -g -std=c++11 -o $@ $^ -lpthread

run: hull
	$(UPCCRUN) -n 12 -N 2 hull ../init/points_1kk

clean:
	rm -rf hull *.o
