all: hull

UPC_COMPILER_FLAGS=-D_GNU_SOURCE=1 -O3 \
		    --param max-inline-insns-single=35000 \
		    --param inline-unit-growth=10000 \
		    --param large-function-growth=200000 \
		    -Wno-unused -Wunused-result -Wno-unused-parameter -Wno-address

hull: hull.cpp
	g++ -g -std=c++11 ${UPC_COMPILER_FLAGS} -o $@ $< -lpthread
clean:
	rm -rf hull
