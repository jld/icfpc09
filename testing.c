#include <stdio.h>
#include <math.h>

int main(void)
{
	const double in16000 = 1001, in2 = 0, in3 = 0;
	double out0 = 0, out1 = 0, out2 = 0, out3 = 0, out4 = 0;
	double oo0, oo1, oo2, oo3, oo4;
	#include "testing_decl.i"
	int t;
	
	for (t = 0; t < 1000; ++t) {
		oo0 = out0; oo1 = out1; oo2 = out2; oo3 = out3; oo4 = out4;
		#include "testing_stmt.i"
		if (oo0 != out0) printf("%d 0 %.17g\n", t, out0);
		if (oo1 != out1) printf("%d 1 %.17g\n", t, out1);
		if (oo2 != out2) printf("%d 2 %.17g\n", t, out2);
		if (oo3 != out3) printf("%d 3 %.17g\n", t, out3);
		if (oo4 != out4) printf("%d 4 %.17g\n", t, out4);
	}
	return 0;
}
