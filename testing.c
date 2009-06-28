#include <stdio.h>
#include <math.h>

#define VSIZE 256

int main(void)
{
	const double in16000 = 4001, in2[VSIZE] = {0}, in3[VSIZE] = {0};
	double out0[VSIZE] = {0}, out1[VSIZE] = {0}, out2[VSIZE] = {0}, out3[VSIZE] = {0}, out4;
	#include "testing_decl.i"
	int t;
	
	for (t = 0; t < 1000000; ++t) {
		#include "testing_stmt.i"
#if 0
		if (oo0 != out0) printf("%d 0 %.17g\n", t, out0);
		if (oo1 != out1) printf("%d 1 %.17g\n", t, out1);
		if (oo2 != out2) printf("%d 2 %.17g\n", t, out2);
		if (oo3 != out3) printf("%d 3 %.17g\n", t, out3);
		if (oo4 != out4) printf("%d 4 %.17g\n", t, out4);
#endif
	}
	return 0;
}
