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


/*QUAKED info_null (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for spotlights, etc.
*/
void() info_null =
{
    remove(self);
};

/*QUAKED info_notnull (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for lightning.
*/
void() info_notnull =
{
};

//============================================================================

#define START_OFF   1

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

/*QUAKED light (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
*/
void() light =
{
    if (!self.targetname)
    {   // inert light
        remove(self);
        return;
    }

    if (self.style >= 32)
    {
        self.use = light_use;
        if (self.spawnflags & START_OFF)
            lightstyle(self.style, "a");
        else
            lightstyle(self.style, "m");
    }
};

/*QUAKED light_fluoro (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
Makes steady fluorescent humming sound
*/
void() light_fluoro =
{
    if (self.style >= 32)
    {
        self.use = light_use;
        if (self.spawnflags & START_OFF)
            lightstyle(self.style, "a");
        else
            lightstyle(self.style, "m");
    }

    precache_sound ("ambience/amb2.wav");
    ambientsound (self.origin, "ambience/amb2.wav", 0.5, ATTN_STATIC);
};

/*QUAKED light_fluorospark (0 1 0) (-8 -8 -8) (8 8 8)
Non-displayed light.
Default light value is 300
Default style is 10
Makes sparking, broken fluorescent sound
*/
void() light_fluorospark =
{
    if (!self.style)
        self.style = 10;

    precache_sound ("ambience/elecgen2.wav");
    ambientsound (self.origin, "ambience/elecgen2.wav", 0.5, ATTN_STATIC);
};

/*QUAKED light_globe (0 1 0) (-8 -8 -8) (8 8 8)
Sphere globe light.
Default light value is 300
Default style is 0
*/
void() light_globe =
{
    precache_model ("progs/s_light.spr");
    setmodel (self, "progs/s_light.spr");
    makestatic (self);
};

void() FireAmbient =
{
    precache_sound ("ambience/sizzle.wav");
    // attenuate fast
    ambientsound (self.origin, "ambience/sizzle.wav", 0.4, ATTN_STATIC);
};

/*QUAKED light_torch_small_walltorch (0 .5 0) (-10 -10 -20) (10 10 20)
Short wall torch
Default light value is 200
Default style is 0
*/
void() light_torch_small_walltorch =
{
    precache_model ("progs/flame.mdl");
    setmodel (self, "progs/flame.mdl");
    FireAmbient ();
    makestatic (self);
};

/*QUAKED light_flame_large_yellow (0 1 0) (-10 -10 -12) (12 12 18)
Large yellow flame ball
*/
void() light_flame_large_yellow =
{
    precache_model ("progs/flame2.mdl");
    setmodel (self, "progs/flame2.mdl");
    self.frame = 1;
    FireAmbient ();
    makestatic (self);
};

/*QUAKED light_flame_small_yellow (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Small yellow flame ball
*/
void() light_flame_small_yellow =
{
    precache_model ("progs/flame2.mdl");
    setmodel (self, "progs/flame2.mdl");
    FireAmbient ();
    makestatic (self);
};

/*QUAKED light_flame_small_white (0 1 0) (-10 -10 -40) (10 10 40) START_OFF
Small white flame ball
*/
void() light_flame_small_white =
{
    precache_model ("progs/flame2.mdl");
    setmodel (self, "progs/flame2.mdl");
    FireAmbient ();
    makestatic (self);
};

//============================================================================


/*QUAKED misc_fireball (0 .5 .8) (-8 -8 -8) (8 8 8)
Lava Balls
*/

void() fire_fly;
void() fire_touch;
void() misc_fireball =
{

    precache_model ("progs/lavaball.mdl");
    self.classname = "fireball";
    self.nextthink = time + (random() * 5);
    self.think = fire_fly;
    if (!self.speed)
        self.speed == 1000;
};

void() fire_fly =
{
local entity    fireball;

    fireball = spawn();
    fireball.solid = SOLID_TRIGGER;
    fireball.movetype = MOVETYPE_TOSS;
    fireball.velocity = '0 0 1000';
    fireball.velocity_x = (random() * 100) - 50;
    fireball.velocity_y = (random() * 100) - 50;
    fireball.velocity_z = self.speed + (random() * 200);
    fireball.classname = "fireball";
    setmodel (fireball, "progs/lavaball.mdl");
    setsize (fireball, '0 0 0', '0 0 0');
    setorigin (fireball, self.origin);
    fireball.nextthink = time + 5;
    fireball.think = SUB_Remove;
    fireball.touch = fire_touch;

    self.nextthink = time + (random() * 5) + 3;
    self.think = fire_fly;
};


void() fire_touch =
{
    // Make fireballs do fire damage.
    T_Damage (other, self, self, 20, DF_FIRE, "fire");
    remove(self);
};


//============================================================================

//  This fixes a bug in which barrel explosions cancel other explosions.
//  Here, the barrel explosion is delayed for one frame so that other
//  explosions can occur without interference from the barrel.
void() barrel_damage =
{
    setorigin (self, self.origin + '0 0 32');
    T_RadiusDamage (self, self, 160, world, string_null);

    #ifdef QUAKEWORLD
    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
    WriteByte (MSG_MULTICAST, TE_EXPLOSION);
    WriteCoord (MSG_MULTICAST, self.origin_x);
    WriteCoord (MSG_MULTICAST, self.origin_y);
    WriteCoord (MSG_MULTICAST, self.origin_z);
    multicast (self.origin, MULTICAST_PHS);
    remove (self);
    #else
    sound (self, CHAN_VOICE, "weapons/napalm/explodfl.wav", 1, ATTN_NORM);
    particle (self.origin, '0 0 0', 75, 255);
    BecomeExplosion ();
    #endif
};

void() barrel_explode =
{
    self.takedamage = DAMAGE_NO;
    self.classname = "explo_box";
    self.nextthink = time + 0.1;
    self.think = barrel_damage;
};


/*QUAKED misc_explobox (0 .5 .8) (0 0 0) (32 32 64)
TESTING THING
*/

void() misc_explobox =
{
    local float oldz;

    self.solid = SOLID_BBOX;
    self.movetype = MOVETYPE_NONE;
    precache_model ("maps/b_explob.bsp");
    setmodel (self, "maps/b_explob.bsp");
    setsize (self, '0 0 0', '32 32 64');
    precache_sound ("weapons/napalm/explodfl.wav");
    self.health = 20;
    self.th_die = barrel_explode;
    self.takedamage = DAMAGE_AIM;

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




/*QUAKED misc_explobox2 (0 .5 .8) (0 0 0) (32 32 64)
Smaller exploding box, REGISTERED ONLY
*/

void() misc_explobox2 =
{
    local float oldz;

    self.solid = SOLID_BBOX;
    self.movetype = MOVETYPE_NONE;
    precache_model2 ("progs/barrel.mdl"); // maps/b_exbox2.bsp
    setmodel (self, "progs/barrel.mdl"); // maps/b_exbox2.bsp");
    setsize (self, '-16 -16 0', '16 16 32');
    precache_sound ("weapons/napalm/explodfl.wav");
    self.health = 20;
    self.th_die = barrel_explode;
    self.takedamage = DAMAGE_AIM;

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

//============================================================================

#define SPAWNFLAG_SUPERSPIKE    1
#define SPAWNFLAG_LASER         2

void() Laser_Touch =
{
    local vector org;

    if (other == self.owner)
        return;     // don't explode on owner

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

    sound (self, CHAN_WEAPON, "ambience/spark.wav", 1, ATTN_STATIC);
    org = self.origin - 8*normalize(self.velocity);

    if (other.health)
    {
        SpawnBlood (org, self.velocity*0.2, 15);
        other.deathtype = "laser";
        T_Damage (other, self, self.owner, 15, DF_FIRE, "laser");
    }
    else
    {
        #ifdef QUAKEWORLD
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
        WriteByte (MSG_MULTICAST, TE_GUNSHOT);
        WriteByte (MSG_MULTICAST, 5);
        WriteCoord (MSG_MULTICAST, org_x);
        WriteCoord (MSG_MULTICAST, org_y);
        WriteCoord (MSG_MULTICAST, org_z);
        multicast (org, MULTICAST_PVS);
        #else
        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte (MSG_BROADCAST, TE_GUNSHOT);
        WriteCoord (MSG_BROADCAST, org_x);
        WriteCoord (MSG_BROADCAST, org_y);
        WriteCoord (MSG_BROADCAST, org_z);
        #endif
    }

    remove(self);
};

void(vector org, vector vec) LaunchLaser =
{
    local   vector  vec;

    vec = normalize(vec);

    newmis = spawn();
    newmis.owner = self;
    newmis.movetype = MOVETYPE_FLY;
    newmis.solid = SOLID_BBOX;
    newmis.effects = EF_DIMLIGHT;

    setmodel (newmis, "progs/laser.mdl");
    setsize (newmis, '0 0 0', '0 0 0');

    setorigin (newmis, org);

    newmis.velocity = vec * 600;
    newmis.angles = vectoangles(newmis.velocity);

    newmis.nextthink = time + 5;
    newmis.think = SUB_Remove;
    newmis.touch = Laser_Touch;
};

void() spikeshooter_use =
{
    if (self.spawnflags & SPAWNFLAG_LASER)
    {
        sound (self, CHAN_VOICE, "weapons/tesla/tessngfr.wav", 1, ATTN_NORM);
        LaunchLaser (self.origin, self.movedir);
    }
    else
    {
        sound (self, CHAN_VOICE, "weapons/tommygun/_tom.wav", 1, ATTN_NORM);
        launch_spike (self.origin, self.movedir);
        newmis.velocity = self.movedir * 500;
        if (self.spawnflags & SPAWNFLAG_SUPERSPIKE)
            newmis.touch = superspike_touch;
    }
};

void() shooter_think =
{
    spikeshooter_use ();
    self.nextthink = time + self.wait;
    newmis.velocity = self.movedir * 500;
};


/*QUAKED trap_spikeshooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser
When triggered, fires a spike in the direction set in QuakeEd.
Laser is only for REGISTERED.
*/

void() trap_spikeshooter =
{
    SetMovedir ();
    self.use = spikeshooter_use;
    if (self.spawnflags & SPAWNFLAG_LASER)
    {
        precache_model2 ("progs/laser.mdl");

        precache_sound ("weapons/tesla/tessngfr.wav");
        precache_sound ("ambience/spark.wav");
    }
    else
        precache_sound ("weapons/tommygun/_tom.wav");
};


/*QUAKED trap_shooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser
Continuously fires spikes.
"wait" time between spike (1.0 default)
"nextthink" delay before firing first spike, so multiple shooters can be stagered.
*/
void() trap_shooter =
{
    trap_spikeshooter ();

    if (self.wait == 0)
        self.wait = 1;
    self.nextthink = self.nextthink + self.wait + self.ltime;
    self.think = shooter_think;
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

// Bloodbath `CLUE' entity for Area 15
void() sentry_detect_laugh =
{
    sentry_detect_init ("ambience/laugh.wav");
};

// Bloodbath `CLUE' entity for Bodies
void() sentry_detect_switch1 =
{
    sentry_detect_init ("locks/switch1.wav");
};


/*
===============================================================================


===============================================================================
*/


void() make_bubbles;
void() bubble_remove;
void() bubble_bob;

/*QUAKED air_bubbles (0 .5 .8) (-8 -8 -8) (8 8 8)

testing air bubbles
*/

void() air_bubbles =

{
    if (gametype > GAME_COOPERATIVE)
    {
        remove (self);
        return;
    }
    precache_model ("progs/s_bubble.spr");
    self.nextthink = time + 1;
    self.think = make_bubbles;
};

void() make_bubbles =
{
local entity    bubble;

    bubble = spawn();
    setmodel (bubble, "progs/s_bubble.spr");
    setorigin (bubble, self.origin);
    bubble.movetype = MOVETYPE_NOCLIP;
    bubble.solid = SOLID_NOT;
    bubble.velocity = '0 0 15';
    bubble.nextthink = time + 0.5;
    bubble.think = bubble_bob;
    bubble.touch = bubble_remove;
    bubble.classname = "bubble";
    bubble.frame = 0;
    bubble.cnt = 0;
    setsize (bubble, '-8 -8 -8', '8 8 8');
    self.nextthink = time + random() + 0.5;
    self.think = make_bubbles;
};

void() bubble_split =
{
local entity    bubble;
    bubble = spawn();
    setmodel (bubble, "progs/s_bubble.spr");
    setorigin (bubble, self.origin);
    bubble.movetype = MOVETYPE_NOCLIP;
    bubble.solid = SOLID_NOT;
    bubble.velocity = self.velocity;
    bubble.nextthink = time + 0.5;
    bubble.think = bubble_bob;
    bubble.touch = bubble_remove;
    bubble.classname = "bubble";
    bubble.frame = 1;
    bubble.cnt = 10;
    setsize (bubble, '-8 -8 -8', '8 8 8');
    self.frame = 1;
    self.cnt = 10;
    if (self.waterlevel != 3)
        remove (self);
};

void() bubble_remove =
{
    if (other.classname == self.classname)
    {
//      dprint ("bump");
        return;
    }
    remove(self);
};

void() bubble_bob =
{
local float     rnd1, rnd2, rnd3;
local vector    vtmp1, modi;

    self.cnt = self.cnt + 1;
    if (self.cnt == 4)
        bubble_split();
    if (self.cnt == 20)
        remove(self);

    rnd1 = self.velocity_x + (-10 + (random() * 20));
    rnd2 = self.velocity_y + (-10 + (random() * 20));
    rnd3 = self.velocity_z + 10 + random() * 10;

    if (rnd1 > 10)
        rnd1 = 5;
    if (rnd1 < -10)
        rnd1 = -5;

    if (rnd2 > 10)
        rnd2 = 5;
    if (rnd2 < -10)
        rnd2 = -5;

    if (rnd3 < 10)
        rnd3 = 15;
    if (rnd3 > 30)
        rnd3 = 25;

    self.velocity_x = rnd1;
    self.velocity_y = rnd2;
    self.velocity_z = rnd3;

    self.nextthink = time + 0.5;
    self.think = bubble_bob;
};

/*~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>
~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~*/

/*QUAKED viewthing (0 .5 .8) (-8 -8 -8) (8 8 8)

Just for the debugging level.  Don't use
*/

void() viewthing =

{
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;
    precache_model ("progs/player.mdl");
    setmodel (self, "progs/player.mdl");
};


/*
==============================================================================

SIMPLE BMODELS

==============================================================================
*/

void() func_wall_use =
{   // change to alternate textures
    self.frame = 1 - self.frame;
};

/*QUAKED func_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
*/
void() func_wall =
{
    self.angles = '0 0 0';
    self.movetype = MOVETYPE_PUSH;  // so it doesn't get pushed by anything
    self.solid = SOLID_BSP;
    self.use = func_wall_use;
    setmodel (self, self.model);
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

/*QUAKED func_episodegate (0 .5 .8) ? E1 E2 E3 E4
This bmodel will appear if the episode has allready been completed, so players can't reenter it.
*/
void() func_episodegate =

{
    if (!(serverflags & self.spawnflags))
        return;         // can still enter episode

    self.angles = '0 0 0';
    self.movetype = MOVETYPE_PUSH;  // so it doesn't get pushed by anything
    self.solid = SOLID_BSP;
    self.use = func_wall_use;
    setmodel (self, self.model);
};

/*QUAKED func_bossgate (0 .5 .8) ?
This bmodel appears unless players have all of the episode sigils.
*/
void() func_bossgate =

{
    if ( (serverflags & 15) == 15)
        return;     // all episodes completed
    self.angles = '0 0 0';
    self.movetype = MOVETYPE_PUSH;  // so it doesn't get pushed by anything
    self.solid = SOLID_BSP;
    self.use = func_wall_use;
    setmodel (self, self.model);
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
        if(self.noise1) // if noise has been set, sound is enabled so play sounds
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
    if (self.skin <= 4)
        new.skin = self.skin;
    else
        new.skin = self.skin - 5;

    if (self.noise1)
    {
        new.noise1 = self.noise1;  // set noise1 for the rubble
        new.noise2 = self.noise2;  // set noise2 for the rubble
    }
    new.velocity = VelocityForDamage (dm);
    new.movetype = MOVETYPE_BOUNCE;
    new.classname = "rubble";
    new.solid = SOLID_TRIGGER;
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

// called when the wall is destroyed.
// throws gibs (rubble).
void () wall_killed =
{
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
        // if cnt is not set, use object bbox volume to set it
        if (! self.cnt)
            self.cnt = (self.size_x * self.size_y * self.size_z) / 64000;
        if (self.cnt > 6)
            self.cnt = 6;

        while (self.cnt > 0)
        {
            self.dest_x = (random() * 100) - 50;
            self.dest_y = (random() * 100) - 50;
            self.dest_z = (random() * 100);

            if (self.skin > 4)
            {
                ThrowRubble ("progs/glass1.mdl", self.health);
                ThrowRubble ("progs/glass2.mdl", self.health);
                ThrowRubble ("progs/glass3.mdl", self.health);
            }
            else
            {
                ThrowRubble ("progs/rubble1.mdl", self.health);
                ThrowRubble ("progs/rubble2.mdl", self.health);
                ThrowRubble ("progs/rubble3.mdl", self.health);
            }

            self.cnt = self.cnt - 1;
        }
    }

    activator = self;
    SUB_UseTargets();

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
    self.dest_x = (random() * 10) - 5;
    self.dest_y = (random() * 10) - 5;
    self.dest_z = (random() * 10);
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
*/
void() exploding_wall =
{
    setmodel (self, self.model);

    // precache rubble models (two models used since red trails on gibs, grey on other rubble)
    if (! (self.spawnflags & 16))  // if rubble is not turned off
    {
        if (self.skin > 4)  // if skin is set to glass, use the glass shards instead - d.turner
        {
            precache_model ("progs/glass1.mdl");
            precache_model ("progs/glass2.mdl");
            precache_model ("progs/glass3.mdl");
        }
        else
        {
            precache_model ("progs/rubble1.mdl");
            precache_model ("progs/rubble2.mdl");
            precache_model ("progs/rubble3.mdl");
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

        else if(self.skin == 3)
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
    {
        self.solid = SOLID_BSP;
        self.movetype = MOVETYPE_PUSH;
    }
    else
    {
        self.solid = SOLID_BBOX;
        self.movetype = MOVETYPE_NONE;
    }

    // Only destroyable by triggering
    if (self.spawnflags & 1)
        self.takedamage = DAMAGE_NO;
    else
    {
        self.takedamage = DAMAGE_YES;
        if (! self.health)
            self.health = 15;  // set default health if none set
    }

    // "One shot kill" only
    if (self.spawnflags & 2)
        self.max_health = self.health;  // set health value to return to if not killed

    self.th_pain = wall_pain;
    self.th_die = wall_killed;

    if (self.targetname)
        self.use = wall_use;
};


//============================================================================
/*QUAKED ambient_suck_wind (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_suck_wind =
{
    precache_sound ("ambience/amb1.wav");
    ambientsound (self.origin, "ambience/amb1.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_drone (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_drone =
{
    precache_sound ("ambience/drone.wav");
    ambientsound (self.origin, "ambience/drone.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_flouro_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_flouro_buzz =
{
    precache_sound ("ambience/elecgen2.wav");
    ambientsound (self.origin, "ambience/elecgen2.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_drip (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_drip =
{
    precache_sound ("ambience/drip3.wav");
    ambientsound (self.origin, "ambience/drip3.wav", 0.5, ATTN_STATIC);
};

/*QUAKED ambient_comp_hum (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_comp_hum =
{
    precache_sound ("ambience/fanlup2.wav");
    ambientsound (self.origin, "ambience/fanlup2.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_thunder (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_thunder =
{
    precache_sound ("ambience/amb18.wav"); // not really thunder anymore
    ambientsound (self.origin, "ambience/amb18.wav", 1, ATTN_STATIC);
};

void() ambient_amb18 =
{
    precache_sound ("ambience/amb18.wav"); // for Winter Wonderland
    ambientsound (self.origin, "ambience/amb18.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_light_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_light_buzz =
{
    precache_sound ("ambience/hum.wav");
    ambientsound (self.origin, "ambience/hum.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_swamp1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_swamp1 =
{
    precache_sound ("ambience/swamp.wav");
    ambientsound (self.origin, "ambience/swamp.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_swamp2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_swamp2 =
{
    precache_sound ("ambience/amb19.wav");
    ambientsound (self.origin, "ambience/amb19.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_1wind (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_1wind =
{
    precache_sound ("ambience/1wind.wav");
    ambientsound (self.origin, "ambience/1wind.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_altair2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_altair2 =
{
    precache_sound ("ambience/altair2.wav");
    ambientsound (self.origin, "ambience/altair2.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb10 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb10 =
{
    precache_sound ("ambience/amb10.wav");
    ambientsound (self.origin, "ambience/amb10.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb11 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb11 =
{
    precache_sound ("ambience/amb11.wav");
    ambientsound (self.origin, "ambience/amb11.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb12 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb12 =
{
    precache_sound ("ambience/amb12.wav");
    ambientsound (self.origin, "ambience/amb12.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb13 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb13 =
{
    precache_sound ("ambience/amb13.wav");
    ambientsound (self.origin, "ambience/amb13.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb14 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb14 =
{
    precache_sound ("ambience/amb14.wav");
    ambientsound (self.origin, "ambience/amb14.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb15 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb15 =
{
    precache_sound ("ambience/amb15.wav");
    ambientsound (self.origin, "ambience/amb15wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb16 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb16 =
{
    precache_sound ("ambience/amb16.wav");
    ambientsound (self.origin, "ambience/amb16.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb17 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb17 =
{
    precache_sound ("ambience/amb17.wav");
    ambientsound (self.origin, "ambience/amb17.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb2 =
{
    precache_sound ("ambience/amb2.wav");
    ambientsound (self.origin, "ambience/amb2.wav", 1, ATTN_NONE);
};

/*QUAKED ambient_amb20 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb20 =
{
    precache_sound ("ambience/amb20.wav");
    ambientsound (self.origin, "ambience/amb20.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb21 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb21 =
{
    precache_sound ("ambience/amb21.wav");
    ambientsound (self.origin, "ambience/amb21.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb22 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb22 =
{
    precache_sound ("ambience/amb22.wav");
    ambientsound (self.origin, "ambience/amb22.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb24 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb24 =
{
    precache_sound ("ambience/amb24.wav");
    ambientsound (self.origin, "ambience/amb24.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb25 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb25 =
{
    precache_sound ("ambience/amb25.wav");
    ambientsound (self.origin, "ambience/amb25.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb26 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb26 =
{
    precache_sound ("ambience/amb26.wav");
    ambientsound (self.origin, "ambience/amb26.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb3 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb3 =
{
    precache_sound ("ambience/amb3.wav");
    ambientsound (self.origin, "ambience/amb3.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb4 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb4 =
{
    precache_sound ("ambience/amb4.wav");
    ambientsound (self.origin, "ambience/amb4.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb5 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb5 =
{
    precache_sound ("ambience/amb5.wav");
    ambientsound (self.origin, "ambience/amb5.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb6 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb6 =
{
    precache_sound ("ambience/amb6.wav");
    ambientsound (self.origin, "ambience/amb6.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb7 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb7 =
{
    precache_sound ("ambience/amb7.wav");
    ambientsound (self.origin, "ambience/amb7.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb8 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb8 =
{
    precache_sound ("ambience/amb8.wav");
    ambientsound (self.origin, "ambience/amb8.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_amb9 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_amb9 =
{
    precache_sound ("ambience/amb9.wav");
    ambientsound (self.origin, "ambience/amb9.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_brgloop (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_brgloop =
{
    precache_sound ("ambience/brgloop.wav");
    ambientsound (self.origin, "ambience/brgloop.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_buzslow2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_buzslow2 =
{
    precache_sound ("ambience/buzslow2.wav");
    ambientsound (self.origin, "ambience/buzslow2.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_buzz2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_buzz2 =
{
    precache_sound ("ambience/buzz2.wav");
    ambientsound (self.origin, "ambience/buzz2.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_chain1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_chain1 =
{
    precache_sound ("ambience/chain1.wav");
    ambientsound (self.origin, "ambience/chain1.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_chain2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_chain2 =
{
    precache_sound ("ambience/chain2.wav");
    ambientsound (self.origin, "ambience/chain2.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_chain4 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_chain4 =
{
    precache_sound ("ambience/chain4.wav");
    ambientsound (self.origin, "ambience/chain4.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_chain5 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_chain5 =
{
    precache_sound ("ambience/chain5.wav");
    ambientsound (self.origin, "ambience/chain5.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_chain6 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_chain6 =
{
    precache_sound ("ambience/chain6.wav");
    ambientsound (self.origin, "ambience/chain6.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_chant1lp (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_chant1lp =
{
    precache_sound ("ambience/chant1lp.wav");
    ambientsound (self.origin, "ambience/chant1lp.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_chant2lp (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_chant2lp =
{
    precache_sound ("ambience/chant2lp.wav");
    ambientsound (self.origin, "ambience/chant2lp.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_clock (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_clock =
{
    precache_sound ("ambience/clock.wav");
    ambientsound (self.origin, "ambience/clock.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_cryptlp (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_cryptlp =
{
    precache_sound ("ambience/cryptlp.wav");
    ambientsound (self.origin, "ambience/cryptlp.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_dialtone (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_dialtone =
{
    precache_sound ("ambience/dialtone.wav");
    ambientsound (self.origin, "ambience/dialtone.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_elcloop1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_elcloop1 =
{
    precache_sound ("ambience/elcloop1.wav");
    ambientsound (self.origin, "ambience/elcloop1.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_eriedrne (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_eriedrne =
{
    precache_sound ("ambience/eriedrne.wav");
    ambientsound (self.origin, "ambience/eriedrne.wav", 1, ATTN_NONE);
};

/*QUAKED ambient_erthloop (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_erthloop =
{
    precache_sound ("ambience/erthloop.wav");
    ambientsound (self.origin, "ambience/erthloop.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_flatlin2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_flatlin2 =
{
    precache_sound ("ambience/flatlin2.wav");
    ambientsound (self.origin, "ambience/flatlin2.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_flybuzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_flybuzz =
{
    precache_sound ("ambience/flybuzz.wav");
    ambientsound (self.origin, "ambience/flybuzz.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_grglng (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_grglng =
{
    precache_sound ("ambience/grglng.wav");
    ambientsound (self.origin, "ambience/grglng.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_howling (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_howling =
{
    precache_sound ("ambience/howling.wav");
    ambientsound (self.origin, "ambience/howling.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_hrtbt (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_hrtbt =
{
    precache_sound ("ambience/hrtbt.wav");
    ambientsound (self.origin, "ambience/hrtbt.wav", 1, ATTN_NONE);
};

/*QUAKED ambient_icemellp (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_icemellp =
{
    precache_sound ("ambience/icemellp.wav");
    ambientsound (self.origin, "ambience/icemellp.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_icevio (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_icevio =
{
    precache_sound ("ambience/icevio.wav");
    ambientsound (self.origin, "ambience/icevio.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_mfly (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_mfly =
{
    precache_sound ("ambience/mfly.wav");
    ambientsound (self.origin, "ambience/mfly.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_moan2lp (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_moan2lp =
{
    precache_sound ("ambience/maon2lp.wav");
    ambientsound (self.origin, "ambience/moan2lp.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_mtldrn (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_mtldrn =
{
    precache_sound ("ambience/mtldrn.wav");
    ambientsound (self.origin, "ambience/mtldrn.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qamb10 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qamb10 =
{
    precache_sound ("ambience/qamb10.wav");
    ambientsound (self.origin, "ambience/qamb10.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qamb11 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qamb11 =
{
    precache_sound ("ambience/qamb11.wav");
    ambientsound (self.origin, "ambience/qamb11.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qamb12 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qamb12 =
{
    precache_sound ("ambience/qamb12.wav");
    ambientsound (self.origin, "ambience/qamb12.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qamb2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qamb2 =
{
    precache_sound ("ambience/qamb2.wav");
    ambientsound (self.origin, "ambience/qamb2.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qamb3 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qamb3 =
{
    precache_sound ("ambience/qamb3.wav");
    ambientsound (self.origin, "ambience/qamb3.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qamb4 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qamb4 =
{
    precache_sound ("ambience/qamb4.wav");
    ambientsound (self.origin, "ambience/qamb4.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qamb5 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qamb5 =
{
    precache_sound ("ambience/qamb5.wav");
    ambientsound (self.origin, "ambience/qamb5.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qamb6 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qamb6 =
{
    precache_sound ("ambience/qamb6.wav");
    ambientsound (self.origin, "ambience/qamb6.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qamb7 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qamb7 =
{
    precache_sound ("ambience/qamb7.wav");
    ambientsound (self.origin, "ambience/qamb7.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qamb8 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qamb8 =
{
    precache_sound ("ambience/qamb8.wav");
    ambientsound (self.origin, "ambience/qamb8.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qamb9 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qamb9 =
{
    precache_sound ("ambience/qamb9.wav");
    ambientsound (self.origin, "ambience/qamb9.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qsuck1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qsuck1 =
{
    precache_sound ("ambience/qsuck1.wav");
    ambientsound (self.origin, "ambience/qsuck1.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qtrain1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qtrain1 =
{
    precache_sound ("ambience/qtrain1.wav");
    ambientsound (self.origin, "ambience/qtrain1.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_qwindfly (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_qwindfly =
{
    precache_sound ("ambience/qwindfly.wav");
    ambientsound (self.origin, "ambience/qwindfly.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_rain2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_rain2 =
{
    precache_sound ("ambience/rain2.wav");
    ambientsound (self.origin, "ambience/rain2.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_sawcut(0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_sawcut =
{
    precache_sound ("ambience/sawcut.wav");
    ambientsound (self.origin, "ambience/sawcut.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_sawrun (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_sawrun =
{
    precache_sound ("ambience/sawrun.wav");
    ambientsound (self.origin, "ambience/sawrun.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_sewage (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_sewage =
{
    precache_sound ("ambience/sewage.wav");
    ambientsound (self.origin, "ambience/sewage.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_sizzle (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_sizzle =
{
    precache_sound ("ambience/sizzle.wav");
    ambientsound (self.origin, "ambience/sizzle.wav", 0.4, ATTN_STATIC);
};

/*QUAKED ambient_sizzle1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_sizzle1 =
{
    precache_sound ("ambience/sizzle1.wav");
    ambientsound (self.origin, "ambience/sizzle1.wav", 0.4, ATTN_STATIC);
};

/*QUAKED ambient_sizzle2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_sizzle2 =
{
    precache_sound ("ambience/sizzle2.wav");
    ambientsound (self.origin, "ambience/sizzle2.wav", 0.4, ATTN_STATIC);
};

/*QUAKED ambient_snakepit (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_snakepit =
{
    precache_sound ("ambience/snakepit.wav");
    ambientsound (self.origin, "ambience/snakepit.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_sngair2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_sngair2 =
{
    precache_sound ("ambience/sngair2.wav");
    ambientsound (self.origin, "ambience/sngair2.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_torch (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_torch =
{
    precache_sound ("ambience/torch.wav");
    ambientsound (self.origin, "ambience/torch.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_train1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_train1 =
{
    precache_sound ("ambience/train1.wav");
    ambientsound (self.origin, "ambience/train1.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_underwat (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_underwat =
{
    precache_sound ("ambience/underwat.wav");
    ambientsound (self.origin, "ambience/underwat.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_water (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_water =
{
    precache_sound ("ambience/water.wav");
    ambientsound (self.origin, "ambience/water.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_water1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_water1 =
{
    precache_sound ("ambience/water1.wav");
    ambientsound (self.origin, "ambience/water1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED ambient_waterlap (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_waterlap =
{
    precache_sound ("ambience/waterlap.wav");
    ambientsound (self.origin, "ambience/waterlap.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_wind2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_wind2 =
{
    precache_sound ("ambience/wind2.wav");
    ambientsound (self.origin, "ambience/wind2.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_drip1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_drip1 =
{
    precache_sound ("ambience/drip1.wav");
    ambientsound (self.origin, "ambience/drip1.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_drip2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_drip2 =
{
    precache_sound ("ambience/drip2.wav");
    ambientsound (self.origin, "ambience/drip2.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_drip5 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_drip5 =
{
    precache_sound ("ambience/drip5.wav");
    ambientsound (self.origin, "ambience/drip5.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_laugh (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_laugh =
{
    precache_sound ("ambience/laugh.wav");
    ambientsound (self.origin, "ambience/laugh.wav", 1, ATTN_STATIC);
};

//============================================================================

void() noise_think =
{
    self.nextthink = time + 0.5;
    sound (self, 1, "enforcer/enfire.wav", 1, ATTN_NORM);
    sound (self, 2, "enforcer/enfstop.wav", 1, ATTN_NORM);
    sound (self, 3, "enforcer/sight1.wav", 1, ATTN_NORM);
    sound (self, 4, "enforcer/sight2.wav", 1, ATTN_NORM);
    sound (self, 5, "enforcer/sight3.wav", 1, ATTN_NORM);
    sound (self, 6, "enforcer/sight4.wav", 1, ATTN_NORM);
    sound (self, 7, "enforcer/pain1.wav", 1, ATTN_NORM);
};

/*QUAKED misc_noisemaker (1 0.5 0) (-10 -10 -10) (10 10 10)

For optimzation testing, starts a lot of sounds.
*/

void() misc_noisemaker =

{
    precache_sound2 ("enforcer/enfire.wav");
    precache_sound2 ("enforcer/enfstop.wav");
    precache_sound2 ("enforcer/sight1.wav");
    precache_sound2 ("enforcer/sight2.wav");
    precache_sound2 ("enforcer/sight3.wav");
    precache_sound2 ("enforcer/sight4.wav");
    precache_sound2 ("enforcer/pain1.wav");
    precache_sound2 ("enforcer/pain2.wav");
    precache_sound2 ("enforcer/death1.wav");
    precache_sound2 ("enforcer/idle1.wav");

    self.nextthink = time + 0.1 + random();
    self.think = noise_think;
};
