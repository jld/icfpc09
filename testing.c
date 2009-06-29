#include <stdio.h>
#include <math.h>

#define VSIZE 4

int main(void)
{
	const double in16000 = 1001;
	double in2[VSIZE], in3[VSIZE];
	double out0[VSIZE], out1[VSIZE], out2[VSIZE], out3[VSIZE], out4;
	#include "testing_decl.i"
	int t, i;

	for (i = 0; i < VSIZE; ++i) {
		in2[i] = i / 2;
		in3[i] = i % 2;
	}
	#include "testing_stmt.i"
	for (i = 0; i < VSIZE; ++i) 
		in3[i] = in2[i] = 0;

	for (t = 0; t < 1000; ++t) {
		#include "testing_stmt.i"
	}

	for (i = 0; i < VSIZE; ++i) {
		printf("=== %d %d ===\n", i/2, i%2);
		printf("X 2 %.18g\n", out2[i]);
		printf("X 3 %.18g\n", out3[i]);
	}

	return 0;
}
