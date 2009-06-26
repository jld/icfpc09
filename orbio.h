#include <stdio.h>
#include "orbit.h"

/* file insns data => n_insn */
int orb_read_prog(FILE *, is_t, ds_t);

/* file insns data n_insn => */
void orb_write_prog(FILE *, is_t, ds_t, int);

void orb_print_insn(int, double, uint32_t);
