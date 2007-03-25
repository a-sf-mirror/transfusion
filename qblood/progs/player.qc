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
void(entity ent) CloneCorpse;

/*
==============================================================================
PLAYER
==============================================================================
*/

/*
====================
Player_Reset

Called at the end of the warmup
====================
*/
void() Player_Reset =
{
	respawn(FALSE);
};

//============================================================================
// Brink Of Death
//============================================================================
void(entity player, entity attacker) Player_BrinkOfDeath =
{
	player.player_state = PS_BOD_FALL;
	player.health = 1;  // 0 toggles the dead view on the client

	self.weaponentity.nextthink = 0;
	setmodel(player.weaponentity, "");
	setmodel(player.overhead, "");

	// We make the BODed player invincible for 1 sec
	// so that attackers will have the time to stop firing
	player.takedamage = DAMAGE_NO;

	player.t_length = time + 15;  // the effect will last 15 sec
	sound(player, CHAN_VOICE, "thevoice/vo15.wav", 1, ATTN_NONE);
	centerprint(player, "YOU ARE ON THE BRINK OF DEATH!!");
	// If there's a real attacker (not a BOD triggered by cheat code)
	if (attacker != world)
		centerprint(attacker, "FINISH HIM!!");
};

void() Player_LiveAgain =
{
	sound(self, CHAN_VOICE, "player/taunts/t1010.wav", 1, ATTN_NORM);  // I live ... again!
	self.player_state = PS_IDLE;
	W_DrawWeapon(self.weapon);
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
			sound(self, CHAN_VOICE, "ambience/bubrise.wav", 1, ATTN_NORM);
		else
			sound(self, CHAN_VOICE, "foley/undchoke.wav", 1, ATTN_NORM);
		return TRUE;
	}
	if (self.deathtype == "falling")
	{
		sound(self, CHAN_VOICE, "player/pain/play1105.wav", 1, ATTN_NORM);
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
		sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
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

	sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	return TRUE;
};

void() player_pain =
{
	if (PainSound() && self.player_state < PS_BOD_FALL)
		self.player_state = PS_PAIN;
};

void() PlayerDead =
{
	self.nextthink = -1;

	// allow respawn after a certain time
	self.deadflag = DEAD_DEAD;
	if (self.player_state != PS_MENU)
		self.player_state = PS_IDLE;  // so that he can enter the menu
};

void() DeathSound =
{
	local float     rs;

	// water death sounds
	if (self.waterlevel == 3)
	{
		sound(self, CHAN_VOICE, "ambience/bubrise.wav", 1, ATTN_NONE);
		return;
	}

	rs = rint(random() * 2);

	if (rs == 0)
		self.noise = "player/die1.wav";
	else if (rs == 1)
		self.noise = "player/die2.wav";
	else
		self.noise = "player/die3.wav";

	sound(self, CHAN_VOICE, self.noise, 1, ATTN_NONE);
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
	setmodel(new, gibname);
	setsize(new, '-1 -1 -1', '1 1 1');
	new.velocity = VelocityForDamage(dm);
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
	new.cnt = ceil(random() * 25);
	te_blood(new.origin, new.avelocity, new.cnt);
};

/*
====================
HeadDie

Function called when a head "dies"
====================
*/
void() HeadDie =
{
	sound(self, CHAN_ITEM, "misc/gibsq.wav", 1, ATTN_NORM);
	ThrowGib("models/objects/m_brain.md3", self.health);
	remove(self);
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
			self.th_die();
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
	self.cnt = ceil(random() * 25);
	te_blood(self.origin, self.avelocity, self.cnt);

	self.flags = self.flags - (self.flags & FL_ONGROUND);
};

void(string headmodel, float dm) ThrowHead =
{
	self.frame = 0;
	self.skin = 0;
	setmodel(self, headmodel);

	if (self.classname == "player")
		setsize(self, '-10 -13 -3', '12 6 18');

	else if (self.classname == "monster_butcher")
		setsize(self, '-5 12 0', '5 20 9');

	else
		setsize(self, '0 0 0', '0 0 0');

	self.view_ofs = '0 0 8';

	self.movetype = MOVETYPE_BOUNCE;
	self.velocity = VelocityForDamage(dm);
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
	if (random() < 0.75)
		ThrowGib("models/objects/m_chest.md3", self.health);
	if (random() < 0.25)
		ThrowGib("models/objects/gib3.md3", self.health);

	// throw eyes
	r = random();
	if (r > 0.33)
		ThrowGib("models/objects/m_eyeball.md3", self.health);
	if (r > 0.66)
		ThrowGib("models/objects/m_eyeball.md3", self.health);

	// throw guts
	r = random();
	if (r > 0.33)
		ThrowGib("models/objects/m_guts.md3", self.health);
	if (r > 0.66)
		ThrowGib("models/objects/m_guts.md3", self.health);

	// throw arms / hands
	gibs = 2;
	while (gibs > 0)
	{
		r = random();
		if (r < 0.2)
			ThrowGib("models/objects/gib4.md3", self.health);
		else if (r < 0.4)
			ThrowGib("models/objects/gib5.md3", self.health);
		else if (r < 0.6)
			ThrowGib("models/objects/m_arm.md3", self.health);
		else if (r < 0.8)
			ThrowGib("models/objects/m_hand.md3", self.health);
		gibs = gibs - 1;
	}

	// throw legs
	gibs = 2;
	while (gibs > 0)
	{
		r = random();
		if (r < 0.33)
			ThrowGib("models/objects/m_leg.md3", self.health);
		else if (r < 66)
			ThrowGib("models/objects/m_foot.md3", self.health);
		gibs = gibs - 1;
	}
};

void() GibPlayer =
{
	local float rs;

	// Very large blood splat!
	te_bloodshower(self.origin, self.origin + self.size, 100, 200);

	ThrowHead("progs/h_player.mdl", self.health);
	RandomHumanGibs();

	self.deadflag = DEAD_DEAD;

	if (damage_attacker.classname == "teledeath"  ||
		damage_attacker.classname == "teledeath2" ||
		damage_attacker.classname == "teledeath3" )
	{
		sound(self, CHAN_VOICE, "firepod/fpodcol2.wav", 1, ATTN_NONE);
		return;
	}

	rs = rint(random() * 2);

	if (self.deathtype == "falling")
		self.noise =  "misc/gibsq.wav";
	else if (rs == 0)
		self.noise = "player/die1.wav";
	else if (rs == 1)
		self.noise = "player/die2.wav";
	else
		self.noise = "player/die3.wav";

	sound(self, CHAN_VOICE, self.noise, 1, ATTN_NONE);
	return;
};

void() PlayerDie =
{
	local   string  s;

	// I may not die alone...
	ActivateRemoteBombs();

	// Drop any lighted bomb/can
	if (self.weapon == IT_TNT || self.weapon == IT_SPRAY_CAN)
	{
		if (self.player_state == PS_HOLD_FIRE || self.weaponentity.charge)
		{
			self.weaponentity.charge = 0;
			Bomb_Fire();
		}
	}

	remove(self.weaponentity);
	remove(self.overhead);
	self.items = self.items - (self.items & IT_INVISIBILITY);

	if (self.akimbo_finished > 0)
	{
		s = ftos(rint(self.akimbo_finished - time));
		bprint4(self.netname, " lost a Guns Akimbo with ", s, " seconds remaining\n");
		Akimbo_Drop(self.akimbo_finished - time);
	}

	if (self.invisible_finished > 0)
	{
		s = ftos(rint(self.invisible_finished - time));
		bprint4(self.netname, " lost a cloak with ", s, " seconds remaining\n");
		Invisibility_Drop(self.invisible_finished - time);
	}

	CTF_PlayerDropFlag();

	self.invisible_finished = 0;    // don't die as eyes
	self.invincible_finished = 0;
	self.akimbo_finished = 0;
	self.modelindex = modelindex_player;    // don't use eyes
	self.poison = 0;
	self.alpha = 1;
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
		GibPlayer();
		return;
	}

	DeathSound();

	self.angles_x = 0;
	self.angles_z = 0;

	// If the player was on the Brink Of Death
	if (self.player_state >= PS_BOD_FALL && self.player_state <= PS_BOD_SWAY)
	{
		// If the head is removed in the process
		if (self.health < -10)
		{
			// The player entity will be the head, so we must
			// create a new entity for the corpse
			player_head = self;
			self = spawn();
			setmodel(self, player_head.model);
			setorigin(self, player_head.origin);
			setsize(self, player_head.mins, player_head.maxs);
			self.angles = player_head.angles;
			self.frame = player_head.frame;
			self.skin = player_head.skin;
			self.colormap = player_head.colormap;
			self.movetype = player_head.movetype;
			self.velocity = player_head.velocity;
			self.player_state = PS_HEADLESS_DEATH;

			self = player_head;
			self.deadflag = DEAD_DEAD;
			ThrowHead("progs/h_player.mdl", self.health);
		}
		else
			self.player_state = PS_BOD_DEATH;
	}
	else
		self.player_state = PS_DEATH;
};

// used by kill command and disconnect command
void() set_suicide_frame =
{
	if (self.model == "progs/player.mdl")
		self.frame = PLAYER_DEATH_END;

	// Make copy of self
	CloneCorpse(self);

	// Then disappear - Kind of a hack to handle persistant corpse on disconnect
	self.model = string_null;
	self.modelindex = 0;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_TOSS;
	self.deadflag = DEAD_DEAD;
	self.reset = SUB_Remove;
	self.think = SUB_Remove;
	self.nextthink = time + 0.1;
};

void() DrawOverheadWeapon =
{
	if (self.weapon > IT_PITCHFORK)
	{
		local string g_wep;

		if (self.weapon == IT_FLAREGUN)
			g_wep = "models/weapons/g_flare.md3";
		else if (self.weapon == IT_SAWED_OFF)
			g_wep = "models/weapons/g_shotgun.md3";
		else if (self.weapon == IT_TOMMYGUN)
			g_wep = "models/weapons/g_tommy.md3";
		else if (self.weapon == IT_NAPALM_LAUNCHER)
			g_wep = "models/weapons/g_napalm.md3";
		else if (self.weapon == IT_TNT)
			g_wep = "models/ammo/a_tnt.md3";
		else if (self.weapon == IT_PROXIMITY_BOMB)
			g_wep = "models/weapons/g_proxy.md3";
		else if (self.weapon == IT_REMOTE_DETONATOR)
			g_wep = "models/weapons/g_remote.md3";
		else if (self.weapon == IT_SPRAY_CAN)
			g_wep = "models/ammo/g_aerosol.md3";
		else if (self.weapon == IT_TESLA_CANNON)
			g_wep = "models/weapons/g_tesla.md3";
		else if (self.weapon == IT_LIFE_LEECH)
			g_wep = "models/weapons/g_leech.md3";
		else if (self.weapon == IT_VOODOO_DOLL)
			g_wep = "models/weapons/g_voodoo.md3";

		self.overhead.angles_y = self.angles_y + 90;

		if (self.weapon == IT_VOODOO_DOLL)
			self.overhead.angles_y = self.angles_y + 180;

		self.overhead.origin = self.origin + v_up * 37;
		self.overhead.scale = 0.6;

		setmodel(self.overhead, g_wep);
	}
	else
		setmodel(self.overhead, "");
};

/*
====================
player_animate

animate the player, this is really ugly, because of the only two-weapons builtins
====================
*/
void() player_animate =
{
	local float pw; //player weapon
	if (self.weapon == IT_PITCHFORK) pw = 1; else pw = 2;

	self.nextthink = time + 0.1;
	self.think = player_animate;

	if (self.crouch && self.health && self.player_state < PS_BOD_FALL) //crouching has not firing or running animtion
	{
		self.frame = PLAYER_CROUCH;
		return;
	}
	else if (self.player_state == PS_IDLE)
	{
		if (self.velocity_x || self.velocity_y) //we're moving
		{
			if (pw == 1)
			{
				if (self.frame < PLAYER_PITCH_RUN_START || self.frame >= PLAYER_PITCH_RUN_END)
					self.frame = PLAYER_PITCH_RUN_START;
				else
					self.frame = self.frame + 1;
			}
			else //player_weapon == 2
			{
				if (self.frame < PLAYER_RUN_START || self.frame >= PLAYER_RUN_END)
					self.frame = PLAYER_RUN_START;
				else
					self.frame = self.frame + 1;
			}
		}
		else //standing still
		{
			if (pw == 1)
				self.frame = PLAYER_PITCH_STAND;
			else
				self.frame = PLAYER_STAND;
		}
	}
	else if (self.player_state == PS_FIRE || self.player_state == PS_ALTFIRE)
	{
		if (pw == 1 && (self.frame < PLAYER_PITCH_ATTACK_START || self.frame >= PLAYER_PITCH_ATTACK_END))
			self.frame = PLAYER_PITCH_ATTACK_START;
		else if (pw == 2 && (self.frame < PLAYER_ATTACK_START || self.frame >= PLAYER_ATTACK_END))
			self.frame = PLAYER_ATTACK_START;
		else
			self.frame = self.frame + 1;
	}
	else if (self.player_state == PS_CHARGE || self.player_state == PS_HOLD_FIRE)
	{
		self.frame = PLAYER_ATTACK_START;
		return;
	}
	else if (self.player_state == PS_DRAW)
	{
		if (pw == 1 && (self.frame < PLAYER_DRAW_PITCH_START || self.frame >= PLAYER_DRAW_PITCH_END))
			self.frame = PLAYER_DRAW_PITCH_START;
		else if (pw == 2 && (self.frame < PLAYER_DRAW_GUN_START || self.frame >= PLAYER_DRAW_GUN_END))
			self.frame = PLAYER_DRAW_GUN_START;
		else
			self.frame = self.frame + 1;
	}
	else if (self.player_state == PS_HOLSTER || self.player_state == PS_MENU)
	{
		if (pw == 1)
			self.frame = PLAYER_PITCH_STAND;
		else
			self.frame = PLAYER_STAND;
	}
	else if (self.player_state == PS_BOD_FALL)
	{
		if (self.frame == PLAYER_BOD_FALL_END)
		{
			self.player_state = PS_BOD_SWAY;
			self.takedamage = DAMAGE_AIM;
			return;
		}

		if (self.frame < PLAYER_BOD_FALL_START || self.frame > PLAYER_BOD_FALL_END)
			self.frame = PLAYER_BOD_FALL_START;
		else
			self.frame = self.frame + 1;
	}
	else if (self.player_state == PS_BOD_SWAY)
	{
		if (self.frame < PLAYER_BOD_SWAY_START || self.frame >= PLAYER_BOD_SWAY_END)
			self.frame = PLAYER_BOD_SWAY_START;
		else
			self.frame = self.frame + 1;
	}
	else if (self.player_state == PS_BOD_DEATH)
	{
		if (self.frame == PLAYER_BOD_DEATH_END)
		{
			self.frame = PLAYER_BOD_DEATH_END;
			PlayerDead();
			return;
		}

		if (self.frame < PLAYER_BOD_DEATH_START || self.frame > PLAYER_BOD_DEATH_END)
			self.frame = PLAYER_BOD_DEATH_START;
		else
			self.frame = self.frame + 1;
	}
	else if (self.player_state == PS_HEADLESS_DEATH)
	{
		if (self.frame == PLAYER_DEATH_HEADLESS_END)
		{
			self.think = SUB_Remove;
			return;
		}

		if (self.frame < PLAYER_DEATH_HEADLESS_START || self.frame > PLAYER_DEATH_HEADLESS_END)
			self.frame = PLAYER_DEATH_HEADLESS_START;
		else
			self.frame = self.frame + 1;
	}
	else if (self.player_state == PS_PAIN)
	{
		if (self.frame == PLAYER_PAIN_END || self.frame == PLAYER_PITCH_PAIN_END)
		{
			self.player_state = PS_IDLE;
			return;
		}

		if ((pw == 1) && (self.frame < PLAYER_PITCH_PAIN_START || self.frame > PLAYER_PITCH_PAIN_END))
			self.frame = PLAYER_PITCH_PAIN_START;
		else if ((pw == 2) && (self.frame < PLAYER_PAIN_START || self.frame > PLAYER_PAIN_END))
			self.frame = PLAYER_PAIN_START;
		else
			self.frame = self.frame + 1;
	}
	else if (self.player_state == PS_DEATH)
	{
		if (self.frame == PLAYER_DEATH_END)
		{
			self.frame = PLAYER_DEATH_END;
			PlayerDead();
			return;
		}

		if (self.frame < PLAYER_DEATH_START || self.frame > PLAYER_DEATH_END)
			self.frame = PLAYER_DEATH_START;
		else
			self.frame = self.frame + 1;
	}
};