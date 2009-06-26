#include "orbio.h"
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>

typedef struct twoframe
{
	double d0;
	uint32_t i0;
	uint32_t i1;
	double d1;
} tf_t;

int
orb_read_prog(FILE *fp, is_t insns, ds_t data)
{
	tf_t ibuf[SSIZE / 2];
	int ilim, i;
	
	memset(ibuf, 0, sizeof(ibuf));
	ilim = fread(ibuf, 12, SSIZE, fp);
	if (ferror(fp)) {
		perror("orb_read_prog");
		exit(1);
	}
	
	for (i = 0; i < (SSIZE / 2); ++i) {
		insns[2 * i] = ibuf[i].i0;
		insns[2 * i + 1] = ibuf[i].i1;
		data[2 * i] = ibuf[i].d0;
		data[2 * i + 1] = ibuf[i].d1;
	}
	return ilim;
}

void
orb_write_prog(FILE *fp, is_t insns, ds_t data, int ilim)
{
	tf_t obuf[SSIZE / 2];
	int i, olim;

	for (i = 0; i < ilim; ++i) {
		if (i % 2 == 0) {
			obuf[i / 2].i0 = insns[i];
			obuf[i / 2].d0 = data[i];
		} else {
			obuf[i / 2].i1 = insns[i];
			obuf[i / 2].d1 = data[i];
		}
	}
	olim = fwrite(obuf, 12, ilim, fp);
	if (olim != ilim)
		perror("orb_write_prog");
}


void
orb_print_insn(int addr, double d, uint32_t insn)
{
	int d_op, d_r1, d_r2, s_op, s_imm, s_r1;

	d_op = insn >> 28;
	d_r1 = (insn >> 14) & 16383;
	d_r2 = insn & 16383;
	s_op = (insn >> 24) & 15;
	s_imm = (insn >> 21) & 7;
	s_r1 = insn & 16383;

	if (d_op != 0) {
		static const char * const ops[] =
		    { "Add", "Sub", "Mult", "Div", "Output", "Phi" };
		printf("%04x: [%.11g] %s %04x %04x\n",
		    addr, d, ops[d_op - 1], d_r1, d_r2);
	} else {
		static const char * const ops[] = 
		    { "Noop", 0, "Sqrt", "Copy", "Input" };
		static const char * const relops[] =
		    { "LTZ", "LEZ", "EQZ", "GEZ", "GTZ" };
		const char* op =
		    (s_op == 1) ? relops[s_imm] : ops[s_op];
		printf("%04x: [%.11g] %s %04x\n",
		    addr, d, op, s_op ? s_r1 : addr);
	}
}


static uint32_t get_u32(FILE *);
static double get_f64(FILE *);
static void put_u32(FILE *, uint32_t);
static void put_f64(FILE *, double);
static void xxx(int, int);

itrace_t
orb_read_trace(FILE *fp)
{
	itrace_t it;
	struct trframe *tf;
	uint32_t i;
	
	if (get_u32(fp) != 0xCAFEBABE) {
		fprintf(stderr, "Wrong magic number.\n");
		exit(1);
	}
		
	it = malloc(sizeof(struct itrace));
	it->team = get_u32(fp);
	it->scenario = get_u32(fp);
	it->frames = NULL;

	for (;;) {
		tf = malloc(sizeof(struct trframe));
		tf->time = get_u32(fp);
		tf->count = get_u32(fp);
		tf->maps = NULL;
		tf->cdr = it->frames;
		it->frames = tf;
		if (tf->count == 0) {
			if (tf->time >= 3000000)
				fprintf(stderr, "Warning: %"PRIu32
				    " > 3000000\n",
				    tf->time);
			break;
		}
		tf->maps = malloc(tf->count * sizeof(struct valmap));
		for (i = 0; i < tf->count; ++i) {
			tf->maps[i].addr = get_u32(fp);
			tf->maps[i].value = get_f64(fp);
		}
	}
	
	tf = it->frames;
	it->frames = NULL;
	while (tf) {
		struct trframe *tfc = tf->cdr;
		tf->cdr = it->frames;
		it->frames = tf;
		tf = tfc;
	}
	
	return it;
}

void orb_write_trace(FILE *fp, itrace_t it)
{
	struct trframe *tf;
	uint32_t i;

	put_u32(fp, 0xCAFEBABE);
	put_u32(fp, it->team);
	put_u32(fp, it->scenario);
	
	for (tf = it->frames; tf; tf = tf->cdr) {
		put_u32(fp, tf->time);
		put_u32(fp, tf->count);
		for (i = 0; i < tf->count; ++i) {
			put_u32(fp, tf->maps[i].addr);
			put_f64(fp, tf->maps[i].value);
		}
	}
}

void orb_write_trace_text(FILE *fp, itrace_t it)
{
	struct trframe *tf;
	uint32_t i;

	fprintf(fp, "h %"PRIu32" %"PRIu32"\n", it->team, it->scenario);
	for (tf = it->frames; tf; tf = tf->cdr) {
		fprintf(fp, "f %"PRIu32" %"PRIu32"\n", tf->time, tf->count);
		for (i = 0; i < tf->count; ++i) {
			fprintf(fp, " %d %.17g\n", 
			    tf->maps[i].addr, tf->maps[i].value);
		}
	}
}

itrace_t orb_read_trace_text(FILE *fp)
{
	itrace_t it;
	struct trframe *tf;
	uint32_t i;
	
	it = malloc(sizeof(struct itrace));
	xxx(2, fscanf(fp, "h %"SCNu32" %"SCNu32,
		&it->team, &it->scenario));
	it->frames = NULL;

	for (;;) {
		tf = malloc(sizeof(struct trframe));
		xxx(2, fscanf(fp, "f %"SCNu32" %"SCNu32,
			&tf->time, &tf->count));
		tf->maps = NULL;
		tf->cdr = it->frames;
		it->frames = tf;
		if (tf->count == 0) {
			if (tf->time >= 3000000)
				fprintf(stderr, "Warning: %"PRIu32
				    " > 3000000\n", tf->time);
			break;
		}
		tf->maps = malloc(tf->count * sizeof(struct valmap));
		for (i = 0; i < tf->count; ++i) {
			xxx(2, fscanf(fp, "%"SCNu32" %lg", 
				&tf->maps[i].addr, &tf->maps[i].value));
		}
	}
	
	tf = it->frames;
	it->frames = NULL;
	while (tf) {
		struct trframe *tfc = tf->cdr;
		tf->cdr = it->frames;
		it->frames = tf;
		tf = tfc;
	}
	
	return it;
}


static uint32_t get_u32(FILE *fp)
{
	uint32_t uv;
	
	xxx(1, fread(&uv, 4, 1, fp));
	return uv;
}

static double get_f64(FILE *fp)
{
	double dv;

	xxx(1, fread(&dv, 8, 1, fp));
	return dv;
}

static void put_u32(FILE *fp, uint32_t uv)
{
	xxx(1, fwrite(&uv, 4, 1, fp));
}

static void put_f64(FILE *fp, double dv)
{
	xxx(1, fwrite(&dv, 8, 1, fp));
}

static void xxx(int a, int b)
{
	if (a == b)
		return;
	fprintf(stderr, "Syntax error.\n");
	exit(1);
}
