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
#include "player.qh"

void() CTF_PlayerDropFlag;
void() PlayerDead;
void(float cloneCorpse) respawn;


/*
==============================================================================
PLAYER
==============================================================================
*/

void() player_run;

float(void() idleFunction) player_idleWeapon =
{
    // Do NOTHING  when on the BOD
    if (self.player_state == PS_BRINK_OF_DEATH)
        return FALSE;

    self.nextthink = time + 0.1;
    self.think = idleFunction;

    if (self.player_state != PS_HOLD_FIRE && self.player_state != PS_MENU)
    {
        self.weaponframe = 0;

        // If there's a pending weapon change
        if (self.newweapon)
            W_SwitchToWeapon (self.newweapon);
        else
            self.player_state = PS_IDLE;
    }

    return TRUE;
};

void() player_stand =
{
    if (!player_idleWeapon (player_stand))
        return;

    if (self.velocity_x || self.velocity_y)
    {
        player_run();
        return;
    }

    if (self.weapon == IT_PITCHFORK)
        self.frame = $pitchstand1;
    else
        self.frame = $stand1;
};

void() player_run =
{
    if (!player_idleWeapon (player_run))
        return;

    if (!self.velocity_x && !self.velocity_y)
    {
        player_stand ();
        return;
    }

    if (self.weapon == IT_PITCHFORK)
    {
        if (self.frame >= $pitchrun6 || self.frame < $pitchrun1)
        {
            self.frame = $pitchrun1;
            return;
        }
    }
    else if (self.frame >= $run6 || self.frame < $run1)
    {
        self.frame = $run1;
        return;
    }
    self.frame = self.frame + 1;
};

void() muzzleflash =
{
    self.effects = self.effects | EF_MUZZLEFLASH;
};


/*
====================
Player_Reset

Called at the end of the warmup
====================
*/
void() Player_Reset =
{
    respawn (FALSE);
};


//============================================================================
// Brink Of Death
//============================================================================

void() player_bod1  = [$fall1, player_bod2 ] {};
void() player_bod2  = [$fall2, player_bod3 ] {};
void() player_bod3  = [$fall3, player_bod4 ] {};
void() player_bod4  = [$fall4, player_bod5 ] {};
void() player_bod5  = [$fall5, player_bod6 ] {};
void() player_bod6  = [$fall6, player_bod7 ] {};
void() player_bod7  = [$fall7, player_bod8 ] {};
void() player_bod8  = [$fall8, player_bod9 ] {};
void() player_bod9  = [$fall9, player_bod10] {self.takedamage = DAMAGE_AIM;};
void() player_bod10 = [$sway1, player_bod11] {};
void() player_bod11 = [$sway2, player_bod12] {};
void() player_bod12 = [$sway3, player_bod13] {};
void() player_bod13 = [$sway4, player_bod14] {};
void() player_bod14 = [$sway5, player_bod15] {};
void() player_bod15 = [$sway6, player_bod16] {};
void() player_bod16 = [$sway7, player_bod17] {};
void() player_bod17 = [$sway8, player_bod10] {};

void() player_bod_die1 = [$deathc1, player_bod_die2] {};
void() player_bod_die2 = [$deathc2, player_bod_die3] {};
void() player_bod_die3 = [$deathc3, player_bod_die4] {};
void() player_bod_die4 = [$deathc4, SUB_Remove     ] {};

void() player_bod_dieh1 = [$deathb1, player_bod_dieh2] {};
void() player_bod_dieh2 = [$deathb2, player_bod_dieh3] {};
void() player_bod_dieh3 = [$deathb3, player_bod_dieh3] {PlayerDead();};


void(entity player, entity attacker) Player_BrinkOfDeath =
{
    local entity oself;

    player.player_state = PS_BRINK_OF_DEATH;

    player.health = 1;  // 0 toggles the dead view on the client

    // We make the BODed player invincible for 1 sec
    // so that attackers will have the time to stop firing
    player.takedamage = DAMAGE_NO;

    oself = self;
    self = player;
    player_bod1 ();
    self = oself;
    player.weaponmodel = string_null;

    player.t_length = time + 15;  // the effect will last 15 sec
    sound (player, CHAN_VOICE, "thevoice/vo15.wav", 1, ATTN_NONE);
    centerprint (player, "YOU ARE ON THE BRINK OF DEATH!!");
    // If there's a real attacker (not a BOD triggered by cheat code)
    if (attacker != world)
        centerprint (attacker, "FINISH HIM!!");
};


void() Player_LiveAgain =
{
    sound (self, CHAN_VOICE, "player/taunts/t1010.wav", 1, ATTN_NORM);  // I live ... again!
    self.player_state = PS_IDLE;
    player_run ();
    W_DrawWeapon (self.weapon);
};


//============================================================================

float() PainSound =
{
local float     rs;

    if (self.health < 0)
        return FALSE;

    if (self.pain_finished > time)
        return FALSE;

    self.pain_finished = time + 0.5;

    if (self.deathtype == "drowning")
    {
        if (random() > 0.5)
            sound (self, CHAN_VOICE, "ambience/bubrise.wav", 1, ATTN_NORM);
        else
            sound (self, CHAN_VOICE, "foley/undchoke.wav", 1, ATTN_NORM);
        return TRUE;
    }
    if (self.deathtype == "falling")
    {
        sound (self, CHAN_VOICE, "player/pain/play1105.wav", 1, ATTN_NORM);
        return TRUE;
    }
    if (self.deathtype == "fire")
    {
        // PM -- Player is on fire so scream.
        rs = ceil(random() * 3);
        if (rs == 3)
        {
            self.noise = "player/pain/play1120.wav";
            self.pain_finished = time + 1.9;
        }
        else if (rs == 2)
        {
            self.noise = "player/pain/play1119.wav";
            self.pain_finished = time + 2;
        }
        else
        {
            self.noise = "player/pain/play1118.wav";
            self.pain_finished = time + 2.6;
        }
        sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
        return TRUE;
    }

    // Normal pain sound.
    rs = ceil(random() * 3);
    if (rs == 0)
        self.noise = "player/pain/play1106.wav";
    else if (rs == 1)
        self.noise = "player/pain/play1107.wav";
    else
        self.noise = "player/pain/play1108.wav";

    sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
    return TRUE;
};


void() player_pain1 = [$pain1, player_pain2] {};
void() player_pain2 = [$pain2, player_pain3] {};
void() player_pain3 = [$pain3, player_pain4] {};
void() player_pain4 = [$pain4, player_pain5] {};
void() player_pain5 = [$pain5, player_run  ] {};

void() player_axpain1 = [$pitchpain1, player_axpain2] {};
void() player_axpain2 = [$pitchpain2, player_axpain3] {};
void() player_axpain3 = [$pitchpain3, player_axpain4] {};
void() player_axpain4 = [$pitchpain4, player_axpain5] {};
void() player_axpain5 = [$pitchpain5, player_run    ] {};

void() player_pain =
{
    // FIXME: check the player state instead
    if (self.weaponframe)
        return;

    if (self.invisible_finished > time)
        return;     // eyes don't have pain frames

    // Changed so player only shows pain when player make noise.
    if (PainSound ())
    {
        if (self.weapon == IT_PITCHFORK)
            player_axpain1 ();
        else
            player_pain1 ();
    }
};


void() PlayerDead =
{
    self.nextthink = -1;

    // allow respawn after a certain time
    self.deadflag = DEAD_DEAD;
    if (self.player_state != PS_MENU)
        self.player_state = PS_IDLE;  // so that he can enter the menu
};


void() player_die1 = [$deatha1, player_die2] {};
void() player_die2 = [$deatha2, player_die3] {};
void() player_die3 = [$deatha3, player_die4] {};
void() player_die4 = [$deatha4, player_die5] {};
void() player_die5 = [$deatha5, player_die6] {};
void() player_die6 = [$deatha6, player_die6] {PlayerDead();};


void() DeathSound =
{
local float     rs;

    // water death sounds
    if (self.waterlevel == 3)
    {
        sound (self, CHAN_VOICE, "ambience/bubrise.wav", 1, ATTN_NONE);
        return;
    }

    rs = rint (random() * 2);

	if (rs == 0)
        self.noise = "player/die1.wav";
    else if (rs == 1)
        self.noise = "player/die2.wav";
    else
        self.noise = "player/die3.wav";

    sound (self, CHAN_VOICE, self.noise, 1, ATTN_NONE);
    return;
};

vector(float dm) VelocityForDamage =
{
    local vector v;

    if (vlen(damage_inflictor.velocity)>0)
    {
        v = 0.5 * damage_inflictor.velocity;
        v = v + (25 * normalize(self.origin-damage_inflictor.origin));
        v_z = 100 + 240 * random();
        v_x = v_x + (200 * crandom());
        v_y = v_y + (200 * crandom());
    }
    else
    {
        v_x = 100 * crandom();
        v_y = 100 * crandom();
        v_z = 200 + 100 * random();
    }

    if (dm > -50)
        v = v * 0.7;
    else if (dm > -200)
        v = v * 2;
    else
        v = v * 10;

    return v;
};


void(string gibname, float dm) ThrowGib =
{
    local   entity new;

    new = spawn();
    new.origin = self.origin;
    setmodel (new, gibname);
    setsize (new, '-1 -1 -1', '1 1 1');
    new.velocity = VelocityForDamage (dm);
    new.movetype = MOVETYPE_BOUNCE;
    new.solid = SOLID_NOT;
    new.avelocity_x = random()*600;
    new.avelocity_y = random()*600;
    new.avelocity_z = random()*600;
    new.think = SUB_Remove;
    new.reset = SUB_Remove;
    new.ltime = time;
    new.nextthink = time + 5 + random()*7;
    new.frame = 0;
    new.flags = 0;
};

/*
====================
HeadDie

Function called when a head "dies"
====================
*/
void() HeadDie =
{
    sound (self, CHAN_ITEM, "misc/gibsq.wav", 1, ATTN_NORM);
    ThrowGib ("models/objects/m_brain.md3", self.health);
    remove (self);
};


/*
====================
HeadTouch

Function used for throwing heads when someone touchs them
====================
*/
void() HeadTouch =
{
    // only a player can kick it
    if (other.classname != "player")
        return;

    sound(other, CHAN_ITEM, "foley/punt.wav", 1, ATTN_NORM);

    // Destroy the head, kick after kick
    if (self.takedamage != DAMAGE_NO)
    {
        self.health = self.health - 10;
        if (self.health <= 0)
        {
            self.enemy = other;
            self.th_die ();
            return;
        }
    }

    // define velocity
    // you can play with these formulas to adjust trajectory
    self.velocity_x = other.velocity_x * 3 + 50 * random();
    self.velocity_y = other.velocity_y * 3 + 50 * random();
    self.velocity_z = 300 + 160 * random() + (other.velocity_y + other.velocity_x) * 0.30;
    self.avelocity_x = crandom() * 600;
    self.avelocity_y = crandom() * 600;
    self.avelocity_z = crandom() * 600;

    self.flags = self.flags - (self.flags & FL_ONGROUND);
};


void(string headmodel, float dm) ThrowHead =
{
    self.frame = 0;
    self.skin = 0;
    setmodel (self, headmodel);
    
	if (self.classname == "player")
        setsize (self, '-10 -13 -3', '12 6 18');
		
	else if (self.classname == "monster_butcher")
	    setsize (self, '-5 12 0', '5 20 9');
	
	else
	    setsize (self, '0 0 0', '0 0 0');
    
	self.view_ofs = '0 0 8';

    self.movetype = MOVETYPE_BOUNCE;
    self.velocity = VelocityForDamage (dm);
    self.avelocity_x = crandom() * 600;
    self.avelocity_y = crandom() * 600;
    self.avelocity_z = crandom() * 600;

    self.flags = self.flags - (self.flags & FL_ONGROUND);
};


//  This produces a variety of semi-random gibs.  This should only be
//  used by gibbed players and humanoid monsters (e.g., zombies, cultists)
void() RandomHumanGibs =
{
//
// In Blood, you get 2 hands, ribcage, some meat, guts, eyeball, and a skull
//
// gib models...
//
// gib1 = bone (arm/leg) with flesh
// gib2 = rib cage
// gib3 = heart
// gib4 = small flesh piece
// gib5 = bigger flesh piece
// m_arm = upper arm
// m_brain = brain (used when the head "dies")
// m_chest = torso
// m_foot = looks like a bloody shoe?
// m_guts = intestines
// m_leg = femur with meat
// m_eyeball = severed eyeball
// m_hand = severed hand
//

    local   float   gibs, r;

    // throw torso, and heart
    if (random () < 0.75)
        ThrowGib ("models/objects/m_chest.md3", self.health);
    if (random () < 0.25)
        ThrowGib ("models/objects/gib3.md3", self.health);

    // throw eyes
    r = random ();
    if (r > 0.33)
        ThrowGib ("models/objects/m_eyeball.md3", self.health);
    if (r > 0.66)
        ThrowGib ("models/objects/m_eyeball.md3", self.health);

    // throw guts
    r = random ();
    if (r > 0.33)
        ThrowGib ("models/objects/m_guts.md3", self.health);
    if (r > 0.66)
        ThrowGib ("models/objects/m_guts.md3", self.health);

    // throw arms / hands
    gibs = 2;
    while (gibs > 0)
    {
        r = random ();
        if (r < 0.2)
            ThrowGib ("models/objects/gib4.md3", self.health);
        else if (r < 0.4)
            ThrowGib ("models/objects/gib5.md3", self.health);
        else if (r < 0.6)
            ThrowGib ("models/objects/m_arm.md3", self.health);
        else if (r < 0.8)
            ThrowGib ("models/objects/m_hand.md3", self.health);
        gibs = gibs - 1;
    }

    // throw legs
    gibs = 2;
    while (gibs > 0)
    {
        r = random();
        if (r < 0.33)
            ThrowGib ("models/objects/m_leg.md3", self.health);
        else if (r < 66)
            ThrowGib ("models/objects/m_foot.md3", self.health);
        gibs = gibs - 1;
    }
};


void() GibPlayer =
{
    local float rs;
	
	ThrowHead ("progs/h_player.mdl", self.health);
    RandomHumanGibs ();

    self.deadflag = DEAD_DEAD;

    if (damage_attacker.classname == "teledeath"  ||
        damage_attacker.classname == "teledeath2" ||
        damage_attacker.classname == "teledeath3" )
    {
        sound (self, CHAN_VOICE, "firepod/fpodcol2.wav", 1, ATTN_NONE);
        return;
    }

    rs = rint (random() * 2);

    if (self.deathtype == "falling")
	    self.noise =  "misc/gibsq.wav";
	else if (rs == 0)
        self.noise = "player/die1.wav";
    else if (rs == 1)
        self.noise = "player/die2.wav";
    else
        self.noise = "player/die3.wav";

    sound (self, CHAN_VOICE, self.noise, 1, ATTN_NONE);
    return;
};

void() PlayerDie =
{
    local   float   i;
    local   string  s;

    // I may not die alone...
    W_ActivateRemoteBombs ();

    // Drop any lighted bomb/can
    if (self.weapon == IT_TNT || self.weapon == IT_SPRAY_CAN)
    {
        if (self.player_state == PS_HOLD_FIRE || self.charge)
        {
            self.charge = 0;
            Bomb_Fire ();
        }
    }

    self.items = self.items - (self.items & IT_INVISIBILITY);

    if (self.akimbo_finished > 0)
    {
        s = ftos(rint(self.akimbo_finished - time));
        bprint4 (self.netname, " lost a Guns Akimbo with ", s, " seconds remaining\n");
        Akimbo_Drop (self.akimbo_finished - time);
    }

    if (self.invisible_finished > 0)
    {
        s = ftos(rint(self.invisible_finished - time));
        bprint4 (self.netname, " lost a cloak with ", s, " seconds remaining\n");
        Invisibility_Drop (self.invisible_finished - time);
    }

    CTF_PlayerDropFlag ();

    self.invisible_finished = 0;    // don't die as eyes
    self.invincible_finished = 0;
    self.akimbo_finished = 0;
    self.modelindex = modelindex_player;    // don't use eyes
    self.poison = 0;
    self.alpha = 1;
	self.weaponmodel = string_null;
    self.view_ofs = '0 0 -8';
    self.deadflag = DEAD_DYING;
    self.solid = SOLID_NOT;
    self.flags = self.flags - (self.flags & FL_ONGROUND);
    self.movetype = MOVETYPE_TOSS;
    if (self.velocity_z < 10)
        self.velocity_z = self.velocity_z + random()*300;

    if (self.health < -40)
    {
        self.nextthink = -1;
        GibPlayer ();
        return;
    }

    DeathSound();

    self.angles_x = 0;
    self.angles_z = 0;

    // If the player was on the Brink Of Death
    if (self.player_state == PS_BRINK_OF_DEATH)
    {
        // If the head is removed in the process
        if (self.health < -10)
        {
            local entity player_head;

            // The player entity will be the head, so we must
            // create a new entity for the corpse
            player_head = self;
            self = spawn ();
            setmodel (self, player_head.model);
            setorigin (self, player_head.origin);
            setsize (self, player_head.mins, player_head.maxs);
            self.angles = player_head.angles;
            self.frame = player_head.frame;
            self.skin = player_head.skin;
            self.colormap = player_head.colormap;
            self.movetype = player_head.movetype;
            self.velocity = player_head.velocity;
            player_bod_die1 ();

            self = player_head;
            self.deadflag = DEAD_DEAD;
            ThrowHead ("progs/h_player.mdl", self.health);
        }
        else
            player_bod_dieh1 ();
    }
    else
        player_die1 ();
};

// used by kill command and disconnect command
void() set_suicide_frame =
{
    if (self.model == "progs/player.mdl")
    {
        self.frame = $deatha6;
    }
    else if (self.observer)
    {
        self.model = string_null;
        self.modelindex = 0;
    }

    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_TOSS;
    self.deadflag = DEAD_DEAD;
    self.nextthink = -1;
};
