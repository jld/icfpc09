#include <math.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <stdio.h>

#define ISIZE 8
#define JSIZE 8
#define VSIZE (ISIZE * JSIZE)
#define NDOT VSIZE
#define NBOX ((ISIZE - 1) * (JSIZE - 1))
#define NSAT 11

#define BOXFUDGE boxfudge

#define FORLOOP(i,l) for (int i = 0; i < (l); ++i)
#define DOTLOOP(i,j) FORLOOP(i, ISIZE) FORLOOP(j, JSIZE)
#define BOXLOOP(i,j) FORLOOP(i, ISIZE-1) FORLOOP(j, JSIZE-1)
#define LIN(i,j) ((i) * JSIZE + (j))
#define alloc_fa(n) \
	caml_alloc((n) * Double_wosize, Double_array_tag)

#define SCENE 4001

value caml_gridtrace(value stuff);
value caml_gridtrace(value stuff)
{
	CAMLparam1(stuff);
	CAMLlocal3(report, tmp, tmp2);

	int
	    badbox[ISIZE-1][JSIZE-1] = { { 0 } }, 
	    boxhit[ISIZE-1][JSIZE-1] = { { 0 } }, 
	    deadbox[ISIZE-1][JSIZE-1] = { { 0 } }, 
	    deaddot[ISIZE][JSIZE] = { { 0 } },
	    dothit[ISIZE][JSIZE] = { { 0 } };

	double boxfudge;
	int nbadbox = 0, nboxhit = 0, ndeadbox = 0, ndeaddot = 0, ndothit = 0;
	int t;

	double
	    pvx[ISIZE-1][JSIZE-1], pvy[ISIZE-1][JSIZE-1],
	    in2[VSIZE], in3[VSIZE];

	double relx_earth[VSIZE], rely_earth[VSIZE],
	    relx_sat[NSAT][VSIZE], rely_sat[NSAT][VSIZE],
	    score[VSIZE], sathit[NSAT][VSIZE];
	
	double herex[ISIZE][JSIZE], herey[ISIZE][JSIZE],
	    satx[NSAT], saty[NSAT];

	double vx0, vy0, vidx, vidy, vjdx, vjdy;
	int goal_dothit, goal_boxhit, goal_time;

	vx0 = Double_val(Field(Field(stuff, 0), 0));
	vy0 = Double_val(Field(Field(stuff, 0), 1));
	vidx = Double_val(Field(Field(stuff, 1), 0));
	vidy = Double_val(Field(Field(stuff, 1), 1));
	vjdx = Double_val(Field(Field(stuff, 2), 0));
	vjdy = Double_val(Field(Field(stuff, 2), 1));
	goal_dothit = Int_val(Field(stuff, 3));
	goal_boxhit = Int_val(Field(stuff, 4));
	goal_time = Int_val(Field(stuff, 5));
	boxfudge = Double_val(Field(stuff,6));

	#include "gridtrace_decl.i"

	DOTLOOP(i,j) {
		double ri = (2. / (ISIZE - 1)) * i - 1;
		double rj = (2. / (JSIZE - 1)) * j - 1;

		in2[LIN(i,j)] = vx0 + ri * vidx + rj * vjdx;
		in3[LIN(i,j)] = vy0 + ri * vidy + rj * vjdy;
	}
	BOXLOOP(i,j) {
		double ri = (2. / (ISIZE - 1)) * (i + .5) - 1;
		double rj = (2. / (JSIZE - 1)) * (j + .5) - 1;
		
		pvx[i][j] = vx0 + ri * vidx + rj * vjdx;
		pvy[i][j] = (2. / (JSIZE - 1)) * (j + .5) - 1;
	}

	#include "gridtrace_stmt.i"

	FORLOOP(n, VSIZE) {
		in3[n] = in2[n] = 0;
	}

	for (t = 1; t < goal_time; ++t) {
		int donesat = 0;
		DOTLOOP(i,j) {
			if (deaddot[i][j])
				continue;
			if (score[LIN(i,j)] < 0) {
				deaddot[i][j] = 1;
				++ndeaddot;
				if (i > 0 && j > 0)
					++deadbox[i-1][j-1];
				if (i > 0 && j < JSIZE-1)
					++deadbox[i-1][j];
				if (i < ISIZE-1 && j > 0)
					++deadbox[i][j-1];
				if (i < ISIZE-1 && j < JSIZE-1)
					++deadbox[i][j];
			}
			FORLOOP(s, NSAT) {
				if (sathit[s][LIN(i,j)] > 0.5 
				    && !dothit[i][j]) {
					dothit[i][j] = t;
					++ndothit;
				}
			}

			herex[i][j] = -relx_earth[LIN(i,j)];
			herey[i][j] = -rely_earth[LIN(i,j)];
			if (!donesat) {
				donesat = 1;
				FORLOOP(k, NSAT) {
					satx[k] = relx_sat[k][LIN(i,j)]
					    - relx_earth[LIN(i,j)];
					saty[k] = rely_sat[k][LIN(i,j)]
					    - rely_earth[LIN(i,j)];
				}
			}
		}

		BOXLOOP(i,j) {
			if (badbox[i][j] || boxhit[i][j] || deadbox[i][j])
				continue;

			double ax = herex[i][j], ay = herey[i][j];
			double bx = herex[i][j+1], by = herey[i][j+1];
			double cx = herex[i+1][j], cy = herey[i+1][j];
			double dx = herex[i+1][j+1], dy = herey[i+1][j+1];
			
			double
			    ox = (ax + bx + cx + dx) / 4,
			    oy = (ay + by + cy + dy) / 4;
			double
			    ix = (ax + bx - cx - dx) / 4,
			    iy = (ay + by - cy - dy) / 4;
			double
			    jx = (ax - bx + cx - dx) / 4,
			    jy = (ay - by + cy - dy) / 4;
			double 
			    ir2 = ix * ix + iy * iy,
			    jr2 = jx * jx + jy * jy;

			double ij = ix * jx + iy * jy;
			
			ix -= jx * ij / jr2;
			iy -= jy * ij / jr2;
			jx -= ix * ij / ir2;
			jy -= iy * ij / jr2;

#define BOXTEST(qx,qy) \
    ((fabs((((qx) - ox) * ix + ((qy) - oy) * iy) / ir2) < BOXFUDGE) \
  && (fabs((((qx) - ox) * jx + ((qy) - oy) * jy) / jr2) < BOXFUDGE))
	       
			if (!BOXTEST(ax,ay) || !BOXTEST(bx,by) ||
			    !BOXTEST(cx,cy) || !BOXTEST(dx,dy)) {
				fprintf(stderr, "bees %.18g %.18g   %.18g %.18g   %.18g %.18g   %.18g %.18g   %d\n", ax, ay, bx, by, cx, cy, dx, dy, t);
				badbox[i][j] = t;
				++nbadbox;
			}

			FORLOOP(k, NSAT) {
				if (BOXTEST(satx[k], saty[k])) {
					boxhit[i][j] = t;
					++nboxhit;
				}
			}
		}

		if (ndothit >= goal_dothit || nboxhit >= goal_boxhit
		    || nboxhit + nbadbox >= NBOX || ndeaddot >= NDOT)
			break;

		#include "gridtrace_stmt.i"	      
	}

	report = caml_alloc(15, 0);
#define copyout_faa(off, var) \
	tmp = caml_alloc(ISIZE-1, 0);					\
	FORLOOP(i, ISIZE-1) {						\
		tmp2 = alloc_fa(JSIZE-1);				\
		FORLOOP(j, JSIZE-1) {					\
			Store_double_field(tmp2, j, var[i][j]);		\
		}							\
		Store_field(tmp, i, tmp2);				\
	}								\
	Store_field(report, off, tmp);
#define copyout_iaa(off, var, nvar, il, jl)				\
	tmp = caml_alloc(il, 0);					\
	FORLOOP(i, il) {						\
		tmp2 = caml_alloc(jl, 0);				\
		FORLOOP(j, jl) { Store_field(tmp2, j, Val_int(var[i][j])); } \
		Store_field(tmp, i, tmp2);				\
	}								\
	Store_field(report, off, tmp);					\
	Store_field(report, off + 1, Val_int(nvar));
#define copyout_iaa_dot(off, var, nvar) \
	copyout_iaa(off, var, nvar, ISIZE, JSIZE)
#define copyout_iaa_box(off, var, nvar) \
	copyout_iaa(off, var, nvar, ISIZE-1, JSIZE-1)
#define copyout_coord(off, vx, vy) \
	tmp = caml_alloc(2, 0);			   \
	Store_field(tmp, 0, caml_copy_double(vx)); \
	Store_field(tmp, 1, caml_copy_double(vy)); \
	Store_field(report, off, tmp);

	copyout_faa(0, pvx);
	copyout_faa(1, pvy);
	copyout_coord(2, vidx / ISIZE, vidy / ISIZE);
	copyout_coord(3, vjdx / JSIZE, vjdy / JSIZE);
	copyout_iaa_box(4, badbox, nbadbox);
	copyout_iaa_box(6, boxhit, nboxhit);
	copyout_iaa_box(8, deadbox, ndeadbox);
	copyout_iaa_dot(10, deaddot, ndeaddot);
	copyout_iaa_dot(12, dothit, ndothit);
	Store_field(report, 14, Val_int(t));
	
	CAMLreturn(report);
}

value testfun(value vu)
{
	CAMLparam1(vu);
	CAMLreturn(caml_alloc(Int_val(vu) * Double_wosize, Double_array_tag));
}
