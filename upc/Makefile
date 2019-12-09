all: hull hull_fixed

hull: hull.o hull_cpp.o
	$(UPCC) -link-with=mpicxx -o $@ $^ -shared-heap=200MB -pthreads -lpthread

hull_fixed: hull_fixed.o hull_cpp.o
	$(UPCC) -link-with=mpicxx -o $@ $^ -shared-heap=200MB -T=${P_NUM} -pthreads -lpthread
    
hull.o: hull.upc
	$(UPCC) -c -o $@ $^ -shared-heap=200MB -pthreads -lpthread

hull_fixed.o: hull.upc
	$(UPCC) -c -o $@ $^ -shared-heap=200MB -T=${P_NUM} -pthreads -lpthread

hull_cpp.o: hull.cpp
	g++ -c -std=c++11 -o $@ $^ -lpthread

run: hull
	$(UPCCRUN) -n ${P_NUM} hull ../threads/points_50kk.in

run_th: hull
	$(UPCCRUN) -n ${P_NUM} -p ${P_NUM}  hull ../threads/points_50kk.in

run_fixed: hull_fixed
	$(UPCCRUN) -n ${P_NUM} hull_fixed ../threads/points_50kk.in

run_fixed_th: hull_fixed
	$(UPCCRUN) -n ${P_NUM} -p ${P_NUM} hull_fixed ../threads/points_50kk.in

clean:
	rm -rf hull hull_fixed *.o
