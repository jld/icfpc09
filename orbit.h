#include <stdint.h>

typedef double *restrict ds_t;
typedef uint32_t *restrict is_t;

#define SSIZE 16384
typedef double dss_t[SSIZE];
typedef uint32_t iss_t[SSIZE];

/* insns data input output status n_insn => status */
int orb_step(is_t, ds_t, ds_t, ds_t, int, int);

/* progfile input nstep => */
void orb_simplesim(const char *, ds_t, ds_t, int);
