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


// prototypes
void () W_WeaponFrame;
void() player_pain;
void() player_stand;
void (vector org) spawn_tfog;
void (vector org, entity death_owner) spawn_tdeath;

/*
=============================================================================

                LEVEL CHANGING / INTERMISSION

=============================================================================
*/

float   intermission_exittime;

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() info_intermission =
{
    #ifdef QUAKEWORLD
    self.angles = self.mangle;      // so C can get at it
    #endif
};

void() SetChangeParms =
{
    if (self.health <= 0)
    {
        SetNewParms ();
        return;
    }

    // remove items
    self.items  = self.items  - (self.items  & (IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT));
    self.items2 = self.items2 - (self.items2 & (IT2_KEY1 | IT2_KEY2));

    // Recharge inventory, except for first-aid.
    InvenRecharge ();

    // cap super health
    if (self.health > 200)
        self.health = 200;

    //
    //  *Very* important note:
    //
    //  Since qblood has enough data to require more than 16 parms, some of
    //  the parms contain data from up to three different fields.
    //
    //  Ammo parms...
    //  parm3 -> Bits used for flares/shells/bullets are 7/7/9.
    //      Flares use bits 0-6.  Shells use bits 7-13.  Bullets use bits 14-22.
    //  parm4 -> Bits used for napalm/tnt/proxy are 7/7/7.
    //      Rockets use bits 0-6.  TNT use bits 7-13.  Proxy use bits 14-20.
    //  parm5 -> Bits used for remote/spraycan/cells are 7/8/8.
    //      Remotes use bits 0-6.  Cans use bits 7-14.  Cells use bits 15-22.
    //  parm6 -> Bits used for voodoo/souls are 8/8.
    //      Voodoo uses bits 0-7.  Souls use bits 8-15.
    //
    //  Armor parms...
    //  parm8 -> Bits used for fire/body/spirit are 8/8/8.
    //      Fire uses bits 0-7.  Body uses bits 8-15.  Spirit uses bits 16-23.
    //
    parm1 = self.items;
    parm2 = self.items2;
    parm3 = self.health;
    parm4 = self.ammo_flares + (self.ammo_shells * 128) + (self.ammo_nails * 16384);
    parm5 = self.ammo_rockets + (self.ammo_tnt_bundle * 128) + (self.ammo_tnt_proxy * 16384);
    parm6 = self.ammo_tnt_remote + (self.ammo_spray * 128) + (self.ammo_cells * 32768);
    parm7 = self.ammo_voodoo + (self.ammo_leech * 256);
    parm8 = self.weapon;
    parm9 = self.armor_fire + (self.armor_body * 256) + (self.armor_mind * 65536);
    parm10 = self.inven1;
    parm11 = self.inven2;
    parm12 = self.it_select;
};

void() SetNewParms =
{
    parm1 = IT_PITCHFORK;
    parm2 = 0;
    parm3 = 100;
    parm4 = 0;
    parm5 = 0;
    parm6 = 0;
    parm7 = 0;
    parm8 = IT_PITCHFORK;
    parm9 = 0;
    parm10 = 0;
    parm11 = 0;
    parm12 = 0;
    parm13 = 0;
};

void() DecodeLevelParms =
{
    // take away all stuff on starting new episode
    if (serverflags && world.model == "maps/start.bsp")
        SetNewParms ();

    self.items           = parm1;
    self.items2          = parm2;
    self.health          = parm3;
    self.ammo_flares     = (parm4 & 127);
    self.ammo_shells     = (parm4 & 16256) / 128;
    self.ammo_nails      = (parm4 & 8372224) / 16384;
    self.ammo_rockets    = (parm5 & 127);
    self.ammo_tnt_bundle = (parm5 & 16256) / 128;
    self.ammo_tnt_proxy  = (parm5 & 2080768) / 16384;
    self.ammo_tnt_remote = (parm6 & 127);
    self.ammo_spray      = (parm6 & 32640) / 128;
    self.ammo_cells      = (parm6 & 8355840) / 32768;
    self.ammo_voodoo     = (parm7 & 255);
    self.ammo_leech      = (parm7 & 65280) / 256;
    self.weapon          = parm8;
    self.armor_fire      = (parm9 & 255);
    self.armor_body      = (parm9 & 65280) / 256;
    self.armor_mind      = (parm9 & 16711680) / 65536;
    self.inven1          = parm10;
    self.inven2          = parm11;
    self.it_select       = parm12;

    if (self.items & IT_ARMOR1)
        self.armorvalue = self.armor_body;
    else if (self.items & IT_ARMOR2)
        self.armorvalue = self.armor_fire;
    else if (self.items & IT_ARMOR3)
        self.armorvalue = self.armor_mind;
    else
        self.armorvalue = 0;
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity() FindIntermission =
{
    local   entity spot;
    local   float cyc;

    // look for info_intermission first
    spot = find (world, classname, "info_intermission");
    if (spot)
    {   // pick a random one
        cyc = random() * 4;
        while (cyc > 1)
        {
            spot = find (spot, classname, "info_intermission");
            if (!spot)
                spot = find (spot, classname, "info_intermission");
            cyc = cyc - 1;
        }
        return spot;
    }

    // If we haven't found an "info_intermission" entity,
    // use an "info_player_deathmatch" entity instead
    Bprint (PRINT_HIGH, "варнинг╨ FindIntermission: no info_intermission\n");  // "WARNING: ..."
    spot = find (world, classname, "info_player_deathmatch");
    if (spot)
        return spot;

    objerror ("FindIntermission: no spot");
};


void() GotoNextMap =
{
    #ifdef QUAKEWORLD
    local string newmap;

    // QW supports a configurable map list
    // see if the current map exists as a serverinfo / localinfo var
    newmap = infokey(world, mapname);
    if (newmap != "")
        changelevel (newmap);
    else
    #endif
        changelevel (nextmap);
};


/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
void() IntermissionThink =
{
    if (time < intermission_exittime)
        return;

    if (!self.button0 && !self.button3 && !self.button2)
        return;

    GotoNextMap ();
};


/*
====================
Cl_PlayIntermissionSound

Think fonction to make the intermission sound loop
====================
*/
void() Cl_PlayIntermissionSound =
{
    sound (self.enemy, CHAN_VOICE, "misc/moans.wav", 0.5, ATTN_NONE);
    self.nextthink = time + 5.2;
};


/*
============
execute_changelevel

The global "nextmap" has been set previously.
Take the players to the intermission spot
============
*/
void() execute_changelevel =
{
    local entity    pos;

    intermission_running = 1;

    // enforce a wait time before allowing changelevel
    intermission_exittime = time + 5;

    pos = FindIntermission ();

    // Play the intermission sound
    sound (pos, CHAN_VOICE, "misc/moans.wav", 0.5, ATTN_NONE);
    self.enemy = pos;
    self.nextthink = time + 5.2;
    self.think = Cl_PlayIntermissionSound;

    WriteByte (MSG_ALL, SVC_CDTRACK);
    WriteByte (MSG_ALL, 3);

    #ifndef QUAKEWORLD
    WriteByte (MSG_ALL, 3);

    #else
    WriteByte (MSG_ALL, SVC_INTERMISSION);
    WriteCoord (MSG_ALL, pos.origin_x);
    WriteCoord (MSG_ALL, pos.origin_y);
    WriteCoord (MSG_ALL, pos.origin_z);
    WriteAngle (MSG_ALL, pos.mangle_x);
    WriteAngle (MSG_ALL, pos.mangle_y);
    WriteAngle (MSG_ALL, pos.mangle_z);
    #endif

    other = find (world, classname, "player");
    while (other != world)
    {
        #ifndef QUAKEWORLD
        KillBurner (other);
        other.view_ofs = '0 0 0';
        other.angles = other.v_angle = pos.mangle;
        other.fixangle = TRUE;      // turn this way immediately
        other.nextthink = time + 0.5;
        #endif

        other.takedamage = DAMAGE_NO;
        other.solid = SOLID_NOT;
        other.movetype = MOVETYPE_NONE;
        other.modelindex = 0;

        #ifndef QUAKEWORLD
        setorigin (other, pos.origin);
        #endif
        other = find (other, classname, "player");
    }

    #ifndef QUAKEWORLD
    WriteByte (MSG_ALL, SVC_INTERMISSION);
    #endif
};


void() changelevel_touch =
{
    local entity    pos;

    if (other.classname != "player")
        return;

    // if "noexit" is set, blow up the player trying to leave
    if ((cvar("noexit") == 1) || ((cvar("noexit") == 2) && (mapname != "start")))
    {
        T_Damage (other, self, self, 50000, DF_NO_PROTECT, "noexit");
        return;
    }

    Bprint (PRINT_HIGH, other.netname);
    Bprint (PRINT_HIGH," checked out for good\n");

    nextmap = self.map;

    SUB_UseTargets ();

    self.touch = SUB_Null;

// we can't move people right now, because touch functions are called
// in the middle of C movement code, so set a think time to do it
    self.think = execute_changelevel;
    self.nextthink = time + 0.1;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.
Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
    if (!self.map)
        objerror ("changelevel trigger doesn't have map");

    InitTrigger ();
    self.touch = changelevel_touch;
};


/*
=============================================================================

                PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

/*
====================
UpdatePlayerFrags

Update the frag count of the player and his team
====================
*/
void(entity player, float fragsToAdd) UpdatePlayerFrags =
{
    local string score;

    player.frags = player.frags + fragsToAdd;

    if (gametype == GT_TEAM_BLOODBATH)
    {
        if (player.team == TEAM_COLOR1)
            team1score = team1score + fragsToAdd;
        else
            team2score = team2score + fragsToAdd;

        // Show scores
        Bprint (PRINT_HIGH, "ред╨ ");            // "RED: "
        score = ftos (team1score);
        Bprint (PRINT_HIGH, score);
        Bprint (PRINT_HIGH, " ╞ блуе╨ ");        // " / BLUE: "
        score = ftos (team2score);
        Bprint (PRINT_HIGH, score);
        Bprint (PRINT_HIGH, "\n");
    }
};


// called by ClientKill and DeadThink
void() respawn =
{
    // make a copy of the dead body for appearances sake
    if (self.classname != "observer")
        CloneCorpse (self);

    // set default spawn parms
    SetNewParms ();

    // respawn
    PutClientInServer ();
};


/*
============
ClientKill

Player entered the suicide command
============
*/
void() set_suicide_frame;
void() ClientKill =
{
    // can't suicide when observer
    if (self.observer)
        return;

    Bprint (PRINT_MEDIUM, "Kevorkian approves!\n");
    sound (self, CHAN_AUTO, "thevoice/vo5.wav", 1, ATTN_NORM);
    CTF_PlayerDropFlag ();
    set_suicide_frame ();
    self.modelindex = modelindex_player;
    #ifdef QUAKEWORLD
    logfrag (self, self);
    #endif
    UpdatePlayerFrags (self, -2);  // extra penalty
    respawn ();
};


float(vector v) CheckSpawnPoint =
{
    return FALSE;
};


/*
====================
Cl_IsSpawnSpotFree

Test whether or not someone is on the spawn point
====================
*/
float(entity spot) Cl_IsSpawnSpotFree =
{
    local entity thing;

    thing = findradius (spot.origin, 32);
    while (thing)
    {
        if (thing.classname == "player")
            return FALSE;
        thing = thing.chain;
    }

    return TRUE;
};


/*
====================
Cl_GetRandomSpawnPoint

Select a random spawn point. Avoid telefragging when possible
====================
*/
entity(string spawnclass) Cl_GetRandomSpawnPoint =
{
    local entity spot;
    local float freespots, totalspots;

    // Count the spots
    freespots = totalspots = 0;
    spot = find (world, classname, spawnclass);
    while (spot)
    {
        totalspots = totalspots + 1;
        if (Cl_IsSpawnSpotFree (spot))
        {
            spot.cnt = 1;  // mark the spot as "free" so we won't do the test twice
            freespots = freespots + 1;
        }
        else
            spot.cnt = 0;

        spot = find (spot, classname, spawnclass);
    }

    // If there's no spawn point with this classname
    if (! totalspots)
        return world;

    // If there's no free spot, we will have to telefrag someone...
    if (! freespots)
    {
        totalspots = floor (random () * totalspots);
        spot = find (world, classname, spawnclass);
        while (totalspots > 0)
        {
            totalspots = totalspots - 1;
            spot = find (spot, classname, spawnclass);
        }
        return spot;
    }

    // Choose one of the free spots at random
    freespots = ceil (random () * freespots);
    spot = world;
    while (freespots > 0)
    {
        spot = find (spot, classname, spawnclass);
        if (spot.cnt)
            freespots = freespots - 1;
    }
    return spot;
};


/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity() SelectSpawnPoint =
{
    local entity spawnpoint;

    // If it's a team based game, try to spawn on one of the team's points
    if (gametype != GT_BLOODBATH)
    {
        if (self.team == TEAM_COLOR1)
        {
            spawnpoint = Cl_GetRandomSpawnPoint ("info_player_team1");
            if (spawnpoint)
                return spawnpoint;
        }
        else if (self.team == TEAM_COLOR2)
        {
            spawnpoint = Cl_GetRandomSpawnPoint ("info_player_team2");
            if (spawnpoint)
                return spawnpoint;
        }
    }

    spawnpoint = Cl_GetRandomSpawnPoint ("info_player_deathmatch");
    if (spawnpoint)
        return spawnpoint;

    // We haven't found a suitable spawn point
    error ("SelectSpawnPoint: no spawn point on level");
};


void() DecodeLevelParms;
void() PlayerDie;


/*
===========
PutClientInServer

called each time a player is spawned
============
*/
void() PutClientInServer =
{
    local   entity spot;

    spot = SelectSpawnPoint ();

    self.classname = "player";
    self.health = 100;
    self.takedamage = DAMAGE_AIM;
    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_WALK;
    self.show_hostile = 0;
    self.max_health = 100;
    self.flags = FL_CLIENT;
    self.air_finished = time + 12;
    self.dmg = 2;           // initial water damage
    self.akimbo_finished = 0;
    self.radsuit_finished = 0;
    self.invisible_finished = 0;
    self.invincible_finished = 0;
    self.effects = 0;
    self.invincible_time = 0;
    KillBurner (self);

    self.reflect_finished = 0;
    self.remain_dmg = 0;
    self.remain_arm = 0;

    Bomb_Uncharge ();
    ResetIdle (self);

    DecodeLevelParms ();

    // You surely don't want to toss your brand new TNT *right now*...
    self.attack_finished = time + 0.3;
    self.impulse = 0;

    self.th_pain = player_pain;
    self.th_die = PlayerDie;
    self.touch = SUB_Null;  // remove the "HeadTouch" binding (if any)

    self.deadflag = DEAD_NO;
    self.player_state = PS_IDLE;
    self.newweapon = 0;

    // paustime is set by teleporters to keep the player from moving a while
    self.pausetime = 0;

    self.origin = spot.origin + '0 0 1';
    self.angles = spot.angles;
    self.fixangle = TRUE;       // turn this way immediately

    // Hack to get the eyes model index
    setmodel (self, "progs/eyes.mdl");
    modelindex_eyes = self.modelindex;

    setmodel (self, "progs/player.mdl");
    modelindex_player = self.modelindex;

    setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

    self.view_ofs = '0 0 25';
    self.velocity = '0 0 0';
    self.avelocity = '0 0 0';

    player_stand ();

    if (self.do_observer)
    {
        BecomeObserver (self);
        return;
    }

    // Select the appropriate skin
    if (self.team == TEAM_COLOR1)
        self.skin = 1;
    else if (self.team == TEAM_COLOR2)
        self.skin = 2;

    makevectors(self.angles);
    spawn_tfog (self.origin + v_forward*20);

    spawn_tdeath (self.origin, self);

    // Let's start with our best weapon
    self.weapon = W_BestWeapon ();
    W_DrawWeapon (self.weapon);
};


/*
=============================================================================

                QUAKED FUNCTIONS

=============================================================================
*/


/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start =
{
};


/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
*/
void() info_player_deathmatch =
{
};


// Team base starting locations
void() info_player_team1 =
{
};

void() info_player_team2 =
{
};


/*
===============================================================================

RULES

===============================================================================
*/

/*
go to the next level for deathmatch
only called if a time or frag limit has expired
*/
void() NextLevel =
{
    local entity o;

    #ifdef QUAKEWORLD
    if (nextmap != "")
        return; // already done
    #endif

    // find a trigger changelevel
    o = find(world, classname, "trigger_changelevel");

    // go back to same map if no trigger_changelevel
    if (!o)
    {
        o = spawn();
        o.map = mapname;
    }

    nextmap = o.map;
    gameover = TRUE;

    if (o.nextthink < time)
    {
        o.think = execute_changelevel;
        o.nextthink = time + 0.1;
    }
};

/*
============
CheckRules

Exit deathmatch games upon conditions
============
*/
void() CheckRules =
{
    if (gameover)   // someone else quit the game already
        return;

    if (timelimit && time >= timelimit)
    {
        NextLevel ();
        return;
    }

    if (fraglimit)
    {
        // If we are in a team based mode
        if (gametype > GT_BLOODBATH)
        {
            if (team1score >= fraglimit || team2score >= fraglimit)
            {
                NextLevel ();
                return;
            }
        }
        else if (self.frags >= fraglimit)
        {
            NextLevel ();
            return;
        }
    }
};

//============================================================================

void() PlayerDeathThink =
{
    local entity    old_self;
    local float     forward;

    if ((self.flags & FL_ONGROUND))
    {
        forward = vlen (self.velocity);
        forward = forward - 20;
        if (forward <= 0)
            self.velocity = '0 0 0';
        else
            self.velocity = forward * normalize(self.velocity);
    }

    // wait for all buttons released
    if (self.deadflag == DEAD_DEAD)
    {
        if (self.button2 || self.button3 || self.button0)
            return;
        self.deadflag = DEAD_RESPAWNABLE;

        // Play the obituary sound
        if (self.noise1)
        {
            sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
            self.noise1 = string_null;
        }

        return;
    }

    // wait for any button down
    if (!self.button2 && !self.button3 && !self.button0)
        return;

    self.button0 = 0;
    self.button3 = 0;
    self.button2 = 0;
    respawn();
};


void() PlayerJump =
{
    local vector start, end;

    if (self.flags & FL_WATERJUMP)
        return;

    if (self.waterlevel >= 2)
    {
        if (self.watertype == CONTENT_WATER)
            self.velocity_z = 100;
        else if (self.watertype == CONTENT_SLIME)
            self.velocity_z = 80;
        else
            self.velocity_z = 50;

        // play swiming sound
        if (self.swim_flag < time)
        {
            self.swim_flag = time + 1;
            if (random() < 0.5)
                sound (self, CHAN_BODY, "foley/swim.wav", 1, ATTN_NORM);
            else
                sound (self, CHAN_BODY, "foley/submerge.wav", 1, ATTN_NORM);
        }

        return;
    }

    if (!(self.flags & FL_ONGROUND))
        return;

    if ( !(self.flags & FL_JUMPRELEASED) )
        return;     // don't pogo stick

    self.flags = self.flags - (self.flags & FL_JUMPRELEASED);

    self.button2 = 0;
    sound (self, CHAN_BODY, "foley/jump.wav", 1, ATTN_NORM);  // player jumping sound

    local   float   jump;

    #ifndef QUAKEWORLD
    jump = 350;     // quake value was 270
    #else
    jump = 80;     // quake will add 270 to that
    #endif

    // Boots let player jump about 4x as high.
    // NOTE:  max height = v0^2 / 2g.
    if (self.boots_on)
        #ifndef QUAKEWORLD
        jump = jump + 320;
        #else
        jump = jump + 600;
        #endif

    self.flags = self.flags - FL_ONGROUND;  // don't stairwalk
    self.velocity_z = self.velocity_z + jump;
};


/*
===========
WaterMove

============
*/
void() WaterMove =
{
    if (self.movetype == MOVETYPE_NOCLIP)
        return;
    if (self.health < 0)
        return;

    if (self.waterlevel != 3)
    {
        if (self.air_finished < time)
            sound (self, CHAN_VOICE, "foley/undchoke.wav", 1, ATTN_NORM);
        else if (self.air_finished < time + 9)
            sound (self, CHAN_VOICE, "foley/gasp.wav", 1, ATTN_NORM);
        self.air_finished = time + 12;
        self.dmg = 2;
        if (self.dive_on)
            Use_DivingSuit ();  // Turn of diving suit.
    }
    else if (self.air_finished < time)
    {   // drown!
        if (self.pain_finished < time)
        {
            self.dmg = self.dmg + 2;
            if (self.dmg > 15)
                self.dmg = 10;
            // Armor does not protect against drowning.
            T_Damage (self, world, world, self.dmg, 0, "drowning");
            self.pain_finished = time + 1;
        }
    }
    // Auto-use diving suit if underwater.
    if (self.waterlevel == 3)
    {
        if (self.air_finished < time + 11)
            if (!self.dive_on)
                Use_DivingSuit ();

        // Holster all weapons based on fire
        if (self.weapon == IT_TNT || self.weapon == IT_SPRAY_CAN)
        {
            if (self.player_state != PS_HOLSTER)
            {
                Bomb_Uncharge ();

                // Switch to our best weapon
                self.newweapon = W_BestWeapon ();
                W_SwitchToWeapon (self.newweapon);
            }
        }
    }

    if (!self.waterlevel || self.watertype == CONTENT_EMPTY)
    {
        if (self.flags & FL_INWATER)
        {
            // play leave water sound
            sound (self, CHAN_BODY, "foley/emerge.wav", 1, ATTN_NORM);
            self.flags = self.flags - FL_INWATER;
        }
        return;
    }

    if (self.watertype == CONTENT_LAVA)
    {   // do damage
        if (self.dmgtime < time)
        {
            if (self.dive_on)
                self.dmgtime = time + 1;
            else
                self.dmgtime = time + 0.2;

            // Fire-based damage
            T_Damage (self, world, world, 10*self.waterlevel, DF_FIRE, "fire");
        }
    }
    else if (self.watertype == CONTENT_SLIME)
    {   // do damage
        if (self.dmgtime < time)
            if (!self.dive_on)
        {
            self.dmgtime = time + 1;
            T_Damage (self, world, world, 4*self.waterlevel, DF_BODY, "acid");
        }
    }

    if ( !(self.flags & FL_INWATER) )
    {

        // player enter water sound
        if (self.watertype == CONTENT_LAVA)
            sound (self, CHAN_BODY, "weapons/napalm/burn.wav", 1, ATTN_NORM);
        if (self.watertype == CONTENT_WATER)
            sound (self, CHAN_BODY, "foley/submerge.wav", 1, ATTN_NORM);
        if (self.watertype == CONTENT_SLIME)
            sound (self, CHAN_BODY, "ambience/sizzle.wav", 1, ATTN_NORM);

        self.flags = self.flags + FL_INWATER;
        self.dmgtime = 0;
    }

    #ifndef QUAKEWORLD
    if (! (self.flags & FL_WATERJUMP) )
        self.velocity = self.velocity - 0.8*self.waterlevel*frametime*self.velocity;
    #endif
};

void() CheckWaterJump =
{
    local vector start, end;

// check for a jump-out-of-water
    makevectors (self.angles);
    start = self.origin;
    start_z = start_z + 8;
    v_forward_z = 0;
    normalize(v_forward);
    end = start + v_forward*24;
    traceline (start, end, TRUE, self);
    if (trace_fraction < 1)
    {   // solid at waist
        start_z = start_z + self.maxs_z - 8;
        end = start + v_forward*24;
        self.movedir = trace_plane_normal * -50;
        traceline (start, end, TRUE, self);
        if (trace_fraction == 1)
        {   // open at eye level
            self.flags = self.flags | FL_WATERJUMP;
            self.velocity_z = 225;
            self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
            self.teleport_time = time + 2;  // safety net
            return;
        }
    }
};


/*
================
PlayerPreThink

Called every frame before physics are run
================
*/
void() PlayerPreThink =
{
    local   float   mspeed, aspeed;
    local   float   r;

    #ifdef FRIKBOT
    if (BotPreFrame())
        return;
    #endif

    if (intermission_running)
    {
        IntermissionThink ();   // otherwise a button could be missed between
        return;                 // the think tics
    }

    if (self.view_ofs == '0 0 0')
        return;     // intermission or finale

    makevectors (self.v_angle);     // is this still used

    self.deathtype = "";

    CheckRules ();
    WaterMove ();

    #ifndef QUAKEWORLD
    if (self.waterlevel == 2)
        CheckWaterJump ();
    #endif

    if (self.deadflag >= DEAD_DEAD)
    {
        PlayerDeathThink ();
        return;
    }

    #ifndef QUAKEWORLD
    // Players on the BOD can't move
    if (self.player_state == PS_BRINK_OF_DEATH)
    {
        self.velocity_x = 0;
        self.velocity_y = 0;
        return;
    }
    #endif

    if (self.observer)
    {
        ObserverThink();
        return;
    }

    if (self.deadflag == DEAD_DYING)
        return; // dying, so do nothing

    if (self.button2)
    {
        PlayerJump ();
    }
    else
        self.flags = self.flags | FL_JUMPRELEASED;

// teleporters can force a non-moving pause time
    if (time < self.pausetime)
        self.velocity = '0 0 0';
};

/*
================
CheckPowerups

Check for turning off powerups
================
*/
void() CheckPowerups =
{
    if (self.health <= 0)
        return;

// invisibility
    if (self.invisible_finished)
    {
// sound and screen flash when items starts to run out
        if (self.invisible_sound < time)
        {
            sound (self, CHAN_AUTO, "bludbath/powerup.wav", 0.5, ATTN_IDLE);
            self.invisible_sound = time + ((random() * 3) + 1);
        }


        if (self.invisible_finished < time + 3)
        {
            if (self.invisible_time == 1)
            {
                Sprint (self, PRINT_HIGH, "Cloak of Invisibility is draining\n");
                stuffcmd (self, "bf\n");
                sound (self, CHAN_AUTO, "bludbath/powerup.wav", 1, ATTN_NORM);
                self.invisible_time = time + 1;
            }

            if (self.invisible_time < time)
            {
                self.invisible_time = time + 1;
                stuffcmd (self, "bf\n");
            }
        }

        if (self.invisible_finished < time)
        {   // just stopped
            self.items = self.items - IT_INVISIBILITY;
            self.invisible_finished = 0;
            self.invisible_time = 0;
        }

    // use the eyes
        self.frame = 0;
        self.modelindex = modelindex_eyes;
    }
    else
        self.modelindex = modelindex_player;    // don't use eyes

// invincibility
    if (self.invincible_finished)
    {
// sound and screen flash when items starts to run out
        if (self.invincible_finished < time + 3)
        {
            if (self.invincible_time == 1)
            {
                Sprint (self, PRINT_HIGH, "Death Mask is almost used up\n");
                stuffcmd (self, "bf\n");
                sound (self, CHAN_AUTO, "bludbath/powerup.wav", 1, ATTN_NORM);
                self.invincible_time = time + 1;
            }

            if (self.invincible_time < time)
            {
                self.invincible_time = time + 1;
                stuffcmd (self, "bf\n");
            }
        }

        if (self.invincible_finished < time)
        {   // just stopped
            self.items = self.items - IT_INVULNERABILITY;
            self.invincible_time = 0;
            self.invincible_finished = 0;
        }
        if (self.invincible_finished > time)
            self.effects = self.effects | EF_DIMLIGHT | EF_RED;
        else
            self.effects = self.effects - (self.effects & (EF_DIMLIGHT | EF_RED));
    }

    // Guns akimbo
    if (self.akimbo_finished)
    {
        // just stopped
        if (self.akimbo_finished < time)
        {
            self.akimbo_finished = 0;
            W_SetCurrentAmmo ();
        }

        // (un)set the entity effects
        if (self.akimbo_finished > time)
            self.effects = self.effects | EF_DIMLIGHT;
        else
            self.effects = self.effects - (self.effects & EF_DIMLIGHT);
    }

    // Reflective shots
    if (self.reflect_finished)
    {
        // In Blood, there is no warning when it stops.

        if (self.reflect_finished < time)
        {   // just stopped
            self.reflect_finished = 0;

            self.effects = self.effects - (self.effects & (EF_DIMLIGHT | EF_BLUE));
        }
        else
            self.effects = self.effects | EF_DIMLIGHT | EF_BLUE;
    }

    // Check inventory items.
    InvenCheck ();
};


/*
============
Impulses_Player

Impulse list for living players
============
*/
void() Impulses_Player =
{
    // Nothing to do, or altfire (will be treated later)
    if (self.impulse == 0 || self.impulse == 12)
        return;

    if ((self.impulse >= 1 && self.impulse <= 9) || self.impulse == 17)
        W_ChangeWeapon ();

    else if (self.impulse == 10)
        CycleWeaponCommand ();
    else if (self.impulse == 11)
        CycleWeaponReverseCommand ();

    // Inventory selection/usage.
    else if (self.impulse == 13)
        InvenUse ();
    else if (self.impulse == 14)
        InvenSelect (FALSE);
    else if (self.impulse == 15)
        InvenSelect (TRUE);

    // Armor cycle.
    else if (self.impulse == 16)
        ArmorTest ();

    // Toggle menu
    else if (self.impulse == 50)
        Menu_Start ();

    #ifdef FRIKBOT
    // Bot management
    else if (self.impulse == 100 || self.impulse == 101)
    {
        // If bots are disabled
        if (cvar ("sv_disable") & SV_DISABLE_BOTS)
            Sprint (self, PRINT_HIGH, "Bots are disabled on this server\n");
        else
        {
            local float botskill;

            botskill = cvar ("skill");
            BotConnect (self.impulse - 100, 0, botskill);
        }
    }
    else if (self.impulse == 102)
        KickABot();
    #else
    else if (self.impulse >= 100 && self.impulse <= 102)
        Sprint (self, PRINT_HIGH, "Sorry, these progs don't have bot support\n");
    #endif

    else if (self.impulse == 141)
        identify_player ();

    // These ones are considered cheats and are only allowed when the "sv_allowCheat" cvar is set
    else if (cvar ("sv_allowCheat"))
    {
        #if defined(FRIKBOT) && !defined (QUAKEWORLD)
        if (self.impulse == 103)
            botcam_u ();
        else if (self.impulse == 104)
            bot_way_edit ();
        else
        #endif

        if (self.impulse == 250)
        {
            coredump ();
        }
        else if (self.impulse == 251)
        {
            Sprint (self, PRINT_MEDIUM, "griswold -- You have full armor.\n");
            self.armor_fire = self.armor_body = self.armor_mind = self.armorvalue = 200;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR2;
        }
        else if (self.impulse == 252)
        {
            Sprint (self, PRINT_MEDIUM, "mcgee -- You're fired!\n");
            Ignite (self, self, 200, DF_FIRE);
        }
        else if (self.impulse == 253)
            Cheat_Inventory ();
        #ifndef QUAKEWORLD
        else if (self.impulse == 254)
            Player_BrinkOfDeath (self, world);
        #endif
        else if (self.impulse == 255)
            Cheat_Akimbo ();
    }

    self.impulse = 0;
};


/*
============
Impulses_Dead

Impulse list for dead players
============
*/
void() Impulses_Dead =
{
    if (self.impulse == 0)
        return;

    // If we're dead, we are allowed to become an observer again
    if (self.impulse == 20)
    {
        self.do_observer = 1;
        respawn ();
        Bprint (PRINT_MEDIUM, self.netname);
        Bprint (PRINT_MEDIUM, " is an observer again\n");
    }

    // Toggle menu
    else if (self.impulse == 50)
        Menu_Start ();

    #ifdef FRIKBOT
    // Bot management
    else if (self.impulse == 100 || self.impulse == 101)
    {
        // If bots are disabled
        if (cvar ("sv_disable") & SV_DISABLE_BOTS)
            Sprint (self, PRINT_HIGH, "Bots are disabled on this server\n");
        else
        {
            local float botskill;

            botskill = cvar ("skill");
            BotConnect (self.impulse - 100, 0, botskill);
        }
    }
    else if (self.impulse == 102)
        KickABot();
    #else
    else if (self.impulse >= 100 && self.impulse <= 102)
        Sprint (self, PRINT_HIGH, "Sorry, these progs don't have bot support\n");
    #endif

    else if (self.impulse == 141)
        identify_player ();

    self.impulse = 0;
};


/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() PlayerPostThink =
{
    local   float   mspeed, aspeed;
    local   float   r;

    #ifdef FRIKBOT
    if (BotPostFrame())
        return;
    #endif

    // Check for menu commands
    if (self.player_state == PS_MENU)
        Menu_Update ();

    // if we're not allowed to act (in intermission, or dead, or observer)
    if (self.view_ofs == '0 0 0' || self.deadflag || self.observer)
    {
        // allow some impulses
        if (self.observer)
            Impulses_Observer ();
        else if (self.deadflag == DEAD_RESPAWNABLE)
            Impulses_Dead ();

        return;
    }

    // check to see if player landed and play landing sound
    // no damage taken if not > 350 units high
    if ((self.jump_flag < -350) && (self.flags & FL_ONGROUND) && (self.health > 0))
    {
        if (self.watertype == CONTENT_WATER)
            sound (self, CHAN_BODY, "foley/lndwater.wav", 1, ATTN_NORM);

        // if higher than 700 units
        else if (self.jump_flag < -700)
        {
            // Armor does not protect against falling.
            aspeed = (-650 - self.jump_flag) * 0.3;
            T_Damage (self, world, world, aspeed, 0, "falling");
        }
        else
            sound (self, CHAN_VOICE, "foley/land.wav", 1, ATTN_NORM);

        self.jump_flag = 0;
    }

    self.jump_flag = self.velocity_z;

    CheckPowerups ();

    #ifndef QUAKEWORLD  // No BOD in QW
    // If we are on the Brink Of Death
    if (self.player_state == PS_BRINK_OF_DEATH)
    {
        if (self.t_length < time)
            Player_LiveAgain ();
        ResetIdle (self);
        return;
    }
    #endif

    W_WeaponFrame ();

    // Check for boredom.
    if (self.velocity == '0 0 0' && self.idle_time <= time && !self.idle_done)
    {
        BoredCaleb (self);
        self.idle_done = TRUE;
    }
    else
        ResetIdle (self);
};


/*
===========
ClientConnect

called when a player connects to a server
============
*/
void() ClientConnect =
{
    #ifdef FRIKBOT
    ClientInRankings();
    #endif

    Bprint (PRINT_HIGH, self.netname);
    Bprint (PRINT_HIGH, " lives again!\n"); // entered the game

    sound (self, CHAN_AUTO, "thevoice/vo1.wav", 1, ATTN_NORM); // Let the Bloodbath Begin!
    self.do_observer = 1;

    // a client connecting during an intermission can cause problems
    if (intermission_running)
        GotoNextMap ();
};


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
    local string finalscore;

    #ifdef FRIKBOT
    ClientDisconnected();
    #endif

    // if the level end trigger has been activated, just return
    // since they aren't *really* leaving
    if (gameover)
        return;

    // let everyone else know
    Bprint (PRINT_HIGH, self.netname);
    Bprint (PRINT_HIGH, " left this world for another with ");
    finalscore = ftos (self.frags);
    Bprint (PRINT_HIGH, finalscore);
    Bprint (PRINT_HIGH, " kills\n");
    sound (self, CHAN_BODY, "thevoice/vo2.wav", 1, ATTN_NONE);
    CTF_PlayerDropFlag ();
    set_suicide_frame ();
};

/*
===========
ClientObituary

called when a player dies (self is the victim)
============
*/
void(entity attacker) ClientObituary =
{
    local   float rnum;
    local   string deathstring, deathstring2;

    rnum = random();

    if (self.classname != "player")
        return;  // Maybe we should print an error message

    if (attacker.classname == "teledeath")
    {
        Bprint (PRINT_MEDIUM,self.netname);
        Bprint (PRINT_MEDIUM,"'s personal space was invaded by ");
        Bprint (PRINT_MEDIUM,attacker.owner.netname);
        Bprint (PRINT_MEDIUM,"\n");
        self.noise1 = "thevoice/splatt.wav";
        #ifdef QUAKEWORLD
        logfrag (attacker.owner, self);
        #endif

        UpdatePlayerFrags (attacker.owner, 1);
        return;
    }

    if (attacker.classname == "teledeath2")
    {
        Bprint (PRINT_MEDIUM,"Tchernobog's Death Mask deflects ");
        Bprint (PRINT_MEDIUM,self.netname);
        Bprint (PRINT_MEDIUM,"'s telefrag\n");
        self.noise1 = "thevoice/splatt.wav";
        #ifdef QUAKEWORLD
        logfrag (self, self);
        #endif

        UpdatePlayerFrags (self, -1);
        return;
    }

    // double 666 telefrag
    if (attacker.classname == "teledeath3")
    {
        Bprint (PRINT_MEDIUM,self.netname);
        Bprint (PRINT_MEDIUM," was overcome by  ");
        Bprint (PRINT_MEDIUM,attacker.owner.netname);
        Bprint (PRINT_MEDIUM, "'s Death Mask power\n");
        UpdatePlayerFrags (self, -1);
        self.noise1 = "thevoice/splatt.wav";
        #ifdef QUAKEWORLD
        logfrag (self, self);
        #endif
        return;
    }

    if (self.deathtype == "squish")
    {
        Bprint (PRINT_MEDIUM,self.netname);
        Bprint (PRINT_MEDIUM," was squashed\n");
        self.noise1 = "thevoice/squash.wav";
        UpdatePlayerFrags (self, -1);  // killed self
        #ifdef QUAKEWORLD
        logfrag (self, self);
        #endif
        return;
    }

    if (attacker.classname == "player")
    {
        if (self == attacker)
        {
            // killed self in a dumb fashion
            #ifdef QUAKEWORLD
            logfrag (attacker, attacker);
            #endif
            UpdatePlayerFrags (attacker, -1);
            Bprint (PRINT_MEDIUM,self.netname);

            if (rnum < 0.33)
            {
                deathstring = " receives the Darwin Award.\n";
                self.noise1 = "thevoice/vo16.wav";
            }
            else if (rnum < 0.66)
            {
                deathstring = " exercises Population control.\n";
                self.noise1 = "thevoice/vo12.wav";
            }
            else
            {
                deathstring = " gets an Unassisted death\n";
                self.noise1 = "thevoice/vo13.wav";
            }

            Bprint (PRINT_MEDIUM, deathstring);
            return;
        }
        else if (friendlyfire && self.team > 0 && self.team == attacker.team)
        {
            if (rnum < 0.25)
                deathstring = " mows down a teammate\n";
            else if (rnum < 0.50)
                deathstring = " checks his glasses\n";
            else if (rnum < 0.75)
                deathstring = " gets a frag for the other team\n";
            else
                deathstring = " loses another friend\n";
            Bprint (PRINT_MEDIUM, attacker.netname);
            Bprint (PRINT_MEDIUM, deathstring);

            UpdatePlayerFrags (attacker, -1);

            #ifdef QUAKEWORLD
            // killing a teammate logs as suicide
            logfrag (attacker, attacker);
            #endif
            return;
        }
        else
        {
            // no weapon associations, just random message and Announcer voice
            #ifdef QUAKEWORLD
            logfrag (attacker, self);
            #endif
            UpdatePlayerFrags (attacker, 1);

            rnum = random()*54;

            // Messages with no names
            if (rnum <= 1)
            {
                Bprint (PRINT_MEDIUM, "Beaten like a Cur.\n");
                self.noise1 = "thevoice/vo39.wav";
            }
            else if (rnum <= 2)
            {
                Bprint (PRINT_MEDIUM, "Bobbettized!\n");
                self.noise1 = "thevoice/vo31.wav";
            }
            else if (rnum <= 3)
            {
                Bprint (PRINT_MEDIUM, "Destroyed!\n");
                self.noise1 = "thevoice/vo24.wav";
            }
            else if (rnum <= 4)
            {
                Bprint (PRINT_MEDIUM, "Dog meat.\n");
                self.noise1 = "thevoice/vo36.wav";
            }
            else if (rnum <= 5)
            {
                Bprint (PRINT_MEDIUM, "Excellent!\n");
                self.noise1 = "thevoice/vo44.wav";
            }
            else if (rnum <= 6)
            {
                Bprint (PRINT_MEDIUM, "Fine work.\n");
                self.noise1 = "thevoice/vo22.wav";
            }
            else if (rnum <= 7)
            {
                Bprint (PRINT_MEDIUM, "Good one\n");
                self.noise1 = "thevoice/vo20.wav";
            }
            else if (rnum <= 8)
            {
                Bprint (PRINT_MEDIUM, "He shoots! He scores!\n");
                self.noise1 = "thevoice/vo33.wav";
            }
            else if (rnum <= 8)
            {
                Bprint (PRINT_MEDIUM, "Hosed!\n");
                self.noise1 = "thevoice/vo25.wav";
            }
            else if (rnum <= 10)
            {
                Bprint (PRINT_MEDIUM, "Humiliated!\n");
                self.noise1 = "thevoice/vo26.wav";
            }
            else if (rnum <= 11)
            {
                Bprint (PRINT_MEDIUM, "Lunch meat!\n");
                self.noise1 = "thevoice/vo21.wav";
            }
            else if (rnum <= 12)
            {
                Bprint (PRINT_MEDIUM, "Pass the chili!\n");
                self.noise1 = "thevoice/vo29.wav";
            }
            else if (rnum <= 13)
            {
                Bprint (PRINT_MEDIUM, "Punishment delivered\n");
                self.noise1 = "thevoice/vo30.wav";
            }
            else if (rnum <= 14)
            {
                Bprint (PRINT_MEDIUM, "Ripped 'em loose.\n");
                self.noise1 = "thevoice/vo38.wav";
            }
            else if (rnum <= 15)
            {
                Bprint (PRINT_MEDIUM, "Sent to HELL!\n");
                self.noise1 = "thevoice/vo28.wav";
            }
            else if (rnum <= 16)
            {
                Bprint (PRINT_MEDIUM, "Snuffed!\n");
                self.noise1 = "thevoice/vo41.wav";
            }
            else if (rnum <= 17)
            {
                Bprint (PRINT_MEDIUM, "Spillage!\n");
                self.noise1 = "thevoice/vo34.wav";
            }
            else if (rnum <= 18)
            {
                Bprint (PRINT_MEDIUM, "Sprayed!\n");
                self.noise1 = "thevoice/vo35.wav";
            }
            else if (rnum <= 19)
            {
                Bprint (PRINT_MEDIUM, "Stiffed!\n");
                self.noise1 = "thevoice/vo32.wav";
            }
            else if (rnum <= 20)
            {
                Bprint (PRINT_MEDIUM, "Talented!\n");
                self.noise1 = "thevoice/vo19.wav";
            }
            else if (rnum <= 21)
            {
                Bprint (PRINT_MEDIUM, "Toasted!\n");
                self.noise1 = "thevoice/vo27.wav";
            }
            else if (rnum <= 22)
            {
                Bprint (PRINT_MEDIUM, "Vaporized!\n");
                self.noise1 = "thevoice/vo43.wav";
            }
            else if (rnum <= 23)
            {
                Bprint (PRINT_MEDIUM, "Well done!\n");
                self.noise1 = "thevoice/vo23.wav";
            }
            else if (rnum <= 24)
            {
                Bprint (PRINT_MEDIUM, "Whipped and creamed!\n");
                self.noise1 = "thevoice/vo40.wav";
            }

            // Messages with the attacker name only
            else if (rnum <= 25)
            {
                Bprint (PRINT_MEDIUM, self.netname);
                Bprint (PRINT_MEDIUM, " suffered scrotum separation\n");
                self.noise1 = "thevoice/vo9.wav";
            }
            else if (rnum <= 26)
            {
                Bprint (PRINT_MEDIUM, self.netname);
                Bprint (PRINT_MEDIUM, " is excrement\n");
                self.noise1 = "thevoice/vo7.wav";
            }
            else if (rnum <= 27)
            {
                Bprint (PRINT_MEDIUM, self.netname);
                Bprint (PRINT_MEDIUM, " is hamburger\n");
                self.noise1 = "thevoice/vo8.wav";
            }
            else if (rnum <= 28)
            {
                Bprint (PRINT_MEDIUM, self.netname);
                Bprint (PRINT_MEDIUM, " had his spleen vented\n");
                self.noise1 = "thevoice/vo42.wav";
            }

            // Messages with attacker name and target name
            else
            {
                deathstring2 = string_null;

                if (rnum <= 29)
                {
                    deathstring = " body bagged ";
                    self.noise1 = "thevoice/vo10.wav";
                }
                else if (rnum <= 30)
                {
                    deathstring = " boned ";
                    deathstring2 = " like a fish!";
                    self.noise1 = "thevoice/boned.wav";
                }
                else if (rnum <= 31)
                {
                    deathstring = " gave ";
                    deathstring2 = " Anal Justice!";
                    self.noise1 = "thevoice/justice.wav";
                }
                else if (rnum <= 32)
                {
                    deathstring = " hurt ";
                    deathstring2 = " real bad!\n";
                    self.noise1 = string_null;
                }
                else if (rnum <= 33)
                {
                    deathstring = " ripped ";
                    deathstring2 = " a new orifice!";
                    self.noise1 = "thevoice/ripped.wav";
                }
                else if (rnum <= 34)
                {
                    deathstring = " castrated ";
                    self.noise1 = "thevoice/castra.wav";
                }
                else if (rnum <= 35)
                {
                    deathstring = " creamed ";
                    self.noise1 = "thevoice/creamed.wav";
                }
                else if (rnum <= 36)
                {
                    deathstring = " decimated ";
                    self.noise1 = "thevoice/decimat.wav";
                }
                else if (rnum <= 37)
                {
                    deathstring = " destroyed ";
                    self.noise1 = "thevoice/destro.wav";
                }
                else if (rnum <= 38)
                {
                    deathstring = " diced ";
                    self.noise1 = "thevoice/diced.wav";
                }
                else if (rnum <= 39)
                {
                    deathstring = " disembowled ";
                    self.noise1 = "thevoice/disembo.wav";
                }
                else if (rnum <= 40)
                {
                    deathstring = " flattened ";
                    self.noise1 = "thevoice/flatte.wav";
                }
                else if (rnum <= 41)
                {
                    deathstring = " killed ";
                    self.noise1 = "thevoice/killed.wav";
                }
                else if (rnum <= 42)
                {
                    deathstring = " gave AnAl MaDnEsS to ";
                    self.noise1 = "thevoice/madness.wav";
                }
                else if (rnum <= 43)
                {
                    deathstring = " massacred ";
                    self.noise1 = "thevoice/massacr.wav";
                }
                else if (rnum <= 44)
                {
                    deathstring = " made mincemeat out of ";
                    self.noise1 = "thevoice/mincmeat.wav";
                }
                else if (rnum <= 45)
                {
                    deathstring = " mutilated ";
                    self.noise1 = "thevoice/mutila.wav";
                }
                else if (rnum <= 46)
                {
                    deathstring = " reamed ";
                    self.noise1 = "thevoice/reamed.wav";
                }
                else if (rnum <= 47)
                {
                    deathstring = " shat upon ";
                    self.noise1 = "thevoice/vo14.wav";
                }
                else if (rnum <= 48)
                {
                    deathstring = " slaughtered ";
                    self.noise1 = "thevoice/slaught.wav";
                }
                else if (rnum <= 49)
                {
                    deathstring = " sliced ";
                    self.noise1 = "thevoice/sliced.wav";
                }
                else if (rnum <= 50)
                {
                    deathstring = " smashed ";
                    self.noise1 = "thevoice/smashed.wav";
                }
                else if (rnum <= 51)
                {
                    deathstring = " sodomized ";
                    self.noise1 = "thevoice/sodomiz.wav";
                }
                else if (rnum <= 52)
                {
                    deathstring = " splattered ";
                    self.noise1 = "thevoice/splatt.wav";
                }
                else if (rnum <= 53)
                {
                    deathstring = " throttled ";
                    self.noise1 = "thevoice/throttl.wav";
                }
                else
                {
                    deathstring = " wasted ";
                    self.noise1 = "thevoice/wasted.wav";
                }

                Bprint (PRINT_MEDIUM, attacker.netname);
                Bprint (PRINT_MEDIUM, deathstring);
                Bprint (PRINT_MEDIUM, self.netname);
                if (deathstring2)
                    Bprint (PRINT_MEDIUM, deathstring2);
                Bprint (PRINT_MEDIUM, "\n");
            }
        }
        return;
    }
    else
    {
        #ifdef QUAKEWORLD
        logfrag (self, self);
        #endif
        UpdatePlayerFrags (self, -1);

        // hell if I know; he's just dead!!!
        Bprint (PRINT_MEDIUM, self.netname);
        Bprint (PRINT_MEDIUM," died\n");
    }
};
