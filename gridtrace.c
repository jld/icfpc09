#define ISIZE 8
#define JSIZE 8
#define VSIZE (ISIZE * JSIZE)
#define NSAT 11

#define BOXFUDGE (1.1)

#define FORLOOP(i,l) for (int i = 0; i < (l); ++i)
#define DOTLOOP(i,j) FORLOOP(i, ISIZE) FORLOOP(j, JSIZE)
#define BOXLOOP(i,j) FORLOOP(i, ISIZE-1) FORLOOP(j, JSIZE-1)
#define LIN(i,j) ((i) * JSIZE + (j))

#define SCENE 4001

/* THE FUNCTION */
{
	int 
	    badbox[ISIZE-1][JSIZE-1], 
	    boxhit[ISIZE-1][JSIZE-1], 
	    deadbox[ISIZE-1][JSIZE-1], 
	    deaddot[ISIZE][JSIZE],
	    dothit[ISIZE][JSIZE];

	int nbadbox, nboxhit, ndeadbox, ndeaddot, ndothit;

	double 
	    pvx[ISIZE][JSIZE], pvy[ISIZE][JSIZE],
	    in2[VSIZE], in3[VSIZE];

	double vx0, vy0, vidx, vidy;
	int goal_dothit, goal_boxhit;

	/* OBTAIN THE PARAMETERS */

	#include "gridtrace_decl.i"

	DOTLOOP(i,j) {
		double ri = (2. / (ISIZE - 2)) * i - 1;
		double rj = (2. / (JSIZE - 2)) * j - 1;

		in2[LIN(i,j)] = pvx[i][j] = vx0 + ri * vidx + rj * vjdx;
		in3[LIN(i,j)] = pvy[i][j] = vy0 + ri * vidy + rj * vjdy;
	}

	#include "gridtrace_stmt.i"

	FORLOOP(n, VSIZE) {
		in3[n] = in2[n] = 0;
	}

	for (int t = 1; t < goal_time; ++t) {
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
			double cx = herex[i+1][j], cy = herey[i][j];
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
			
#define BOXTEST(qx,qy) \
    ((fabs((((qx) - ox) * ix + ((qy) - oy) * iy) / ir2) < BOXFUDGE) \
  && (fabs((((qx) - ox) * jx + ((qy) - oy) * jy) / jr2) < BOXFUDGE))
	       
			if (!BOXTEST(ax,ay) || !BOXTEST(bx,by) ||
			    !BOXTEST(cx,cy) || !BOXTEST(dx,dy)) {
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
	/* REPORT RESULTS */
}
