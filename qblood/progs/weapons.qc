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


void (entity targ, entity inflictor, entity attacker, float damage) T_Damage;
void () player_run;
void(entity bomb, entity attacker, float rad, entity ignore, string dtype) T_RadiusDamage;
void() SuperDamageSound;
entity() identify_player;


// called by worldspawn
void() W_Precache =
{
    // pitchfork
//    precache_sound ("weapons/pitchfrk/pflesh.wav");
//    precache_sound ("weapons/pitchfrk/pmetal.wav");
    precache_sound ("weapons/pitchfrk/pstone.wav");
/*
    precache_sound ("weapons/pitchfrk/pwood.wav");

    // flaregun
    precache_sound ("weapons/flaregun/burstflm.wav");
    precache_sound ("weapons/flaregun/flar_wat.wav");
    precache_sound ("weapons/flaregun/flarair2.wav");
*/
    precache_sound ("weapons/flaregun/flaref.wav");  // Flaregun fire
//    precache_sound ("weapons/flaregun/flarefuw.wav");

    // dynamite bundles/proximity/remote detonators
    precache_sound ("weapons/tnt/tntfuse.wav");  // tnt lighted
    precache_sound ("weapons/tnt/proxarm.wav");  // proximity bomb armed
    precache_sound ("weapons/tnt/proxdet.wav");  // proximity bomb triggered
    precache_sound ("weapons/tnt/tnttoss.wav");  // bounce sound
/*
    precache_sound ("weapons/tnt/remdet.wav");   // remote armed
    precache_sound ("weapons/tnt/remfire.wav");  // remote set off
    precache_sound ("weapons/tnt/zipclose.wav");
    precache_sound ("weapons/tnt/ziplight.wav");
    precache_sound ("weapons/tnt/zipopen.wav");

    // lifeleech
    precache_sound ("weapons/lifelech/laltfr1.wav");
    precache_sound ("weapons/lifelech/llaltfr2.wav");
    precache_sound ("weapons/lifelech/llaltht.wav");
    precache_sound ("weapons/lifelech/llcharge.wav");
    precache_sound ("weapons/lifelech/llsngfr3.wav");
    precache_sound ("weapons/lifelech/llsnght2.wav");
    precache_sound ("weapons/lifelech/skulair4.wav");

    // voodoo doll
    precache_sound ("weapons/voodoodl/vooburn.wav");
    precache_sound ("weapons/voodoodl/voochant.wav");
*/

    // REMOVEME as soon as we have voodoo items directly in maps
    // because the sound is also precached in item_voodoo
    precache_sound ("weapons/voodoodl/voolaugh.wav");
    precache_sound ("weapons/voodoodl/voostab.wav");

/*
    // common sounds - some are in the C code, some aren't
    precache_sound ("weapons/bflesh.wav");
    precache_sound ("weapons/bmetal.wav");
    precache_sound ("weapons/bstone.wav");
    precache_sound ("weapons/bwater.wav");
    precache_sound ("weapons/bwood.wav");
    precache_sound ("weapons/mtshls.wav");
*/
    precache_sound ("weapons/r_exp3.wav");  // Explosion (used in c code)
    precache_sound ("weapons/ric1.wav");    // ricochet (used in c code)
    precache_sound ("weapons/ric2.wav");    // ricochet (used in c code)
    precache_sound ("weapons/ric3.wav");    // ricochet (used in c code)

    precache_sound ("weapons/tink1.wav");    // spikes tink (used in c code)
    precache_sound ("weapons/tommygun/tomcock.wav");  // Out of ammo
//    precache_sound ("weapons/lstart.wav");
};

float() crandom =
{
    return 2*(random() - 0.5);
};


//============================================================================

vector() wall_velocity =
{
    local vector    vel;

    vel = normalize (self.velocity);
    vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5));
    vel = vel + 2*trace_plane_normal;
    vel = vel * 200;

    return vel;
};


/*
================
SpawnMeatSpray
================
*/
void(vector org, vector vel) SpawnMeatSpray =
{
    local   entity missile;
    local   vector  org;

    missile = spawn ();
    missile.owner = self;
    missile.movetype = MOVETYPE_BOUNCE;
    missile.solid = SOLID_NOT;

    makevectors (self.angles);

    missile.velocity = vel;
    missile.velocity_z = missile.velocity_z + 250 + 50*random();

    missile.avelocity = '3000 1000 2000';

// set missile duration
    missile.nextthink = time + 1;
    missile.think = SUB_Remove;

    setmodel (missile, "progs/zom_gib.mdl");
    setsize (missile, '0 0 0', '0 0 0');
    setorigin (missile, org);
};

/*
================
SpawnBlood
================
*/
#ifdef QUAKEWORLD
void(vector org, float damage) QW_SpawnBlood =
{
    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
    WriteByte (MSG_MULTICAST, TE_BLOOD);
    WriteByte (MSG_MULTICAST, 1);
    WriteCoord (MSG_MULTICAST, org_x);
    WriteCoord (MSG_MULTICAST, org_y);
    WriteCoord (MSG_MULTICAST, org_z);
    multicast (org, MULTICAST_PVS);
};
#else
void(vector org, vector vel, float damage) NQ_SpawnBlood =
{
    particle (org, vel*0.1, 73, damage*2);
};
#endif

/*
================
spawn_touchblood
================
*/
void(float damage) spawn_touchblood =
{
    local vector    vel;

    vel = wall_velocity () * 0.2;
    SpawnBlood (self.origin + vel*0.01, vel, damage);
};


/*
================
W_FireAxe - Pitchfork
================
*/
void() W_FireAxe =
{
    local   vector  source;
    local   vector  org;

    makevectors (self.v_angle);
    source = self.origin + '0 0 16';
    traceline (source, source + v_forward*64, FALSE, self);
    if (trace_fraction == 1.0)
        return;

    org = trace_endpos - v_forward*4;

    if (trace_ent.takedamage)
    {
        trace_ent.axhitme = 1;
        SpawnBlood (org, '0 0 0', 20);

        T_Damage (trace_ent, self, self, 51); // this needs to be 17 per tine, 68 max, need logic for checking how many tines contact enemy
    }
    else
    {   // hit wall
        sound (self, CHAN_WEAPON, "weapons/pitchfrk/pstone.wav", 1, ATTN_NORM);
        #ifdef QUAKEWORLD
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
        WriteByte (MSG_MULTICAST, TE_GUNSHOT);
        WriteByte (MSG_MULTICAST, 3);
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
};


/*
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
*/

entity  multi_ent;
float   multi_damage;

#ifdef QUAKEWORLD
vector  blood_org;
float   blood_count;

vector  puff_org;
float   puff_count;
#endif

void() ClearMultiDamage =
{
    multi_ent = world;
    multi_damage = 0;
    #ifdef QUAKEWORLD
    blood_count = 0;
    puff_count = 0;
    #endif
};

void() ApplyMultiDamage =
{
    if (!multi_ent)
        return;
    T_Damage (multi_ent, self, self, multi_damage);
};

void(entity hit, float damage) AddMultiDamage =
{
    if (!hit)
        return;

    if (hit != multi_ent)
    {
        ApplyMultiDamage ();
        multi_damage = damage;
        multi_ent = hit;
    }
    else
        multi_damage = multi_damage + damage;
};

#ifdef QUAKEWORLD
void() Multi_Finish =
{
    if (puff_count)
    {
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
        WriteByte (MSG_MULTICAST, TE_GUNSHOT);
        WriteByte (MSG_MULTICAST, puff_count);
        WriteCoord (MSG_MULTICAST, puff_org_x);
        WriteCoord (MSG_MULTICAST, puff_org_y);
        WriteCoord (MSG_MULTICAST, puff_org_z);
        multicast (puff_org, MULTICAST_PVS);
    }

    if (blood_count)
    {
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
        WriteByte (MSG_MULTICAST, TE_BLOOD);
        WriteByte (MSG_MULTICAST, blood_count);
        WriteCoord (MSG_MULTICAST, blood_org_x);
        WriteCoord (MSG_MULTICAST, blood_org_y);
        WriteCoord (MSG_MULTICAST, blood_org_z);
        multicast (puff_org, MULTICAST_PVS);
    }
};
#endif

/*
==============================================================================

BULLETS

==============================================================================
*/

/*
================
TraceAttack
================
*/
void(float damage, vector dir) TraceAttack =
{
    local   vector  vel, org;

    vel = normalize(dir + v_up*crandom() + v_right*crandom());
    vel = vel + 2*trace_plane_normal;
    vel = vel * 200;

    org = trace_endpos - dir*4;

    if (trace_ent.takedamage)
    {
        #ifdef QUAKEWORLD
        blood_count = blood_count + 1;
        blood_org = org;
        #else
        SpawnBlood (org, vel*0.2, damage);
        #endif
        AddMultiDamage (trace_ent, damage);
    }
    else
    {
        #ifdef QUAKEWORLD
        puff_count = puff_count + 1;
        #else
        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte (MSG_BROADCAST, TE_GUNSHOT);
        WriteCoord (MSG_BROADCAST, org_x);
        WriteCoord (MSG_BROADCAST, org_y);
        WriteCoord (MSG_BROADCAST, org_z);
        #endif
    }
};

/*
================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
void(float shotcount, vector dir, vector spread) FireBullets =
{
    local   vector direction;
    local   vector  src;

    makevectors(self.v_angle);

    src = self.origin + v_forward*10;
    src_z = self.absmin_z + self.size_z * 0.7;

    ClearMultiDamage ();

    #ifdef QUAKEWORLD
    traceline (src, src + dir*2048, FALSE, self);
    puff_org = trace_endpos - dir*4;
    #endif

    while (shotcount > 0)
    {
        direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;

        traceline (src, src + direction*2048, FALSE, self);
        if (trace_fraction != 1.0)
            TraceAttack (4, direction);

        shotcount = shotcount - 1;
    }
    ApplyMultiDamage ();

    #ifdef QUAKEWORLD
    Multi_Finish ();
    #endif
};

/*
================
W_FireShotgun - Flaregun
================
*/
void() W_FireShotgun =
{
    local vector dir;

    sound (self, CHAN_WEAPON, "weapons/flaregun/flaref.wav", 1, ATTN_NORM);

    #ifndef QUAKEWORLD
    self.punchangle_x = -2;
    #else
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #endif

    self.currentammo = self.ammo_shells = self.ammo_shells - 1;

    dir = aim (self, 100000);
    FireBullets (1, dir, '0.04 0.04 0');
};


/*
================
ShellHit

Plays hit sound when shell hits hard surface if not stuck inloop
================
*/
void() ShellHit =
{
    // prevent sound if last shellhit sound occured within last 2 frames
    if (self.ltime <= (time - 0.2))
        sound (self, CHAN_WEAPON, self.noise, 1,ATTN_NORM);

    self.ltime = time; // marks time of current touch triggeractivation
};


/*
================
DropShell

Displays shell and defines its dynamic manifestation
================
*/
void() DropShell =
{
    self.movetype = MOVETYPE_BOUNCE;
    self.solid = SOLID_BBOX;
    setmodel (self, self.mdl);
    setsize (self, VEC_ORIGIN, VEC_ORIGIN);
    makevectors (self.owner.v_angle);
    if (self.weapon == IT_NAILGUN)
    {
        setorigin (self, self.owner.origin + v_forward * 15 + v_up * 12 + v_right * 4);
        self.velocity = (crandom() + 1)*v_forward*30 - v_right*(100 + crandom()*10) + v_up*(100 + crandom()*10);
    }
    else if (self.weapon == IT_SUPER_SHOTGUN)
    {
        setorigin (self, self.owner.origin + v_forward * 15);
        self.velocity = (crandom() + 1)*v_forward*30 + v_up*(220 + crandom()*10) - v_right*crandom()*30;
    }
    self.avelocity_x = crandom()*500;
    self.avelocity_y = crandom()*500;
    self.avelocity_z = crandom()*500;
    self.touch = ShellHit;
    self.nextthink = time + 1.5;
    self.think = SUB_Remove;
    self.ltime = time - 1;

    if (self.noise1)
        sound (self ,CHAN_WEAPON, self.noise1, 1, ATTN_NORM);
};


/*
================
SpawnShell

Spawns new shell entity but doesn't display it until reloadtime
================
*/
void() SpawnShell =
{
    local entity shell;

    shell = spawn ();
    shell.owner = self;

    // shell.noise is the hitting ground sound
    // shell.noise1 is the cocking sound

    // Tommy gun shells
    if (self.weapon == IT_NAILGUN)
    {
        local entity player;

        shell.mdl    = "progs/tommyshl.mdl";
        if (random() < 0.5)
            shell.noise  = "weapons/shtshl.wav";
        else
            shell.noise  = "weapons/shtshl3.wav";
        shell.weapon = IT_NAILGUN;

        // since we directly call DropShell, the shell must be "self" temporary
        player = self;
        self = shell;
        DropShell ();
        self = player;
    }
    // Shotgun shells (2 shells dropped at a time, or nothing)
    else if (self.weapon == IT_SUPER_SHOTGUN && (self.currentammo & 1) == 0)
    {
        local entity shell2;

        // 1st shell
        shell.nextthink = time + 0.4;  // delay shells until reload
        shell.mdl    = "progs/shotshl.mdl";
        shell.noise  = "weapons/shtshl2.wav";
        shell.noise1 = "weapons/shotgun/shotcock.wav";
        shell.think  = DropShell;
        shell.weapon = IT_SUPER_SHOTGUN;

        // 2nd shell
        shell2 = spawn ();
        shell2.owner = self;

        shell2.nextthink = shell.nextthink;
        shell2.mdl       = shell.mdl;
        shell2.noise     = shell.noise;
        shell2.think     = shell.think;
        shell2.weapon    = shell.weapon;
    }
};


/*
================
W_FireSuperShotgun - Sawed Off
================
*/
void() W_FireSuperShotgun =
{
    local float nbshots;
    local vector dir;

    if ((self.impulse != 12 && !self.button1) || (self.currentammo & 1) == 1)
        nbshots = 1;
    else
        nbshots = 2;

    #ifndef QUAKEWORLD
    self.punchangle_x = -2 * nbshots;
    #else
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK + nbshots - 1);
    #endif

    self.currentammo = self.ammo_shells = self.ammo_shells - nbshots;

    if (nbshots == 1)
        sound (self, CHAN_WEAPON, "weapons/shotgun/shotfire.wav", 1, ATTN_NORM);
    else
        sound (self ,CHAN_WEAPON, "weapons/shotgun/shotfir2.wav", 1, ATTN_NORM);

    dir = aim (self, 100000);
    SpawnShell ();
    FireBullets (9 * nbshots, dir, '0.08 0.08 0');  // 9 "shot pellets" per shell.  quake = 14 bullets
};


/*
==============================================================================

ROCKETS

==============================================================================
*/

#ifndef QUAKEWORLD
// 13 frames for Blood's explosion
void() s_explode1  = [0,  s_explode2]  {};
void() s_explode2  = [1,  s_explode3]  {};
void() s_explode3  = [2,  s_explode4]  {};
void() s_explode4  = [3,  s_explode5]  {};
void() s_explode5  = [4,  s_explode6]  {};
void() s_explode6  = [5,  s_explode7]  {};
void() s_explode7  = [6,  s_explode8]  {};
void() s_explode8  = [7,  s_explode9]  {};
void() s_explode9  = [8,  s_explode10] {};
void() s_explode10 = [9,  s_explode11] {};
void() s_explode11 = [10, s_explode12] {};
void() s_explode12 = [11, s_explode13] {};
void() s_explode13 = [12, SUB_Remove]  {};

void() BecomeExplosion =
{
    self.movetype = MOVETYPE_NONE;
    self.velocity = '0 0 0';
    self.touch = SUB_Null;
    setmodel (self, "progs/s_explod.spr");
    self.solid = SOLID_NOT;
    s_explode1 ();
};
#endif


/*
================
SpawnBouncingNapalmBall

Spawn a bouncing napalm ball
================
*/
void() GrenadeExplode;
void() GrenadeTouch;
void() SpawnBouncingNapalmBall =
{
    newmis = spawn ();
    #ifdef QUAKEWORLD
    newmis.voided=0;
    #endif
    newmis.owner = self;
    newmis.movetype = MOVETYPE_BOUNCE;
    newmis.solid = SOLID_BBOX;
    newmis.classname = "grenade";

    // set newmis speed
    newmis.velocity_x = random() * 300;
    newmis.velocity_y = random() * 300;
    newmis.velocity_z = random() * 300;

    newmis.avelocity = '150 150 150';
    newmis.angles = vectoangles(newmis.velocity);

    // set missile duration
    newmis.nextthink = time + 1 + random();

    newmis.touch = GrenadeTouch;
    newmis.think = GrenadeExplode;
    newmis.netname = "Napalm Ball";
    newmis.dmg = 120;

    setmodel (newmis, "progs/naltball.mdl");
    setsize (newmis, '-1 -1 -1', '1 1 1');

    // spawn the ball just behind the missile
    setorigin (newmis, self.origin - v_forward);
};


/*
================
T_MissileTouch

Touch function for the rockets
================
*/
void() T_MissileTouch =
{
    local float damg;
    local float ind;

    if (other == self.owner)
        return;     // don't explode on owner

    #ifdef QUAKEWORLD
    if (self.voided) {
        return;
    }
    self.voided = 1;
    #endif

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

    damg = 50 + random()*50; // quake = 100 + random()*20

    if (other.health)
    {
        other.deathtype = "rocket";
        #ifndef QUAKEWORLD
        if (other.classname == "monster_shambler")
            damg = damg * 0.5;  // mostly immune
        #endif
        T_Damage (other, self, self.owner, damg );
    }

    // don't do radius damage to the other, because all the damage
    // was done in the impact
    T_RadiusDamage (self, self.owner, 120, other, "rocket");

    self.origin = self.origin - 8*normalize(self.velocity);

    // Spawn bouncing napalm balls
    makevectors (self.v_angle);
    ind = 0;
    while (ind < self.cnt)
    {
        SpawnBouncingNapalmBall ();
        ind = ind + 1;
    }

    #ifdef QUAKEWORLD
    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
    WriteByte (MSG_MULTICAST, TE_EXPLOSION);
    WriteCoord (MSG_MULTICAST, self.origin_x);
    WriteCoord (MSG_MULTICAST, self.origin_y);
    WriteCoord (MSG_MULTICAST, self.origin_z);
    multicast (self.origin, MULTICAST_PHS);
    remove(self);

    #else
    WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte (MSG_BROADCAST, TE_EXPLOSION);
    WriteCoord (MSG_BROADCAST, self.origin_x);
    WriteCoord (MSG_BROADCAST, self.origin_y);
    WriteCoord (MSG_BROADCAST, self.origin_z);
    BecomeExplosion ();
    #endif
};



/*
================
W_FireRocket
================
*/
void() W_FireRocket =
{
    sound (self, CHAN_WEAPON, "weapons/napalm/blaster.wav", 1, ATTN_NORM);

    #ifdef QUAKEWORLD
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #else
    self.punchangle_x = -2;
    #endif

    newmis = spawn ();
    newmis.owner = self;
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.solid = SOLID_BBOX;

    // set newmis speed
    makevectors (self.v_angle);
    newmis.velocity = aim(self, 1000);
    newmis.velocity = newmis.velocity * 1500;
    newmis.angles = vectoangles(newmis.velocity);

    newmis.touch = T_MissileTouch;
    newmis.classname = "rocket";
    #ifdef QUAKEWORLD
    newmis.voided = 0;
    #endif

    if ((self.impulse == 12 || self.button1) && self.ammo_rockets >= 12)
    {
        self.ammo_rockets = self.ammo_rockets - 12;
        newmis.cnt = 8;  // set the number of bouncing balls
    }
    else
        self.ammo_rockets = self.ammo_rockets - 1;
    self.currentammo = self.ammo_rockets;

    // set newmis duration
    newmis.nextthink = time + 5;
    newmis.think = SUB_Remove;

    setmodel (newmis, "progs/missile.mdl");
    setsize (newmis, '-1 -1 -1', '1 1 1');
    setorigin (newmis, self.origin + v_forward*8 + '0 0 16');
};

/*
===============================================================================

LIGHTNING

===============================================================================
*/

void(entity from, float damage) LightningHit =
{
    #ifdef QUAKEWORLD
    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
    WriteByte (MSG_MULTICAST, TE_LIGHTNINGBLOOD);
    WriteCoord (MSG_MULTICAST, trace_endpos_x);
    WriteCoord (MSG_MULTICAST, trace_endpos_y);
    WriteCoord (MSG_MULTICAST, trace_endpos_z);
    multicast (trace_endpos, MULTICAST_PVS);

    #else
    particle (trace_endpos, '0 0 100', 225, damage*4);
    #endif

    T_Damage (trace_ent, from, from, damage);
};

/*
=================
LightningDamage
=================
*/
void(vector p1, vector p2, entity from, float damage) LightningDamage =
{
    local entity        e1, e2;
    local vector        f;

    f = p2 - p1;
    normalize (f);
    f_x = 0 - f_y;
    f_y = f_x;
    f_z = 0;
    f = f*16;

    e1 = e2 = world;

    traceline (p1, p2, FALSE, self);
    if (trace_ent.takedamage)
    {
        LightningHit (from, damage);
        if (self.classname == "player")
        {
            if (other.classname == "player")
                trace_ent.velocity_z = trace_ent.velocity_z + 400;
        }
    }
    e1 = trace_ent;

    traceline (p1 + f, p2 + f, FALSE, self);
    if (trace_ent != e1 && trace_ent.takedamage)
    {
        LightningHit (from, damage);
    }
    e2 = trace_ent;

    traceline (p1 - f, p2 - f, FALSE, self);
    if (trace_ent != e1 && trace_ent != e2 && trace_ent.takedamage)
    {
        LightningHit (from, damage);
    }
};


void() W_FireLightning =
{
    local   vector      org;
    local   float       cells;

    if (self.ammo_cells < 1)
        return;

// explode if under water
    if (self.waterlevel > 1)
    {
        cells = self.ammo_cells;
        self.ammo_cells = 0;
        W_SetCurrentAmmo ();
        T_RadiusDamage (self, self, 35*cells, world, "");
        return;
    }

    if (self.t_width < time)
    {
        sound (self, CHAN_WEAPON, "weapons/tesla/tessngfr.wav", 1, ATTN_NORM);
        self.t_width = time + 0.6;
    }
    #ifndef QUAKEWORLD
    self.punchangle_x = -2;
    #else
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #endif

    self.currentammo = self.ammo_cells = self.ammo_cells - 1;

    org = self.origin + '0 0 16';

    traceline (org, org + v_forward*600, TRUE, self);

    #ifdef QUAKEWORLD
    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
    WriteByte (MSG_MULTICAST, TE_LIGHTNING2);
    WriteEntity (MSG_MULTICAST, self);
    WriteCoord (MSG_MULTICAST, org_x);
    WriteCoord (MSG_MULTICAST, org_y);
    WriteCoord (MSG_MULTICAST, org_z);
    WriteCoord (MSG_MULTICAST, trace_endpos_x);
    WriteCoord (MSG_MULTICAST, trace_endpos_y);
    WriteCoord (MSG_MULTICAST, trace_endpos_z);
    multicast (org, MULTICAST_PHS);

    #else
    WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
    WriteEntity (MSG_BROADCAST, self);
    WriteCoord (MSG_BROADCAST, org_x);
    WriteCoord (MSG_BROADCAST, org_y);
    WriteCoord (MSG_BROADCAST, org_z);
    WriteCoord (MSG_BROADCAST, trace_endpos_x);
    WriteCoord (MSG_BROADCAST, trace_endpos_y);
    WriteCoord (MSG_BROADCAST, trace_endpos_z);
    #endif

    LightningDamage (self.origin, trace_endpos + v_forward*4, self, 25); //quake = 30
};


/*
===============================================================================

VOODOO DOLL

===============================================================================
*/

#define DMG_VOODOO_DOLL 25 //per Matt Saettler

/*
================
W_UseVoodooDoll

Attack with the voodoo doll
================
*/
void() W_UseVoodooDoll =
{
    local vector dir;
    local vector src;
    local vector vel, org;
    local float stab_type;
    local float damage;

    // Select a stab type at random
    stab_type = random()*4;
    damage = random();
    if (stab_type >= 3) // Stab Groin
        damage = damage*49 + 4;
    else if (stab_type >= 2) // Stab Shoulder (supposed to make player lower weapon in MP mode)
        damage = damage*9 + 4;
    else if (stab_type >= 1) // Stab Chest
        damage = damage*17 + 4;
    else if (stab_type < 1) // Stab Eye (supposed to blind player in MP mode)
        damage = damage*11 + 4;
    else
        Sprint (self, PRINT_MEDIUM, "There's a problem with the voodoo doll code\n");

    // Play the appropriate sound
    if (stab_type >= 3)  // Stab Groin
        sound (self, CHAN_WEAPON, "weapons/voodoodl/voolaugh.wav", 1, ATTN_NORM);
    else
        sound (self, CHAN_WEAPON, "weapons/voodoodl/voostab.wav", 1, ATTN_NORM);

    self.currentammo = self.ammo_cells = self.ammo_cells - damage / 4;

    dir = aim (self, 100000);

    makevectors(self.v_angle);

    src = self.origin + v_forward*10;
    src_z = self.absmin_z + self.size_z * 0.7;

    traceline (src, src + dir*2048, FALSE, self);

    // If we had a target that can be damaged and seems alive
    #ifdef QUAKEWORLD
    if (trace_fraction != 1.0 && trace_ent.takedamage && trace_ent.classname == "player")
    #else
    if (trace_fraction != 1.0 && trace_ent.takedamage && ((trace_ent.flags & FL_MONSTER) || trace_ent.classname == "player"))
    #endif
    {
        org = trace_endpos - dir*4;

        vel = normalize(dir + v_up*crandom() + v_right*crandom());
        vel = vel + 2*trace_plane_normal;
        vel = vel * 200;

        #ifdef QUAKEWORLD
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
        WriteByte (MSG_MULTICAST, TE_BLOOD);
        WriteByte (MSG_MULTICAST, 1);
        WriteCoord (MSG_MULTICAST, org_x);
        WriteCoord (MSG_MULTICAST, org_y);
        WriteCoord (MSG_MULTICAST, org_z);
        multicast (puff_org, MULTICAST_PVS);
        #else
        SpawnBlood (org, vel*0.2, DMG_VOODOO_DOLL);
        #endif

        T_Damage (trace_ent, self, self, DMG_VOODOO_DOLL);
    }

    // Else, WE take the damage
    else
        T_Damage (self, self, self, DMG_VOODOO_DOLL);
};


/*
===============================================================================

GRENADES, TNT, BOMBS ...

===============================================================================
*/

#define DMG_TNT            120
#define DMG_PROXIMITY_BOMB 150

void() GrenadeExplode =
{
    #ifdef QUAKEWORLD
    if (self.voided) {
        return;
    }
    self.voided = 1;
    #endif

    T_RadiusDamage (self, self.owner, self.dmg, world, "grenade");

    #ifdef QUAKEWORLD
    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
    WriteByte (MSG_MULTICAST, TE_EXPLOSION);
    WriteCoord (MSG_MULTICAST, self.origin_x);
    WriteCoord (MSG_MULTICAST, self.origin_y);
    WriteCoord (MSG_MULTICAST, self.origin_z);
    multicast (self.origin, MULTICAST_PHS);
    remove (self);

    #else
    WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte (MSG_BROADCAST, TE_EXPLOSION);
    WriteCoord (MSG_BROADCAST, self.origin_x);
    WriteCoord (MSG_BROADCAST, self.origin_y);
    WriteCoord (MSG_BROADCAST, self.origin_z);
    BecomeExplosion ();
    #endif
};


/*
================
ProximBombCheck

The proximity bomb checks its neighborhood and explodes if a living being is nearby
================
*/
void() ProximBombCheck =
{
    local entity thing;

    // Try to find something interesting nearby
    // Note: in T_RadiusDamage, an explosion can damage someone up to a distance of its damage + 40
    thing = findradius (self.origin, self.dmg + 20);
    while (thing)
    {
        // If it's a player or a monster, explode in 400 msec
        if (thing.classname == "player" || (thing.flags & FL_MONSTER))
        {
            sound (self, CHAN_WEAPON, "weapons/tnt/proxdet.wav", 1, ATTN_NORM);
            self.nextthink = time + 0.4;
            self.think = GrenadeExplode;
            return;
        }

        // Next one
        thing = thing.chain;
    }

    // Retry in a moment
    self.nextthink = time + 0.25;
};


/*
================
ProximBombArmed

The proximity bomb becomes armed, ready to explode as soon as someone is nearby
================
*/
void() ProximBombArmed =
{
    sound (self, CHAN_WEAPON, "weapons/tnt/proxarm.wav", 1, ATTN_NORM);

    self.nextthink = time;
    self.think = ProximBombCheck;
};


/*
================
GrenadeTouch

"Touch" function for grenades
================
*/
void() GrenadeTouch =
{
    // Normal grenades are the only ones which can explode on touch
    if (self.dmg = DMG_TNT)
    {
        if (other == self.owner)
            return;     // don't explode on owner
        if (other.takedamage == DAMAGE_AIM)
        {
            GrenadeExplode();
            return;
        }
    }

    if (self.velocity == '0 0 0')
        self.avelocity = '0 0 0';
};


/*
================
W_FireGrenade

Fire a grenade
================
*/
void() W_FireGrenade =
{
    self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

    sound (self, CHAN_WEAPON, "weapons/tnt/tnttoss.wav", 1, ATTN_NORM);

    #ifdef QUAKEWORLD
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #else
    self.punchangle_x = -2;
    #endif

    newmis = spawn ();
    #ifdef QUAKEWORLD
    newmis.voided=0;
    #endif
    newmis.owner = self;
    newmis.movetype = MOVETYPE_BOUNCE;
    newmis.solid = SOLID_BBOX;
    newmis.classname = "grenade";

    // set newmis speed
    makevectors (self.v_angle);
    if (self.v_angle_x)
        newmis.velocity = v_forward*600 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
    else
    {
        newmis.velocity = aim(self, 10000);
        newmis.velocity = newmis.velocity * 600;
        newmis.velocity_z = 200;
    }

    newmis.avelocity = '300 300 300';
    newmis.angles = vectoangles(newmis.velocity);
    newmis.touch = GrenadeTouch;

    // Explodes as soon as it takes 1 point of damage
    newmis.takedamage = DAMAGE_YES;
    newmis.health = 1;
    newmis.th_die = GrenadeExplode;

    // set missile duration
    newmis.nextthink = time + 2.5;

    // If we fire a proximity bomb
    if (self.weapon == IT_PROXIMITY_BOMB)
    {
        newmis.think = ProximBombArmed;
        newmis.netname = "proximity bomb";
        newmis.dmg = DMG_PROXIMITY_BOMB;
    }
    // Else, it's a normal grenade
    else
    {
        newmis.think = GrenadeExplode;
        newmis.netname = "TNT";
        newmis.dmg = DMG_TNT;

        sound (newmis, CHAN_VOICE, "weapons/tnt/tntfuse.wav", 1, ATTN_NORM);
    }

    setmodel (newmis, "progs/grenade.mdl");
    setsize (newmis, '-1 -1 -1', '1 1 1');
    setorigin (newmis, self.origin);
};


//=============================================================================

void() spike_touch;
void() superspike_touch;


/*
===============
launch_spike

Used for both the player and the ogre
===============
*/
void(vector org, vector dir) launch_spike =
{
    newmis = spawn ();
    #ifdef QUAKEWORLD
    newmis.voided=0;
    #endif
    newmis.owner = self;
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.solid = SOLID_BBOX;

    newmis.angles = vectoangles(dir);

    newmis.touch = spike_touch;
    newmis.classname = "spike";
    newmis.think = SUB_Remove;
    newmis.nextthink = time + 6;
    setmodel (newmis, "progs/spike.mdl");
    setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
    setorigin (newmis, org);

    newmis.velocity = dir * 2000;
};

void() W_FireSuperSpikes =
{
    local vector    dir;
    local entity    old;

    sound (self, CHAN_WEAPON, "weapons/spraycan/sprayfir.wav", 1, ATTN_NORM);
    self.attack_finished = time + 0.2;
    self.currentammo = self.ammo_nails = self.ammo_nails - 2;
    dir = aim (self, 1000);
    launch_spike (self.origin + '0 0 16', dir);
    newmis.touch = superspike_touch;
    setmodel (newmis, "progs/s_spike.mdl");
    setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);

    #ifdef QUAKEWORLD
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #else
    self.punchangle_x = -2;
    #endif
};

void() W_FireSpikes =
{
    local vector    dir;
    local entity    old;

    if (self.ammo_nails < 1)
        return;

    makevectors (self.v_angle);

    if (self.ammo_nails >= 2 && self.weapon == IT_SUPER_NAILGUN)
    {
        W_FireSuperSpikes ();
        return;
    }

    sound (self, CHAN_WEAPON, "weapons/tommygun/_tom.wav", 1, ATTN_NORM);
    self.attack_finished = time + 0.2;
    self.currentammo = self.ammo_nails = self.ammo_nails - 1;
    SpawnShell ();

    // set the bullet direction according to the weapon real direction
    dir = aim (self, 1000);
    if (self.weaponframe == 8 || self.weaponframe == 10)
        dir = dir - v_right * (1 / 10);
    else if (self.weaponframe == 9)
        dir = dir - v_right * (1 / 5);
    else if (self.weaponframe == 12)
        dir = dir + v_right * (1 / 10);

    launch_spike (self.origin + '0 0 16' + v_right * 8 + v_forward * 4, dir);

    #ifdef QUAKEWORLD
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #else
    self.punchangle_x = -2;
    #endif
};



.float hit_z;
void() spike_touch =
{
local float rand;
    if (other == self.owner)
        return;

    #ifdef QUAKEWORLD
    if (self.voided) {
        return;
    }
    self.voided = 1;
    #endif

    if (other.solid == SOLID_TRIGGER)
        return; // trigger field, do nothing

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

// hit something that bleeds
    if (other.takedamage)
    {
        spawn_touchblood (9);
        other.deathtype = "nail";
        T_Damage (other, self, self.owner, 9);
    }
    else
    {
        #ifdef QUAKEWORLD
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
        if (self.classname == "wizspike")
            WriteByte (MSG_MULTICAST, TE_WIZSPIKE);
        else if (self.classname == "knightspike")
            WriteByte (MSG_MULTICAST, TE_KNIGHTSPIKE);
        else
            WriteByte (MSG_MULTICAST, TE_SPIKE);
        WriteCoord (MSG_MULTICAST, self.origin_x);
        WriteCoord (MSG_MULTICAST, self.origin_y);
        WriteCoord (MSG_MULTICAST, self.origin_z);
        multicast (self.origin, MULTICAST_PHS);

        #else
        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);

        if (self.classname == "wizspike")
            WriteByte (MSG_BROADCAST, TE_WIZSPIKE);
        else if (self.classname == "knightspike")
            WriteByte (MSG_BROADCAST, TE_KNIGHTSPIKE);
        else
            WriteByte (MSG_BROADCAST, TE_SPIKE);
        WriteCoord (MSG_BROADCAST, self.origin_x);
        WriteCoord (MSG_BROADCAST, self.origin_y);
        WriteCoord (MSG_BROADCAST, self.origin_z);
        #endif
    }

    remove(self);

};

void() superspike_touch =
{
local float rand;
    if (other == self.owner)
        return;

    #ifdef QUAKEWORLD
    if (self.voided) {
        return;
    }
    self.voided = 1;
    #endif

    if (other.solid == SOLID_TRIGGER)
        return; // trigger field, do nothing

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

// hit something that bleeds
    if (other.takedamage)
    {
        spawn_touchblood (18);
        other.deathtype = "supernail";
        T_Damage (other, self, self.owner, 18);
    }
    else
    {
        #ifdef QUAKEWORLD
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
        WriteByte (MSG_MULTICAST, TE_SUPERSPIKE);
        WriteCoord (MSG_MULTICAST, self.origin_x);
        WriteCoord (MSG_MULTICAST, self.origin_y);
        WriteCoord (MSG_MULTICAST, self.origin_z);
        multicast (self.origin, MULTICAST_PHS);

        #else
        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
        WriteCoord (MSG_BROADCAST, self.origin_x);
        WriteCoord (MSG_BROADCAST, self.origin_y);
        WriteCoord (MSG_BROADCAST, self.origin_z);
        #endif
    }

    remove(self);

};


/*
===============================================================================

PLAYER WEAPON USE

===============================================================================
*/

void() W_SetCurrentAmmo =
{
    // If the player is not alive, exit so that we don't
    // reset his current frame with "player_run ()"
    if (self.deadflag != DEAD_NO)
        return;

    player_run ();      // get out of any weapon firing states

    self.items = self.items - ( self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS) );

    if (self.weapon == IT_AXE)
    {
        self.currentammo = 0;
        self.weaponmodel = "progs/v_axe.mdl";
        self.weaponframe = 0;
    }
    else if (self.weapon == IT_SHOTGUN)
    {
        self.currentammo = self.ammo_shells;
        self.weaponmodel = "progs/v_shot.mdl";
        self.weaponframe = 0;
        self.items = self.items | IT_SHELLS;
    }
    else if (self.weapon == IT_SUPER_SHOTGUN)
    {
        self.currentammo = self.ammo_shells;
        self.weaponmodel = "progs/v_shot2.mdl";
        self.weaponframe = 0;
        self.items = self.items | IT_SHELLS;
    }
    else if (self.weapon == IT_NAILGUN)
    {
        self.currentammo = self.ammo_nails;
        self.weaponmodel = "progs/v_nail.mdl";
        self.weaponframe = 0;
        self.items = self.items | IT_NAILS;
    }
    else if (self.weapon == IT_SUPER_NAILGUN)
    {
        self.currentammo = self.ammo_nails;
        self.weaponmodel = "progs/v_nail2.mdl";
        self.weaponframe = 0;
        self.items = self.items | IT_NAILS;
    }
    else if (self.weapon == IT_GRENADE_LAUNCHER || self.weapon == IT_PROXIMITY_BOMB)
    {
        self.currentammo = self.ammo_rockets;
        self.weaponmodel = "progs/v_rock.mdl";
        self.weaponframe = 0;
        self.items = self.items | IT_ROCKETS;
    }
    else if (self.weapon == IT_ROCKET_LAUNCHER)
    {
        self.currentammo = self.ammo_rockets;
        self.weaponmodel = "progs/v_rock2.mdl";
        self.weaponframe = 0;
        self.items = self.items | IT_ROCKETS;
    }
    else if (self.weapon == IT_LIGHTNING)
    {
        self.currentammo = self.ammo_cells;
        self.weaponmodel = "progs/v_light.mdl";
        self.weaponframe = 0;
        self.items = self.items | IT_CELLS;
    }
    else if (self.weapon == IT_VOODOO_DOLL)
    {
        self.currentammo = self.ammo_cells;
        self.weaponmodel = "progs/v_voodoo.mdl";
        self.weaponframe = 0;
        self.items = self.items | IT_CELLS;
    }
    else
    {
        self.currentammo = 0;
        self.weaponmodel = "";
        self.weaponframe = 0;
    }
};

float() W_BestWeapon =
{
    local   float   it;

    it = self.items;

    if(self.ammo_rockets >= 1 && (it & IT_ROCKET_LAUNCHER) )
        return IT_ROCKET_LAUNCHER;
    if (self.waterlevel <= 1 && self.ammo_cells >= 1 && (it & IT_LIGHTNING) )
        return IT_LIGHTNING;
    if(self.ammo_nails >= 2 && (it & IT_SUPER_NAILGUN) )
        return IT_SUPER_NAILGUN;
    if(self.ammo_rockets >= 1 && (it & IT_GRENADE_LAUNCHER) )
        return IT_GRENADE_LAUNCHER;
    if(self.ammo_shells >= 2 && (it & IT_SUPER_SHOTGUN) )
        return IT_SUPER_SHOTGUN;
    if(self.ammo_nails >= 1 && (it & IT_NAILGUN) )
        return IT_NAILGUN;
    if(self.ammo_shells >= 1 && (it & IT_SHOTGUN) )
        return IT_SHOTGUN;
    if(self.ammo_cells >= 1 && (it & IT_VOODOO_DOLL) )
        return IT_VOODOO_DOLL;

    return IT_AXE;
};

float() W_AmmoAvailable =
{
    if (self.currentammo > 0 || self.weapon == IT_AXE)
        return TRUE;

    return FALSE;
};

/*
============
W_Attack

An attack impulse can be triggered now
============
*/
void()  player_axe1;
void()  player_axeb1;
void()  player_axec1;
void()  player_axed1;
void()  player_shot1;
void()  player_nail1;
void()  player_light1;
void()  player_rocket1;

void() W_Attack =
{
    local   float   r;

    if (! W_AmmoAvailable ())
    {
        sound (self, CHAN_WEAPON, "weapons/tommygun/tomcock.wav", 1, ATTN_NORM);
        self.attack_finished = time + 0.5;
        return;
    }

    makevectors (self.v_angle);         // calculate forward angle for velocity
    self.show_hostile = time + 1;   // wake monsters up

    if (self.weapon == IT_AXE)
    {
        self.attack_finished = time + 0.5;
        r = random();
        if (r < 0.25)
            player_axe1 ();
        else if (r<0.5)
            player_axeb1 ();
        else if (r<0.75)
            player_axec1 ();
        else
            player_axed1 ();
        self.attack_finished = time + 0.5;
    }
    else if (self.weapon == IT_SHOTGUN)
    {
        player_shot1 ();
        self.attack_finished = time + 0.5;
        W_FireShotgun ();
    }
    else if (self.weapon == IT_SUPER_SHOTGUN)
    {
        player_shot1 ();
        self.attack_finished = time + 0.7;
        W_FireSuperShotgun ();
    }
    else if (self.weapon == IT_NAILGUN || self.weapon == IT_SUPER_NAILGUN)
    {
        player_nail1 ();
    }
    else if (self.weapon == IT_GRENADE_LAUNCHER || self.weapon == IT_PROXIMITY_BOMB)
    {
        player_rocket1();
        self.attack_finished = time + 0.6;
        W_FireGrenade();
    }
    else if (self.weapon == IT_ROCKET_LAUNCHER)
    {
        player_rocket1();
        self.attack_finished = time + 0.8;
        W_FireRocket();
    }
    else if (self.weapon == IT_LIGHTNING)
    {
        self.attack_finished = time + 0.1;
        sound (self, CHAN_AUTO, "weapons/tesla/teslaz~1.wav", 1, ATTN_NORM);
        player_light1();
    }
    else if (self.weapon == IT_VOODOO_DOLL)
    {
        player_shot1 ();  // FIXME: we should call a "player_???"
        self.attack_finished = time + 0.7;
        W_UseVoodooDoll ();
    }
};

/*
============
W_ChangeWeapon

============
*/
void() W_ChangeWeapon =
{
    local   float   it, am, fl;

    it = self.items;
    am = 0;

    if (self.impulse == 1)
    {
        fl = IT_AXE;
    }
    else if (self.impulse == 2)
    {
        fl = IT_SHOTGUN;
        if (self.ammo_shells < 1)
            am = 1;
    }
    else if (self.impulse == 3)
    {
        fl = IT_SUPER_SHOTGUN;
        if (self.ammo_shells < 2)
            am = 1;
    }
    else if (self.impulse == 4)
    {
        fl = IT_NAILGUN;
        if (self.ammo_nails < 1)
            am = 1;
    }
    else if (self.impulse == 5)
    {
        fl = IT_ROCKET_LAUNCHER;
        if (self.ammo_rockets < 1)
            am = 1;
    }
    else if (self.impulse == 6)
    {
        fl = IT_GRENADE_LAUNCHER;
        if (self.ammo_rockets < 1)
            am = 1;
    }
    else if (self.impulse == 7)
    {
        fl = IT_SUPER_NAILGUN;
        if (self.ammo_nails < 2)
            am = 1;
    }
    else if (self.impulse == 8)
    {
        fl = IT_LIGHTNING;
        if (self.ammo_cells < 1)
            am = 1;
    }
    else if (self.impulse == 9)
    {
        fl = IT_VOODOO_DOLL;
        if (self.ammo_cells < 1)
            am = 1;
    }

    self.impulse = 0;

    if (!(self.items & fl))
    {   // don't have the weapon or the ammo
        Sprint (self, PRINT_MEDIUM, "You don't have that weapon.\n");
        return;
    }

    if (am)
    {   // don't have the ammo
        Sprint (self, PRINT_MEDIUM, "You have no ammo.\n");
        return;
    }

    // If the grenade launcher has been selected...
    if (fl == IT_GRENADE_LAUNCHER)
    {
        // ... and that it was already selected, switch to proximity bombs
        if (self.weapon == IT_GRENADE_LAUNCHER)
        {
            self.weapon = IT_PROXIMITY_BOMB;
            Sprint (self, PRINT_MEDIUM, "Promixity bombs selected.\n");
        }
        else
        {
            self.weapon = IT_GRENADE_LAUNCHER;
            Sprint (self, PRINT_MEDIUM, "TNT Bundle selected.\n");
        }
    }
    else
        self.weapon = fl;

    // set ammo
    W_SetCurrentAmmo ();
};


#ifndef QUAKEWORLD
/*
============
CheatCommand
============
*/
void() CheatCommand =
{
    if (deathmatch || coop)
        return;

    self.ammo_rockets = 100;
    self.ammo_nails = 200;
    self.ammo_shells = 100;
    self.ammo_cells = 200;
    self.items = self.items |
        IT_AXE |
        IT_SHOTGUN |
        IT_SUPER_SHOTGUN |
        IT_NAILGUN |
        IT_SUPER_NAILGUN |
        IT_GRENADE_LAUNCHER |
        IT_ROCKET_LAUNCHER |
        IT_LIGHTNING |
        IT_VOODOO_DOLL;
    self.items2 = self.items2 |
        IT2_KEY1 | IT2_KEY2;

    // FIXME: we should precache all the weapons sounds

    self.weapon = IT_ROCKET_LAUNCHER;
    self.impulse = 0;
    W_SetCurrentAmmo ();
};
#endif


/*
============
CycleWeaponCommand

Go to the next weapon with ammo
============
*/
void() CycleWeaponCommand =
{
    local   float   am;

    self.impulse = 0;

    while (1)
    {
        am = 0;

        if (self.weapon == IT_VOODOO_DOLL)
        {
            self.weapon = IT_AXE;
        }
        else if (self.weapon == IT_AXE)
        {
            self.weapon = IT_SHOTGUN;
            if (self.ammo_shells < 1)
                am = 1;
        }
        else if (self.weapon == IT_SHOTGUN)
        {
            self.weapon = IT_SUPER_SHOTGUN;
            if (self.ammo_shells < 2)
                am = 1;
        }
        else if (self.weapon == IT_SUPER_SHOTGUN)
        {
            self.weapon = IT_NAILGUN;
            if (self.ammo_nails < 1)
                am = 1;
        }
        else if (self.weapon == IT_NAILGUN)
        {
            self.weapon = IT_ROCKET_LAUNCHER;
            if (self.ammo_rockets < 1)
                am = 1;
        }
        else if (self.weapon == IT_ROCKET_LAUNCHER)
        {
            self.weapon = IT_GRENADE_LAUNCHER;
            if (self.ammo_rockets < 1)
                am = 1;
        }
        else if (self.weapon == IT_GRENADE_LAUNCHER || self.weapon == IT_PROXIMITY_BOMB)
        {
            self.weapon = IT_SUPER_NAILGUN;
            if (self.ammo_nails < 2)
                am = 1;
        }
        else if (self.weapon == IT_SUPER_NAILGUN)
        {
            self.weapon = IT_LIGHTNING;
            if (self.ammo_cells < 1)
                am = 1;
        }
        else if (self.weapon == IT_LIGHTNING)
        {
            self.weapon = IT_VOODOO_DOLL;
            if (self.ammo_cells < 1)
                am = 1;
        }

        if ( (self.items & self.weapon) && am == 0)
        {
            W_SetCurrentAmmo ();
            return;
        }
    }

};

/*
============
CycleWeaponReverseCommand

Go to the prev weapon with ammo
============
*/
void() CycleWeaponReverseCommand =
{
    local   float   am;

    self.impulse = 0;

    while (1)
    {
        am = 0;

        if (self.weapon == IT_VOODOO_DOLL)
        {
            self.weapon = IT_LIGHTNING;
            if (self.ammo_cells < 1)
                am = 1;
        }
        else if (self.weapon == IT_LIGHTNING)
        {
            self.weapon = IT_SUPER_NAILGUN;
            if (self.ammo_nails < 2)
                am = 1;
        }
        else if (self.weapon == IT_SUPER_NAILGUN)
        {
            self.weapon = IT_GRENADE_LAUNCHER;
            if (self.ammo_rockets < 1)
                am = 1;
        }
        else if (self.weapon == IT_GRENADE_LAUNCHER || self.weapon == IT_PROXIMITY_BOMB)
        {
            self.weapon = IT_ROCKET_LAUNCHER;
            if (self.ammo_rockets < 1)
                am = 1;
        }
        else if (self.weapon == IT_ROCKET_LAUNCHER)
        {
            self.weapon = IT_NAILGUN;
            if (self.ammo_nails < 1)
                am = 1;
        }
        else if (self.weapon == IT_NAILGUN)
        {
            self.weapon = IT_SUPER_SHOTGUN;
            if (self.ammo_shells < 2)
                am = 1;
        }
        else if (self.weapon == IT_SUPER_SHOTGUN)
        {
            self.weapon = IT_SHOTGUN;
            if (self.ammo_shells < 1)
                am = 1;
        }
        else if (self.weapon == IT_SHOTGUN)
        {
            self.weapon = IT_AXE;
        }
        else if (self.weapon == IT_AXE)
        {
            self.weapon = IT_VOODOO_DOLL;
            if (self.ammo_cells < 1)
                am = 1;
        }

        if ( (self.items & self.weapon) && am == 0)
        {
            W_SetCurrentAmmo ();
            return;
        }
    }

};


#ifndef QUAKEWORLD
void() QuadCheat =
{
    if (deathmatch || coop)
        return;

    self.super_time = 1;
    self.super_damage_finished = time + 30;
    self.items = self.items | IT_QUAD;
    dprint ("quad cheat\n");
};
#endif

/*
============
ImpulseCommands

============
*/
void() ImpulseCommands =
{
    // Commands forbidden to observers
    if (!self.observer)
    {
        if (self.impulse >= 1 && self.impulse <= 9)
            W_ChangeWeapon ();

        else if (self.impulse == 10)
            CycleWeaponCommand ();
        else if (self.impulse == 11)
            CycleWeaponReverseCommand ();

        // Altfire
        else if (self.impulse == 12)
        {
            SuperDamageSound ();
            W_Attack ();

            self.button0 = 0;  // avoid a normal attack
            self.button1 = 0;  // avoid a double altfire attack
        }

        #ifndef QUAKEWORLD
        else if (self.impulse == 254)
            CheatCommand ();
        else if (self.impulse == 255)
            QuadCheat ();
        #endif
    }

    // Commands allowed to observers
    if (self.impulse == 141)
        identify_player ();

    self.impulse = 0;
};

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
void() W_WeaponFrame =
{
    if (time < self.attack_finished)
        return;

    ImpulseCommands ();

    // Check for attack
    if (self.button0 || self.button1)
    {
        SuperDamageSound ();
        W_Attack ();
    }
};

/*
========
SuperDamageSound

Plays sound if needed
========
*/
void() SuperDamageSound =
{
    if (self.super_damage_finished > time)
    {
        if (self.super_sound < time)
        {
            self.super_sound = time + 1;
            sound (self, CHAN_BODY, "bludbath/powerup.wav", 1, ATTN_NORM);
        }
    }
    return;
};


