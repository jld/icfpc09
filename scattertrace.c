#include <math.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <stdio.h>

#define NSAT 11
#define VSIZE 16

#define FORLOOP(i,l) for (int i = 0; i < (l); ++i)

#define SC_HIT 1
#define SC_STR 2e6
#define SC_BIAS 1e6

#define SCENE 4001

value caml_st_vsize(value vu);
value caml_st_vsize(value vu)
{
	vu = vu;
	return Val_int(VSIZE);
}

value caml_scattertrace(value preload, value tmx, value pts);
value caml_scattertrace(value preload, value tmx, value pts)
{
	CAMLparam3(preload, tmx, pts);
	CAMLlocal2(tmp, tmp2);
	int npt = Wosize_val(pts);
	double rating[npt];
	int lsat[npt], gotsat[npt];
	
	FORLOOP(i, npt) {
		rating[i] = 0;
		lsat[i] = -1;
		gotsat[i] = 0;
	}

	#include "st_preload_decl.i"

	while (Is_block(preload)) {
		double relx_earth, rely_earth,
		    relx_sat[NSAT], rely_sat[NSAT],
		    sathit[NSAT], score;
		
		double 
		    in2 = Double_val(Field(Field(Field(preload, 0), 0), 0)),
		    in3 = Double_val(Field(Field(Field(preload, 0), 0), 1));
		int tl = Int_val(Field(Field(preload, 0), 1));
		preload = Field(preload, 1);
		
		FORLOOP(t, tl) {
			#include "st_preload_stmt.i"
			
			if (t == 0)
				in3 = in2 = 0;

			FORLOOP(s, NSAT) {
				if (sathit[s] > 0.5 &&
				    !(gotsat[0] & (1 << s))) {
					FORLOOP(i, npt)
					    gotsat[i] |= (1 << s);
				}
			}
		}
	}

	for (int i = 0; i < npt; i += VSIZE) {
		double relx_earth[VSIZE], rely_earth[VSIZE],
		    relx_sat[NSAT][VSIZE], rely_sat[NSAT][VSIZE],
		    sathit[NSAT][VSIZE], score[VSIZE];
		int deaddot[VSIZE] = { 0 }, ndeaddot = 0;
		
		double in2[VSIZE], in3[VSIZE];

		#include "scattertrace_decl.i"

		for (int j = i; j < (i + VSIZE) && j < npt; ++j) {
			in2[j-i] = Double_val(Field(Field(pts, j), 0));
			in3[j-i] = Double_val(Field(Field(pts, j), 1));
		}

		FORLOOP(t, Int_val(tmx)) {
			if (ndeaddot >= VSIZE)
				break;

			#include "scattertrace_stmt.i"

			if (t == 0)
				FORLOOP(j, VSIZE) in3[j] = in2[j] = 0;

			for (int j = i; j < (i + VSIZE) && j < npt; ++j) {
				if (deaddot[j-i]) 
					continue;
				if (score[j-i] < 0) {
					rating[j] = -1;
					deaddot[j-i] = 1;
					++ndeaddot;
					continue;
				}

				double ra = 0;
				FORLOOP(s, NSAT) {
					if (gotsat[j] & (1 << s))
						continue;
					double rxs = relx_sat[s][j-i];
					double rys = rely_sat[s][j-i];

					if (sathit[s][j-i] > 0.5) {
						gotsat[j] |= (1 << s);
						lsat[j] = t;
						ra += SC_HIT;
					}
					ra += SC_STR / (SC_BIAS +
					    rxs * rxs + rys * rys);
				}
				if (rating[j] < ra)
					rating[j] = ra;
			}
		}
	}

	tmp = caml_alloc(npt, 0);
	FORLOOP(i, npt) {
		tmp2 = caml_alloc(2, 0);
		Store_field(tmp2, 0, caml_copy_double(rating[i]));
		Store_field(tmp2, 1, Val_int(lsat[i] + 1));
		Store_field(tmp, i, tmp2);
	}
	CAMLreturn(tmp);
}
