/*  Copyright (C) 2001-2003  Mathieu Olivier

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

void() Fork_Fire;

//============================================================================
// ----- Pitchfork model ----- //
$modelname v_pitch

// idle
$frame fork_idle1

// draw
$frame fork_draw1 fork_draw2 fork_draw3

// fire
$frame fork_fire1 fork_fire2 fork_fire3 fork_fire4

// holster
$frame fork_holster1 fork_holster2 fork_holster3

// ----- Player related code ----- //
void() player_fork4 =
{
	self.frame = self.frame + 1;
	self.nextthink = time + 0.1;
	self.think = player_run;

	self.weaponframe = $fork_fire4;
};

void() player_fork3 =
{
	self.frame = self.frame + 1;
	self.nextthink = time + 0.1;
	self.think = player_fork4;

	self.weaponframe = $fork_fire3;
	Fork_Fire ();
};

void() player_fork2 =
{
	self.frame = self.frame + 1;
	self.nextthink = time + 0.1;
	self.think = player_fork3;

	self.weaponframe = $fork_fire2;
};

void() player_fork1 =
{
	// self.frame has been initialized by Fork_Attack
	self.nextthink = time + 0.1;
	self.think = player_fork2;

	self.weaponframe = $fork_fire1;

	self.player_state = PS_FIRE;
};

// Normal draw
void() player_forkdraw1 = [$pitchstand1, player_forkdraw2] { self.weaponframe = $fork_draw1; };
void() player_forkdraw2 = [$pitchstand1, player_forkdraw3] { self.weaponframe = $fork_draw2; };
void() player_forkdraw3 = [$pitchstand1, player_run      ] { self.weaponframe = $fork_draw3; };

// Normal holster
void() player_forkholster1 = [$pitchstand1, player_forkholster2] { self.weaponframe = $fork_holster1; };
void() player_forkholster2 = [$pitchstand1, player_forkholster3] { self.weaponframe = $fork_holster2; };
void() player_forkholster3 = [$pitchstand1, player_forkholster4] { self.weaponframe = $fork_holster3; };
void() player_forkholster4 = [$pitchstand1, player_run         ] { W_DrawWeapon (self.newweapon); };

//============================================================================

/*
============
TineHit

Handle one tine hit with the pitchfork
============
*/
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
		// If the target can bleed, spawn some blood
		if (targ.classname == "player" || (targ.flags & FL_MONSTER) ||
			targ.classname == "corpse" || targ.classname == "head")
		{
			SpawnBlood (org, '0 0 0', damage);
			SpawnBloodSpray (trace_ent, org);
			sound (self, CHAN_WEAPON, "weapons/pitchfrk/pflesh.wav", 1, ATTN_NORM);
		}
		else
			sound (self, CHAN_WEAPON, "weapons/pitchfrk/pstone.wav", 1, ATTN_NORM);
		AddMultiDamage (targ, damage);
	}
	else
	{
		// hit wall
		sound (self, CHAN_WEAPON, "weapons/pitchfrk/pstone.wav", 1, ATTN_NORM);

		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};

/*
============
Fork_Fire

Try to hit something with the pitchfork
============
*/
void() Fork_Fire =
{
	local   vector  source;
	local   vector  start, end;     // Endpoints per tine.
	local   vector  vx, vy, vz;     // forward, right, up unit vectors.
	local   float   damage;         // Damage per tine.
	local   float   loop;           // Number of tines.

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
	ApplyMultiDamage (DF_STAB);
};

/*
============
Fork_Attack

Attack code for the pitchfork
============
*/
void() Fork_Attack =
{
	local float r;

	self.frame = $pitchattack1;

	player_fork1 ();
	self.attack_finished = time + 0.5;
};

/*
============
Fork_Draw

Draw code for the pitchfork
============
*/
void() Fork_Draw =
{
	self.weapon = IT_PITCHFORK;
	self.currentammo = 0;
	self.items = self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_CELLS | IT_ROCKETS));

	Fork_UpdateView ();

	self.attack_finished = time + 0.3;
	player_forkdraw1 ();
};

/*
============
Fork_Holster

Holster code for the pitchfork
============
*/
void() Fork_Holster =
{
	self.attack_finished = time + 0.3;
	player_forkholster1 ();
};

/*
============
Fork_UpdateView

Choose the right pitchfork model to display
============
*/
void() Fork_UpdateView =
{
	self.weaponmodel = "models/weapons/v_pitch.psk";
	self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};
