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
    precache_sound ("weapons/napalm/explodfs.wav");
    precache_sound ("weapons/flaregun/flar_wat.wav");
    precache_sound ("weapons/flaregun/flarair2.wav");
*/
    precache_sound ("weapons/flaregun/flaref.wav");  // Flaregun fire
//    precache_sound ("weapons/flaregun/flarefuw.wav");

    // dynamite bundles/proximity/remote detonators
    precache_sound ("misc/null.wav");            // null .wav to stop fuse
    precache_sound ("weapons/tnt/tntfuse.wav");  // tnt lighted
    precache_sound ("weapons/tnt/proxarm.wav");  // proximity bomb armed
    precache_sound ("weapons/tnt/proxdet.wav");  // proximity bomb triggered
    precache_sound ("weapons/tnt/tnttoss.wav");  // bounce sound
    precache_sound ("weapons/tnt/remdet.wav");   // remote triggered
/*
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

    PM_PrecacheFire ();  // why is this *here* and what does it do? D_L

    precache_sound ("weapons/napalm/explodfs.wav"); // For alt-flares.
//  PM:  Currently here so alt-napalm won't crash in levels without
//       incinerator.  Should remove later.
    precache_model ("progs/naltball.mdl");
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
MeatSprayTouch

Bleeds when generic meat spray touches something
================
*/
void() MeatSprayTouch =
{
    SpawnBlood (self.origin, '0 0 500', 16);
};

/*
================
BloodMeatSpray

Modified to behave more like Blood's blood spray
================
*/
void(vector org, vector vel, entity ignore) BloodMeatSpray =
{
    local   entity  missile;
    local   vector  org;

    missile = spawn ();
    missile.owner       = ignore;
    missile.movetype    = MOVETYPE_TOSS;    // Was *_BOUNCE
    missile.solid       = SOLID_BBOX;       // Was *_NOT

    missile.velocity    = vel;
    missile.avelocity   = '3000 1000 2000';

    // set missile duration
    missile.nextthink   = time + 1;
    missile.think       = SUB_Remove;
    missile.touch       = MeatSprayTouch;

    setmodel (missile, "progs/zom_gib.mdl");
    setsize (missile, '0 0 0', '0 0 0');
    setorigin (missile, org);
};

/*
================
SpawnMeatSpray

Default to modified function above
================
*/
void(vector org, vector vel) SpawnMeatSpray =
{
    vel_z = vel_z + 250 + 50*random();
    BloodMeatSpray (org, vel, self);
};

/*
================
SpawnBloodSpray
================
*/
void(entity targ, vector org) SpawnBloodSpray =
{
    if (random() < 0.25)    // 25% chance per call of spawning blood.
        if ((targ.flags & FL_MONSTER) || (targ.classname == "player"))
        {
            local   vector  vel;

            vel_x = crandom() * 300;
            vel_y = crandom() * 300;
            vel_z = random() * 300 + 200;
            BloodMeatSpray (org, vel, targ);
        }
};


/*
================
W_FireAxe - Pitchfork
================
*/

void() ClearMultiDamage;
void(entity hit, float damage) AddMultiDamage;
void() ApplyMultiDamage;

float(entity targ) Reflected =
{
    if (!targ)
        return FALSE;
    return (targ.reflect_finished >= time);
};

void(entity targ, vector org, float damage) TineHit =
{
    if (targ.takedamage)
    {
        if (Reflected (targ))
        {
            if (Reflected (self))
                return;     // Both have reflection, so negate attack.

            // Hit attacker instead.
            targ = self;
            org = self.origin;
        }
        targ.axhitme = 1;
        SpawnBlood (org, '0 0 0', damage);
        AddMultiDamage (targ, damage);
        SpawnBloodSpray (trace_ent, org);
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

void() W_FireAxe =
{
    local   vector  source;
    local   vector  start, end;         // Endpoints per tine.
    local   vector  vx, vy, vz;         // forward, right, up unit vectors.
    local   float   damage;             // Damage per tine.
    local   float   loop;               // Number of tines.

    makevectors (self.v_angle);
    vx = v_forward;
    vy = v_right;
    vz = v_up;
    source = self.origin + '0 0 16';
    damage = 17;
    loop = 4;

    // Tines attacks start at the right, and end at the left.
    ClearMultiDamage ();
    while (loop > 0)
    {
        start = source + vy * ((loop - 2) * 4 - 2);
        end = start + vx * 64;
        traceline (start, end, FALSE, self);
        if (trace_fraction < 1)
        {
            end = trace_endpos - vx * 4;
            TineHit (trace_ent, end, damage);
        }
        loop = loop - 1;
    }
    ApplyMultiDamage ();
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
    if (Reflected (trace_ent))
    {
        if (Reflected (self))
            return;     // Both have reflection, so negate attack.

        // Hit attacker instead.
        trace_ent = self;
        trace_endpos = self.origin;
        dir = '0 0 0' - dir;
    }

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
        SpawnBloodSpray (trace_ent, org);
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
    local float  mspeed;

    // Launch flare instead.
    sound (self, CHAN_WEAPON, "weapons/flaregun/flaref.wav", 1, ATTN_NORM);

    #ifndef QUAKEWORLD
    self.punchangle_x = -2;
    #else
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #endif

    mspeed = 1000;
    dir = aim (self, mspeed);

    // Spawn the flare a little ahead of the player
    local vector orig;
    makevectors(self.v_angle);
    orig = self.origin + v_forward * 10 + v_right * 4;
    orig_z = self.absmin_z + self.size_z * 0.8;

    if ((self.impulse == 12 || self.button1) && self.ammo_flares >= 8)
    {
        // Fire alt-flares instead.
        self.currentammo = self.ammo_flares = self.ammo_flares - 8;
        PM_FireAltFlares (self, orig, dir, mspeed, 10, 50);
        return;
    }

    self.currentammo = self.ammo_flares = self.ammo_flares - 1;
    PM_FireFlare (self, orig, dir, mspeed);
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

    // shell.noise is the hitting ground sound
    // shell.noise1 is the cocking sound

    // Tommy gun shells
    if (self.weapon == IT_NAILGUN)
    {
        local entity player;

        shell = spawn ();
        shell.owner = self;

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
        shell = spawn ();
        shell.owner = self;

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
    FireBullets (9 * nbshots, dir, '0.08 0.08 0');  // 9 "shot pellets" per shell
};


/*
==============================================================================

ROCKETS

==============================================================================
*/

.float  charge;
.float  powertime;
.float  tnt_time;
.float  tnt_type;

.float  idle_time;
.float  idle_done;

void(entity client) PM_ResetIdle =
{
    client.idle_done = FALSE;
    client.idle_time = time + 10 + random() * 10;  // 10-20 sec.
};

// This makes the player rave.
void(entity client) PM_BoredCaleb =
{
    if (client.health <= 0)
        return;
    if (client.deadflag)
        return;
    if (client.classname != "player")
        return;

    local   float   rs;
    local   string  playit;

    rs = floor (random() * 12);

    if (rs == 0)
        playit = "player/songs/1093.wav";   // "Strangers in the night..."
    else if (rs == 1)
        playit = "player/songs/1094.wav";   // "There's no business like..."
    else if (rs == 2)
        playit = "player/songs/1095.wav";   // "I did it... my way!"
    else if (rs == 3)
        playit = "player/songs/1097.wav";   // "...putting on the Ritz."
    else if (rs == 4)
        playit = "player/songs/vo3011.wav";   // "sun will come out . . ."
    else if (rs == 5)
        playit = "player/songs/vo3024.wav";   // "row row row your boat"
    else if (rs == 6)
        playit = "player/songs/vo3026.wav";   // "it's a long way ..."
    else if (rs == 7)
        playit = "player/songs/vo3030.wav";   // "somewhere over the rainbow."
    else if (rs == 8)
        playit = "player/songs/vo3033.wav";   // "sailing sailing ..."
    else if (rs == 9)
        playit = "player/songs/vo3034.wav";   // "on the good ship lollipop."
    else if (rs == 10)
        playit = "player/songs/vo3035.wav";   // "i get no kick from champagne...."
    else
        playit = "player/songs/vo3039.wav";   // "i've got you under my skin"

    sound (client, CHAN_VOICE, playit, 1, ATTN_NORM);
};

// This makes the player laugh or utter one of Caleb's signature one-liners.
void(entity client) PM_PsychoCaleb =
{
    if (random() > 0.05)
        return;     // Only 5% chance per call.
    if (client.health <= 0)
        return;
    if (client.deadflag)
        return;
    if (client.classname != "player")
        return;

    local   float   rs;
    local   string  playit;

    rs = floor (random() * 5);

    if (rs == 0)
        playit = "player/quips/1039.wav";   // "Son of a bitch must pay!"
    else if (rs == 1)
        playit = "player/quips/1050.wav";   // "Tha, tha, that's all folks!"
    else if (rs == 2)
        playit = "player/quips/1057.wav";   // "Rest in pieces"
    else
    {
        // Laugh like a psycho.
        rs = floor (random() * 8);

        if (rs == 0)
            playit = "player/play1109.wav";
        else if (rs == 1)
            playit = "player/play1110.wav";
        else if (rs == 2)
            playit = "player/play1111.wav";
        else if (rs == 3)
            playit = "player/play1112.wav";
        else if (rs == 4)
            playit = "player/play1113.wav";
        else if (rs == 5)
            playit = "player/play1114.wav";
        else if (rs == 6)
            playit = "player/play1115.wav";
        else
            playit = "player/play1116.wav";
    }

    // Play on two channels so the player can hear himself clearly.
    sound (client, CHAN_VOICE, playit, 1, ATTN_NORM);
    sound (client, CHAN_BODY, playit, 1, ATTN_NORM);
};

// This creates a blank entity that inflicts burn damage for several
// frames.  Refers to code in 'fire.qc'

void() PM_BlastDamageThink =
{
    PM_BurnRadius (self, self.dmg, self.cnt, world);

    // Damage decreases each frame to a minimum of 5.
    if (self.dmg > 5)
    {
        if (self.dmg < 15)
            self.dmg = 5;
        else
            self.dmg = self.dmg - 10;
    }
    self.cnt = 5;   // Burn up to a half second per frame.

    self.delay = self.delay - 1;
    if (self.delay <= 0)
    {
        remove (self);
        return;
    }

    self.nextthink = time + 0.1;
};

void(entity inflictor, float radius, float damage, float burn) PM_MakeBlastDamage =
{
    local   entity  blast;

    blast = spawn();

    setorigin (blast, inflictor.origin);
    setmodel (blast, string_null);
    setsize (blast, VEC_ORIGIN, VEC_ORIGIN);

    blast.solid     = SOLID_NOT;
    blast.movetype  = MOVETYPE_NONE;
    blast.velocity  = '0 0 0';
    blast.touch     = SUB_Null;

    blast.owner     = inflictor.owner;
    blast.height    = radius;
    blast.dmg       = damage;
    blast.cnt       = burn;
    blast.delay     = 7;    // Damage for seven frames.

    blast.nextthink = time + 0.1;
    blast.think     = PM_BlastDamageThink;
};

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
    // Remember who really owns the napalm.
    if (self.owner)
        newmis.oldenemy = self.owner;
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
    setorigin (newmis, self.origin - 8 * v_forward);
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

    damg = 50 + random()*50;

    self.deathtype = "rocket";  // Done for the fire code.
    if (other.health)
    {
        other.deathtype = "rocket";
        if (other.classname == "monster_shambler")
            damg = damg * 0.5;  // mostly immune
        PM_BurnDamage (other, self, damg*0.75, damg*0.25);
    }

    // don't do radius damage to the other, because all the damage
    // was done in the impact
    PM_BurnRadius (self, 90, 30, other);

    self.origin = self.origin - 8*normalize(self.velocity);

    // Spawn bouncing napalm balls
    makevectors (self.v_angle);
    ind = 0;
    while (ind < self.cnt)
    {
        SpawnBouncingNapalmBall ();
        ind = ind + 1;
    }

    PM_ThrowEmbers (8);
    PM_MakeBlastDamage (self, 160, 20, 10);
    PM_PsychoCaleb (self.owner);

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
//  PM:  Function mostly rewritten.
//
//  What did the old code suppose to do?  Hit three different targets
//  in row ala railgun?  Make the beam wider?  Whatever it was supposed
//  to do, it didn't work.  Therefore, I simplified the code.
//  Also, the +400 up vector to 'other' code in player vs. player
//  Thunderbolt battles doesn't work either, so I removed it.

    traceline (p1, p2, FALSE, self);
    if (trace_ent.takedamage)
        LightningHit (from, damage);
};


//  PM:  Tesla Cannon

void() PM_TeslaTouch =
{
    if (other == self.owner)
        return;     // don't explode on owner

    #ifdef QUAKEWORLD
    if (self.voided)
        return;
    self.voided = 1;
    #endif

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

    if (other.takedamage)
        T_NewDamage (other, self, self.owner, self.dmg, DF_BODY, "tesla");

    if (self.style)
    {
        // Alt-fire touch.
        T_RadiusDamage (self, self.owner, self.dmg, other, "tesla");

        self.origin = self.origin - 8*normalize(self.velocity);
        sound (self, CHAN_AUTO, "weapons/tesla/tesaltht.wav", 1, ATTN_NORM);

        // FIXME:  Remove later.
        #ifndef QUAKEWORLD
        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte (MSG_BROADCAST, 12);
        WriteCoord (MSG_BROADCAST, self.origin_x);
        WriteCoord (MSG_BROADCAST, self.origin_y);
        WriteCoord (MSG_BROADCAST, self.origin_z);
        WriteByte (MSG_BROADCAST, 244);
        WriteByte (MSG_BROADCAST, 3);
        #endif
    }
    else
    {
        // Normal touch
        self.origin = self.origin - 8*normalize(self.velocity);
        sound (self, CHAN_AUTO, "weapons/tesla/tessnght.wav", 1, ATTN_NORM);
    }

    remove (self);
};

void(entity attacker, vector org, vector dir, float mspeed, float big) PM_LaunchJolt =
{
    // PM:  This is for the plasma gun-wannabe mode.
    local   entity  jolt;

    jolt = spawn();

    #ifdef QUAKEWORLD
    jolt.voided     = 0;
    #endif

    jolt.owner      = self;
    jolt.movetype   = MOVETYPE_FLYMISSILE;
    jolt.solid      = SOLID_BBOX;
    jolt.classname  = "tesla";
    jolt.velocity   = dir * mspeed;
    jolt.angles     = vectoangles(dir);
    if (big)
    {
        jolt.dmg    = 170;
        jolt.model  = "progs/bolt2.mdl";
    }
    else
    {
        jolt.dmg       = 25;
        jolt.model     = "progs/bolt.mdl";
        jolt.avelocity = '300 300 300';
    }
    jolt.style      = big;
    jolt.touch      = PM_TeslaTouch;
    jolt.nextthink  = time + (8000 / mspeed);
    jolt.think      = SUB_Remove;

    setmodel (jolt, jolt.model);
    setsize (jolt, '0 0 0', '0 0 0');
    setorigin (jolt, org);
};

void(float big) W_FireLightning =
{
    local   vector      org;
    local   float       cells;
    local   float       mspeed;

    if (self.ammo_cells < 1)
        return;

    muzzleflash ();
    SuperDamageSound ();
//    sound (self, CHAN_AUTO, "weapons/tesla/taltac3.wav", 1, ATTN_NORM);

    #ifndef QUAKEWORLD
    self.punchangle_x = -2;
    #else
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #endif

    if (big && self.ammo_cells >= 35)
    {
        // We have already started the sound

        self.ammo_cells = self.ammo_cells - 35;
        mspeed = 2000;
    }
    else
    {
        big = FALSE;

        sound (self, CHAN_WEAPON, "weapons/tesla/tessngfr.wav", 1, ATTN_NORM);

        self.ammo_cells = self.ammo_cells - 1;
        mspeed = 1500;
    }
    self.currentammo = self.ammo_cells;

    // PM:  This is for the plasma gun-wannabe mode.
    local   vector  dir;

    makevectors (self.v_angle);
    dir = aim(self, mspeed);
    org = self.origin + v_forward * 50 + '0 0 12' + v_right * 12;

    PM_LaunchJolt (self, org, dir, mspeed, big);
};


/*
===============================================================================

VOODOO DOLL

===============================================================================
*/

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
    local entity targ;

    muzzleflash ();

    // Alt-fire mode
    if ((self.impulse == 12 || self.button1) && self.ammo_voodoo >= 1)
    {
        damage = self.ammo_voodoo;
        self.ammo_voodoo = 0;
        self.weaponframe = 19;
        sound (self, CHAN_WEAPON, "weapons/voodoodl/voochant.wav", 1, ATTN_NORM);
    }

    // Normal fire mode
    else
    {
        stab_type = random()*4;
        damage = random();
        if (stab_type >= 3) // Stab Groin
        {
            damage = damage*49 + 4;
            self.weaponframe = 12;
        }
        else if (stab_type >= 2) // Stab Shoulder (supposed to make player lower weapon in MP mode)
        {
            self.weaponframe = 8;
            damage = damage*9 + 4;
        }
        else if (stab_type >= 1) // Stab Chest
        {
            self.weaponframe = 0;
            damage = damage*17 + 4;
        }
        else if (stab_type < 1) // Stab Eye (supposed to blind player in MP mode)
        {
            self.weaponframe = 4;
            damage = damage*11 + 4;
        }
        else
            Sprint (self, PRINT_MEDIUM, "There's a problem with the voodoo doll code\n");

        // Play the appropriate sound
        if (stab_type >= 3)  // Stab Groin
            sound (self, CHAN_WEAPON, "weapons/voodoodl/voolaugh.wav", 1, ATTN_NORM);
        else
            sound (self, CHAN_WEAPON, "weapons/voodoodl/voostab.wav", 1, ATTN_NORM);

        self.ammo_voodoo = self.ammo_voodoo - damage / 4;
    }

    self.currentammo = self.ammo_voodoo;

    dir = aim (self, 100000);

    makevectors(self.v_angle);

    src = self.origin + v_forward*10;
    src_z = self.absmin_z + self.size_z * 0.7;

    traceline (src, src + dir*2048, FALSE, self);

    // If we had a target that can be damaged and seems alive
    if (trace_fraction != 1.0 && trace_ent.takedamage && ((trace_ent.flags & FL_MONSTER) || trace_ent.classname == "player"))
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
        SpawnBlood (org, vel*0.2, damage);
        #endif

        targ = trace_ent;
    }

    // Else, WE take the damage
    else
        targ = self;

    // PM:  I assume voodoo does 'spiritual' damage.
    T_NewDamage (targ, self, self, damage, DF_MIND, "voodoo");
};


/*
===============================================================================

GRENADES, TNT, BOMBS ...

===============================================================================
*/

#define DMG_TNT              120
#define DMG_PROXIMITY_BOMB   150
#define DMG_REMOTE_DETONATOR 120

void() GrenadeExplode =
{
    #ifdef QUAKEWORLD
    if (self.voided) {
        return;
    }
    self.voided = 1;
    #endif

    // Stop the fuse sound if any
    sound (self, CHAN_BODY, "misc/null.wav", 0, ATTN_NORM);

    // Don't let the remote find and detonate grenades that are already
    // exploding
    self.classname = "exploded";

    // Don't let grenade explode twice.
    self.takedamage = DAMAGE_NO;

    // Remember who really owns the napalm.
    if (self.netname == "Napalm Ball")
    {
        self.owner = self.oldenemy;
        PM_ThrowEmbers (4);
        local   float   radius, damage, burn;
        radius = self.dmg + 40;
        damage = self.dmg / 6;
        burn   = self.dmg / 12;
        PM_MakeBlastDamage (self, radius, damage, burn);
    }

    PM_PsychoCaleb (self.owner);

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


// This makes bomb take damage if in slime/lava.  Assumes 'self' == bomb
void() BombContents =
{
    // Dynamite will take damage then explode if in slime or lava.
    local   float   pc;

    pc = pointcontents (self.origin);
    if (pc == CONTENT_SLIME)
        T_NewDamage (self, world, world, 4, DF_BODY, "acid");
    else if (pc == CONTENT_LAVA)
        T_NewDamage (self, world, world, 10, DF_FIRE, "fire");
};

void() BombThink =
{
    self.nextthink  = time + 0.1;
    BombContents ();
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
            self.pausetime = time + 0.4;
            self.think1 = SUB_Null;
            return;
        }

        // Next one
        thing = thing.chain;
    }

    // Retry in a moment
    self.pausetime = time + 0.25;
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

    self.pausetime = time;
    self.think1 = ProximBombCheck;
};


/*
================
ProximBombThink

The proximity bomb does a generic think, then is checked against the world
================
*/
void() ProximBombThink =
{
    if (self.pausetime <= time)
    {
        if (self.think1 == SUB_Null)
        {
            GrenadeExplode ();
            return;
        }
        self.think1 ();
    }

    // Do the standard bomb thinking
    BombThink ();
};


/*
================
GrenadeTouch

"Touch" function for grenades
================
*/
void() GrenadeTouch =
{
// PM:  Removed dynamite stuff.
    if (self.velocity == '0 0 0')
        self.avelocity = '0 0 0';
};


// The 2 types of TNT
#define TNT_TYPE_NORMAL  0
#define TNT_TYPE_ALTFIRE 1

// Dynamite stuff.
void() DynaTouch =
{
    // Normal grenades are the only ones which can explode on touch
    if (self.style == TNT_TYPE_NORMAL)
    {
        local   float   blow;

        blow = TRUE;

        // Rebound if it hits the ceiling.  Otherwise, explode.
        traceline (self.origin - self.dest*4, self.origin + self.dest*16, TRUE, self);
        if (trace_fraction < 1 && trace_plane_normal_z < 0)
            blow = FALSE;

        if (blow)
        {
            GrenadeExplode ();
            return;
        }
    }

    if (self.velocity == '0 0 0')
        self.avelocity = '0 0 0';
};


void() DynaThink =
{
    if (self.pausetime <= time)
    {
        GrenadeExplode ();
        return;
    }

    if (self.t_width <= time)
    {
        self.t_width    = time + 3;
        sound (self, CHAN_BODY, "weapons/tnt/tntfuse.wav", 1, ATTN_NORM);
    }
    self.dest = normalize (self.velocity);

    BombThink ();
};


/*
================
W_ActivateRemoteBombs

Make all remote bombs owned by "self" explode
================
*/
void() W_ActivateRemoteBombs =
{
    local entity grenadeEnt;
    local entity tempEnt;

    grenadeEnt = find (world, classname, "grenade");
    while (grenadeEnt)
    {
        if (grenadeEnt.netname == "remote detonator" && grenadeEnt.owner == self)
        {
            tempEnt = self;
            self = grenadeEnt;
            GrenadeExplode ();
            self = tempEnt;
        }
        grenadeEnt = find (grenadeEnt, classname, "grenade");
    }

    self.attack_finished = time + 0.6;
};


/*
================
W_FireGrenade

Fire a grenade
================
*/
void() W_FireGrenade =
{
    if (self.weapon == IT_PROXIMITY_BOMB)
        self.currentammo = self.ammo_tnt_proxy = self.ammo_tnt_proxy - 1;
    else if (self.weapon == IT_REMOTE_DETONATOR)
        self.currentammo = self.ammo_tnt_remote = self.ammo_tnt_remote - 1;
    else
        self.currentammo = self.ammo_tnt_bundle = self.ammo_tnt_bundle - 1;

    sound (self, CHAN_WEAPON, "weapons/tnt/tnttoss.wav", 1, ATTN_NORM);

    newmis = spawn ();
    newmis.owner = self;
    newmis.movetype = MOVETYPE_BOUNCE;
    newmis.solid = SOLID_BBOX;
    newmis.classname = "grenade";
    #ifdef QUAKEWORLD
    newmis.voided=0;

    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #else
    self.punchangle_x = -2;
    #endif

    // set newmis speed
    makevectors (self.v_angle);

    // TNT Charge/throw meter power.
    local   float   mspeed, mup;

    mspeed = 200 + (self.charge * 50);
    mup = mspeed / 2;

    if (self.v_angle_x)
        newmis.velocity = v_forward*mspeed + v_up * mup + crandom()*v_right*10 + crandom()*v_up*10;
    else
    {
        newmis.velocity = aim(self, 10000);
        newmis.velocity = newmis.velocity * mspeed;
        newmis.velocity_z = mup;
    }

    if (!self.charge)
        newmis.velocity = '0 0 0';

    newmis.avelocity = '300 300 300';
    newmis.angles = vectoangles(newmis.velocity);
    newmis.touch = GrenadeTouch;

    // Explodes as soon as it takes 1 point of damage
    newmis.takedamage = DAMAGE_YES;
    newmis.health = 1;
    newmis.th_die = GrenadeExplode;

    newmis.nextthink = 0.1;
    newmis.think     = BombThink;

    // If we fire a proximity bomb
    if (self.weapon == IT_PROXIMITY_BOMB)
    {
        newmis.pausetime = time + 2.5;
        newmis.think = ProximBombThink;
        newmis.think1 = ProximBombArmed;
        newmis.netname = "proximity bomb";
        newmis.dmg = DMG_PROXIMITY_BOMB;
    }
    // else if we fire a remote detonator
    else if (self.weapon == IT_REMOTE_DETONATOR)
    {
        newmis.netname = "remote detonator";
        newmis.dmg = DMG_REMOTE_DETONATOR;

        // We switch to the remote model / frames
        self.weaponmodel = "";  // FIXME: we don't have the remote model / frames yet
        Sprint (self, PRINT_LOW, "You now have the remote in your hands...\n");
    }
    // Else, it's TNT !
    else
    {
        newmis.style     = self.tnt_type;
        newmis.pausetime = self.tnt_time;
        newmis.think     = DynaThink;
        newmis.touch     = DynaTouch;
        newmis.netname   = "TNT";
        newmis.dmg       = DMG_TNT;
        newmis.dest      = normalize (newmis.velocity);
    }

    setmodel (newmis, "progs/grenade.mdl");
    setsize (newmis, '-1 -1 -1', '1 1 1');
    setorigin (newmis, self.origin);

    // If we have no more dynamite, we "loose" the weapon
    // (expect for remote detonators: we always have the remote)
    if (self.currentammo == 0 && self.weapon != IT_REMOTE_DETONATOR)
    {
        self.items = self.items - self.weapon;
        self.weapon = W_BestWeapon();
        W_SetCurrentAmmo (TRUE);
    }
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

    if (self.ammo_spray < 1)
        return;

    sound (self, CHAN_WEAPON, "weapons/spraycan/sprayfir.wav", 1, ATTN_NORM);
    self.attack_finished = time + 0.2;
    self.currentammo = self.ammo_spray = self.ammo_spray - 1;
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

    sound (self, CHAN_WEAPON, "weapons/tommygun/_tom.wav", 1, ATTN_NORM);
    self.attack_finished = time + 0.1; // rate is too slow still D_L
    self.currentammo = self.ammo_nails = self.ammo_nails - 1;
    SpawnShell ();

    // set the bullet direction according to the weapon real direction
    dir = aim (self, 1000);
    if (self.weaponframe == 9 || self.weaponframe == 11)
        dir = dir - v_right * (1 / 10);
    else if (self.weaponframe == 10)
        dir = dir - v_right * (1 / 5);
    else if (self.weaponframe == 13)
        dir = dir + v_right * (1 / 10);

    FireBullets (1, dir, '0.04 0.04 0');

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

void(float weaponHasChanged) W_SetCurrentAmmo =
{
    // If the player is not alive, exit so that we don't
    // reset his current frame with "player_run ()"
    if (self.deadflag != DEAD_NO)
        return;

    if (weaponHasChanged)
    {
        player_run ();      // get out of any weapon firing states

        self.items = self.items - ( self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS) );
        self.weaponframe = 0;
    }

    if (self.weapon == IT_AXE)
    {
        self.currentammo = 0;
        self.weaponmodel = "progs/v_axe.mdl";
    }
    else if (self.weapon == IT_SHOTGUN)
    {
        self.currentammo = self.ammo_flares;
        self.weaponmodel = "progs/v_shot.mdl";
//        self.items = self.items | IT_SHELLS;
    }
    else if (self.weapon == IT_SUPER_SHOTGUN)
    {
        self.currentammo = self.ammo_shells;
        self.weaponmodel = "progs/v_shot2.mdl";
        self.items = self.items | IT_SHELLS;
    }
    else if (self.weapon == IT_NAILGUN)
    {
        self.currentammo = self.ammo_nails;
        self.weaponmodel = "progs/v_nail.mdl";
        self.items = self.items | IT_NAILS;
    }
    else if (self.weapon == IT_SUPER_NAILGUN)
    {
        self.currentammo = self.ammo_spray;
        self.weaponmodel = "progs/v_nail2.mdl";
//        self.items = self.items | IT_NAILS;
    }
    else if (self.weapon == IT_GRENADE_LAUNCHER)
    {
        self.currentammo = self.ammo_tnt_bundle;
        self.weaponmodel = "progs/v_rock.mdl";
//        self.items = self.items | IT_ROCKETS;
        Sprint (self, PRINT_MEDIUM, "TNT Bundle selected\n");
    }
    else if (self.weapon == IT_PROXIMITY_BOMB)
    {
        self.currentammo = self.ammo_tnt_proxy;

        // Don't print a message if the current weapon hasn't changed
        if (weaponHasChanged)
        {
            self.weaponmodel = "progs/v_rock.mdl";
//            self.items = self.items | IT_ROCKETS;
            Sprint (self, PRINT_MEDIUM, "Promixity bombs selected\n");
        }
    }
    else if (self.weapon == IT_REMOTE_DETONATOR)
    {
        self.currentammo = self.ammo_tnt_remote;

        // Don't print a message if the current weapon hasn't changed
        if (weaponHasChanged)
        {
            if (!self.currentammo)
            {
                self.weaponmodel = "";  // FIXME: we don't have the remote model / frames yet
                Sprint (self, PRINT_MEDIUM, "Remote detonator selected\n");
            }
            else
            {
                self.weaponmodel = "progs/v_rock.mdl";
                Sprint (self, PRINT_MEDIUM, "Remote bombs selected\n");
            }

//            self.items = self.items | IT_ROCKETS;
        }
    }
    else if (self.weapon == IT_ROCKET_LAUNCHER)
    {
        self.currentammo = self.ammo_rockets;
        self.weaponmodel = "progs/v_rock2.mdl";
        self.items = self.items | IT_ROCKETS;
    }
    else if (self.weapon == IT_LIGHTNING)
    {
        self.currentammo = self.ammo_cells;
        self.weaponmodel = "progs/v_light.mdl";
        self.items = self.items | IT_CELLS;
    }
    else if (self.weapon == IT_VOODOO_DOLL)
    {
        self.currentammo = self.ammo_voodoo;
        self.weaponmodel = "progs/v_voodoo.mdl";
//        self.items = self.items | IT_CELLS;
    }
    else
    {
        self.currentammo = 0;
        self.weaponmodel = "";
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
    if(self.ammo_spray >= 1 && (it & IT_SUPER_NAILGUN) )
        return IT_SUPER_NAILGUN;
    if(self.ammo_tnt_bundle >= 1 && (it & IT_GRENADE_LAUNCHER) )
        return IT_GRENADE_LAUNCHER;
    if(self.ammo_shells >= 1 && (it & IT_SUPER_SHOTGUN) )
        return IT_SUPER_SHOTGUN;
    if(self.ammo_nails >= 1 && (it & IT_NAILGUN) )
        return IT_NAILGUN;
    if(self.ammo_flares >= 1 && (it & IT_SHOTGUN) )
        return IT_SHOTGUN;
    if(self.ammo_voodoo >= 1 && (it & IT_VOODOO_DOLL) )
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
void()  player_altnail1;
void()  player_light1;
void()  player_altlight1;
void()  player_rocket1;
void()  player_doll1;

void() W_Attack =
{
    local   float   r;

    if (! W_AmmoAvailable ())
    {
        // Check to see which weapon player is holding
        if (self.weapon == IT_SUPER_SHOTGUN)
            sound (self, CHAN_WEAPON, "weapons/shotgun/shotcock.wav", 1, ATTN_NORM);
        else if (self.weapon == IT_NAILGUN)
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
        // If it's a tommy gun altfire start
        if (self.weapon == IT_NAILGUN && (self.impulse == 12 || self.button1))
        {
            player_altnail1 ();
            self.attack_finished = time + 0.2;
        }
        else
            player_nail1 ();
    }
    else if (self.weapon == IT_GRENADE_LAUNCHER ||
             self.weapon == IT_PROXIMITY_BOMB   ||
             self.weapon == IT_REMOTE_DETONATOR )
    {
        player_rocket1();
        self.attack_finished = time + 0.6;
        W_FireGrenade();
    }
    else if (self.weapon == IT_ROCKET_LAUNCHER)
    {
        player_rocket1();
        self.attack_finished = time + 0.5;
        W_FireRocket();
    }
    else if (self.weapon == IT_LIGHTNING)
    {
        if (self.button0 || self.ammo_cells < 35)
        {
            player_light1();
            self.attack_finished = time + 1;
        }
        else
        {
            player_altlight1();
            self.attack_finished = time + 1.256;
        }

        self.impulse = 0;  // REMOVEME as soon as the altfire will no longer be bind to an impulse
    }
    else if (self.weapon == IT_VOODOO_DOLL)
    {
        W_UseVoodooDoll();
        self.attack_finished = time + 0.5;

        // Don't call player_run if dead.
        if (!self.deadflag)
            player_doll1 ();
    }
};

/*
============
W_ChangeWeapon

============
*/
void() W_ChangeWeapon =
{
    local   float   old, am, fl;

    old = self.weapon;
    am = 0;

    if (self.impulse == 1)
    {
        fl = IT_AXE;
    }
    else if (self.impulse == 2)
    {
        fl = IT_SHOTGUN;
        if (self.ammo_flares < 1)
            am = 1;
    }
    else if (self.impulse == 3)
    {
        fl = IT_SUPER_SHOTGUN;
        if (self.ammo_shells < 1)
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
        fl = 0;

        // If we don't have any type of dynamite
        if (self.ammo_tnt_bundle < 1 &&
            self.ammo_tnt_proxy  < 1 &&
            !(self.items & IT_REMOTE_DETONATOR))  // select at least the remote if we have it
            am = 1;

        else
        {
            // If the TNT was already selected
            if (self.weapon == IT_GRENADE_LAUNCHER)
            {
                if (self.ammo_tnt_proxy > 0)
                    fl = IT_PROXIMITY_BOMB;
                else if (self.items & IT_REMOTE_DETONATOR)
                    fl = IT_REMOTE_DETONATOR;
                else
                    fl = IT_GRENADE_LAUNCHER;
            }

            // Else, if the proximity bombs were already selected
            else if (self.weapon == IT_PROXIMITY_BOMB)
            {
                if (self.items & IT_REMOTE_DETONATOR)
                    fl = IT_REMOTE_DETONATOR;
                else if (self.ammo_tnt_bundle > 0)
                    fl = IT_GRENADE_LAUNCHER;
                else
                    fl = IT_PROXIMITY_BOMB;
            }

            // Else (if the previous weapon was the remote detonators or a non-dynamite weapon)
            else
            {
                if (self.ammo_tnt_bundle > 0)
                    fl = IT_GRENADE_LAUNCHER;
                else if (self.ammo_tnt_proxy > 0)
                    fl = IT_PROXIMITY_BOMB;
                else
                    fl = IT_REMOTE_DETONATOR;
            }
        }
    }
    else if (self.impulse == 7)
    {
        fl = IT_SUPER_NAILGUN;
        if (self.ammo_spray < 1)
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
        if (self.ammo_voodoo < 1)
            am = 1;
    }

    self.impulse = 0;

    // Don't let player change weapons while holding lit dynamite.
    if (self.tnt_time)
        return;
    if (!(self.items & fl))
    {
        // don't have the weapon
        Sprint (self, PRINT_MEDIUM, "You don't have that weapon.\n");
        return;
    }

    if (am)
    {   // don't have the ammo
        Sprint (self, PRINT_MEDIUM, "You have no ammo.\n");
        return;
    }

    // If the weapon has really changed
    if (fl != old)
    {
        self.weapon = fl;
        W_SetCurrentAmmo (TRUE);
    }
};


/*
============
CheatCommand
============
*/
void() CheatCommand =
{
    self.ammo_flares     = MAX_FLARES;
    self.ammo_shells     = MAX_SHELLS;
    self.ammo_nails      = MAX_NAILS;
    self.ammo_rockets    = MAX_ROCKETS;
    self.ammo_tnt_bundle = MAX_TNT;
    self.ammo_tnt_proxy  = MAX_PROXY;
    self.ammo_tnt_remote = MAX_REMOTE;
    self.ammo_spray      = MAX_SPRAY;
    self.ammo_cells      = MAX_CELLS;
    self.ammo_voodoo     = MAX_VOODOO;
    self.ammo_leech      = MAX_LEECH;

    self.items = self.items |
        IT_AXE |
        IT_SHOTGUN |
        IT_SUPER_SHOTGUN |
        IT_NAILGUN |
        IT_SUPER_NAILGUN |
        IT_GRENADE_LAUNCHER |
        IT_PROXIMITY_BOMB |
        IT_REMOTE_DETONATOR |
        IT_ROCKET_LAUNCHER |
        IT_LIGHTNING |
        IT_VOODOO_DOLL;
    self.items2 = self.items2 |
        IT2_KEY1 | IT2_KEY2;

    // FIXME: we should precache all the weapons sounds

    self.weapon = IT_ROCKET_LAUNCHER;
    self.impulse = 0;
    W_SetCurrentAmmo (TRUE);
};


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

    // Don't let player change weapons while holding lit dynamite.
    if (self.tnt_time)
        return;
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
            if (self.ammo_flares < 1)
                am = 1;
        }
        else if (self.weapon == IT_SHOTGUN)
        {
            self.weapon = IT_SUPER_SHOTGUN;
            if (self.ammo_shells < 1)
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
            // No need to check the ammo (it's removed as soon as there's no more ammo)
        }
        else if (self.weapon == IT_GRENADE_LAUNCHER)
        {
            self.weapon = IT_PROXIMITY_BOMB;
            // No need to check the ammo (it's removed as soon as there's no more ammo)
        }
        else if (self.weapon == IT_PROXIMITY_BOMB)
        {
            self.weapon = IT_REMOTE_DETONATOR;
            // No need to check the ammo (it's removed as soon as there's
            // no more ammo and no remaining bombs to trigger)
        }
        else if (self.weapon == IT_REMOTE_DETONATOR)
        {
            self.weapon = IT_SUPER_NAILGUN;
            if (self.ammo_spray < 1)
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
            if (self.ammo_voodoo < 1)
                am = 1;
        }

        if ( (self.items & self.weapon) && am == 0)
        {
            W_SetCurrentAmmo (TRUE);
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

    // Don't let player change weapons while holding lit dynamite.
    if (self.tnt_time)
        return;
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
            if (self.ammo_spray < 2)
                am = 1;
        }
        else if (self.weapon == IT_SUPER_NAILGUN)
        {
            self.weapon = IT_REMOTE_DETONATOR;
            // No need to check the ammo (it's removed as soon as there's
            // no more ammo and no remaining bombs to trigger)
        }
        else if (self.weapon == IT_REMOTE_DETONATOR)
        {
            self.weapon = IT_PROXIMITY_BOMB;
            // No need to check the ammo (it's removed as soon as there's no more ammo)
        }
        else if (self.weapon == IT_PROXIMITY_BOMB)
        {
            self.weapon = IT_GRENADE_LAUNCHER;
            // No need to check the ammo (it's removed as soon as there's no more ammo)
        }
        else if (self.weapon == IT_GRENADE_LAUNCHER)
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
            if (self.ammo_shells < 1)
                am = 1;
        }
        else if (self.weapon == IT_SUPER_SHOTGUN)
        {
            self.weapon = IT_SHOTGUN;
            if (self.ammo_flares < 1)
                am = 1;
        }
        else if (self.weapon == IT_SHOTGUN)
        {
            self.weapon = IT_AXE;
        }
        else if (self.weapon == IT_AXE)
        {
            self.weapon = IT_VOODOO_DOLL;
            if (self.ammo_voodoo < 1)
                am = 1;
        }

        if ( (self.items & self.weapon) && am == 0)
        {
            W_SetCurrentAmmo (TRUE);
            return;
        }
    }

};


void() QuadCheat =
{
    self.super_time = 1;
    self.super_damage_finished = time + 30;

    // Guns Akimbo no longer uses IT_QUAD.
    Sprint (self, PRINT_MEDIUM, "tequila\n");
    dprint ("quad cheat\n");
};


void() ShowThrowMeter =
{
    local   string  text;

    if (self.charge == 20)
        text = "žžžžžžžžžžžžžžžžžžžž";
    else if (self.charge == 19)
        text = "žžžžžžžžžžžžžžžžžžž ";
    else if (self.charge == 18)
        text = "žžžžžžžžžžžžžžžžžž  ";
    else if (self.charge == 17)
        text = "žžžžžžžžžžžžžžžžž   ";
    else if (self.charge == 16)
        text = "žžžžžžžžžžžžžžžž    ";
    else if (self.charge == 15)
        text = "žžžžžžžžžžžžžžž     ";
    else if (self.charge == 14)
        text = "žžžžžžžžžžžžžž      ";
    else if (self.charge == 13)
        text = "žžžžžžžžžžžžž       ";
    else if (self.charge == 12)
        text = "žžžžžžžžžžžž        ";
    else if (self.charge == 11)
        text = "žžžžžžžžžžž         ";
    else if (self.charge == 10)
        text = "žžžžžžžžžž          ";
    else if (self.charge == 9)
        text = "žžžžžžžžž           ";
    else if (self.charge == 8)
        text = "žžžžžžžž            ";
    else if (self.charge == 7)
        text = "žžžžžžž             ";
    else if (self.charge == 6)
        text = "žžžžžž              ";
    else if (self.charge == 5)
        text = "žžžžž               ";
    else if (self.charge == 4)
        text = "žžžž                ";
    else if (self.charge == 3)
        text = "žžž                 ";
    else if (self.charge == 2)
        text = "žž                  ";
    else if (self.charge == 1)
        text = "ž                   ";
    else
        text = "";

    centerprint (self, text);
};

void() W_Uncharge =
{
    self.charge     = 0;
    self.powertime  = 0;
    self.tnt_time   = 0;
};

#define FUSE_TIME   5.5

// This throws some dynamite and resets the charge
void() ThrowBomb =
{
    // Throw the dynamite
    SuperDamageSound ();
    W_Attack ();
    W_Uncharge ();
    ShowThrowMeter ();  // Remove throw meter
};

// This charges up and displays the throw meter
void() BuildThrowMeter =
{
    PM_ResetIdle (self);  // Don't let Caleb rave

    if (self.charge >= 20)
    {
        // Maxed out
        self.powertime = 0;
    }
    else if (self.powertime <= time)
    {
        self.powertime = time + 0.1;
        self.charge = self.charge + 1;
    }
    ShowThrowMeter ();
};

// This controls charging and firing of normal dynamite
void() W_ChargeNormal =
{
    local   float   altfire;

    if ((self.impulse == 12) || self.button1)
    {
        altfire = TRUE;
        self.impulse = 0;
    }
    else
        altfire = FALSE;

    // Check if player is holding lit dynamite
    if (self.tnt_time)
    {
        // We have lit dynamite

        // If the match is over, the TNT explodes in our hands...
        if (self.tnt_time && self.tnt_time <= time)
        {
            Sprint (self, PRINT_LOW, "Sorry, the match is over...\n");

            // Indeed, we use a little trick: we drop the dynamite with a zero match time
            self.charge = 0;    // Make sure it's dropped, not thrown
            ThrowBomb ();
            return;
        }

        // Check for throwing
        // NOTE:  In Blood, normal-fire has priority over alt-fire
        if (self.button0)
        {
            BuildThrowMeter ();
        }
        else if (self.charge)
        {
            ThrowBomb ();
            return;
        }
        if (altfire)
        {
            self.charge = 0;    // Make sure it's dropped, not thrown
            ThrowBomb ();
            return;
        }

        // Play the fuse sound if needed
        if (self.t_width <= time)
        {
            // Fuse sound not playing, so play it again
            sound (self, CHAN_WEAPON, "weapons/tnt/tntfuse.wav", 1, ATTN_NORM);
            self.t_width = time + 3;
        }

        return;
    }

    // Dynamite is not lit, so check for ignition.  If either button is
    // held, start the fuse
    if (self.button0 || altfire)
    {
        if (self.button0)
        {
            BuildThrowMeter ();
            self.tnt_type = TNT_TYPE_NORMAL;
        }
        else // if (altfire)
        {
            self.tnt_type = TNT_TYPE_ALTFIRE;
            self.attack_finished = time + 0.3;  // avoid the light-and-drop bug with +use
        }

        self.tnt_time = time + FUSE_TIME;
        self.t_width  = 0;  // So the fuse wav starts at the next frame
        Sprint (self, PRINT_LOW, "WARNING: you've just lit up the TNT match (5 sec)...\n");
    }
};

// This controls charging and firing of the dynamite variants
void() W_ChargeBomb =
{
    local   float   altfire;

    if ((self.impulse == 12) || self.button1)
    {
        altfire = TRUE;
        self.impulse = 0;
    }
    else
        altfire = FALSE;

    if (self.button0)
    {
        BuildThrowMeter ();
    }
    else if (self.charge)
    {
        ThrowBomb ();
        return;
    }

    // Altfire -> drop the bomb at the current position
    if (altfire)
    {
        Sprint (self, PRINT_LOW, "Bomb dropped\n");
        self.charge = 0;    // Make sure it's dropped, not thrown
        ThrowBomb ();
        return;
    }
};

// This fires the remote if the player is hold it
float() W_CheckRemote =
{
    // Check if holding the remote
    if (self.weaponmodel == "" &&
        (self.button0 || self.button1 || self.impulse == 12))
    {
        // If we trigger the bombs
        if (self.button0)
        {
            sound (self, CHAN_WEAPON, "weapons/tnt/remdet.wav", 1, ATTN_NORM);
            W_ActivateRemoteBombs ();

            // If we have no more remote bombs, we "loose" this weapon
            if (self.currentammo == 0)
            {
                self.items = self.items - self.weapon;
                self.weapon = W_BestWeapon();
                W_SetCurrentAmmo (TRUE);
            }
            else
                self.weaponmodel = "progs/v_rock.mdl";
        }
        // Else (altfire: take another bomb in our hands)
        else
        {
            if (self.currentammo != 0)
            {
                self.weaponmodel = "progs/v_rock.mdl";
                self.attack_finished = time + 0.4;
            }
            else
                Sprint (self, PRINT_LOW, "You have no more remote bombs\n");
        }

        self.impulse = 0;
        return TRUE;
    }

    return FALSE;
};

// The checks if the player is using a charge weapon
float() W_FireCharge =
{
    // Check if we are using dynamite
    if ((self.weapon == IT_GRENADE_LAUNCHER) && (self.ammo_tnt_bundle >= 1))
    {
        W_ChargeNormal ();
        return TRUE;
    }
    if ((self.weapon == IT_PROXIMITY_BOMB) && (self.ammo_tnt_proxy >= 1))
    {
        W_ChargeBomb ();
        return TRUE;
    }
    if (self.weapon == IT_REMOTE_DETONATOR)
    {
        if (W_CheckRemote ())
            return TRUE;
        if (self.ammo_tnt_remote >= 1)
        {
            W_ChargeBomb ();
            return TRUE;
        }
    }

    // FIXME:  Add alt-fire spray can

    // Player can rapid-fire the weapon
    W_Uncharge ();
    return FALSE;
};


// PM:  Let's player change the armor shown if he has more than one armor.
void() PM_ArmorTest =
{
    if (self.items & IT_ARMOR2)
    {
        if (self.armor_body)
        {
            self.armorvalue = self.armor_body;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR1;
        }
        else if (self.armor_mind)
        {
            self.armorvalue = self.armor_mind;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR3;
        }
    }
    else if (self.items & IT_ARMOR1)
    {
        if (self.armor_mind)
        {
            self.armorvalue = self.armor_mind;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR3;
        }
        else if (self.armor_fire)
        {
            self.armorvalue = self.armor_fire;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR2;
        }
    }
    else if (self.items & IT_ARMOR3)
    {
        if (self.armor_fire)
        {
            self.armorvalue = self.armor_fire;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR2;
        }
        else if (self.armor_body)
        {
            self.armorvalue = self.armor_body;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR1;
        }
    }
};


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

        // Altfire (will be treated later; just return)
        else if (self.impulse == 12)
            return;

        // Inventory selection/usage.
        else if (self.impulse == 13)
            InvenUse ();
        else if (self.impulse == 14)
            InvenSelect (FALSE);
        else if (self.impulse == 15)
            InvenSelect (TRUE);

        // Armor cycle.
        else if (self.impulse == 16)
            PM_ArmorTest ();

        // Cheat codes are not allowed in multiplayer games (except when the "sv_allowCheat" cvar is set)
        else if ((!deathmatch && !coop) || cvar ("sv_allowCheat"))
        {
            if (self.impulse == 251)
            {
                Sprint (self, PRINT_MEDIUM, "griswold -- You have full armor.\n");
                self.armor_fire = self.armor_body = self.armor_mind = self.armorvalue = 200;
                self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR2;
            }
            else if (self.impulse == 252)
            {
                Sprint (self, PRINT_MEDIUM, "mcgee -- You're fired!\n");
                PM_Ignite (self, self, 200);
            }
            else if (self.impulse == 253)
                InvenCheat ();
            else if (self.impulse == 254)
                CheatCommand ();
            else if (self.impulse == 255)
                QuadCheat ();
        }
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

    if (W_FireCharge ())
        return;

    // Check for attack
    if (self.button0 || self.button1 || self.impulse == 12)
    {
        PM_ResetIdle (self);
        SuperDamageSound ();
        W_Attack ();

        self.impulse = 0;
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
