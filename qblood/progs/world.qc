/*  Copyright (C) 1996-1997  Id Software, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/


#include "common.qh"


void() main =
{
    dprint ("main function\n");

    // Initialize the recursion counter
    recursioncount = 0;

    // these are just commands to the prog compiler to copy these files

    precache_file ("progs.dat");
    precache_file ("gfx.wad");
    precache_file ("quake.rc");
    precache_file ("default.cfg");

    precache_file ("end1.bin");
    precache_file2 ("end2.bin");

    precache_file ("qblood1.dem");
    precache_file ("qblood2.dem");
    precache_file ("qblood3.dem");

//
// these are all of the lumps from the cached.ls files
//
    precache_file ("gfx/palette.lmp");
    precache_file ("gfx/colormap.lmp");

    precache_file2 ("gfx/pop.lmp");

    precache_file ("gfx/complete.lmp");
    precache_file ("gfx/inter.lmp");

    precache_file ("gfx/ranking.lmp");
    precache_file ("gfx/vidmodes.lmp");
    precache_file ("gfx/finale.lmp");
    precache_file ("gfx/conback.lmp");
    precache_file ("gfx/qplaque.lmp");

    precache_file ("gfx/menudot1.lmp");
    precache_file ("gfx/menudot2.lmp");
    precache_file ("gfx/menudot3.lmp");
    precache_file ("gfx/menudot4.lmp");
    precache_file ("gfx/menudot5.lmp");
    precache_file ("gfx/menudot6.lmp");

    precache_file ("gfx/menuplyr.lmp");
    precache_file ("gfx/bigbox.lmp");
    precache_file ("gfx/dim_modm.lmp");
    precache_file ("gfx/dim_drct.lmp");
    precache_file ("gfx/dim_ipx.lmp");
    precache_file ("gfx/dim_tcp.lmp");
    precache_file ("gfx/dim_mult.lmp");
    precache_file ("gfx/mainmenu.lmp");

    precache_file ("gfx/box_tl.lmp");
    precache_file ("gfx/box_tm.lmp");
    precache_file ("gfx/box_tr.lmp");

    precache_file ("gfx/box_ml.lmp");
    precache_file ("gfx/box_mm.lmp");
    precache_file ("gfx/box_mm2.lmp");
    precache_file ("gfx/box_mr.lmp");

    precache_file ("gfx/box_bl.lmp");
    precache_file ("gfx/box_bm.lmp");
    precache_file ("gfx/box_br.lmp");

    precache_file ("gfx/sp_menu.lmp");
    precache_file ("gfx/ttl_sgl.lmp");
    precache_file ("gfx/ttl_main.lmp");
    precache_file ("gfx/ttl_cstm.lmp");

    precache_file ("gfx/mp_menu.lmp");

    precache_file ("gfx/netmen1.lmp");
    precache_file ("gfx/netmen2.lmp");
    precache_file ("gfx/netmen3.lmp");
    precache_file ("gfx/netmen4.lmp");
    precache_file ("gfx/netmen5.lmp");

    precache_file ("gfx/sell.lmp");

    precache_file ("gfx/help0.lmp");
    precache_file ("gfx/help1.lmp");
    precache_file ("gfx/help2.lmp");
    precache_file ("gfx/help3.lmp");
    precache_file ("gfx/help4.lmp");
    precache_file ("gfx/help5.lmp");

    precache_file ("gfx/pause.lmp");
    precache_file ("gfx/loading.lmp");

    precache_file ("gfx/p_option.lmp");
    precache_file ("gfx/p_load.lmp");
    precache_file ("gfx/p_save.lmp");
    precache_file ("gfx/p_multi.lmp");

    // These sounds are used by the engine code - DON'T TOUCH !!
    precache_sound ("misc/menu1.wav");
    precache_sound ("misc/menu2.wav");
    precache_sound ("misc/menu3.wav");

    precache_sound ("ambience/water1.wav");
    precache_sound ("ambience/wind2.wav");

// shareware
    precache_file ("maps/start.bsp");

    precache_file ("maps/e1m1.bsp");
    precache_file ("maps/e1m2.bsp");
    precache_file ("maps/e1m3.bsp");
    precache_file ("maps/e1m4.bsp");
    precache_file ("maps/e1m5.bsp");
    precache_file ("maps/e1m6.bsp");
    precache_file ("maps/e1m7.bsp");
    precache_file ("maps/e1m8.bsp");

// registered
    precache_file2 ("gfx/pop.lmp");

    precache_file2 ("maps/e2m1.bsp");
    precache_file2 ("maps/e2m2.bsp");
    precache_file2 ("maps/e2m3.bsp");
    precache_file2 ("maps/e2m4.bsp");
    precache_file2 ("maps/e2m5.bsp");
    precache_file2 ("maps/e2m6.bsp");
    precache_file2 ("maps/e2m7.bsp");

    precache_file2 ("maps/e3m1.bsp");
    precache_file2 ("maps/e3m2.bsp");
    precache_file2 ("maps/e3m3.bsp");
    precache_file2 ("maps/e3m4.bsp");
    precache_file2 ("maps/e3m5.bsp");
    precache_file2 ("maps/e3m6.bsp");
    precache_file2 ("maps/e3m7.bsp");

    precache_file2 ("maps/e4m1.bsp");
    precache_file2 ("maps/e4m2.bsp");
    precache_file2 ("maps/e4m3.bsp");
    precache_file2 ("maps/e4m4.bsp");
    precache_file2 ("maps/e4m5.bsp");
    precache_file2 ("maps/e4m6.bsp");
    precache_file2 ("maps/e4m7.bsp");
    precache_file2 ("maps/e4m8.bsp");

    precache_file2 ("maps/end.bsp");

    precache_file2 ("maps/dm1.bsp");
    precache_file2 ("maps/dm2.bsp");
    precache_file2 ("maps/dm3.bsp");
    precache_file2 ("maps/dm4.bsp");
    precache_file2 ("maps/dm5.bsp");
    precache_file2 ("maps/dm6.bsp");
};


entity  lastspawn;

//=======================
/*QUAKED worldspawn (0 0 0) ?
Only used for the world entity.
Set message to the level name.
Set sounds to the cd track to play.

World Types:
0: medieval
1: metal
2: base
*/
//=======================
void() worldspawn =
{
    lastspawn = world;

// custom map attributes
    if (self.model == "maps/e1m8.bsp")
        cvar_set ("sv_gravity", "100");
    else
        cvar_set ("sv_gravity", "800");

    // Some CTF variables need an initialization
    team1score = team2score = 0;
    team1_lastspawn = team2_lastspawn = world;

// the area based ambient sounds MUST be the first precache_sounds

// player precaches
    W_Precache ();          // get weapon precaches

// sounds used from C physics code
    precache_sound ("hknight/hit.wav"); // misc/gibsq.wav
 // ambience/qsuck1.wav
    precache_sound ("misc/h2ohit.wav"); // foley/lndwater.wav
    precache_sound ("misc/h2ohit1.wav"); // same as above
    precache_sound ("misc/outwater.wav"); // foley/emerge.wav
    precache_sound ("player/gasp1.wav"); // foley/gasp.wav
    precache_sound ("player/gasp2.wav"); // foley/gasp.wav
    precache_sound ("player/inh2o.wav"); // foley/submerge.wav
    precache_sound ("player/inlava.wav"); // foley/??
    precache_sound ("player/slimbrn2.wav"); // foley/??
    precache_sound ("shambler/sattck1.wav"); // misc/qbasetry.wav
    precache_sound ("misc/talk.wav"); // bludbath/message.wav
    precache_sound ("wizard/hit.wav"); //  foley/??

// setup precaches always needed

    precache_sound ("misc/gibsq.wav");    // used by when a head is destroyed
    precache_sound ("foley/punt.wav");    // used by kickable heads
    precache_sound ("demon/dland2.wav");  // landing thud -  foley/lnddirt.wav
    precache_sound ("bludbath/reappear.wav");     // item respawn sound
    precache_sound ("foley/jump.wav");            // player jump
    precache_sound ("foley/land.wav");            // player landing
    precache_sound ("ambience/bubrise.wav");      // drowning pain
    precache_sound ("foley/undchoke.wav");        // drowning pain
    precache_sound ("foley/gasp.wav");            // gasping for air
    precache_sound ("foley/undchoke.wav");        // taking breath
    precache_sound ("bludbath/message.wav");    // talk
//    precache_sound ("player/play1115.wav");    // telefrag - evil laugh
    precache_sound ("firepod/fpodcol2.wav");    // telefrag sound
    precache_sound ("misc/r_tele1.wav");        // teleport sounds
    precache_sound ("misc/r_tele2.wav");    // these are all qbasetry.wav
    precache_sound ("misc/r_tele3.wav");
    precache_sound ("misc/r_tele4.wav");
    precache_sound ("misc/r_tele5.wav");
    precache_sound ("items/ammo.wav");              // ammo pick up
    precache_sound ("items/weaponup.wav");          // weapon up
    precache_sound ("items/pickarmr.wav");          // armor up
    precache_sound ("weapons/napalm/burn.wav");  // burning on lava
    precache_sound ("ambience/sizzle.wav");      // smelt on slime
    precache_sound ("foley/swimuw.wav"); // diving suit engage sound

    precache_sound ("player/taunts/t1010.wav");  // "I live ... again !"

// player gib sounds
    precache_sound ("butcher/fzomdie1.wav");
    precache_sound ("butcher/fzomdie2.wav");
    precache_sound ("butcher/fzomdie3.wav");
    precache_sound ("player/udeath.wav");  // extreme gib sound

// player pain sounds

    precache_sound ("player/pain/play1100.wav");
    precache_sound ("player/pain/play1101.wav");
    precache_sound ("player/pain/play1102.wav");
    precache_sound ("player/pain/play1103.wav");
    precache_sound ("player/pain/play1104.wav");
    precache_sound ("player/pain/play1105.wav");
    precache_sound ("player/pain/play1106.wav");
    precache_sound ("player/pain/play1107.wav");
    precache_sound ("player/pain/play1108.wav");
// PM:  Pain while onfire.
    precache_sound ("player/pain/play1118.wav");
    precache_sound ("player/pain/play1119.wav");
    precache_sound ("player/pain/play1120.wav");

    // Player quips (when playing with explosives).
    precache_sound ("player/play1109.wav");
    precache_sound ("player/play1110.wav");
    precache_sound ("player/play1111.wav");
    precache_sound ("player/play1112.wav");
    precache_sound ("player/play1113.wav");
    precache_sound ("player/play1114.wav");
    precache_sound ("player/play1115.wav");
    precache_sound ("player/play1116.wav");
    precache_sound ("player/quips/1039.wav");   // "SOB must pay!"
    precache_sound ("player/quips/1050.wav");   // "That's all folks!"
    precache_sound ("player/quips/1057.wav");   //  "rest in pieces"

    // Player songs (when idle for too long).
    precache_sound ("player/songs/1093.wav");
    precache_sound ("player/songs/1094.wav");
    precache_sound ("player/songs/1095.wav");
    precache_sound ("player/songs/1097.wav");
    precache_sound ("player/songs/vo3011.wav");
    precache_sound ("player/songs/vo3024.wav");
    precache_sound ("player/songs/vo3026.wav");
    precache_sound ("player/songs/vo3030.wav");
    precache_sound ("player/songs/vo3033.wav");
    precache_sound ("player/songs/vo3034.wav");
    precache_sound ("player/songs/vo3035.wav");
    precache_sound ("player/songs/vo3039.wav");

    // player death sounds
    precache_sound ("player/die1.wav");
    precache_sound ("player/die2.wav");
    precache_sound ("player/die3.wav");

    // The Voice
    precache_sound ("thevoice/boned.wav");
    precache_sound ("thevoice/castra.wav");
    precache_sound ("thevoice/creamed.wav");
    precache_sound ("thevoice/decimat.wav");
    precache_sound ("thevoice/destro.wav");
    precache_sound ("thevoice/diced.wav");
    precache_sound ("thevoice/disembo.wav");
    precache_sound ("thevoice/flatte.wav");
    precache_sound ("thevoice/justice.wav");
    precache_sound ("thevoice/madness.wav");
    precache_sound ("thevoice/killed.wav");
    precache_sound ("thevoice/massacr.wav");
    precache_sound ("thevoice/mincmeat.wav");
    precache_sound ("thevoice/mutila.wav");
    precache_sound ("thevoice/reamed.wav");
    precache_sound ("thevoice/ripped.wav");
    precache_sound ("thevoice/slaught.wav");
    precache_sound ("thevoice/sliced.wav");
    precache_sound ("thevoice/smashed.wav");
    precache_sound ("thevoice/sodomiz.wav");
    precache_sound ("thevoice/splatt.wav");
    precache_sound ("thevoice/squash.wav");
    precache_sound ("thevoice/throttl.wav");
    precache_sound ("thevoice/vo1.wav");
    precache_sound ("thevoice/vo10.wav");
    precache_sound ("thevoice/vo12.wav");
    precache_sound ("thevoice/vo13.wav");
    precache_sound ("thevoice/vo14.wav");
    precache_sound ("thevoice/vo16.wav");
    precache_sound ("thevoice/vo17.wav");
    precache_sound ("thevoice/vo19.wav");
    precache_sound ("thevoice/vo2.wav");
    precache_sound ("thevoice/vo20.wav");
    precache_sound ("thevoice/vo21.wav");
    precache_sound ("thevoice/vo22.wav");
    precache_sound ("thevoice/vo23.wav");
    precache_sound ("thevoice/vo24.wav");
    precache_sound ("thevoice/vo25.wav");
    precache_sound ("thevoice/vo26.wav");
    precache_sound ("thevoice/vo27.wav");
    precache_sound ("thevoice/vo28.wav");
    precache_sound ("thevoice/vo29.wav");
    precache_sound ("thevoice/vo30.wav");
    precache_sound ("thevoice/vo31.wav");
    precache_sound ("thevoice/vo32.wav");
    precache_sound ("thevoice/vo33.wav");
    precache_sound ("thevoice/vo34.wav");
    precache_sound ("thevoice/vo35.wav");
    precache_sound ("thevoice/vo36.wav");
    precache_sound ("thevoice/vo38.wav");
    precache_sound ("thevoice/vo39.wav");
    precache_sound ("thevoice/vo40.wav");
    precache_sound ("thevoice/vo41.wav");
    precache_sound ("thevoice/vo42.wav");
    precache_sound ("thevoice/vo43.wav");
    precache_sound ("thevoice/vo44.wav");
    precache_sound ("thevoice/vo5.wav");
    precache_sound ("thevoice/vo7.wav");
    precache_sound ("thevoice/vo8.wav");     // hamburger
    precache_sound ("thevoice/vo9.wav");
    precache_sound ("thevoice/wasted.wav");

    // some foley sounds
    precache_sound ("foley/lndwater.wav");      // player jumping into water
    precache_sound ("foley/emerge.wav");        // leaving water sound
    precache_sound ("butcher/acidhit1.wav");      // slime burn
    precache_sound ("butcher/acidhit2.wav");      // slime burn
    precache_sound ("player/pain/play1120.wav");  // lava burn
    precache_sound ("player/pain/play1119.wav");  // lava burn
    precache_sound ("foley/swim.wav");          // swimming
    precache_sound ("foley/submerge.wav");      // swimming

    // models and stuff
    precache_model ("progs/player.mdl");
    precache_model ("progs/eyes.mdl");
    precache_model ("progs/h_player.mdl");
    precache_model ("progs/gib1.mdl");
    precache_model ("progs/gib2.mdl");
    precache_model ("progs/gib3.mdl");
    precache_model ("progs/larm.mdl");
    precache_model ("progs/leg.mdl");

//    precache_model ("progs/flesh1.mdl");
//    precache_model ("progs/flesh2.mdl");
//    precache_model ("progs/flesh3.mdl");

    precache_model ("progs/s_bubble.spr");  // drowning bubbles
    precache_model ("progs/s_explod.spr");  // napalm sprite explosion

    precache_model ("progs/v_axe.mdl");
    precache_model ("progs/v_shot.mdl");
    precache_model ("progs/v_nail.mdl");
    precache_model ("progs/v_rock.mdl");
    precache_model ("progs/v_shot2.mdl");
    precache_model ("progs/v_nail2.mdl");
    precache_model ("progs/v_rock2.mdl");
    precache_model ("progs/v_light.mdl");
    precache_model ("progs/v_voodoo.mdl");

    precache_model ("progs/shotshl.mdl");   // shotgun shell
    precache_model ("progs/tommyshl.mdl");  // tommy gun shell

    precache_model ("progs/bolt.mdl");      // for lightning gun
    precache_model ("progs/bolt2.mdl");     // for lightning gun
    precache_model ("progs/bolt3.mdl");     // for boss shock
    precache_model ("progs/lavaball.mdl");  // for testing

    precache_model ("progs/missile.mdl");  // napalm regular fire
    precache_model ("progs/grenade.mdl");
    precache_model ("progs/spike.mdl");
    precache_model ("progs/s_spike.mdl");

    precache_model ("progs/backpack.mdl");

    precache_model ("progs/zom_gib.mdl");


//
// Setup light animation tables. 'a' is total darkness, 'z' is maxbright.
//

    // 0 normal
    lightstyle(0, "m");

    // 1 FLICKER (first variety)
    lightstyle(1, "mmnmmommommnonmmonqnmmo");

    // 2 SLOW STRONG PULSE
    lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");

    // 3 CANDLE (first variety)
    lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");

    // 4 FAST STROBE
    lightstyle(4, "mamamamamama");

    // 5 GENTLE PULSE 1
    lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");

    // 6 FLICKER (second variety)
    lightstyle(6, "nmonqnmomnmomomno");

    // 7 CANDLE (second variety)
    lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");

    // 8 CANDLE (third variety)
    lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");

    // 9 SLOW STROBE (fourth variety)
    lightstyle(9, "aaaaaaaazzzzzzzz");

    // 10 FLUORESCENT FLICKER
    lightstyle(10, "mmamammmmammamamaaamammma");

    // 11 SLOW PULSE NOT FADE TO BLACK
    lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");

    // styles 32-62 are assigned by the light program for switchable lights

    // 63 testing
    lightstyle(63, "a");
};

void() StartFrame =
{
    teamplay = cvar("teamplay");
    timelimit = cvar("timelimit") * 60;
    fraglimit = cvar("fraglimit");
    deathmatch = cvar("deathmatch");
    coop = cvar("coop");
    skill = cvar("skill");

    framecount = framecount + 1;
};


/*
==============================================================================

CORPSE MANAGEMENT

==============================================================================
*/

// In player.qc
void() HeadDie;
void(string gibname, float dm) ThrowGib;


/*
====================
CorpseTouch

So you don't slip on corpses
====================
*/
void () CorpseTouch =
{
    self.velocity = '0 0 0';

    if ((!other.flags & FL_ONGROUND) && (other.health) && (other.flags & FL_CLIENT))
        other.flags = other.flags + FL_ONGROUND;
};


/*
====================
BecomeCorpse

Modify entity properties to change it to a destroyable corpse
====================
*/
void(float corpseHealth, void() corpseToGib) BecomeCorpse =
{
    // Clean all
    // if a monsters death sets off a trigger then dont let the corpses death do the same
    self.use = SUB_Null;
    self.target = string_null;
    self.killtarget = string_null;
    self.targetname = string_null;
    self.th_stand = SUB_Null;
    self.th_walk = SUB_Null;
    self.th_run = SUB_Null;
    self.th_missile = SUB_Null;
    self.th_melee = SUB_Null;
    self.th_pain = SUB_Null;
    self.flags = self.flags - (self.flags & FL_MONSTER);
    self.deadflag = DEAD_DEAD;

    // Corpse will turn into gibs if destroyed
    self.health = corpseHealth;
    self.th_die = corpseToGib;

    // Get rid of it in 2 minutes anyway (to avoid too many entities)
    self.nextthink = time + 120;
    self.think = SUB_Remove;

    // Allow some interactions (so the corpses can be destroyed by explosions)
    self.takedamage = DAMAGE_AIM;

    // The following fields have already been set correctly for heads
    // Note: only player's heads can be into this function
    if (self.classname != "head")
    {
        self.touch = CorpseTouch;
        self.solid = SOLID_BBOX;

        setsize (self, '-32 -32 -24', '32 32 -19');

        self.classname = "corpse";
    }
};


/*
====================
GibPlayerCorpse

Remove a player's corpse and throw gibs
====================
*/
void() GibPlayerCorpse =
{
    ThrowGib ("progs/gib1.mdl", self.health);
    ThrowGib ("progs/gib2.mdl", self.health);
    ThrowGib ("progs/gib3.mdl", self.health);
    ThrowGib ("progs/larm.mdl", self.health);
    ThrowGib ("progs/leg.mdl", self.health);

    sound (self, CHAN_ITEM, "misc/gibsq.wav", 1, ATTN_NORM);

    if (deathmatch)
    {
        Bprint (PRINT_MEDIUM, self.enemy.netname);
        Bprint (PRINT_MEDIUM, " desecrated ");
        Bprint (PRINT_MEDIUM, self.netname);
        Bprint (PRINT_MEDIUM, "'s corpse\n");
    }

    remove (self);
};


/*
====================
CloneCorpse

Make a clone for the given ent so the ent can be respawned elsewhere
====================
*/
void(entity ent) CloneCorpse =
{
    local entity clone;
    local entity tempEnt;

    // Checkings
    if (ent.classname == "observer")
        return;

    // Copy the entity characteristics
    clone = spawn ();
    clone.classname = ent.classname;
    clone.netname = ent.netname;
    clone.angles = ent.angles;
    clone.model = ent.model;
    clone.modelindex = ent.modelindex;
    clone.frame = ent.frame;
    clone.colormap = ent.colormap;
    clone.movetype = ent.movetype;
    clone.velocity = ent.velocity;
    clone.takedamage = ent.takedamage;
    clone.touch = ent.touch;
    clone.solid = ent.solid;
    setorigin (clone, ent.origin);
    setsize (clone, ent.mins, ent.maxs);

    // If the entity is a head, we just need to call HeadDie when it's destroyed
    if (clone.classname == "head")
    {
        tempEnt = self;
        self = clone;
        BecomeCorpse (80, HeadDie);
        self = tempEnt;
        return;
    }

    // Corpse will turn into gibs if destroyed
    tempEnt = self;
    self = clone;
    BecomeCorpse (100, GibPlayerCorpse);
    self = tempEnt;
};
