#include <caml/alloc.h>
#include <caml/bigarray.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <stdio.h>
#include <string.h>
#include "orbio.h"

value orbcaml_read_prog(value);
value orbcaml_step(value, value, value, value, value);
static void orbcaml_outfun(void *, int, double);

value
orbcaml_read_prog(value path)
{
	CAMLparam1(path);
	CAMLlocal3(ival, dval, tval);
	iss_t insns;
	ds_t data;
	is_t iallo;
	FILE *fp;
	int ilim;

	fp = fopen(String_val(path), "r");
	if (!fp)
		caml_failwith("Orbit.read_prog");
	/* The program can read arbitrary data. */
	data = malloc(sizeof(dss_t));
	ilim = orb_read_prog(fp, insns, data);
	fclose(fp);
	iallo = malloc(ilim * 4);
	memcpy(iallo, insns, ilim * 4);
	
	ival = caml_ba_alloc_dims(CAML_BA_INT32 | CAML_BA_MANAGED,
	    1, iallo, ilim);
	dval = caml_ba_alloc_dims(CAML_BA_FLOAT64 | CAML_BA_MANAGED,
	    1, data, ilim);
	tval = caml_alloc(2, 0);
	Store_field(tval, 0, ival);
	Store_field(tval, 1, dval);

	CAMLreturn(tval);	
}

value
orbcaml_step(value cinsns, value cdata, value cinput, value cstat, value outf)
{
	CAMLparam5(cinsns, cdata, cinput, cstat, outf);
	is_t insns;
	ds_t input, data;
	int stat, ilim;

	insns = Caml_ba_data_val(cinsns);
	data = Caml_ba_data_val(cdata);
	input = Caml_ba_data_val(cinput);
	ilim = Caml_ba_array_val(cinsns)->dim[0];
	stat = Bool_val(Field(cstat, 0));
	
	stat = orb_step(insns, ilim, data, input, stat, orbcaml_outfun,
	    (void*)&outf);
	Store_field(cstat, 0, Val_bool(stat));

	CAMLreturn(Val_unit);
}

static void
orbcaml_outfun(void* env, int addr, double val)
{
	CAMLparam0();
	CAMLlocal1(dval);

	dval = caml_copy_double(val);
	caml_callback2(*(value*)env, Val_int(addr), dval);
	CAMLreturn0;
}
