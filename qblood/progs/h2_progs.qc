#include "common.qh"


//precaches

precache_model("progs/beefslab.mdl");

//defs

/*QUAKED obj_beefslab (0.3 0.1 0.6) (-16 -16 0) (16 16 40)
A slab of beef for freezers.
-------------------------FIELDS-------------------------
health = 50
--------------------------------------------------------
*/
void obj_beefslab (void)
{
    precache_model("progs/beefslab.mdl");
    CreateEntityNew(self,ENT_BEEFSLAB,"progs/beefslab.mdl",chunk_death);
}