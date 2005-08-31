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
void () PlayerDie;
void () player_pain;
void () player_stand;
void (vector org) spawn_tfog;
void (vector org, entity death_owner) spawn_tdeath;
void (float snd) Taunt;
void () FadePlayerDisplay;
void () ResetPlayerDisplay;
void () shake_start;
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
};

void() SetChangeParms =
{
    // We need to have this function, but it's unused
};

void() SetNewParms =
{
    // We need to have this function, but it's unused
};

void() InitPlayerCharacteristics =
{
    self.items           = IT_PITCHFORK;
    self.items2          = 0;
    self.health          = 100;
    self.ammo_flare      = 0;
    self.ammo_shells     = 0;
    self.ammo_nails      = 0;
    self.ammo_rockets    = 0;
    self.ammo_tnt_bundle = 0;
    self.ammo_tnt_proxy  = 0;
    self.ammo_tnt_remote = 0;
    self.ammo_spray      = 0;
    self.ammo_cells      = 0;
    self.ammo_voodoo     = 0;
    self.ammo_leech      = 0;
    self.weapon          = IT_PITCHFORK;
    self.armor_fire      = 0;
    self.armor_body      = 0;
    self.armor_mind      = 0;
    self.inven1          = 0;
    self.inven2          = 0;
    self.it_select       = 0;

    // If the warmup is not over, let's give him some extra stuff  :)
    if (! warmup_done)
    {
        self.items = self.items | available_weapons | IT_ARMOR_BODY;
        self.armor_body = 50;
        self.armor_fire = 50;
        self.armor_mind = 50;
        if (available_weapons & IT_FLAREGUN)
            self.ammo_flare = self.ammo_flare + 10;
        if (available_weapons & IT_SAWED_OFF)
            self.ammo_shells = self.ammo_shells + 15;
        if (available_weapons & IT_TOMMYGUN)
            self.ammo_nails = self.ammo_nails + 50;
        if (available_weapons & IT_NAPALM_LAUNCHER)
            self.ammo_rockets = self.ammo_rockets + 5;
        if (available_weapons & IT_TNT)
            self.ammo_tnt_bundle = self.ammo_tnt_bundle + 5;
        if (available_weapons & IT_PROXIMITY_BOMB)
            self.ammo_tnt_proxy = self.ammo_tnt_proxy + 2;
        if (available_weapons & IT_REMOTE_DETONATOR)
            self.ammo_tnt_remote = self.ammo_tnt_remote + 5;
        if (available_weapons & IT_SPRAY_CAN)
            self.ammo_spray = self.ammo_spray + 50;
        if (available_weapons & IT_TESLA_CANNON)
            self.ammo_cells = self.ammo_cells + 40;
        if (available_weapons & IT_VOODOO_DOLL)
            self.ammo_voodoo = self.ammo_voodoo + 100;
        if (available_weapons & IT_LIFE_LEECH)
            self.ammo_leech = self.ammo_leech + 30;
    }

    self.armorvalue = self.armor_body;
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
    bprint ("варнинг╨ FindIntermission: no info_intermission\n");  // "WARNING: ..."
    spot = find (world, classname, "info_player_deathmatch");
    if (spot)
        return spot;

    objerror ("FindIntermission: no spot");
};


/*
====================
GotoNextMap

Switch to the next map
====================
*/
void() GotoNextMap =
{
    local entity warp;
    local string str;
    local float maxmap;

    // Figure out if the change was due to a vote
    warp = find (world, classname, "execute_changelevel");
    if (warp)
        if (warp.style)
        {
            // Save the position in the map list
            str = ftos (map_cycle);
            cvar_set ("saved1", str);

            changelevel (nextmap);
            return;
        }

    // Else, we use the map cycle if available
    maxmap = cvar ("samelevel");
    if (maxmap)
    {
        // If we reached the end of the list, restart from the beginning
        if (map_cycle >= maxmap)
            map_cycle = 1;
        else
            map_cycle = map_cycle + 1;
        str = ftos (map_cycle);

        // Save the position in map list
        cvar_set ("saved1", str);

        // Switch to the next map in the list
        localcmd ("map");
        localcmd (str);
        localcmd ("\n");
    }
    // if there's a nextmap defined
    else if (nextmap)
        changelevel (nextmap);
    // or we go on with the same map
    else
        changelevel (mapname);
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

    WriteByte (MSG_ALL, 3);

    other = nextent (world);
    while (other != world)
    {
        if (other.classname == "player" || other.classname == "observer")
        {
            KillBurner (other);
            other.view_ofs = '0 0 0';
            other.angles = other.v_angle = pos.mangle;
            other.fixangle = TRUE;      // turn this way immediately
            other.nextthink = time + 0.5;

            other.takedamage = DAMAGE_NO;
            other.solid = SOLID_NOT;
            other.movetype = MOVETYPE_NONE;
            other.modelindex = 0;
            other.health = 1;

            setorigin (other, pos.origin);
        }

        other = nextent (other);
    }

    WriteByte (MSG_ALL, SVC_INTERMISSION);
};


/*
=============================================================================

                PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

/*
====================
Cl_PrintTeamScores

Broadcast the score of each team to all players
====================
*/
void() Cl_PrintTeamScores =
{
    local string score1, score2;

    score1 = ftos (team1score);
    score2 = ftos (team2score);

    bprint5 ("ред╨ ", score1, " ╞ блуе╨ ", score2, "\n");  // "RED: ... / BLUE: ... \n"
};


/*
====================
Cl_UpdatePlayerFrags

Update the frag count of the player and his team
====================
*/
void(entity player, float fragsToAdd) Cl_UpdatePlayerFrags =
{
    // No frag until the warmup is finished
    if (!warmup_done)
        return;

    player.frags = player.frags + fragsToAdd;

    if ((gametype == GT_TEAM_BLOODBATH || gametype == GT_CAPTURE_THE_FLAG))
    {
        if (player.team == TEAM_COLOR1)
            team1score = team1score + fragsToAdd;
        else
            team2score = team2score + fragsToAdd;

        Cl_PrintTeamScores ();
    }
};


// called by ClientKill and DeadThink
void(float cloneCorpse) respawn =
{
	if (gametype == GT_COOPERATIVE)
	{
		// make a copy of the dead body for appearances sake
        if (cloneCorpse)
            CloneCorpse (self);

		// get the spawn parms as they were at level start
		setspawnparms (self);

		// respawn		
		PutClientInServer ();
	}
	else if (gametype != GT_SINGLE_PLAYER)
	{
		// make a copy of the dead body for appearances sake
        if (cloneCorpse)
            CloneCorpse (self);

		// set default spawn parms
		SetNewParms ();

		// respawn		
		PutClientInServer ();
	}
	else
	{	// restart the entire server
		localcmd ("restart\n");
	}
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
        bprint("ClientKill\n");
    // can't suicide when observer
    if (self.observer)
        return;

    bprint3 ("Kevorkian approves ", self.netname, "!\n");
    sound (self, CHAN_AUTO, "thevoice/vo5.wav", 1, ATTN_NORM);
    CTF_PlayerDropFlag ();
    set_suicide_frame ();
    self.modelindex = modelindex_player;
    Cl_UpdatePlayerFrags (self, -2);  // extra penalty
    respawn (TRUE);
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
        if (thing.takedamage)
            if (thing.classname == "player")
                return FALSE;
        thing = thing.chain;
    }

    return TRUE;
};


// Cl_FindBestSpawn
entity (string spawnclass) Cl_FindBestSpawn =
{
    local entity thing;
	local entity spot;
	local float radius;	
	local float bad_spawn;
	
	radius = 1500;
	spot = world;	

    // Loop until within telefrag radius
    while(radius >= 32)
	{
	    spot = find (world, classname, spawnclass);		
		
		if (spot == world)
	        return world;		
		
		// loop through all "classname" entites
		while (spot)
	    {		   	
	        thing = findradius (spot.origin, radius);
		    bad_spawn = 0;			
		
		    while (thing)
            {
	            if (thing.classname == "player")
				    bad_spawn = 1;
			
                thing = thing.chain;
            }
			if (!bad_spawn)
			    return spot;
			
			spot = find (spot, classname, spawnclass);
		}		
		    radius = radius - 100;
	}
	
	// If it made it here, then there's no clear spawns.  Pick the first spot and go with it
	spot = find (world, classname, spawnclass);
	
	return spot;    
	
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
        totalspots = rint (random () * (totalspots - 1));  // totalspots = (number between 0 and totalspots - 1)
        spot = find (world, classname, spawnclass);
        while (totalspots > 0)
        {
            totalspots = totalspots - 1;
            spot = find (spot, classname, spawnclass);
        }
        return spot;
    }

    // Choose one of the free spots at random
    freespots = rint ((random () * (freespots - 1)) + 1);  // freespots = (number between 1 and freespots)
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

    // If it's a cooperative game, choose a cooperative spawn point,
    // and fall back to a single player spawn point if necessary
    // TODO: add single player support here
	if (gametype == GT_SINGLE_PLAYER)
	{
		spawnpoint = Cl_GetRandomSpawnPoint ("info_player_start");
	}
	else if (gametype == GT_COOPERATIVE)
	{
		spawnpoint = Cl_GetRandomSpawnPoint("info_player_coop");

		if (spawnpoint == world)
			spawnpoint = Cl_GetRandomSpawnPoint ("info_player_start");

		if (spawnpoint != world)
			return spawnpoint;

		bprint("Coop mode set, but no info_player_coop or info_player_start entities in the map\n");
	}
	// If it's a team based game, try to spawn on one of the team's points
    else if (gametype == GT_TEAM_BLOODBATH || gametype == GT_CAPTURE_THE_FLAG)
    {
        if (self.team == TEAM_COLOR1)
        {
            spawnpoint = Cl_FindBestSpawn ("info_player_team1");
            if (spawnpoint)
                return spawnpoint;
        }
        else if (self.team == TEAM_COLOR2)
        {
            spawnpoint = Cl_FindBestSpawn ("info_player_team2");
            if (spawnpoint)
                return spawnpoint;
        }
        else
            bprint("No team spawns found, looking for deathmatch spawns\n");
    }
    else
        spawnpoint = world;


    if (!spawnpoint)
        spawnpoint = Cl_FindBestSpawn ("info_player_deathmatch");

    // We haven't found a suitable spawn point
    if (!spawnpoint)
        error ("SelectSpawnPoint: no spawn point on level");

    return spawnpoint;
};


/*
===========
PutClientInServer

called each time a player is spawned
============
*/
void() PutClientInServer =
{
    local   entity spot;

    // Reset poison fade effect in case player was killed while screen was darkened
    ResetPlayerDisplay();

	spot = SelectSpawnPoint ();

    self.classname = "player";
    self.health = 100;
    self.takedamage = DAMAGE_AIM;
    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_WALK;
    self.max_health = 100;
    self.flags = FL_CLIENT;
    self.air_finished = time + 12;
    self.dmg = 2;           // initial water damage
    self.akimbo_finished = 0;
    self.invisible_finished = 0;
    self.invincible_finished = 0;
    self.effects = 0;
	self.alpha = 1;
    self.invincible_time = 0;
    KillBurner (self);

    self.reflect_finished = 0;
    self.remain_dmg = 0;
    self.remain_arm = 0;

    Bomb_Uncharge ();
    ResetIdle (self);

    InitPlayerCharacteristics ();

    // You surely don't want to toss your brand new TNT *right now*...
    self.attack_finished = time + 0.3;
    self.impulse = IMP_NONE;

    self.th_pain = player_pain;
    self.th_die = PlayerDie;
    self.touch = SUB_Null;  // remove the "HeadTouch" binding (if any)
    self.reset = Player_Reset;

    self.deadflag = DEAD_NO;
    self.player_state = PS_IDLE;
    self.newweapon = 0;

    // paustime is set by teleporters to keep the player from moving a while
    self.pausetime = 0;

    self.origin = spot.origin + '0 0 1';
    self.angles = spot.angles;
    self.fixangle = TRUE;       // turn this way immediately

    // Hack to get the eyes model index
    setmodel (self, "models/objects/eyes.md3");
    modelindex_eyes = self.modelindex;

    setmodel (self, "progs/player.mdl");
    modelindex_player = self.modelindex;

    setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

    self.view_ofs = VEC_HULL_VIEW_OFS;
    self.velocity = '0 0 0';
    self.avelocity = '0 0 0';

    player_stand ();

	if (self.do_observer && gametype != GT_SINGLE_PLAYER && gametype != GT_COOPERATIVE)
    {
        BecomeObserver (self);
        World_CheckWarmup ();
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

    World_CheckWarmup ();
};


/*
=============================================================================

STARTING POINTS

=============================================================================
*/

// The normal starting point for a level.
void() info_player_start = 
{
    if (gametype != GT_SINGLE_PLAYER && gametype != GT_COOPERATIVE)
	    remove(self);	
};

// Starting point for coop games
void() info_player_coop = 
{
    if (gametype != GT_SINGLE_PLAYER && gametype != GT_COOPERATIVE)
	    remove(self);	
};

// Potential spawning position for deathmatch games
void() info_player_deathmatch = 
{
    if (gametype == GT_SINGLE_PLAYER || gametype == GT_COOPERATIVE)
	    remove(self);
};

// Team base starting locations
void() info_player_team1 =
{
    if (gametype == GT_SINGLE_PLAYER || gametype == GT_COOPERATIVE)
	    remove(self);
};

void() info_player_team2 =
{
    if (gametype == GT_SINGLE_PLAYER || gametype == GT_COOPERATIVE)
	    remove(self);
};

/*
===============================================================================

RULES

===============================================================================
*/

/*
============
Cl_ChangeLevel

End the current game and switch to intermission
============
*/
void(float forcemap) Cl_ChangeLevel =
{
    local entity warp;

    // Already done?
    if (gameover)
        return;

    // we can't move people right now, because touch functions are called
    // in the middle of C movement code, so set a think time to do it
    warp = spawn();
    warp.classname = "execute_changelevel";
    warp.think = execute_changelevel;
    warp.style = forcemap;
    warp.nextthink = time + 0.1;

    gameover = TRUE;

    // Load the map list before GotoNextMap
    if (gametype != GT_SINGLE_PLAYER && gametype != GT_COOPERATIVE)
	    localcmd ("exec maps.cfg\n");
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

    if (warmup_done && timelimit && time - starttime >= timelimit)
    {
        Cl_ChangeLevel (FALSE);
        return;
    }

    if (fraglimit)
    {
        // If we are in a team based mode
        if ((gametype == GT_TEAM_BLOODBATH || gametype == GT_CAPTURE_THE_FLAG))
        {
            if (team1score >= fraglimit || team2score >= fraglimit)
            {
                Cl_ChangeLevel (FALSE);
                return;
            }
        }
        else if (self.frags >= fraglimit)
        {
            Cl_ChangeLevel (FALSE);
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

    self.button0 = self.button1 = self.button2 = self.button3 = self.button4 = 0;
    respawn (TRUE);
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

    jump = 360;     // quake value was 270

    // Boots let player jump about 4x as high.
    // NOTE:  max height = v0^2 / 2g.
    if (self.boots_on)
        jump = jump + 350;

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
        else if (self.air_finished < time + 6)
            sound (self, CHAN_VOICE, "foley/gasp.wav", 1, ATTN_NORM);
        self.air_finished = time + 12;
        self.dmg = 2;
        if (self.dive_on)
            Use_DivingSuit ();  // Turn off diving suit.
    }
    else if (self.air_finished < time)
    {   // drown!

        // Darken screen as player slowly drowns
        self.poison = (time - self.air_finished) * 25;

        if (self.pain_finished < time)
        {
            self.dmg = self.dmg + 2;
            if (self.dmg > 15)
                self.dmg = 10;
            // Armor does not protect against drowning.
            T_Damage (self, world, world, self.dmg, DF_DROWN, "drowning");
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
            T_Damage (self, world, world, 10*self.waterlevel, DF_BURN, "fire");
        }
    }
    else if (self.watertype == CONTENT_SLIME)
    {   // do damage
        if (self.dmgtime < time)
            if (!self.dive_on)
        {
            self.dmgtime = time + 1;
            T_Damage (self, world, world, 4*self.waterlevel, DF_ACID, "acid");
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

    if (! (self.flags & FL_WATERJUMP) )
        self.velocity = self.velocity - 0.8*self.waterlevel*frametime*self.velocity;
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

    // Quake allows players to change "team" manually (thanks to the console command "color")
    // so we must restore it every turn to avoid cheaters
    self.team = self.team_save;

    #ifndef NO_FRIKBOT
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

    self.deathtype = string_null;

    CheckRules ();
    WaterMove ();

    if (self.waterlevel == 2)
        CheckWaterJump ();

    if (self.deadflag >= DEAD_DEAD)
    {
        PlayerDeathThink ();
        return;
    }

    // Players on the BOD can't move
    if (self.player_state == PS_BRINK_OF_DEATH)
    {
        self.velocity_x = 0;
        self.velocity_y = 0;
        return;
    }

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
	if (self.button5)
	{
		if (!self.crouch)
		{
			self.crouch = TRUE;
			self.view_ofs = VEC_HULL_CROUCH_VIEW_OFS;
			setsize (self, VEC_HULL_CROUCH_MIN, VEC_HULL_CROUCH_MAX);
		}
	}
	else
	{
		if (self.crouch)
		{
			tracebox(self.origin, VEC_HULL_MIN, VEC_HULL_MAX, self.origin, FALSE, self);
			if (!trace_startsolid)
			{
				self.crouch = FALSE;
				self.view_ofs = VEC_HULL_VIEW_OFS;
				setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
			}
		}
	}
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
                sprint (self, "Cloak of Invisibility is draining\n");
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
			self.alpha = 1;
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
                sprint (self, "Death Mask is almost used up\n");
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
            self.effects = self.effects | EF_RED;
        else
            self.effects = self.effects - (self.effects & EF_RED);
    }

    // Guns akimbo
    if (self.akimbo_finished)
    {
        // just stopped
        if (self.akimbo_finished < time)
        {
            self.akimbo_finished = 0;

            // Don't reset the weapon view while on the BOD
            if (self.player_state != PS_BRINK_OF_DEATH)
                W_SetCurrentAmmo ();
        }
    }

    // Reflective shots
    if (self.reflect_finished)
    {
        if (self.reflect_finished < time)
        {   // just stopped
            self.reflect_finished = 0;

            self.effects = self.effects - (self.effects & EF_BLUE);
        }
        else
            self.effects = self.effects | EF_BLUE;
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
void(float isAlive) Impulses_Player =
{
    // Nothing to do
    if (self.impulse == IMP_NONE)
        return;

    // Toggle menu
    if (self.impulse == IMP_MENU)
        Menu_Start ();

    #ifndef NO_FRIKBOT
    // Bot management
    else if (self.impulse == IMP_BOT_ADD_RED || self.impulse == IMP_BOT_ADD_BLUE)
    {
        // If bots are disabled
        if (cvar ("sv_disable") & SV_DISABLE_BOTS)
            sprint (self, "Bots are disabled on this server\n");
        else
        {
            local float botskill;

            botskill = cvar ("skill");
            BotConnect (self.impulse - IMP_BOT_ADD_RED, 0, botskill);
        }
    }
    else if (self.impulse == IMP_BOT_KICK)
        KickABot();
    #else
    else if (self.impulse >= IMP_BOT_ADD_RED && self.impulse <= IMP_BOT_KICK)
        sprint (self, "Sorry, these progs don't have bot support\n");
    #endif

    else if (self.impulse == IMP_IDENT_PLAYER)
        identify_player ();

    // If we're dead
    else if (!isAlive)
    {
        // If we want to go back to the observer mode
        if (self.impulse == IMP_OBSERVER)
        {
            self.do_observer = 1;
            respawn (TRUE);
            bprint2 (self.netname, " coardly flees this bloodbath!\n");
        }
    }

    // If we aren't dead, we can play with our stuff
    else
    {
        // Weapons
        if ((self.impulse >= IMP_PITCHFORK && self.impulse <= IMP_VOODOO_DOLL) ||
            self.impulse == IMP_PROXIMITY_BOMB ||
            self.impulse == IMP_REMOTE_DETONATOR)
            W_ChangeWeapon ();

        else if (self.impulse == IMP_WEAP_NEXT)
            CycleWeaponCommand (FALSE);
        else if (self.impulse == IMP_WEAP_PREV)
            CycleWeaponCommand (TRUE);

        // Inventory selection/usage.
        else if (self.impulse == IMP_INV_NEXT)
            InvenSelect (TRUE, FALSE);
        else if (self.impulse == IMP_INV_PREV)
            InvenSelect (FALSE, FALSE);
        else if (self.impulse == IMP_INV_USE)
            InvenUse ();
        else if (self.impulse >= IMP_FIRST_AID && self.impulse <= IMP_JUMP_BOOTS)
            InventChange ();

        // Armor cycle.
        else if (self.impulse == IMP_ARMOR_NEXT)
            ArmorTest ();

        else if (self.impulse == IMP_TAUNT_0)
            Taunt(0);

        else if (self.impulse == IMP_TAUNT_1)
            Taunt(1);

        else if (self.impulse == IMP_TAUNT_2)
            Taunt(2);

        else if (self.impulse == IMP_TAUNT_3)
            Taunt(3);

        else if (self.impulse == IMP_TAUNT_4)
            Taunt(4);

        else if (self.impulse == IMP_TAUNT_5)
            Taunt(5);

        else if (self.impulse == IMP_TAUNT_6)
            Taunt(6);

        else if (self.impulse == IMP_TAUNT_7)
            Taunt(7);

        else if (self.impulse == IMP_TAUNT_8)
            Taunt(8);

        else if (self.impulse == IMP_TAUNT_9)
            Taunt(9);

		else if (self.impulse == 80)
		    shake_start();

        // These ones are considered cheats and are only allowed when the "sv_cheats" cvar is set
        else if (cvar ("sv_cheats"))
        {
            #if !defined(NO_FRIKBOT)
            if (self.impulse == IMP_BOT_CAM)
                botcam_u ();
            else if (self.impulse == IMP_BOT_WAYPT_EDIT)
                bot_way_edit ();
            else
            #endif

            if (self.impulse == IMP_CHEAT_ARMOR)
            {
                sprint (self, "griswold -- You have full armor.\n");
                self.armor_fire = self.armor_body = self.armor_mind = self.armorvalue = 200;
                self.items = self.items - (self.items & IT_ARMOR_ALL) + IT_ARMOR_FIRE;
            }
            else if (self.impulse == IMP_CHEAT_IN_FIRE)
            {
                sprint (self, "mcgee -- You're fired!\n");
                Ignite (self, self, DF_BURN, 10, 20);
            }
            else if (self.impulse == IMP_CHEAT_INVENT)
                Cheat_Inventory ();
            else if (self.impulse == IMP_CHEAT_BOD)
                Player_BrinkOfDeath (self, world);
            else if (self.impulse == IMP_CHEAT_AKIMBO)
                Cheat_Akimbo ();
            else if (self.impulse == IMP_COREDUMP)
                coredump ();
        }
    }

    self.impulse = IMP_NONE;
};


/*
====================
Cl_Use

Look for a usable entity in front of and below the player,
and use it if it's possible.
====================
*/
float(vector start, vector end) Cl_CheckUse =
{
    traceline (start, end, FALSE, self);
    if (trace_fraction < 1)
        if (trace_ent.spawnflags & SF_USABLE)
            if (trace_ent.use)
            {
                local entity stemp;

                activator = self;
                other = self;
                stemp = self;
                self = trace_ent;
                trace_ent.use ();
                self = stemp;

                return TRUE;
            }

    return FALSE;
};

void() Cl_Use =
{
    local vector start_point;

    makevectors (self.v_angle);
    start_point = self.origin + self.view_ofs;

    // Look for a usable entity in front of the player, or below him
    if (!Cl_CheckUse (start_point, start_point + v_forward * 64))
        Cl_CheckUse (start_point, start_point - v_up * 256);
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

    #ifndef NO_FRIKBOT
    if (BotPostFrame())
        return;
    #endif

    // Check for menu commands
    if (self.player_state == PS_MENU && gametype != GT_SINGLE_PLAYER)
        Menu_Update ();

    // if we're not allowed to act (observer)
    if (self.observer)
    {
        Impulses_Observer ();
        return;
    }

    // if we're not allowed to act (in intermission, or dead)
    if (self.view_ofs == '0 0 0' || self.deadflag)
    {
        if (self.deadflag == DEAD_RESPAWNABLE)
            Impulses_Player (FALSE);
        return;
    }

    // Do neato screen fade
    if (self.poison > 1)
	    FadePlayerDisplay();

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
            T_Damage (self, world, world, aspeed, DF_FALL, "falling");
        }
        else
            sound (self, CHAN_VOICE, "foley/land.wav", 1, ATTN_NORM);		
		
		self.jump_flag = 0;
    }
	else if ((self.jump_flag < -750) && !(self.flags & FL_ONGROUND) && (self.health > 0) && !(self.flags & FL_FALLING))
	{
	    self.flags = self.flags | FL_FALLING;
		sound (self, CHAN_VOICE, "player/fall.wav", 1, ATTN_NORM);
	}    
		
	// This little check is here to avoid sliding deaths
    if (!(self.flags & FL_ONGROUND))
	    self.jump_flag = self.velocity_z;
	
    CheckPowerups ();

    // If we are on the Brink Of Death
    if (self.player_state == PS_BRINK_OF_DEATH)
    {
        if (self.t_length < time)
            Player_LiveAgain ();
        ResetIdle (self);
        return;
    }
//if (self.button4 && !self.oldbutton4){usesomething();}self.oldbutton4 = self.button4;
    if (self.button4 && !self.oldbutton4)
        Cl_Use ();
	self.oldbutton4 = self.button4;

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
    #ifndef NO_FRIKBOT
    ClientInRankings(); // FrikBot
    #endif

    bprint2 (self.netname, " entered the game\n");

    sound (self, CHAN_AUTO, "thevoice/vo1.wav", 1, ATTN_NORM); // Let the Bloodbath Begin!
    self.do_observer = 1;

    // Reset the votes
    self.vote_map = 0;
    self.vote_gametype = 0;
    self.vote_fraglimit = 0;
    self.vote_timelimit = 0;
    self.vote_warmup = 0;
    self.vote_options = 0;

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

    // If the player has a Leech Sentry, destroy it
    if (self.leech_sentry)
    {
        local entity theplayer;

        theplayer = self;
        self = self.leech_sentry;
        self.th_die ();
        self = theplayer;
    }

    #ifndef NO_FRIKBOT
    ClientDisconnected(); // FrikBot
    #endif

    // if the level end trigger has been activated, just return
    // since they aren't *really* leaving
    if (gameover)
        return;

    // let everyone else know
    finalscore = ftos (self.frags);
    bprint4 (self.netname, " left this world for another with ", finalscore, " kills\n");
    sound (self, CHAN_BODY, "thevoice/vo2.wav", 1, ATTN_NONE);
    CTF_PlayerDropFlag ();
    set_suicide_frame ();

    World_CheckWarmup ();
    self.classname = string_null;  // just to be sure he won't appear while searching for players
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
        return;

    if (attacker.classname == "teledeath")
    {
        bprint4 (self.netname, "'s personal space was invaded by ",
                 attacker.owner.netname, "\n");
        self.noise1 = "thevoice/splatt.wav";

        Cl_UpdatePlayerFrags (attacker.owner, 1);
        return;
    }

    if (attacker.classname == "teledeath2")
    {
        bprint5 ("Tchernobog's Death Mask deflects ", self.netname,
                 "'s telefrag on ", attacker.owner.netname, "\n");
        self.noise1 = "thevoice/splatt.wav";

        Cl_UpdatePlayerFrags (self, -1);
        return;
    }

    // double 666 telefrag
    if (attacker.classname == "teledeath3")
    {
        bprint4 (self.netname, " was overcome by ",
                 attacker.owner.netname, "'s Death Mask power\n");
        self.noise1 = "thevoice/splatt.wav";

        Cl_UpdatePlayerFrags (self, -1);
        return;
    }

    if (self.deathtype == "squish")
    {
        bprint2 (self.netname, " was squashed\n");
        self.noise1 = "thevoice/squash.wav";

        Cl_UpdatePlayerFrags (self, -1);  // killed self
        return;
    }
	
	if (self.deathtype == "falling")
    {
        bprint2 (self.netname, " fell to his death\n");        

        Cl_UpdatePlayerFrags (self, -1);  // killed self
        return;
    }

    if (attacker.classname == "player")
    {
        if (self == attacker)
        {
            // killed self in a dumb fashion
            Cl_UpdatePlayerFrags (attacker, -1);

            if (rnum < 0.33)
            {
                deathstring = " receives the Darwin Award\n";
                self.noise1 = "thevoice/vo16.wav";
            }
            else if (rnum < 0.66)
            {
                deathstring = " exercises Population control\n";
                self.noise1 = "thevoice/vo12.wav";
            }
            else
            {
                deathstring = " gets an Unassisted death\n";
                self.noise1 = "thevoice/vo13.wav";
            }

            bprint2 (self.netname, deathstring);
            return;
        }
        else if (friendlyfire && self.team > 0 && self.team == attacker.team)
        {
            if (rnum < 0.25)
                deathstring = " mows down his teammate ";
            else if (rnum < 0.50)
                deathstring = " checks his glasses in memory of ";
            else if (rnum < 0.75)
                deathstring = " gets a frag for the other team on ";
            else
                deathstring = " loses his friend ";
            bprint4 (attacker.netname, deathstring, self.netname, "\n");

            Cl_UpdatePlayerFrags (attacker, -1);

            return;
        }
        else
        {
            // no weapon associations, just random message and Announcer voice
            Cl_UpdatePlayerFrags (attacker, 1);

            rnum = random()*54;

            deathstring2 = string_null;

            // Beaten like a Cur
            if (rnum <= 1)
            {
                deathstring = " beat ";
                deathstring2 = " like a cur";
                self.noise1 = "thevoice/vo39.wav";
            }
            // Bobbettized!
            else if (rnum <= 2)
            {
                deathstring = " bobbettized ";
                self.noise1 = "thevoice/vo31.wav";
            }
            // Destroyed!
            else if (rnum <= 3)
            {
                deathstring = " destroyed ";
                self.noise1 = "thevoice/vo24.wav";
            }
            // Dog meat
            else if (rnum <= 4)
            {
                deathstring = " butchered ";
                deathstring2 = " into dog meat";
                self.noise1 = "thevoice/vo36.wav";
            }
            // Excellent!
            else if (rnum <= 5)
            {
                deathstring = " showed his excellence to ";
                self.noise1 = "thevoice/vo44.wav";
            }
            // Fine work
            else if (rnum <= 6)
            {
                deathstring = " made a fine work of ";
                self.noise1 = "thevoice/vo22.wav";
            }
            // Good one
            else if (rnum <= 7)
            {
                deathstring = " showed ";
                deathstring2 = " how good he is";
                self.noise1 = "thevoice/vo20.wav";
            }
            // He shoots! He scores!
            else if (rnum <= 8)
            {
                deathstring = " scored on ";
                self.noise1 = "thevoice/vo33.wav";
            }
            // Hosed!
            else if (rnum <= 8)
            {
                deathstring = " hosed ";
                self.noise1 = "thevoice/vo25.wav";
            }
            // Humiliated!
            else if (rnum <= 10)
            {
                deathstring = " humiliated ";
                self.noise1 = "thevoice/vo26.wav";
            }
            // Lunch meat!
            else if (rnum <= 11)
            {
                deathstring = " made lunch meat with ";
                self.noise1 = "thevoice/vo21.wav";
            }
            // Pass the chili!
            else if (rnum <= 12)
            {
                deathstring = " passed the chili to ";
                self.noise1 = "thevoice/vo29.wav";
            }
            // Punishment delivered
            else if (rnum <= 13)
            {
                deathstring = " punished ";
                self.noise1 = "thevoice/vo30.wav";
            }
            // Ripped 'em loose
            else if (rnum <= 14)
            {
                deathstring = " ripped ";
                self.noise1 = "thevoice/vo38.wav";
            }
            // Sent to HELL!
            else if (rnum <= 15)
            {
                deathstring = " sent ";
                deathstring2 = " to hell!";
                self.noise1 = "thevoice/vo28.wav";
            }
            // Snuffed!
            else if (rnum <= 16)
            {
                deathstring = " snuffed ";
                self.noise1 = "thevoice/vo41.wav";
            }
            // Spillage!
            else if (rnum <= 17)
            {
                deathstring = " spilt ";
                deathstring2 = "'s blood";
                self.noise1 = "thevoice/vo34.wav";
            }
            // Sprayed!
            else if (rnum <= 18)
            {
                deathstring = " sprayed ";
                self.noise1 = "thevoice/vo35.wav";
            }
            // Stiffed!
            else if (rnum <= 19)
            {
                deathstring = " stiffed ";
                self.noise1 = "thevoice/vo32.wav";
            }
            // Talented!
            else if (rnum <= 20)
            {
                deathstring = " dazzled ";
                deathstring2 = " with his talent";
                self.noise1 = "thevoice/vo19.wav";
            }
            // Toasted!
            else if (rnum <= 21)
            {
                deathstring = " toasted ";
                self.noise1 = "thevoice/vo27.wav";
            }
            // Vaporized!
            else if (rnum <= 22)
            {
                deathstring = " vaporized ";
                self.noise1 = "thevoice/vo43.wav";
            }
            // Well done!
            else if (rnum <= 23)
            {
                deathstring = " did well with ";
                self.noise1 = "thevoice/vo23.wav";
            }
            // Whipped and creamed!
            else if (rnum <= 24)
            {
                deathstring = " whipped and creamed ";
                self.noise1 = "thevoice/vo40.wav";
            }
            // Scrotum separation
            else if (rnum <= 25)
            {
                deathstring = " made ";
                deathstring2 = " suffer scrotum separation";
                self.noise1 = "thevoice/vo9.wav";
            }
            // Excrement
            else if (rnum <= 26)
            {
                deathstring = " turned ";
                deathstring2 = " into excrement";
                self.noise1 = "thevoice/vo7.wav";
            }
            // Hamburger
            else if (rnum <= 27)
            {
                deathstring = " turned ";
                deathstring2 = " into hamburger";
                self.noise1 = "thevoice/vo8.wav";
            }
            else if (rnum <= 28)
            {
                deathstring = " vented ";
                deathstring2 = "'s spleen";
                self.noise1 = "thevoice/vo42.wav";
            }
            else if (rnum <= 29)
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
                deathstring2 = " real bad!";
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

            bprint3 (attacker.netname, deathstring, self.netname);
            if (deathstring2)
                bprint (deathstring2);
            bprint ("\n");
        }
    }

    // If the player was killed by a monster
    else if (attacker.flags & FL_MONSTER)
    {
        local string m_name;

        // FIXME: Do you really lose a frag if you die in co-op?
        Cl_UpdatePlayerFrags (self, -1);

        if (attacker.classname == "monster_rat")
            m_name = "a rat";
        else if (attacker.classname == "monster_eel")
            m_name = "an eel";
        else if (attacker.classname == "monster_zombie")
            m_name = "an axe zombie";
        else if (attacker.classname == "monster_hellhound")
            m_name = "a hellhound";
        else if (attacker.classname == "monster_butcher")
            m_name = "a bloated zombie";
        else if (attacker.classname == "monster_browncultist")
            m_name = "a Cultist";
        else if (attacker.classname == "monster_blackcultist")
            m_name = "a Fanatic";
        else if (attacker.classname == "monster_greencultist")
            m_name = "an Acolyte";
        else if (attacker.classname == "monster_bluecultist")
            m_name = "a Zealot";
        else if (attacker.classname == "monster_redcultist")
            m_name = "a Priest";
        else if (attacker.classname == "monster_gargoyle")
            m_name = "a gargoyle";
        else if (attacker.classname == "monster_stonegargoyle")
            m_name = "a stone gargoyle";
        else if (attacker.classname == "monster_minicaleb")
            m_name = "a mini-caleb";
        else
            m_name = "an unknown monster";

        bprint4 (self.netname, " was killed by ", m_name, "\n");
    }

    // No idea?
    else
    {
        Cl_UpdatePlayerFrags (self, -1);

        // hell if I know; he's just dead!!!
        bprint2 (self.netname, " died\n");
    }
};


// I need to test this and see if this only affects on players screen
void() FadePlayerDisplay =
{
    local float i; 
	local string temp1, temp2;
	
	i = 15;
	
	if (self.poison > 255)
	    self.poison = 255;
	
	while (i > 1 && self.poison > 1)
	{
	    temp1 = ftos(self.poison);
		temp2 = strcat("v_cshift 0 0 0 ", temp1);
		
		stuffcmd(self, temp2);
				
		self.poison = self.poison - 1;
		i = i - 1;
	}	
};

void() ResetPlayerDisplay =
{
    localcmd("v_cshift 0 0 0 0\n");
};

// Player taunts
void (float snd) Taunt = 
{
    if (self.voice_finished < time)
    {
        if (snd == 0)
        {
            sound (self, CHAN_AUTO, "player/taunts/taunt0.wav", 1, ATTN_NORM);
            self.voice_finished = time + 3.11;
        }
        else if (snd == 1)
        {
            sound (self, CHAN_AUTO, "player/taunts/taunt1.wav", 1, ATTN_NORM);
            self.voice_finished = time + 2.38;
        }
        else if (snd == 2)
        {
            sound (self, CHAN_AUTO, "player/taunts/taunt2.wav", 1, ATTN_NORM);
            self.voice_finished = time + 0.83;
        }
        else if (snd == 3)
        {
            sound (self, CHAN_AUTO, "player/taunts/taunt3.wav", 1, ATTN_NORM);
            self.voice_finished = time + 2.56;
        }
        else if (snd == 4)
        {
            sound (self, CHAN_AUTO, "player/taunts/taunt4.wav", 1, ATTN_NORM);
            self.voice_finished = time + 2.14;
        }
        else if (snd == 5)
        {
            sound (self, CHAN_AUTO, "player/taunts/taunt5.wav", 1, ATTN_NORM);
            self.voice_finished = time + 3.16;
        }
        else if (snd == 6)
        {
            sound (self, CHAN_AUTO, "player/taunts/taunt6.wav", 1, ATTN_NORM);
            self.voice_finished = time + 0.64;
        }
        else if (snd == 7)
        {
            sound (self, CHAN_AUTO, "player/taunts/taunt7.wav", 1, ATTN_NORM);
            self.voice_finished = time + 2;
        }
        else if (snd == 8)
        {
            sound (self, CHAN_AUTO, "player/taunts/taunt8.wav", 1, ATTN_NORM);
            self.voice_finished = time + 0.95;
        }
        else// if (snd == 9)
        {
            sound (self, CHAN_AUTO, "player/taunts/taunt9.wav", 1, ATTN_NORM);
            self.voice_finished = time + 2.19;
        }
    }
};
