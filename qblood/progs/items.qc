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


//--------------------//
//  NEW EDICT FIELDS  //
//--------------------//
// PM:  Custom ammo.
.float      ammo_flares;        // flare gun
.float      ammo_tnt_bundle;    // standard dynamite
.float      ammo_tnt_proxy;     // proxy bombs
.float      ammo_tnt_remote;    // pipebombs
.float      ammo_spray;         // spray can
.float      ammo_voodoo;        // voodoo doll
.float      ammo_leech;         // leech life

//  NOTE:  The existing Quake ammo are used for the following weapons.
//    ammo_shells  -> sawed-off shotgun
//    ammo_nails   -> tommy sub-machinegun
//    ammo_rockets -> napalm launcher (a.k.a. incinerator)
//    ammo_cells   -> telsa cannon


void() W_SetCurrentAmmo;
/* ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN COLOR */


void() SUB_regen =
{
    self.model = self.mdl;      // restore original model
    self.solid = SOLID_TRIGGER; // allow it to be touched again
    sound (self, CHAN_VOICE, "bludbath/reappear.wav", 1, ATTN_NORM);    // item respawn sound
    setorigin (self, self.origin);
};



/*QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
*/
void() noclass =
{
    dprint ("noclass spawned at");
    dprint (vtos(self.origin));
    dprint ("\n");
    remove (self);
};

void() q_touch =
{
local entity    stemp;
local float     best;
local string    s;

    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

    self.mdl = self.model;

    sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");
    self.solid = SOLID_NOT;
    other.items = other.items | IT_QUAD;
    self.model = string_null;

// do the apropriate action
    other.super_time = 1;
    other.super_damage_finished = self.cnt;

    s=ftos(rint(other.super_damage_finished - time));

    Bprint (PRINT_LOW, other.netname);
    Bprint (PRINT_LOW, " picked up a guns akimbo with ");
    Bprint (PRINT_LOW, s);
    Bprint (PRINT_LOW, " seconds remaining!\n");

    activator = other;
    SUB_UseTargets();                               // fire all targets / killtargets
};

void(float timeleft) DropQuad =
{
    local entity    item;

    item = spawn();
    item.origin = self.origin;

    item.velocity_z = 300;
    item.velocity_x = -100 + (random() * 200);
    item.velocity_y = -100 + (random() * 200);

    item.flags = FL_ITEM;
    item.solid = SOLID_TRIGGER;
    item.movetype = MOVETYPE_TOSS;
    item.noise = "bludbath/powerup.wav";
    setmodel (item, "progs/quaddama.mdl");
    setsize (item, '-16 -16 -24', '16 16 32');
    item.cnt = time + timeleft;
    item.touch = q_touch;
    item.nextthink = time + timeleft;    // remove it with the time left on it
    item.think = SUB_Remove;
};

void() r_touch =
{
local entity    stemp;
local float     best;
local string    s;

    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

    self.mdl = self.model;

    sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");
    self.solid = SOLID_NOT;
    other.items = other.items | IT_INVISIBILITY;
    self.model = string_null;

// do the apropriate action
    other.invisible_time = 1;
    other.invisible_finished = self.cnt;
    s=ftos(rint(other.invisible_finished - time));
    Bprint (PRINT_LOW, other.netname);
    Bprint (PRINT_LOW, " picked up a cloak with ");
    Bprint (PRINT_LOW, s);
    Bprint (PRINT_LOW, " seconds remaining!\n");


    activator = other;
    SUB_UseTargets();                               // fire all targets / killtargets
};

void(float timeleft) DropRing =
{
    local entity    item;

    item = spawn();
    item.origin = self.origin;

    item.velocity_z = 300;
    item.velocity_x = -100 + (random() * 200);
    item.velocity_y = -100 + (random() * 200);

    item.flags = FL_ITEM;
    item.solid = SOLID_TRIGGER;
    item.movetype = MOVETYPE_TOSS;
    item.noise = "bludbath/powerup.wav";
    setmodel (item, "progs/invisibl.mdl");
    setsize (item, '-16 -16 -24', '16 16 32');
    item.cnt = time + timeleft;
    item.touch = r_touch;
    item.nextthink = time + timeleft;    // remove after 30 seconds
    item.think = SUB_Remove;
};


/*
============
PlaceItem

plants the object on the floor
============
*/
void() PlaceItem =
{
    local float oldz;

    self.mdl = self.model;      // so it can be restored on respawn
    self.flags = FL_ITEM;       // make extra wide
    self.solid = SOLID_TRIGGER;
    self.movetype = MOVETYPE_TOSS;
    self.velocity = '0 0 0';
    self.origin_z = self.origin_z + 6;
    oldz = self.origin_z;
    if (!droptofloor())
    {
        dprint ("Bonus item \"");
        dprint (self.classname);
        dprint ("\" fell out of level at ");
        dprint (vtos(self.origin));
        dprint ("\n");
        remove(self);
        return;
    }
};

/*
============
StartItem

Sets the clipping size and plants the object on the floor
============
*/
void() StartItem =
{
    self.nextthink = time + 0.2;    // items start after other solids
    self.think = PlaceItem;
};


/*
============
lure_touch

Touch function for a proxy item (see below)

For test purpose only
============
*/
void() lure_touch =
{
    if (!(other.flags & FL_CLIENT))
        return;

    self.solid = SOLID_NOT;
    self.model = string_null;
    if (deathmatch)
        self.nextthink = time + 20;
    self.think = SUB_regen;

    Sprint (other, PRINT_LOW, "Picked up a LURE\n");
    sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");  // produces a little flash on the interface when you picked up the item
};

/*
============
item_lure

Proxy item. Used by mappers when a spawn function for an item doesn't yet exist

For test purpose only
============
*/
void() item_lure =
{
    // set pickup sound if it wasn't already done
    if (self.noise == "" || self.noise == string_null)
        self.noise = "items/pickup.wav";

    self.touch = lure_touch;

    precache_model (self.model);
    setmodel (self, self.model);
    precache_sound (self.noise);

    setsize (self, '0 0 0', '32 32 32');
    StartItem ();
};


/*
==========================================================

MISCELLANEOUS OBJECTS

==========================================================
*/
// misc. objects that exist in maps as decorations. some are breakable
// dturner 6/30/2001

// small tome or book, closed

void() obj_tome =
    {
    precache_model("progs/a_tome.mdl");
    precache_sound("items/pickup.wav");
    setmodel(self, "progs/a_tome.mdl");
    self.noise = "items/pickup.wav";

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// small potion vial

void() obj_boost =
    {
    precache_model("progs/a_boost.mdl");
    setmodel(self, "progs/a_boost.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// large potion goblet

void() obj_mboost =
    {
    precache_model("progs/a_mboost.mdl");
    setmodel(self, "progs/a_mboost.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };


// huge statue of praying angel

void() obj_anglstat =
    {
    precache_model("progs/anglstat.mdl");
    setmodel(self, "progs/anglstat.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// a slab of beef, found in restaraunt freezers

void() obj_beefslab =
    {
    precache_model("progs/beefslab.mdl");
    setmodel(self, "progs/beefslab.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// pile of bones

void() obj_bonepile =
    {
    precache_model("progs/bonepile.mdl");
    setmodel(self, "progs/bonepile.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// another book, closed

void() obj_bookclos =
    {
    precache_model("progs/bookclos.mdl");
    setmodel(self, "progs/bookclos.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// another book, open

void() obj_bookopen =
    {
    precache_model("progs/bookopen.mdl");
    setmodel(self, "progs/bookopen.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// small bush

void() obj_bush1 =
    {
    precache_model("progs/bush1.mdl");
    setmodel(self, "progs/bush1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// large cauldren

void() obj_cauldren =
    {
    precache_model("progs/cauldren.mdl");
    setmodel(self, "progs/cauldren.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// chrome flaming torch

void() obj_cflmtrch =
    {
    precache_model("progs/cflmtrch.mdl");
    setmodel(self, "progs/cflmtrch.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// a locked chest, with 2 skins

void() obj_chest1 =
    {
    precache_model("progs/chest1.mdl");
    setmodel(self, "progs/chest1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// a locked chest, round, with 3 skins

void() obj_chest2 =
    {
    precache_model("progs/chest2.mdl");
    setmodel(self, "progs/chest2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// square chest

void() obj_chest3 =
    {
    precache_model("progs/chest3.mdl");
    setmodel(self, "progs/chest3.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// corpse lying on stomach, 4 skins

void() obj_corps1 =
    {
    precache_model("progs/corps1.mdl");
    setmodel(self, "progs/corps1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// clue book

void() obj_clueb =
    {
    precache_model("progs/clueb.mdl");
    setmodel(self, "progs/clueb.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// a corpse lying face up with 5 skins
// skin4 is encased in webs
void() obj_corps2 =
    {
    precache_model("progs/corps2.mdl");
    setmodel(self, "progs/corps2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };


// a rusty metal cross with a tilted cross beam

void() obj_cross =
    {
    precache_model("progs/cross.mdl");
    setmodel(self, "progs/cross.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// a chrome skeleton key

void() obj_cskey =
    {
    precache_model("progs/cskey.mdl");
    setmodel(self, "progs/cskey.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// an egyptian looking torch

void() obj_eflmtrch =
    {
    precache_model("progs/eflmtrch.mdl");
    setmodel(self, "progs/eflmtrch.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// egytpian torch, unlit

void() obj_egtorch =
    {
    precache_model("progs/egtorch.mdl");
    setmodel(self, "progs/egtorch.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// iron fence gateway

void() obj_fence =
    {
    precache_model("progs/fence.mdl");
    setmodel(self, "progs/fence.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// large 2 tier fountain

void() obj_fountain =
    {
    precache_model("progs/fountain.mdl");
    setmodel(self, "progs/fountain.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// head of a fallen angel

void() obj_hfangel =
    {
    precache_model("progs/h_fangel.mdl");
    setmodel(self, "progs/h_fangel.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// tall triangular hedge

void() obj_hedge1 =
    {
    precache_model("progs/hedge1.mdl");
    setmodel(self, "progs/hedge1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// tall square hedge

void() obj_hedge2 =
    {
    precache_model("progs/hedge2.mdl");
    setmodel(self, "progs/hedge2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// tall rounded hedge

void() obj_hedge3 =
    {
    precache_model("progs/hedge3.mdl");
    setmodel(self, "progs/hedge3.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// cross with fluer de lis

void() obj_holycrss =
    {
    precache_model("progs/holycrss.mdl");
    setmodel(self, "progs/holycrss.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// huge moving spider web

void() obj_megaweb =
    {
    precache_model("progs/megaweb.mdl");
    setmodel(self, "progs/megaweb.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// small plant

void() obj_plantgen =
    {
    precache_model("progs/plantgen.mdl");
    setmodel(self, "progs/plantgen.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// potted plant

void() obj_plantmez =
    {
    precache_model("progs/plantmez.mdl");
    setmodel(self, "progs/plantmez.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// plant in vase

void() obj_plantrom =
    {
    precache_model("progs/plantrom.mdl");
    setmodel(self, "progs/plantrom.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// large 2 handled jug, 4 skins

void() obj_pot1 =
    {
    precache_model("progs/pot1.mdl");
    setmodel(self, "progs/pot1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// large vase, 4 skins

void() obj_pot2 =
    {
    precache_model("progs/pot2.mdl");
    setmodel(self, "progs/pot2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// large vase, 4 skins

void() obj_pot3 =
    {
    precache_model("progs/pot3.mdl");
    setmodel(self, "progs/pot3.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// roman style flaming torch

void() obj_rflmtrch =
    {
    precache_model("progs/rflmtrch.mdl");
    setmodel(self, "progs/rflmtrch.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// seaweed

void() obj_seaweed =
    {
    precache_model("progs/seaweed.mdl");
    setmodel(self, "progs/seaweed.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// 1 skull on a stick

void() obj_skllstk1 =
    {
    precache_model("progs/skllstk1.mdl");
    setmodel(self, "progs/skllstk1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// 2 skulls on a stick

void() obj_skllstk2 =
    {
    precache_model("progs/skllstk2.mdl");
    setmodel(self, "progs/skllstk2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

//  cross tombstone

void() obj_tombstn1 =
    {
    precache_model("progs/tombstn1.mdl");
    setmodel(self, "progs/tombstn1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// oval tombstone

void() obj_tombstn2 =
    {
    precache_model("progs/tombstn2.mdl");
    setmodel(self, "progs/tombstn2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// dead tree

void() obj_tree =
    {
    precache_model("progs/tree.mdl");
    setmodel(self, "progs/tree.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// leafy tree

void() obj_tree2 =
    {
    precache_model("progs/tree2.mdl");
    setmodel(self, "progs/tree2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// small spider webs

void() obj_webs =
    {
    precache_model("progs/webs.mdl");
    setmodel(self, "progs/webs.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };


/*
===================================

POWERUPS

===================================
*/
void() powerup_touch =
{
    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

// do the apropriate action
// PM:  Listed in alphabetical order.
    if (self.classname == "item_artifact_bag")
    {
        if (InvenMax (other, S_FIRST_AID))
            return;
        InvenSet (other, S_FIRST_AID, 100);
    }
    else if (self.classname == "item_artifact_boots")
    {
        if (InvenMax (other, S_JUMP_BOOTS))
            return;
        InvenSet (other, S_JUMP_BOOTS, 100);
    }
    else if (self.classname == "item_artifact_crystal")
    {
        if (InvenMax (other, S_CRYSTAL_BALL))
            return;
        InvenSet (other, S_CRYSTAL_BALL, 100);
    }
    else if (self.classname == "item_artifact_envirosuit")
    {
        if (InvenMax (other, S_DIVING_SUIT))
            return;
        InvenSet (other, S_DIVING_SUIT, 100);
    }
    else if (self.classname == "item_artifact_invisibility")
    {
        other.invisible_time = 1;
        other.invisible_finished = time + 30;
    }
    else if (self.classname == "item_artifact_invulnerability")
    {
        other.invincible_time = 1;
        other.invincible_finished = time + 30;
    }
    else if (self.classname == "item_artifact_reflect")
    {
        other.reflect_finished = time + 30;
    }
    else if (self.classname == "item_artifact_super_damage")
    {
        other.super_time = 1;
        other.super_damage_finished = time + 30;
    }
    else if (self.classname == "item_artifact_vision")
    {
        if (InvenMax (other, S_BEAST_VISION))
            return;
        InvenSet (other, S_BEAST_VISION, 100);
    }

    Sprint (other, PRINT_LOW, "Picked up ");
    Sprint (other, PRINT_LOW,  self.netname);
    Sprint (other, PRINT_LOW, "\n");

    if (deathmatch)
    {
        self.mdl = self.model;

        if ((self.classname == "item_artifact_invulnerability") ||
            (self.classname == "item_artifact_invisibility"))
            self.nextthink = time + 60*5;
        else
            self.nextthink = time + 60;

        self.think = SUB_regen;
    }

    sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");
    self.solid = SOLID_NOT;
    other.items = other.items | self.items;
    self.model = string_null;

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};

void() item_powerup =
{
    if (self.noise == "" || self.noise == string_null)
        self.noise = "items/pickup.wav";

    self.touch = powerup_touch;

    precache_model (self.model);
    precache_sound (self.noise);
    setmodel (self, self.model);

    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};

//various powerups that aren't in other sections already

// Life Leech model
//  FIXME: move to weapons when code is complete
void() weapon_lifeleech =
{
    self.model = "progs/g_leech.mdl";
    self.noise = "items/weaponup.wav";
    item_lure ();
};

// Doctor's Bag
void() item_artifact_bag =
{
    self.netname = "Doctor's Bag";
    self.model   = "progs/i_docbag.mdl";
    self.noise   = "items/pickup.wav";
    item_powerup ();
};

// Boots of Jumping
void() item_artifact_boots =
{
    self.netname = "Boots of Jumping";
    self.model   = "progs/i_boots.mdl";
    self.noise   = "items/pickup.wav";
    item_powerup ();
};

// Crystal Ball
void() item_artifact_crystal =
{
    self.netname = "Crystal Ball";
    self.model   = "progs/i_crysbl.mdl";
    self.noise   = "items/pickup.wav";
    item_powerup ();
};

// Reflective Shots
void() item_artifact_reflect =
{
    self.netname = "Reflective Shots";
    self.model   = "progs/i_reflct.mdl";
    self.noise   = "bludbath/powerup.wav";

    self.items   = IT_QUAD;
    #ifdef QUAKEWORLD
    self.effects = self.effects | EF_BLUE;
    #endif

    item_powerup ();
};

// Beast Vision
void() item_artifact_vision =
{
    self.netname = "Beast Vision";
    self.model   = "progs/i_vision.mdl";
    self.noise   = "items/pickup.wav";
    item_powerup ();
};

// Cloak of Shadows
void() item_artifact_shadow =
{
    self.model = "progs/i_shadow.mdl";
    item_lure ();
};


// Soccer Goal Post
void() obj_goal =
{
     self.model = "progs/goalpost.mdl";
};

/*
=========================================================================

HEALTH BOX

=========================================================================
*/
//
// T_Heal: add health to an entity, limiting health to max_health
// "ignore" will ignore max_health limit
//
float (entity e, float healamount, float ignore) T_Heal =
{
    if (e.health <= 0)
        return 0;
    if ((!ignore) && (e.health >= other.max_health))
        return 0;
    healamount = ceil(healamount);

    e.health = e.health + healamount;
    if ((!ignore) && (e.health >= other.max_health))
        e.health = other.max_health;

// PM:  In Blood, life seed and cheats maxed out health at 200.
    if (e.health > 200)
        e.health = 200;
    return 1;
};

/*QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
Health box. Normally gives 50 points.
Rotten box heals 20 points,
megahealth will add 100 health, then
rot you down to your maximum health limit,
one point per second.
*/
.float  healamount, healtype;

void() health_touch =
{
    local   float amount;
    local   string  s;

    if (other.classname != "player")
        return;

    if (self.healtype == 2) // Megahealth?  Ignore max_health...
    {
        if (other.health >= 200)
            return;
        if (!T_Heal(other, self.healamount, 1))
            return;
    }
    else
    {
        if (!T_Heal(other, self.healamount, 0))
            return;
    }

    Sprint(other, PRINT_LOW, "Picked up ");
    s = ftos(self.healamount);
    Sprint(other, PRINT_LOW, self.netname);
    Sprint(other, PRINT_LOW, " \n");

    // health touch sound
    sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

    stuffcmd (other, "bf\n");

    self.model = string_null;
    self.solid = SOLID_NOT;

    // Do NOT rot health after taking life seed.
    if (deathmatch)
    {
        self.nextthink = time + 20;
        self.think = SUB_regen;
    }

    activator = other;
    SUB_UseTargets();       // fire all targets / killtargets
};


#define H_ROTTEN    1
#define H_MEGA      2

void() item_health =
{
    self.touch = health_touch;

    if (self.spawnflags & H_ROTTEN)
    {
        precache_model("progs/i_lifess.mdl");

        precache_sound("items/pickheal.wav");
        setmodel(self, "progs/i_lifess.mdl");
        self.noise = "items/pickheal.wav";
        self.healamount = 20;   // PM:  Quake = 15
        self.netname = "Life Essence";
        #ifdef QUAKEWORLD
        self.effects = self.effects | EF_RED;
        #endif
        self.healtype = 1;
    }
    else if (self.spawnflags & H_MEGA)
    {
        precache_model("progs/lifeseed.mdl");
        precache_sound("items/pickup.wav");
        setmodel(self, "progs/lifeseed.mdl");
        self.noise = "items/pickup.wav";
        self.healamount = 100;
        self.netname = "Life Seed";
        self.healtype = 2;
    }
    else
    {
        precache_model("progs/i_medpch.mdl");
        precache_sound("items/pickheal.wav");
        setmodel(self, "progs/i_medpch.mdl");
        self.noise = "items/pickheal.wav";
        self.healamount = 50;
        self.netname = "Medicine Patch";
        self.healtype = 1;
    }
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};

/*
===============================================================================

ARMOR

===============================================================================
*/

void() armor_touch =
{
    local   float   type, value, bit;

    if (other.health <= 0)
        return;
    if (other.classname != "player")
        return;

// PM:  Use Blood's three armor/damage system.
    if (self.classname == "item_armor1")
    {
        // Body armor
        if (other.armor_body >= 100)
            return;
        value = other.armor_body = 100;
        bit = IT_ARMOR1;
    }
    else if (self.classname == "item_armor2")
    {
        // Fire armor
        if (other.armor_fire >= 100)
            return;
        value = other.armor_fire = 100;
        bit = IT_ARMOR2;
    }
    else if (self.classname == "item_armorInv")
    {
        // Super armor (200 of all three armors).
        if (other.armor_body >= 200)
            if (other.armor_fire >= 200)
                if (other.armor_mind >= 200)
                    return;

        other.armor_body = other.armor_fire = other.armor_mind = 200;

        bit = other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
        if (bit == IT_ARMOR1)
            value = other.armor_body;
        else if (bit == IT_ARMOR2)
            value = other.armor_fire;
        else
        {
            bit = IT_ARMOR3;
            value = other.armor_mind;
        }
    }
    else if (self.classname == "item_armor0")
    {
        // Basic armor
        if (other.armor_body >= 100)
            if (other.armor_fire >= 100)
                if (other.armor_mind >= 100)
                    return;

        other.armor_body = other.armor_body + 50;
        if (other.armor_body > 100)
            other.armor_body = 100;
        other.armor_fire = other.armor_fire + 50;
        if (other.armor_fire > 100)
            other.armor_fire = 100;
        other.armor_mind = other.armor_mind + 50;
        if (other.armor_mind > 100)
            other.armor_mind = 100;

        bit = other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
        if (bit == IT_ARMOR3)
            value = other.armor_mind;
        else if (bit == IT_ARMOR2)
            value = other.armor_fire;
        else
        {
            bit = IT_ARMOR1;
            value = other.armor_body;
        }
    }
    else if (self.classname == "item_armor4")
    {
        // Spirit armor
        if (other.armor_mind >= 100)
            return;
        value = other.armor_mind = 100;
        bit = IT_ARMOR3;
    }
    else
    {
        Sprint(other, PRINT_MEDIUM, "Tried to pickup illegal armor.\n");
    }

    other.armorvalue = value;
    if (bit)
        other.items = other.items - (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + bit;

    self.solid = SOLID_NOT;
    self.model = string_null;
    if (deathmatch)
        self.nextthink = time + 20;
    self.think = SUB_regen;

    Sprint(other, PRINT_LOW, "Picked up ");
    Sprint(other, PRINT_LOW, self.netname);
    Sprint(other, PRINT_LOW, "\n");
    sound(other, CHAN_ITEM, "items/pickarmr.wav", 1, ATTN_NORM);
    stuffcmd (other, "bf\n");

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};

// Basic Armor
void() item_armor0 =
    {
    self.touch = armor_touch;
    precache_model("progs/i_arm_bs.mdl");
    setmodel(self, "progs/i_arm_bs.mdl");
    self.netname = "Basic Armor";
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// Spirit Armor
void() item_armor4 =
    {
    self.touch = armor_touch;
    precache_model("progs/i_arm_sp.mdl");
    setmodel(self, "progs/i_arm_sp.mdl");
    self.netname = "Spirit Armor";

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

/*QUAKED item_armor1 (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armor1 =
{
    self.touch = armor_touch;
    precache_model ("progs/i_arm_bd.mdl");
    setmodel (self, "progs/i_arm_bd.mdl");
    self.netname = "Body Armor";

    setsize (self, '-16 -16 0', '16 16 56');
    StartItem ();
};

/*QUAKED item_armor2 (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armor2 =
{
    self.touch = armor_touch;
    precache_model ("progs/i_arm_fr.mdl");
    setmodel (self, "progs/i_arm_fr.mdl");
    self.netname = "Fire Armor";

    setsize (self, '-16 -16 0', '16 16 56');
    StartItem ();
};

/*QUAKED item_armorInv (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armorInv =
{
    self.touch = armor_touch;
    precache_model ("progs/i_arm_su.mdl");
    setmodel (self, "progs/i_arm_su.mdl");
    self.netname = "Super Armor";

    setsize (self, '-16 -16 0', '16 16 56');
    StartItem ();
};

/*
===============================================================================

WEAPONS

===============================================================================
*/

void() bound_other_ammo =
{
    if (other.ammo_shells > MAX_SHELLS)
        other.ammo_shells = MAX_SHELLS;
    if (other.ammo_nails > MAX_NAILS)
        other.ammo_nails = MAX_NAILS;
    if (other.ammo_rockets > MAX_ROCKETS)
        other.ammo_rockets = MAX_ROCKETS;
    if (other.ammo_cells > MAX_CELLS)
        other.ammo_cells = MAX_CELLS;

    // Custom ammo.
    if (other.ammo_flares > MAX_FLARES)
        other.ammo_flares = MAX_FLARES;
    if (other.ammo_tnt_bundle > MAX_TNT)
        other.ammo_tnt_bundle = MAX_TNT;
    if (other.ammo_tnt_proxy > MAX_PROXY)
        other.ammo_tnt_proxy = MAX_PROXY;
    if (other.ammo_tnt_remote > MAX_REMOTE)
        other.ammo_tnt_remote = MAX_REMOTE;
    if (other.ammo_spray > MAX_SPRAY)
        other.ammo_spray = MAX_SPRAY;
    if (other.ammo_voodoo > MAX_VOODOO)
        other.ammo_voodoo = MAX_VOODOO;
    if (other.ammo_leech > MAX_LEECH)
        other.ammo_leech = MAX_LEECH;
};


float(float w) RankForWeapon =
{
    if (w == IT_LIGHTNING)
        return 1;
    if (w == IT_ROCKET_LAUNCHER)
        return 2;
    if (w == IT_SUPER_NAILGUN)
        return 3;
    if (w == IT_GRENADE_LAUNCHER || w == IT_PROXIMITY_BOMB || w == IT_REMOTE_DETONATOR)
        return 4;
    if (w == IT_SUPER_SHOTGUN)
        return 5;
    if (w == IT_NAILGUN)
        return 6;
    if (w == IT_VOODOO_DOLL)
        return 7;
    return 8;
};

float (float w) WeaponCode =
{
    if (w == IT_SUPER_SHOTGUN)
        return 3;
    if (w == IT_NAILGUN)
        return 4;
    if (w == IT_SUPER_NAILGUN)
        return 5;
    if (w == IT_GRENADE_LAUNCHER || w == IT_PROXIMITY_BOMB || w == IT_REMOTE_DETONATOR)
        return 6;
    if (w == IT_ROCKET_LAUNCHER)
        return 7;
    if (w == IT_LIGHTNING)
        return 8;
    if (w == IT_VOODOO_DOLL)
        return 9;
    return 1;
};


/*
=============
Deathmatch_Weapon

Deathmatch weapon change rules for picking up a weapon

.float      ammo_shells, ammo_nails, ammo_rockets, ammo_cells;
=============
*/
void(float old, float new) Deathmatch_Weapon =
{
    local float or, nr;

    // change self.weapon if desired
    or = RankForWeapon (self.weapon);
    nr = RankForWeapon (new);
    if ( nr < or )
        self.weapon = new;
};

float() W_BestWeapon;

/*
=============
weapon_touch
=============
*/
void() weapon_touch =
{
    local   float   new, old;
    local   float   leave;
    local   entity  stemp;

    if (!(other.flags & FL_CLIENT))
        return;

    if (cvar ("g_weaponStay") || (!deathmatch && coop))  // Always leave weapons on SP coop
        leave = 1;
    else
        leave = 0;

    if (self.classname == "weapon_flaregun")
    {
        if (leave && (other.items & IT_SHOTGUN) )
            return;
        new = IT_SHOTGUN;
        other.ammo_flares = other.ammo_flares + 9;
    }
    else if (self.classname == "weapon_nailgun")
    {
        if (leave && (other.items & IT_NAILGUN) )
            return;
        new = IT_NAILGUN;
        other.ammo_nails = other.ammo_nails + 50;
    }
    else if (self.classname == "weapon_supernailgun")
    {
        if (leave && (other.items & IT_SUPER_NAILGUN) )
            return;
        new = IT_SUPER_NAILGUN;
        other.ammo_spray = other.ammo_spray + 48;
    }
    else if (self.classname == "weapon_supershotgun")
    {
        if (leave && (other.items & IT_SUPER_SHOTGUN) )
            return;
        new = IT_SUPER_SHOTGUN;
        other.ammo_shells = other.ammo_shells + 8;
    }
    else if (self.classname == "weapon_rocketlauncher")
    {
        if (leave && (other.items & IT_ROCKET_LAUNCHER) )
            return;
        new = IT_ROCKET_LAUNCHER;
        other.ammo_rockets = other.ammo_rockets + 6;
    }
    else if (self.classname == "weapon_grenadelauncher")
    {
        if (leave && (other.items & IT_GRENADE_LAUNCHER) )
            return;
        new = IT_GRENADE_LAUNCHER;
        other.ammo_tnt_bundle = other.ammo_tnt_bundle + 5;
    }
    else if (self.classname == "item_tnt")
    {
        new = IT_GRENADE_LAUNCHER;
        other.ammo_tnt_bundle = other.ammo_tnt_bundle + 1;
        leave = 0;
    }
    else if (self.classname == "weapon_proximity")
    {
        new = IT_PROXIMITY_BOMB;
        other.ammo_tnt_proxy = other.ammo_tnt_proxy + 1;
        leave = 0;
    }
    else if (self.classname == "weapon_remote")
    {
        new = IT_REMOTE_DETONATOR;
        other.ammo_tnt_remote = other.ammo_tnt_remote + 1;
        leave = 0;
    }
    else if (self.classname == "weapon_lightning")
    {
        if (leave && (other.items & IT_LIGHTNING) )
            return;
        new = IT_LIGHTNING;
        other.ammo_cells = other.ammo_cells + 64;
    }
    else if (self.classname == "weapon_voodoodoll")
    {
        if (leave && (other.items & IT_VOODOO_DOLL) )
            return;
        new = IT_VOODOO_DOLL;
        other.ammo_voodoo = other.ammo_voodoo + 100;
    }
    else
        objerror ("weapon_touch: unknown classname");

    Sprint (other, PRINT_LOW, "Picked up ");
    Sprint (other, PRINT_LOW, self.netname);
    Sprint (other, PRINT_LOW, "\n");

    // weapon touch sound
    sound (other, CHAN_ITEM, "items/weaponup.wav", 1, ATTN_NORM);
    stuffcmd (other, "bf\n");

    bound_other_ammo ();

    // change to the weapon
    old = other.items;
    other.items = other.items | new;

    stemp = self;
    self = other;

    if (!deathmatch)
        self.weapon = new;
    else
        Deathmatch_Weapon (old, new);

    W_SetCurrentAmmo();

    self = stemp;

    if (leave)
        return;

    // remove it in single player, or setup for respawning in deathmatch
    self.model = string_null;
    self.solid = SOLID_NOT;
    if (deathmatch)
        self.nextthink = time + 30;
    self.think = SUB_regen;

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};


/*QUAKED weapon_flaregun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_flaregun =
{
    precache_model ("progs/g_flare.mdl");
    setmodel (self, "progs/g_flare.mdl");
    self.weapon = IT_SHOTGUN;
    self.netname = "Flare Gun";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // precache the necessary sounds
    precache_sound ("weapons/flaregun/flaref.wav");
// PM:  For alt-flares.
    precache_sound ("weapons/napalm/explodfs.wav");

    StartItem ();
};

/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_supershotgun =
{
    precache_model ("progs/g_shot.mdl");
    setmodel (self, "progs/g_shot.mdl");
    self.weapon = IT_SUPER_SHOTGUN;
    self.netname = "Sawed-off";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
//    precache_sound ("weapons/shotgun/sawcock1.wav"); //same as shotcock.wav
    precache_sound ("weapons/shotgun/shotcock.wav");
    precache_sound ("weapons/shotgun/shotfir2.wav");  //shotgun alt-fire
    precache_sound ("weapons/shotgun/shotfire.wav");  // shotgun fired
//    precache_sound ("weapons/shotgun/shotload.wav");
    precache_sound ("weapons/shtshl2.wav");  // shell hitting ground
//    precache_sound ("weapons/shtshl4.wav");  // same as shtshl2.wav

    StartItem ();
};

/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_nailgun =
{
    precache_model ("progs/g_nail.mdl");
    setmodel (self, "progs/g_nail.mdl");
    self.weapon = IT_NAILGUN;
    self.netname = "Tommy Gun";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
    precache_sound ("weapons/tommygun/_tom.wav");  // Fire
//    precache_sound ("weapons/tommygun/tomcock.wav");  // Out of bullet noise
    precache_sound ("weapons/shtshl.wav");   // shell hitting ground
    precache_sound ("weapons/shtshl3.wav");  // shell hitting ground (2nd)

    StartItem ();
};

/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_supernailgun =
{
    precache_model ("progs/g_nail2.mdl");
    setmodel (self, "progs/g_nail2.mdl");
    self.weapon = IT_SUPER_NAILGUN;
    self.netname = "Spray Can";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
//    precache_sound ("weapons/spraycan/burstflm.wav");
//    precache_sound ("weapons/spraycan/spraycan.wav");
    precache_sound ("weapons/spraycan/sprayfir.wav");  // fire

    StartItem ();
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_grenadelauncher =
{
    precache_model ("progs/g_rock.mdl");
    setmodel (self, "progs/g_rock.mdl");
    self.weapon = IT_GRENADE_LAUNCHER;
    self.netname = "Dynamite";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');
    StartItem ();
};

//  TNT Bundle model
void() item_tnt =
{
    precache_model ("progs/i_tnt.mdl");
    setmodel (self, "progs/i_tnt.mdl");
    self.weapon = IT_GRENADE_LAUNCHER;
    self.netname = "Dynamite";
    self.touch = weapon_touch;
    setsize (self, '0 0 0', '32 32 32');
    StartItem ();
};


// Proximity grenade
void() weapon_proximity =
{
    precache_model ("progs/g_proxy.mdl");
    setmodel (self, "progs/g_proxy.mdl");
    self.weapon = IT_PROXIMITY_BOMB;
    self.netname = "Proximity Bomb";
    self.touch = weapon_touch;
    setsize (self, '0 0 0', '32 32 32');
    StartItem ();
};

// Remote Detonator model
void() weapon_remote =
{
    precache_model ("progs/g_remote.mdl");
    setmodel (self, "progs/g_remote.mdl");
    self.weapon = IT_REMOTE_DETONATOR;
    self.netname = "Remote Detonator";
    self.touch = weapon_touch;
    setsize (self, '0 0 0', '32 32 32');
    StartItem ();
};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_rocketlauncher =
{
    precache_model ("progs/g_rock2.mdl");
    setmodel (self, "progs/g_rock2.mdl");
    self.weapon = IT_ROCKET_LAUNCHER;
    self.netname = "Napalm Launcher";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    precache_model ("progs/naltball.mdl"); // napalm alt fire model

    // Precache the necessary sounds
    precache_sound ("weapons/napalm/blaster.wav");  // Napalm launcher
/*
    precache_sound ("weapons/napalm/explodcs.wav");
    precache_sound ("weapons/napalm/explodfl.wav");
    precache_sound ("weapons/napalm/burn.wav");
    precache_sound ("weapons/napalm/explodul.wav");
    precache_sound ("weapons/napalm/explodus.wav");
    precache_sound ("weapons/napalm/naplmex2.wav");
*/

    StartItem ();
};


/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_lightning =
{
    precache_model ("progs/g_light.mdl");
    setmodel (self, "progs/g_light.mdl");
    self.weapon = IT_LIGHTNING;
    self.netname = "Tesla Cannon";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds

    precache_sound ("weapons/tesla/taltac3.wav");
//    precache_sound ("weapons/tesla/tesaltf2.wav");
    precache_sound ("weapons/tesla/tessngfr.wav"); //single fire
    precache_sound ("weapons/tesla/tessnght.wav"); //single hit
//    precache_sound ("weapons/tesla/tesaltfr.wav"); // alt fire
    precache_sound ("weapons/tesla/tesaltht.wav"); //alt hit
//    precache_sound ("weapons/tesla/tesla1.wav"); // alt charge up
    precache_sound ("weapons/tesla/tessuper.wav"); //new alt fire charge up and fire

    StartItem ();
};


/*QUAKED weapon_voodoodoll (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_voodoodoll =
{
    precache_model ("progs/g_voodoo.mdl");
    setmodel (self, "progs/g_voodoo.mdl");
    self.weapon = IT_VOODOO_DOLL;
    self.netname = "Voodoo Doll";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
    precache_sound ("weapons/voodoodl/voolaugh.wav");
    precache_sound ("weapons/voodoodl/voostab.wav");
    precache_sound ("weapons/voodoodl/voochant.wav");

    StartItem ();
};


/*
===============================================================================

AMMO

===============================================================================
*/

void() ammo_touch =
{
local entity    stemp;
local float     best;

    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

    // if the player was using his best weapon, change up to the new one if better
    stemp = self;
    self = other;
    best = W_BestWeapon();
    self = stemp;


    // shotgun
    if (self.weapon == 1)
    {
        if (other.ammo_shells >= MAX_SHELLS)
            return;
        other.ammo_shells = other.ammo_shells + self.aflag;
    }
    // spikes
    else if (self.weapon == 2)
    {
        if (other.ammo_nails >= MAX_NAILS)
            return;
        other.ammo_nails = other.ammo_nails + self.aflag;
    }
    // rockets
    else if (self.weapon == 3)
    {
        if (other.ammo_rockets >= MAX_ROCKETS)
            return;
        other.ammo_rockets = other.ammo_rockets + self.aflag;
    }
    // cells
    if (self.weapon == 4)
    {
        if (other.ammo_cells >= MAX_CELLS)
            return;
        other.ammo_cells = other.ammo_cells + self.aflag;
    }

    // Custom ammo below...
    // flares
    else if (self.weapon == 5)
    {
        if (other.ammo_cells >= MAX_FLARES)
            return;
        other.ammo_flares = other.ammo_flares + self.aflag;
    }
    // tnt bundle
    else if (self.weapon == 6)
    {
        if (other.ammo_cells >= MAX_TNT)
            return;
        other.ammo_tnt_bundle = other.ammo_tnt_bundle + self.aflag;
    }
    // tnt proxy
    else if (self.weapon == 7)
    {
        if (other.ammo_cells >= MAX_PROXY)
            return;
        other.ammo_tnt_proxy = other.ammo_tnt_proxy + self.aflag;
    }
    // tnt remote
    else if (self.weapon == 8)
    {
        if (other.ammo_cells >= MAX_REMOTE)
            return;
        other.ammo_tnt_remote = other.ammo_tnt_remote + self.aflag;
    }
    // spray can
    else if (self.weapon == 9)
    {
        if (other.ammo_cells >= MAX_SPRAY)
            return;
        other.ammo_spray = other.ammo_spray + self.aflag;
    }
    // voodoo doll
    else if (self.weapon == 10)
    {
        if (other.ammo_cells >= MAX_VOODOO)
            return;
        other.ammo_voodoo = other.ammo_voodoo + self.aflag;
    }
    // leech life
    else if (self.weapon == 11)
    {
        if (other.ammo_cells >= MAX_LEECH)
            return;
        other.ammo_leech = other.ammo_leech + self.aflag;
    }

    bound_other_ammo ();

    Sprint (other, PRINT_LOW, "Picked up ");
    Sprint (other, PRINT_LOW, self.netname);
    Sprint (other, PRINT_LOW, "\n");

    // ammo touch sound
    sound (other, CHAN_ITEM, "items/ammo.wav", 1, ATTN_NORM);
    stuffcmd (other, "bf\n");

    // change to a better weapon if appropriate
    if ( other.weapon == best )
    {
        stemp = self;
        self = other;
        self.weapon = W_BestWeapon();
        W_SetCurrentAmmo ();
        self = stemp;
    }

    // if changed current ammo, update it
    stemp = self;
    self = other;
    W_SetCurrentAmmo();
    self = stemp;

    // remove it in single player, or setup for respawning in deathmatch
    self.model = string_null;
    self.solid = SOLID_NOT;
    if (deathmatch)
        self.nextthink = time + 30;

    self.think = SUB_regen;

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};


#define AMMO_BIG 1

/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_shells =
{
    self.touch = ammo_touch;

    if (self.spawnflags & AMMO_BIG)
    {
        precache_model ("progs/i_boxshl.mdl");
        setmodel (self, "progs/i_boxshl.mdl");
        self.netname = "box of shotgun shells";
        self.aflag = 15;
    }
    else
    {
        precache_model ("progs/i_fewshl.mdl");
        setmodel (self, "progs/i_fewshl.mdl");
        self.netname = "4 shotgun shells";
        self.aflag = 4;
    }
    self.weapon = 1;
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};

/*QUAKED item_flares (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_flares =
{
    self.touch = ammo_touch;

    precache_model ("progs/i_flares.mdl");
    setmodel (self, "progs/i_flares.mdl");

    self.netname = "box of flares";
    self.aflag = 8;
    self.weapon = 5;

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};

/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_spikes =
{
    self.touch = ammo_touch;

    if (self.spawnflags & AMMO_BIG)
    {
        precache_model ("progs/i_drum.mdl");
        setmodel (self, "progs/i_drum.mdl");
        self.netname = "full drum of bullets";
        self.aflag = 100;
    }
    else
    {
        precache_model ("progs/i_fewblt.mdl");
        setmodel (self, "progs/i_fewblt.mdl");
        self.netname = "a few bullets";
        self.aflag = 15;
    }
    self.weapon = 2;
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};

/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_rockets =
{
    self.touch = ammo_touch;

    if (self.spawnflags & AMMO_BIG)
    {
        precache_model ("progs/i_gascan.mdl");
        setmodel (self, "progs/i_gascan.mdl");
        self.aflag = 6;
    }
    else
    {
        precache_model ("progs/i_gascan.mdl");
        setmodel (self, "progs/i_gascan.mdl");
        self.aflag = 6;
    }
    self.weapon = 3;
    self.netname = "gasoline cans";
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};


/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_cells =
{
    self.touch = ammo_touch;

    if (self.spawnflags & AMMO_BIG)
    {
        precache_model ("progs/i_teschg.mdl");
        setmodel (self, "progs/i_teschg.mdl");
        self.aflag = 32;
    }
    else
    {
        precache_model ("progs/i_teschg.mdl");
        setmodel (self, "progs/i_teschg.mdl");
        self.aflag = 32;
    }
    self.weapon = 4;
    self.netname = "tesla charges";
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};


// Rewritten to use 'item_*' ammo boxes.
// Some levels such as dm5.bsp use this function.

/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
*/

//-------------------------------
// Spawnflags for 'item_weapon'.
//-------------------------------
#define WEAPON_SHOTGUN  1
#define WEAPON_ROCKET   2
#define WEAPON_SPIKES   4
#define WEAPON_BIG      8

void() item_weapon =
{
    local   float   osf;    // Short for original spawnflags.

    osf = self.spawnflags;

    // Change spawnflags for use with the other ammo items.
    if (self.spawnflags & WEAPON_BIG)
        self.spawnflags = AMMO_BIG;
    else
        self.spawnflags = 0;

    if (osf & WEAPON_SHOTGUN)
    {
        self.classname = "item_shells";
        item_shells ();
        return;
    }
    if (osf & WEAPON_ROCKET)
    {
        self.classname = "item_rockets";
        item_rockets ();
        return;
    }
    if (osf & WEAPON_SPIKES)
    {
        self.classname = "item_spikes";
        item_spikes ();
        return;
    }

    dprint ("Undefined ammo at: ");
    dprint (vtos(self.origin));
    dprint ("\n");
    remove (self);
};


/*
===============================================================================

KEYS

===============================================================================
*/

void() key_touch =
{
local entity    stemp;
local float     best;

    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

    // Changed to .items2 since that is where key bits are stored.
    if (other.items2 & self.items2)
        return;

    Sprint (other, PRINT_LOW, "Picked up ");
    Sprint (other, PRINT_LOW, self.netname);
    Sprint (other,PRINT_LOW, "\n");

    sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");

    // Changed to .items2 since that is where key bits are stored.
    other.items2 = other.items2 | self.items2;

    if (!coop)
    {
        self.solid = SOLID_NOT;
        self.model = string_null;
    }

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};


/*QUAKED item_key (0 .5 .8) (-16 -16 -24) (16 16 32)
one of six keys in Blood
the following keys need to exist in single player qBlood:
Skull, Eye, Fire, Dagger, Spider, Moon
*/
void() item_key =
{
    if ((self.spawnflags & 63) == 0)
    {
        // Convert to skull key.
        dprint ("No key type -- converted to skull type.\n");
        self.spawnflags = self.spawnflags | 1;
    }

    if (self.spawnflags & 32)
    {
        precache_model ("progs/b_g_key.mdl");
        setmodel (self, "progs/b_g_key.mdl");
        self.netname    = "moon key";
        self.items2     = IT2_KEY6;
    }
    else if (self.spawnflags & 16)
    {
        precache_model ("progs/b_s_key.mdl");
        setmodel (self, "progs/b_s_key.mdl");
        self.netname    = "spider key";
        self.items2     = IT2_KEY5;
    }
    else if (self.spawnflags & 8)
    {
        precache_model ("progs/m_g_key.mdl");
        setmodel (self, "progs/m_g_key.mdl");
        self.netname    = "dagger key";
        self.items2     = IT2_KEY4;
    }
    else if (self.spawnflags & 4)
    {
        precache_model ("progs/m_s_key.mdl");
        setmodel (self, "progs/m_s_key.mdl");
        self.netname    = "fire key";
        self.items2     = IT2_KEY3;
    }
    else if (self.spawnflags & 2)
    {
        precache_model ("progs/w_g_key.mdl");
        setmodel (self, "progs/w_g_key.mdl");
        self.netname    = "eye key";
        self.items2     = IT2_KEY2;
    }
    else if (self.spawnflags & 1)
    {
        precache_model ("progs/w_s_key.mdl");
        setmodel (self, "progs/w_s_key.mdl");
        self.netname    = "skull key";
        self.items2     = IT2_KEY1;
    }
    else
    {
        dprint ("No key type -- removed!\n");
        remove (self);
        return;
    }

    precache_sound ("items/pickkey.wav");
    self.noise  = "items/pickkey.wav";
    self.touch  = key_touch;
    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};

/*QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32)
*/
void() item_key1 =
{
    self.spawnflags = 1;    // For compatibility with Quake maps.
    self.classname = "item_key";
    item_key ();
};
/*QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32)
*/
void() item_key2 =
{
    self.spawnflags = 2;    // For compatibility with Quake maps.
    self.classname = "item_key";
    item_key ();
};


/*
===============================================================================

END OF LEVEL RUNES

===============================================================================
*/

void() sigil_touch =
{
local entity    stemp;
local float     best;

    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

    centerprint (other, "Picked up the rune!");

    sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");
    self.solid = SOLID_NOT;
    self.model = string_null;
    serverflags = serverflags | (self.spawnflags & 15);
    self.classname = "";        // so rune doors won't find it

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};


/*QUAKED item_sigil (0 .5 .8) (-16 -16 -24) (16 16 32) E1 E2 E3 E4
End of level sigil, pick up to end episode and return to jrstart.
*/

void() item_sigil =
{
    if (!self.spawnflags)
        objerror ("no spawnflags");

    precache_sound ("items/pickkey.wav");  // runekey
    self.noise = "items/pickkey.wav";

    if (self.spawnflags & 1)
    {
        precache_model ("progs/end1.mdl");
        setmodel (self, "progs/end1.mdl");
    }
    if (self.spawnflags & 2)
    {
        precache_model2 ("progs/end2.mdl");
        setmodel (self, "progs/end2.mdl");
    }
    if (self.spawnflags & 4)
    {
        precache_model2 ("progs/end3.mdl");
        setmodel (self, "progs/end3.mdl");
    }
    if (self.spawnflags & 8)
    {
        precache_model2 ("progs/end4.mdl");
        setmodel (self, "progs/end4.mdl");
    }

    self.touch = sigil_touch;
    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};

/*
===============================================================================

POWERUPS

===============================================================================
*/


/*QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invulnerable for 30 seconds
*/
void() item_artifact_invulnerability =
{
    self.touch = powerup_touch;

    precache_model ("progs/invulner.mdl");
    precache_sound ("bludbath/powerup.wav");
    self.noise = "bludbath/powerup.wav";
    setmodel (self, "progs/invulner.mdl");
    self.netname = "Death mask";
    #ifdef QUAKEWORLD
    self.effects = self.effects | EF_RED;
    #endif
    self.items = IT_INVULNERABILITY;
    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};

/*QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
Player takes no damage from water or slime for 30 seconds
*/
void() item_artifact_envirosuit =
{
    self.touch = powerup_touch;

    precache_model ("progs/suit.mdl");
    precache_sound ("foley/frbreath.wav");
    precache_sound ("foley/uwbreath.wav");
    precache_sound ("items/pickup.wav");
    self.noise = "items/pickup.wav";
    setmodel (self, "progs/suit.mdl");
    self.netname = "Diving Suit";
// PM:  Diving suit/IT_SUIT controlled by inventory.
    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};


/*QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invisible for 30 seconds
*/
void() item_artifact_invisibility =
{
    self.touch = powerup_touch;

    precache_model ("progs/invisibl.mdl");
    precache_sound ("bludbath/powerup.wav");
    self.noise = "bludbath/powerup.wav";
    setmodel (self, "progs/invisibl.mdl");
    self.netname = "Cloak of Invisibility";
    self.items = IT_INVISIBILITY;
    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};


/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
The next attack from the player will do 4x damage
*/
void() item_artifact_super_damage =
{
    self.touch = powerup_touch;

    precache_model ("progs/quaddama.mdl");
    precache_sound ("bludbath/powerup.wav");
    self.noise = "bludbath/powerup.wav";
    setmodel (self, "progs/quaddama.mdl");

    self.netname = "Guns Akimbo";
// PM:  Reflective shots now use IT_QUAD instead.
    #ifdef QUAKEWORLD
    self.effects = self.effects | EF_BLUE;
    #endif

    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};



/*
===============================================================================

PLAYER BACKPACKS

===============================================================================
*/

void() BackpackTouch =
{
    local   string  s;
    local   float   best, old, new;
    local   entity  stemp;
    local   float   acount;

    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

    acount = 0;
    Sprint (other, PRINT_LOW, "You get ");

    if (self.items)
        if ((other.items & self.items) == 0)
        {
            acount = 1;
            Sprint (other, PRINT_LOW, "the ");
            Sprint (other, PRINT_LOW, self.netname);
        }

    // change weapons
    other.ammo_shells = other.ammo_shells + self.ammo_shells;
    other.ammo_nails = other.ammo_nails + self.ammo_nails;
    other.ammo_rockets = other.ammo_rockets + self.ammo_rockets;
    other.ammo_cells = other.ammo_cells + self.ammo_cells;

    // Custom ammo.
    other.ammo_flares = other.ammo_flares + self.ammo_flares;
    other.ammo_tnt_bundle = other.ammo_tnt_bundle + self.ammo_tnt_bundle;
    other.ammo_tnt_proxy = other.ammo_tnt_proxy + self.ammo_tnt_proxy;
    other.ammo_tnt_remote = other.ammo_tnt_remote + self.ammo_tnt_remote;
    other.ammo_spray = other.ammo_spray + self.ammo_spray;
    other.ammo_voodoo = other.ammo_voodoo + self.ammo_voodoo;
    other.ammo_leech = other.ammo_leech + self.ammo_leech;

    new = self.items;
    if (!new)
        new = other.weapon;
    old = other.items;
    other.items = other.items | new;

    bound_other_ammo ();

    if (self.ammo_shells)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_shells);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " shells");  // "Box of shotgun shells"
    }
    if (self.ammo_nails)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_nails);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " nails");  // "Full drum of bullets"
    }
    if (self.ammo_rockets)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_rockets);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " rockets");  // "Gasoline Can"
    }
    if (self.ammo_cells)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_cells);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " cells");  // "Tesla Charge"
    }

    // Custom ammo.
    if (self.ammo_flares)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_flares);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " flares");
    }
    if (self.ammo_tnt_bundle)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_tnt_bundle);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " TNT");

        other.items = other.items | IT_GRENADE_LAUNCHER;
    }
    if (self.ammo_tnt_proxy)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_tnt_proxy);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " proximity bombs");

        other.items = other.items | IT_PROXIMITY_BOMB;
    }
    if (self.ammo_tnt_remote)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_tnt_remote);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " remote detonators");

        other.items = other.items | IT_REMOTE_DETONATOR;
    }
    if (self.ammo_spray)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_spray);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " units of spray can");
    }
    if (self.ammo_voodoo)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_voodoo);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " units of voodoo magic");
    }
    if (self.ammo_leech)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_leech);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " trapped souls");
    }
    Sprint(other, PRINT_LOW, "\n");

    // backpack touch sound
    sound (other, CHAN_ITEM, "items/ammo.wav", 1, ATTN_NORM);
    stuffcmd (other, "bf\n");

    // remove the backpack, change self to the player
    remove(self);
    self = other;

    // change to the weapon
    if (!deathmatch)
        self.weapon = new;
    else
        Deathmatch_Weapon (old, new);

    W_SetCurrentAmmo ();
};

/*
===============
DropBackpack
===============
*/
void() DropBackpack =
{
    local entity    item;

    if (!(self.ammo_shells + self.ammo_nails + self.ammo_rockets + self.ammo_cells))
        return; // nothing in it

    item = spawn();
    item.origin = self.origin - '0 0 24';

    // If the current weapon is dynamite, don't record it (it's just ammo)
    if (self.weapon = IT_GRENADE_LAUNCHER ||
        self.weapon == IT_PROXIMITY_BOMB  ||
        self.weapon == IT_REMOTE_DETONATOR)
    {
        item.items = 0;
        item.netname = "";
    }
    // else, record the weapon name
    else
    {
        item.items = self.weapon;
        if (item.items == IT_AXE)
            item.netname = "Pitchfork";
        else if (item.items == IT_SHOTGUN)
            item.netname = "Flare Gun";
        else if (item.items == IT_SUPER_SHOTGUN)
            item.netname = "Sawed-off";
        else if (item.items == IT_NAILGUN)
            item.netname = "Tommy Gun";
        else if (item.items == IT_SUPER_NAILGUN)
            item.netname = "Spray Can";
        else if (item.items == IT_ROCKET_LAUNCHER)
            item.netname = "Napalm Launcher";
        else if (item.items == IT_LIGHTNING)
            item.netname = "Tesla Cannon";
        else if (item.items == IT_VOODOO_DOLL)
            item.netname = "Voodoo Doll";
        else
            item.netname = "";
    }

    item.ammo_shells = self.ammo_shells;
    item.ammo_nails = self.ammo_nails;
    item.ammo_rockets = self.ammo_rockets;
    item.ammo_cells = self.ammo_cells;

    // Custom ammo.
    item.ammo_flares = self.ammo_flares;
    item.ammo_tnt_bundle = self.ammo_tnt_bundle;
    item.ammo_tnt_proxy = self.ammo_tnt_proxy;
    item.ammo_tnt_remote = self.ammo_tnt_remote;
    item.ammo_spray = self.ammo_spray;
    item.ammo_voodoo = self.ammo_voodoo;
    item.ammo_leech = self.ammo_leech;

    item.velocity_z = 300;
    item.velocity_x = -100 + (random() * 200);
    item.velocity_y = -100 + (random() * 200);

    item.flags = FL_ITEM;
    item.solid = SOLID_TRIGGER;
    item.movetype = MOVETYPE_TOSS;
    setmodel (item, "progs/backpack.mdl");
    setsize (item, '-16 -16 0', '16 16 56');
    item.touch = BackpackTouch;

    item.nextthink = time + 120;    // remove after 2 minutes
    item.think = SUB_Remove;
};
