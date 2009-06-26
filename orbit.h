#include <stdint.h>

typedef double *restrict ds_t;
typedef uint32_t *restrict is_t;

#define SSIZE 16384
typedef double dss_t[SSIZE];
typedef uint32_t iss_t[SSIZE];

typedef struct itrace {
	uint32_t team, scenario;
	struct trframe *frames;
} *itrace_t;

struct trframe {
	uint32_t time, count;
	struct valmap *maps;
	struct trframe *cdr;
};

struct valmap {
	uint32_t addr;
	double value;
};


/* insns data input output status n_insn => status */
int orb_step(is_t, ds_t, ds_t, ds_t, int, int);

/* progfile input nstep => */
void orb_simplesim(const char *, ds_t, ds_t, int);


void orb_free_trace(itrace_t);
