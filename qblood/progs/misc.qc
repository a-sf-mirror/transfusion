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

void() func_wall_go_up;
void() func_wall_go_down;

void() wall_killed;

// Used as a positional target for spotlights, etc
void() info_null =
{
    remove(self);
};

// Used as a positional target for lightning
void() info_notnull =
{
};

// Emit a fire ambient sound
void() FireAmbient =
{
    precache_sound ("ambience/sizzle.wav");
    ambientsound (self.origin, "ambience/sizzle.wav", 0.4, ATTN_STATIC);
};


//============================================================================


void() light_use =
{
    if (self.spawnflags & START_OFF)
    {
        lightstyle(self.style, "m");
        self.spawnflags = self.spawnflags - START_OFF;
    }
    else
    {
        lightstyle(self.style, "a");
        self.spawnflags = self.spawnflags + START_OFF;
    }
};

// Invisible lightsource
// Default light value is 300, default style is 0
// If targeted, it will toggle between on or off.
void() light =
{
    // Inert light
    if (!self.targetname)
    {
        remove(self);
        return;
    }

    // Styles < 32 are reserved
    if (self.style >= 32)
    {
        self.use = light_use;
        if (self.spawnflags & START_OFF)
            lightstyle(self.style, "a");
        else
            lightstyle(self.style, "m");
    }
};

// Fluorescent light
// As "light" + makes steady fluorescent humming sound
void() light_fluoro =
{
    precache_sound ("ambience/amb2.wav");
    ambientsound (self.origin, "ambience/amb2.wav", 0.5, ATTN_STATIC);

    light ();
};

// Sparking fluorescent light
// Makes sparking, broken fluorescent sound
// Default style is 10 (0 forced to 10)
void() light_fluorospark =
{
    if (!self.style)
        self.style = 10;

    precache_sound ("ambience/elecgen2.wav");
    ambientsound (self.origin, "ambience/elecgen2.wav", 0.5, ATTN_STATIC);
};

// Globe light
void() light_globe =
{
    precache_model ("progs/s_light.spr");
    setmodel (self, "progs/s_light.spr");
    makestatic (self);
};

// Generic code for the following torches / flames
void(string flame_model) light_flame_generic =
{
    precache_model (flame_model);
    setmodel (self, flame_model);

    FireAmbient ();
    makestatic (self);
};

// Small wall torch
void() light_torch_small_walltorch =
{
    light_flame_generic ("progs/flame.spr");
};

// Large yellow flame
void() light_flame_large_yellow =
{
    light_flame_generic ("progs/flame2.spr");
};

// Small yellow flame
void() light_flame_small_yellow =
{
    light_flame_generic ("progs/flame.spr");
};

//============================================================================

void() barrel_reset =
{
    self.solid = SOLID_BBOX;
    self.takedamage = DAMAGE_AIM;
    self.classname = "exploding_barrel";
    self.model = "models/world/barrel.md3";
    self.health = self.max_health;
};

//  This fixes a bug in which barrel explosions cancel other explosions.
//  Here, the barrel explosion is delayed for one frame so that other
//  explosions can occur without interference from the barrel.
void() barrel_damage =
{
    local entity tempEnt;

    // If the warmup hasn't been done, don't really destroy it
    if (! warmup_done)
    {
        self.solid = SOLID_NOT;
        self.model = string_null;

        tempEnt = self;
        self = spawn ();
        self.dmg = tempEnt.dmg;
        self.origin = tempEnt.origin;
    }

    KillBurner (self);

    setorigin (self, self.origin + '0 0 32');

    if (self.dmg > 0)    // If we only want the flashy effects don't do damahe
        T_RadiusDamage (self, self, self.dmg, world, string_null);

    sound (self, CHAN_VOICE, "weapons/napalm/explodfl.wav", 1, ATTN_NORM);
    particle (self.origin, '0 0 0', 75, 255);
    BecomeExplosion ();

    if (! warmup_done)
        self = tempEnt;
};

void() barrel_explode =
{
    self.takedamage = DAMAGE_NO;
    self.classname = "explo_box";
    self.nextthink = time + 0.1;
    self.think = barrel_damage;
};


void() exploding_barrel =
{
    local float oldz;

    self.solid = SOLID_BBOX;
    self.movetype = MOVETYPE_NONE;
    precache_model ("models/world/barrel.md3");
    setmodel (self, "models/world/barrel.md3");
    setsize (self, '-16 -16 0', '16 16 32');
    precache_sound ("weapons/napalm/explodfl.wav");
    if (!self.dmg)
        self.dmg = 240;
    self.health = self.max_health = 20;
    self.reset = barrel_reset;
    self.th_die = barrel_explode;
    self.use = barrel_explode;
    self.takedamage = DAMAGE_AIM;
    self.touch = SUB_SolidTouch;

    self.origin_z = self.origin_z + 2;
    oldz = self.origin_z;
    droptofloor();
    if (oldz - self.origin_z > 250)
    {
        dprint ("item fell out of level at ");
        dprint (vtos(self.origin));
        dprint ("\n");
        remove(self);
    }
};

void() hidden_explosion =
{
    if (self.dmg > 0)
        T_RadiusDamage (self, self.owner, self.dmg, world, "hidden");

    sound (self, CHAN_WEAPON, self.noise, 1, ATTN_NORM);



    if (self.style >= 1 && self.style <= 6)
    {
        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);

        // Use neato opengl explosion splash
        if (self.style == 1)
            WriteByte (MSG_BROADCAST, TE_EXPLOSION);

        // Pinkish light, then splash
        else if (self.style == 2)
            WriteByte (MSG_BROADCAST, TE_TAREXPLOSION);

        // red circles floating upward
        else if (self.style == 3)
        WriteByte (MSG_BROADCAST, TE_LAVASPLASH);

        // white circle
        else if (self.style == 4)
            WriteByte (MSG_BROADCAST, TE_TELEPORT);

        // larger than default explosion
        else if (self.style == 5)
            WriteByte (MSG_BROADCAST, TE_TEI_BIGEXPLOSION);

        // large particle based explosion
        else if (self.style == 6)
            WriteByte (MSG_BROADCAST, TE_EXPLOSION2);

        // default to explosion
        else
            WriteByte (MSG_BROADCAST, TE_EXPLOSION);

        WriteCoord (MSG_BROADCAST, self.origin_x);
        WriteCoord (MSG_BROADCAST, self.origin_y);
        WriteCoord (MSG_BROADCAST, self.origin_z);

        if (self.style == 6)
        {
            WriteByte  (MSG_BROADCAST, self.colormap);
            WriteByte  (MSG_BROADCAST, 3);
        }

        remove(self);
    }

    // or use blood sprite explosion
    else
        BecomeExplosion ();

        if (self.target)
            SUB_UseTargets();
};

void() hidden_use =
{
    if (self.delay > 0)  // If there's a delay
        {
          self.nextthink = time + self.delay;
          self.think = hidden_explosion;
        }

    else                     // Otherwise blast immediately
        hidden_explosion();
};

void() hidden_exploder =
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;

    if (!self.noise)
        self.noise = "weapons/napalm/explodfl.wav";
    if (!self.colormap)
        self.colormap = 195;

    precache_sound (self.noise);
    self.use = hidden_use;
};


void() shake_screen =
{
    local entity ent;
	
	if (self.dmgtime <= 0)
	{
	    remove(self);
		return;
	}
	
	
	ent = findradius(self.origin, self.dmg);
	
	while (ent != world)
    {	    
	    if (ent.classname == "player")
		{            
		    ent.punchangle_x = rint(random() * 3) - 1;
	        ent.punchangle_y = rint(random() * 3) - 1;
	        ent.punchangle_z = rint(random() * 3) - 1;		
		}	
	    ent = ent.chain;
	}
	
	self.dmgtime = self.dmgtime - 0.1;
	
	self.think = shake_screen;
	self.nextthink = time + 0.1;

};

void () shake_start =
{
    local entity shaker;
	local entity temp;
	
	temp = find(world, classname, "player");
	
	if (temp != world)
	{
	    bprint("Shaker made\n");
		shaker = spawn();
	    shaker.origin = temp.origin;
	    shaker.dmgtime = 5;
        shaker.dmg = 1000;
		shaker.think = shake_screen;
	    shaker.nextthink = time + 0.1;
	}
};


/*
===========================================================================
TRAPS

Tommy Gun Trap - shoots steady stream of bullets for 30 seconds
Flame Trap - shoots stream of fire for 30 seconds
Napalm Trap - shoots one napalm shot every 5 seconds until switched off
===========================================================================
*/

// ------ Tommy Gun Trap ------ //

void() trap_tommygun_think =
{
    local vector aim_vec;

    sound (self, CHAN_WEAPON, "weapons/tommygun/_tom.wav", 1, ATTN_NORM);

    makevectors (self.v_angle);
    aim_vec = aim (self, 1000);
    FireBullets (self.origin, aim_vec, 1, 5, '0.05 0.02 0');

    // Continue until we have shot all our bullets
    self.ammo_nails = self.ammo_nails - 1;
    if (self.ammo_nails)
        self.nextthink = time + 0.1;
};

void() trap_tommygun_use =
{
    if (!self.ammo_nails)
    {
        self.ammo_nails = 300;  // 300 bullets * 0.1 sec = 30 sec
        self.think = trap_tommygun_think;
        self.nextthink = time + 0.1;
    }
    else
    {
        self.ammo_nails = 0;
        self.think = SUB_Null;
    }
};

void() trap_tommygun =
{
    precache_sound ("weapons/tommygun/_tom.wav");

    self.v_angle = self.angles;

    self.use = trap_tommygun_use;
};


// ------ Flame Trap ------ //

void() trap_flame_think =
{
    if (self.t_width < time)
    {
        sound (self, CHAN_WEAPON, "weapons/spraycan/sprayfir.wav", 0.5, ATTN_NORM);
        self.t_width = time + 2.5;
    }

    Spray_Fire ();

    if (self.ammo_spray)
        self.nextthink = time + 0.1;
    else
        sound (self, CHAN_WEAPON, "misc/null.wav", 0, ATTN_NORM);
};

void() trap_flame_use =
{
    if (self.think == SUB_Null)
    {
        self.ammo_spray = 300;  // 300 fire clouds * 0.1 sec = 30 sec
        self.nextthink = time + 0.1;
        self.t_width = 0;
        self.think = trap_flame_think;
    }
    else
        self.think = SUB_Null;
};

void() trap_flame =
{
    precache_sound ("weapons/spraycan/sprayfir.wav");
    precache_model ("progs/sprayfir.spr");

    self.v_angle = self.angles;

    // a little hack so it will shot from its origin...
    makevectors (self.v_angle);
    self.origin = self.origin - '0 0 10' - v_forward * 50 - v_right * 8;

    self.player_state = PS_FIRE;

    self.use = trap_flame_use;
    self.think = SUB_Null;
};


// ------ Napalm trap ------ //

void() trap_napalm_think =
{
    Napalm_Fire ();
    self.ammo_rockets = 999;
    self.nextthink = time + 5;
};

void() trap_napalm_use =
{
    if (self.think == SUB_Null)
    {
        self.think = trap_napalm_think;
        self.nextthink = time + 5;
    }
    else
        self.think = SUB_Null;
};

void() trap_napalm =
{
    precache_sound ("weapons/napalm/blaster.wav");
    precache_model ("models/weapons/objects/napalm.md3");

    // a little hack so it will shot from its origin...
    self.origin = self.origin - '0 0 16';

    self.v_angle = self.angles;

    self.player_state = PS_FIRE;
    self.ammo_rockets = 999;

    self.use = trap_napalm_use;
    self.think = SUB_Null;
};


/*
===========================================================================
SENTRIES

these entities are like sector effects in BUILD - when they 'see' a player
come near, they emit a sound to alert other players in the match that
someone has entered a 'special' area containing a powerup.
===========================================================================
*/

void() sentry_detect_think =
{
    local entity ent;
    local float lcnt;

    // store count of players in .cnt
    lcnt = 0;
    ent = findradius (self.origin, 200);
    while (ent)
    {
        if (ent.classname == "player")
            lcnt = lcnt + 1;
        ent = ent.chain;
    }

    // If the someone has entered the area since the last check
    // NOTE: there's a mimimum time between each warning (6 sec)
    if (lcnt > self.cnt && self.ltime < time)
    {
        sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
        self.ltime = time + 6;
    }

    // Update sentry data
    self.cnt = lcnt;
    self.nextthink = time + 0.2;  // check every 200 ms
};

void(string soundname) sentry_detect_init =
{
    // Set parameters
    self.noise = soundname;

    // Initialize some stuff
    precache_sound (self.noise);
    self.nextthink = time + 0.2;  // check every 200 ms
    self.think = sentry_detect_think;
};

// Howling sound
void() sentry_detect_crypt = { sentry_detect_init ("misc/b2_crypt.wav"); };

// Custom sentry (sound chosen by mapper)
void() sentry_detect_custom = { sentry_detect_init (self.noise); };

// Laugh sound
void() sentry_detect_laugh = { sentry_detect_init ("ambience/laugh.wav"); };

// Switch sound
void() sentry_detect_switch1 = { sentry_detect_init ("locks/switch1.wav"); };

// Thunder sound
void() sentry_detect_thunder = { sentry_detect_init ("ambience/thunder3.wav"); };


/*
==============================================================================

SIMPLE BMODELS

==============================================================================
*/

void() func_wall_use =
{   // change to alternate textures
    self.frame = 1 - self.frame;
};


void() func_wall_hit_top =
{
    self.state = STATE_TOP;
    func_wall_go_down();
};

void() func_wall_hit_bottom =
{
    self.state = STATE_BOTTOM;
    func_wall_go_up();
};

void() func_wall_go_down =
{
    self.state = STATE_DOWN;
    SUB_CalcMove (self.pos1, self.speed, func_wall_hit_bottom);
};

void() func_wall_go_up =
{
    self.state = STATE_UP;
    SUB_CalcMove (self.pos2, self.speed, func_wall_hit_top);
};

/*QUAKED func_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
*/

void() func_wall =
{
    self.movetype = MOVETYPE_PUSH;  // so it doesn't get pushed by anything
    self.solid = SOLID_BSP;
    setmodel (self, self.model);

    if (!self.style)
    {
        self.angles = '0 0 0';
        self.use = func_wall_use;
    }
    else
    {

    SetMovedir ();
    setorigin (self, self.origin);

    if (!self.speed)
        self.speed = 100;
    if (!self.lip)
        self.lip = 8;

    self.pos1 = self.origin;
    self.pos2 = self.pos1 + self.movedir*(fabs(self.movedir*self.size) - self.lip);

    func_wall_go_up();
    }
};


/*QUAKED func_illusionary (0 .5 .8) ?
A simple entity that looks solid but lets you walk through it.
*/
void() func_illusionary =

{
    self.angles = '0 0 0';
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;
    setmodel (self, self.model);
    makestatic (self);
};



void() func_transparent =

{
   	if (!self.alpha)
	    self.alpha = 0.5;

	self.angles = '0 0 0';
    self.movetype = MOVETYPE_NONE;

    if (!self.style)
        self.solid = SOLID_BSP;
	else
        self.solid = SOLID_NOT;
		
    setmodel (self, self.model);
    makestatic (self);	
};


/*
==============================================================================
EXPLODING WALLS

The following code was originally donated by Than
Modified by Mathieu Olivier
==============================================================================
*/

// exploding_wall
// original code taken from Zerstorer
// heavily modified by than 04.2001

void() brik_touch =
{
    if (self.velocity == '0 0 0')
    {
        self.avelocity = '0 0 0';
        self.solid = SOLID_NOT;
        self.touch = SUB_Null;
        self.think = SUB_Remove;
        self.nextthink = time + (6 * random()) + 2;
        return;
    }
    if (! self.cnt)
        return;

    if (self.attack_finished < time && pointcontents (self.origin) > -3)
    {
        // bounce sound
        if (self.noise1) // if noise has been set, sound is enabled so play sounds
        {
            if (self.cnt == 1)
                sound (self, CHAN_AUTO, self.noise1, 1, ATTN_NORM);
            else
                sound (self, CHAN_AUTO, self.noise2, 1, ATTN_NORM);
        }

        self.attack_finished = time + 0.3;
    }
};

void(string gibname, float dm) ThrowRubble=
{
    local entity new;
    local float sndrnd;

    new = spawn();
    sndrnd = random();
    // new.origin = self.origin doesnt work because the origin is at world (0,0,0).
    new.origin_x = self.absmin_x + (random() * self.size_x);
    new.origin_y = self.absmin_y + (random() * self.size_y);
    new.origin_z = self.absmin_z + (random() * self.size_z);
    setmodel (new, gibname);
    setsize (new, '0 0 0', '0 0 0');

    if (sndrnd < 0.25)
        new.cnt = 1;
    else if (sndrnd < 0.5)
        new.cnt = 2;

    // set the skin of the piece of rubble/glass
    if (self.skin <= 4)  // rubble models have 4 skins
        new.skin = self.skin;
    else
        new.skin = self.skin - 5;   // glass model has 2 skins, so if mapper sets skin to "5", use first skin in model
                                    // else if mapper has chosen skin 6, so use skin1 in the actual model

    // set the proper noise
    if (self.noise1)
    {
        new.noise1 = self.noise1;  // set noise1 for the rubble
        new.noise2 = self.noise2;  // set noise2 for the rubble
    }
    new.velocity = VelocityForDamage (dm);
    new.movetype = MOVETYPE_BOUNCE;
    new.classname = "rubble";
    new.solid = SOLID_TRIGGER;
    new.effects = EF_LOWPRECISION;
    new.touch = brik_touch;
    new.avelocity_x = random()*600;
    new.avelocity_y = random()*600;
    new.avelocity_z = random()*600;
    new.think = SUB_Remove;
    new.ltime = time;
    new.nextthink = time + 3 + random()*2;
    new.frame = 0;
    new.flags = 0;
};

void() wall_reset =
{
    if (self.spawnflags & 4)
        self.solid = SOLID_BSP;
    else
        self.solid = SOLID_BBOX;

    if (! (self.spawnflags & 1))
    {
        self.takedamage = DAMAGE_AIM;
        self.health = self.max_health;
    }

    self.model = self.mdl;
};


// called when the wall is destroyed.
// throws gibs (rubble).
void () wall_killed =
{
    // If the warmup hasn't been done, don't really destroy it
    if (! warmup_done)
    {
        self.solid = SOLID_NOT;
        self.model = string_null;
    }

    // spawnflag 8 is no longer needed since noise would be set if sound is on
    if (self.noise)
    {
        local entity sndspot;
        sndspot = spawn();
        sndspot.origin = self.absmin;
        setorigin(sndspot, sndspot.origin);
        sound (sndspot, CHAN_AUTO, self.noise, 1, ATTN_NORM);
        remove(sndspot);
    }

    if (! (self.spawnflags & 16)) // if rubble is not disabled
    {
        local float nbRubbles;

        // if cnt is not set, use object bbox volume to set it
        if (! self.cnt)
            self.cnt = (self.size_x * self.size_y * self.size_z) / 64000;
        if (self.cnt > 6)
            self.cnt = 6;

        nbRubbles = self.cnt;
        while (nbRubbles > 0)
        {
            if (self.skin > 4)
            {
                ThrowRubble ("models/objects/glass1.md3", self.health);
                ThrowRubble ("models/objects/glass2.md3", self.health);
                ThrowRubble ("models/objects/glass3.md3", self.health);
            }
            else
            {
                ThrowRubble ("models/objects/rubble1.md3", self.health);
                ThrowRubble ("models/objects/rubble2.md3", self.health);
                ThrowRubble ("models/objects/rubble3.md3", self.health);
            }

            nbRubbles = nbRubbles - 1;
        }
    }

    activator = self;
    SUB_UseTargets();

    // We only remove it if the warmup has been done
    if (warmup_done)
        remove (self);
};

void() wall_pain =
{
    // If it's not enough to destroy the wall and if it's a "one shot kill" wall
    if ((self.spawnflags & 2) && self.health > 0)
        self.health = self.max_health;
};

void() wall_use =
{
    self.health = -50;
    wall_killed();
};

/*QUAKED exploding_wall
When the exploding wall is shot, it "gibs" into rubble. Since this has been changed, the entity
has become a lot more flexible and mapper friendly (not that it was hard to use before :). It
now also supports multiple material types (skin, which selects the sounds to be used also). The
amount of rubble thrown is based on the size of the entity by default but can be set manually.
However, it should be noted that cnt should be set between 1 and 6 and that the actual number of
pieces of rubble thrown is cnt*3 (the loop is faster this way).

**
Note: as an undocumented feature, you can disable sound using the spawnflag but then set noise,
noise1 and noise2 in the .map directly thus allowing the user to set their own custom sounds for
both the wall breaking and the rubble bouncing.
**

VARIABLES
"targetname"    allows the wall to be triggered by something else
"target"    all entities with a matching targetname will be used when killed
"health"    the amount of damage needed to destroy the wall instead of touched (default 15)
"skin"      the type of rubble to throw (default 0)
"cnt"       the amount of rubble to throw (default volume based)

SKIN TYPES
0 = grey concrete
1 = brown concrete
2 = red/brown bricks
3 = rusty metal
4 = rotten wood
5 = stained glass // d.turner
6 = regular glass // d.turner

SPAWNFLAGS
1 = the wall will not take damage when shot and will only break if triggered
2 = the wall will return to full health if not destroyed with one hit
4 = use bsp clipping rather than bounding box clipping
8 = play no sounds
16 = throw no rubble
32 = the wall will not take damage from non-explosive sources
*/
void() exploding_wall =
{
    setmodel (self, self.model);

    // Save the model name for wall_reset
    self.mdl = self.model;

    // Set to be destroyed by TNT only by default
    if ( (self.skin <= 3)      &&
	    !(self.spawnflags & 1) &&
		!(self.spawnflags & 2) &&
		!(self.spawnflags & 32))
	{
	    self.spawnflags = self.spawnflags | 32;
		self.health = 1;
	}
		
	// precache rubble models (two models used since red trails on gibs, grey on other rubble)
    if (! (self.spawnflags & 16))  // if rubble is not turned off
    {
        if (self.skin > 4)  // if skin is set to glass, use the glass shards instead - d.turner
        {
            precache_model ("models/objects/glass1.md3");
            precache_model ("models/objects/glass2.md3");
            precache_model ("models/objects/glass3.md3");			
        }
        else
        {
            precache_model ("models/objects/rubble1.md3");
            precache_model ("models/objects/rubble2.md3");
            precache_model ("models/objects/rubble3.md3");			
        }
    }

    // if sounds are not turned off
    if (! (self.spawnflags & 8))
    {
        // self.noise  - object breaking
        // self.noise1 - rubble bounce 1
        // self.noise2 - rubble bounce 2

        if (self.skin > 4)
        {
            self.noise = "misc/glashit2.wav";
            self.noise1 = "misc/glashit3.wav";
            self.noise2 = "misc/glashit4.wav";
        }

        else if (self.skin == 3)
        {
            self.noise = "misc/wb_metal.wav";
            self.noise1 = "misc/methit1.wav";
            self.noise2 = "misc/methit2.wav";
        }
        else if (self.skin == 4)
        {
            self.noise = "misc/wb_wood.wav";
            self.noise1 = "misc/woodhit1.wav";
            self.noise2 = "misc/woodhit2.wav";
        }
        else
        {
            self.noise = "misc/wb_brick.wav";
            self.noise1 = "misc/brikhit1.wav";
            self.noise2 = "misc/brikhit2.wav";
        }
    }

    // In case of a manual sound setting by the creator of the map
    if (self.noise)
        precache_sound(self.noise);
    if (self.noise1)
    {
        precache_sound(self.noise1);
        precache_sound(self.noise2);
    }

    // This flag toggles bsp/bounding box clipping
    if (self.spawnflags & 4)
        self.solid = SOLID_BSP;
    else
        self.solid = SOLID_BBOX;
    self.movetype = MOVETYPE_PUSH;

    // Only destroyable by triggering
    if (self.spawnflags & 1)
        self.takedamage = DAMAGE_NO;
    else
    {
        self.takedamage = DAMAGE_AIM;
        if (! self.health)
            self.health = 15;  // set default health if none set
    }

    self.max_health = self.health;
    self.reset = wall_reset;
    self.th_pain = wall_pain;
    self.th_die = wall_killed;

    if (self.targetname)
        self.use = wall_use;
};


/*
==============================================================================

DECALS

The initial code was shamelessly borrowed from the DarkPlaces mod

==============================================================================
*/

void() decal_custom =
{
    local vector dir, org, dirangles;

    // The model must be set by the mapper
    if (self.model == "")
        objerror ("A decal must have a sprite model");

    // Look backward to see if we can stick to a wall nearby
    makevectors (self.angles);
    dir = normalize (v_forward) * -100;
    traceline (self.origin, self.origin + dir, TRUE, world);

    // If we can't find any wall behind the decal
    if (trace_fraction >= 1 || trace_ent.solid != SOLID_BSP)
        objerror ("Can't attach to a wall");

    // Push the decal origin off the surface
    dir = normalize (trace_plane_normal);
    org = trace_endpos + dir;

    // Orient the bullet hole properly
    // NOTE: due to a bug in the Quake engine, it has to be done that way
    dirangles = vectoangles ('0 0 0' - dir);
    dirangles_x = 0 - dirangles_x;

    // Finally, we initialize the entity
    precache_model (self.model);
    setmodel (self, self.model);
    self.angles = dirangles;
    setorigin (self, org);
    setsize (self, '0 0 0', '0 0 0');

    // If the surface may move, we must follow it
    if (trace_ent != world)
    {
        if (!checkextension ("DP_MOVETYPEFOLLOW"))
            error ("The engine doesn't support the DP_MOVETYPEFOLLOW extension.\n"
                   "You can't put decals on non-static walls.");

        self.solid = SOLID_NOT;
        self.movetype = MOVETYPE_FOLLOW;

        // MOVETYPE_FOLLOW needs a few more informations
        self.aiment = trace_ent;
        self.view_ofs = self.origin - trace_ent.origin;
        self.punchangle = trace_ent.angles;
        self.v_angle = self.angles - trace_ent.angles;
    }
    else
        makestatic (self);
};


//============================================================================

void() sound_player_use =
{
    if (self.noise)
        sound (self, CHAN_AUTO, self.noise, 1, ATTN_NORM);
};

void() sound_player =
{
    if (self.noise)
        precache_sound (self.noise);
    self.use = sound_player_use;
};


//============================================================================

void(string soundname, float volume, float atten) ambient_generic_vol_attn =
{
    precache_sound (soundname);
    ambientsound (self.origin, soundname, volume, atten);
    remove (self);  // we don't need the entity anymore
};

// Ambient sounds with custom attenuation
void(string soundname, float atten) ambient_generic_attn =
{
    ambient_generic_vol_attn (soundname, 1, atten);
};

void() ambient_hrtbt    = { ambient_generic_attn ("ambience/hrtbt.wav", ATTN_NONE);     };
void() ambient_eriedrne = { ambient_generic_attn ("ambience/eriedrne.wav", ATTN_NONE);  };


// Ambient sounds with custom volume
void(string soundname, float volume) ambient_generic_vol =
{
    ambient_generic_vol_attn (soundname, volume, ATTN_STATIC);
};

void() ambient_drip     = { ambient_generic_vol ("ambience/drip3.wav", 0.5);    };
void() ambient_sizzle   = { ambient_generic_vol ("ambience/sizzle.wav", 0.4);   };
void() ambient_sizzle1  = { ambient_generic_vol ("ambience/sizzle1.wav", 0.4);  };
void() ambient_sizzle2  = { ambient_generic_vol ("ambience/sizzle2.wav", 0.4);  };
void() ambient_water1   = { ambient_generic_vol ("ambience/water1.wav", 0.5);   };


// Ambient sounds with generic parameters
void(string soundname) ambient_generic =
{
    ambient_generic_vol_attn (soundname, 1, ATTN_STATIC);
};

void() ambient_custom       = { ambient_generic (self.noise);               };  // Custom entity for mappers

void() ambient_1wind        = { ambient_generic ("ambience/1wind.wav");     };
void() ambient_altair2      = { ambient_generic ("ambience/altair2.wav");   };
void() ambient_amb10        = { ambient_generic ("ambience/amb10.wav");     };
void() ambient_amb11        = { ambient_generic ("ambience/amb11.wav");     };
void() ambient_amb12        = { ambient_generic ("ambience/amb12.wav");     };
void() ambient_amb13        = { ambient_generic ("ambience/amb13.wav");     };
void() ambient_amb14        = { ambient_generic ("ambience/amb14.wav");     };
void() ambient_amb15        = { ambient_generic ("ambience/amb15.wav");     };
void() ambient_amb16        = { ambient_generic ("ambience/amb16.wav");     };
void() ambient_amb17        = { ambient_generic ("ambience/amb17.wav");     };
void() ambient_amb18        = { ambient_generic ("ambience/amb18.wav");     };  // for Winter Wonderland
void() ambient_amb2         = { ambient_generic ("ambience/amb2.wav");      };
void() ambient_amb20        = { ambient_generic ("ambience/amb20.wav");     };
void() ambient_amb21        = { ambient_generic ("ambience/amb21.wav");     };
void() ambient_amb22        = { ambient_generic ("ambience/amb22.wav");     };
void() ambient_amb24        = { ambient_generic ("ambience/amb24.wav");     };
void() ambient_amb25        = { ambient_generic ("ambience/amb25.wav");     };
void() ambient_amb26        = { ambient_generic ("ambience/amb26.wav");     };
void() ambient_amb3         = { ambient_generic ("ambience/amb3.wav");      };
void() ambient_amb4         = { ambient_generic ("ambience/amb4.wav");      };
void() ambient_amb5         = { ambient_generic ("ambience/amb5.wav");      };
void() ambient_amb6         = { ambient_generic ("ambience/amb6.wav");      };
void() ambient_amb7         = { ambient_generic ("ambience/amb7.wav");      };
void() ambient_amb8         = { ambient_generic ("ambience/amb8.wav");      };
void() ambient_amb9         = { ambient_generic ("ambience/amb9.wav");      };
void() ambient_brgloop      = { ambient_generic ("ambience/brgloop.wav");   };
void() ambient_buzslow2     = { ambient_generic ("ambience/buzslow2.wav");  };
void() ambient_buzz2        = { ambient_generic ("ambience/buzz2.wav");     };
void() ambient_chain1       = { ambient_generic ("ambience/chain1.wav");    };
void() ambient_chain2       = { ambient_generic ("ambience/chain2.wav");    };
void() ambient_chain4       = { ambient_generic ("ambience/chain4.wav");    };
void() ambient_chain5       = { ambient_generic ("ambience/chain5.wav");    };
void() ambient_chain6       = { ambient_generic ("ambience/chain6.wav");    };
void() ambient_chant1lp     = { ambient_generic ("ambience/chant1lp.wav");  };
void() ambient_chant2lp     = { ambient_generic ("ambience/chant2lp.wav");  };
void() ambient_chant3lp     = { ambient_generic ("ambience/chant3lp.wav");  };
void() ambient_clock        = { ambient_generic ("ambience/clock.wav");     };
void() ambient_comp_hum     = { ambient_generic ("ambience/fanlup2.wav");   };
void() ambient_cryptlp      = { ambient_generic ("ambience/cryptlp.wav");   };
void() ambient_dialtone     = { ambient_generic ("ambience/dialtone.wav");  };
void() ambient_drip1        = { ambient_generic ("ambience/drip1.wav");     };
void() ambient_drip2        = { ambient_generic ("ambience/drip2.wav");     };
void() ambient_drip5        = { ambient_generic ("ambience/drip5.wav");     };
void() ambient_drone        = { ambient_generic ("ambience/drone.wav");     };
void() ambient_elcloop1     = { ambient_generic ("ambience/elcloop1.wav");  };
void() ambient_erthloop     = { ambient_generic ("ambience/erthloop.wav");  };
void() ambient_flatlin2     = { ambient_generic ("ambience/flatlin2.wav");  };
void() ambient_flouro_buzz  = { ambient_generic ("ambience/elecgen2.wav");  };
void() ambient_flybuzz      = { ambient_generic ("ambience/flybuzz.wav");   };
void() ambient_grglng       = { ambient_generic ("ambience/grglng.wav");    };
void() ambient_howling      = { ambient_generic ("ambience/howling.wav");   };
void() ambient_icemellp     = { ambient_generic ("ambience/icemellp.wav");  };
void() ambient_icevio       = { ambient_generic ("ambience/icevio.wav");    };
void() ambient_laugh        = { ambient_generic ("ambience/laugh.wav");     };
void() ambient_light_buzz   = { ambient_generic ("ambience/hum.wav");       };
void() ambient_mfly         = { ambient_generic ("ambience/mfly.wav");      };
void() ambient_moan2lp      = { ambient_generic ("ambience/moan2lp.wav");   };
void() ambient_mtldrn       = { ambient_generic ("ambience/mtldrn.wav");    };
void() ambient_qamb10       = { ambient_generic ("ambience/qamb10.wav");    };
void() ambient_qamb11       = { ambient_generic ("ambience/qamb11.wav");    };
void() ambient_qamb12       = { ambient_generic ("ambience/qamb12.wav");    };
void() ambient_qamb2        = { ambient_generic ("ambience/qamb2.wav");     };
void() ambient_qamb3        = { ambient_generic ("ambience/qamb3.wav");     };
void() ambient_qamb4        = { ambient_generic ("ambience/qamb4.wav");     };
void() ambient_qamb5        = { ambient_generic ("ambience/qamb5.wav");     };
void() ambient_qamb6        = { ambient_generic ("ambience/qamb6.wav");     };
void() ambient_qamb7        = { ambient_generic ("ambience/qamb7.wav");     };
void() ambient_qamb8        = { ambient_generic ("ambience/qamb8.wav");     };
void() ambient_qamb9        = { ambient_generic ("ambience/qamb9.wav");     };
void() ambient_qsuck1       = { ambient_generic ("ambience/qsuck1.wav");    };
void() ambient_qtrain1      = { ambient_generic ("ambience/qtrain1.wav");   };
void() ambient_qwindfly     = { ambient_generic ("ambience/qwindfly.wav");  };
void() ambient_rain2        = { ambient_generic ("ambience/rain2.wav");     };
void() ambient_sawcut       = { ambient_generic ("ambience/sawcut.wav");    };
void() ambient_sawrun       = { ambient_generic ("ambience/sawrun.wav");    };
void() ambient_sewage       = { ambient_generic ("ambience/sewage.wav");    };
void() ambient_snakepit     = { ambient_generic ("ambience/snakepit.wav");  };
void() ambient_sngair2      = { ambient_generic ("ambience/sngair2.wav");   };
void() ambient_suck_wind    = { ambient_generic ("ambience/amb1.wav");      };
void() ambient_swamp1       = { ambient_generic ("ambience/swamp.wav");     };
void() ambient_swamp2       = { ambient_generic ("ambience/amb19.wav");     };
void() ambient_torch        = { ambient_generic ("ambience/torch.wav");     };
void() ambient_train1       = { ambient_generic ("ambience/train1.wav");    };
void() ambient_underwat     = { ambient_generic ("ambience/underwat.wav");  };
void() ambient_water        = { ambient_generic ("ambience/water.wav");     };
void() ambient_waterlap     = { ambient_generic ("ambience/waterlap.wav");  };
void() ambient_wind2        = { ambient_generic ("ambience/wind2.wav");     };
