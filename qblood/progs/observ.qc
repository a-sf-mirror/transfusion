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

entity() SelectSpawnPoint;

void(entity player,entity door) ObserverDoor =
{
	local entity d,d_master;
	local vector dmin,dmax;
	local float is_x,is_y,is_z,set;
	local vector dir,or;

	d_master = d = door.owner;
	if (d_master)
	{
		dmin = d_master.absmin;
		dmax = d_master.absmax;
	}
	else
		dmin = dmax = '0 0 0';

	if (dmin != dmax)
	{
		// regular doors
		if (d_master.state != STATE_BOTTOM)
			return;
		do
		{
			if (d.absmin_x < dmin_x)
				dmin_x = d.absmin_x;
			if (d.absmax_x > dmax_x)
				dmax_x = d.absmax_x;
			if (d.absmin_y < dmin_y)
				dmin_y = d.absmin_y;
			if (d.absmax_y > dmax_y)
				dmax_y = d.absmax_y;
			if (d.absmin_z < dmin_z)
				dmin_z = d.absmin_z;
			if (d.absmax_z > dmax_z)
				dmax_z = d.absmax_z;
			d = d.enemy; // next linked door;
		} while ((d != d_master) && (d != world));
	}
	else
		// secret doors; we ignore these currently
		return;

	set = is_x = is_y = is_z = FALSE;
	or = player.origin;
	if (dmin_x + 15 < player.absmin_x && player.absmax_x < dmax_x - 15)
		is_x = TRUE;
	if (dmin_y + 15 < player.absmin_y && player.absmax_y < dmax_y - 15)
		is_y = TRUE;
	if (dmin_z + 15 < player.absmin_z && player.absmax_z < dmax_z - 15)
		is_z = TRUE;

	if (is_x && is_y)
	{
		if (or_z < dmin_z)
		{
			dir = '0 0  1';
			or_z = dmax_z + 25;
		}
		else if (or_z > dmax_z)
		{
			dir = '0 0 -1';
			or_z = dmin_z - 25;
		}
		set = TRUE;
	}
	else if (is_x && is_z)
	{
		if (or_y < dmin_y)
		{
			dir = '0  1 0';
			or_y = dmax_y + 25;
		}
		else if (or_y > dmax_y)
		{
			dir = '0 -1 0';
			or_y = dmin_y - 25;
		}
		set = TRUE;
	}
	else if (is_y && is_z)
	{
		if (or_x < dmin_x)
		{
			dir = ' 1 0 0';
			or_x = dmax_x + 25;
		}
		else if (or_x > dmax_x)
		{
			dir = '-1 0 0';
			or_x = dmin_x - 25;
		}
		set = TRUE;
	}
	if (set)
	{
		local vector v;
		v =  normalize(player.velocity);
		if (dir * v < 0.5)
			return;
		player.origin = or;
		setorigin(player, player.origin);
	}
};

void(entity player,entity tele) ObserverTeleporter =
{
	local entity targ;
	local vector v1,v2;

	v1 = ((tele.absmax + tele.absmin) * 0.5) - player.origin;
	normalize(v1);
	v2 = player.velocity;
	normalize(v2);
	if (v1 * v2 <= 0.1)
		return;

	targ = find(world, targetname, tele.target);
	if (!targ)
	{
		dprint("ObserverTeleport: couldn't find teleporter target\n");
		return;
	}
	makevectors(targ.mangle);
	setorigin(player, targ.origin);
	player.angles = targ.mangle;
	player.fixangle = TRUE; // turn this way immediately
	player.teleport_time = time + 0.7;
	player.velocity = v_forward * 300;
};

/*
============
Impulses_Observer

Impulse list for observers
============
*/
void() Impulses_Observer =
{
	if (self.impulse == IMP_NONE && !self.button0 && !self.button2 && !self.button4)
		return;

	// If we're not in a team mode, join the game on impulse 1 or 2, or on "jump" or "fire"
	if ((gametype != GT_TEAM_BLOODBATH && gametype != GT_CAPTURE_THE_FLAG))
	{
		if (self.impulse == 1 || self.impulse == 2 || self.button0 || self.button1 || self.button2 || self.button3 || self.button4)
		{
			self.observer = 0;
			self.frags = 0;
			respawn(FALSE);
		}
	}

	// Else (in a team mode)
	else
	{
		if (self.button0 || self.button1 || self.button2 || self.button3 || self.button4)
			centerprint(self, "Type:\nimpulse 1 for joining the RED team\nimpulse 2 for joining the BLUE team");
		else if (self.impulse == 1 || self.impulse == 2)
		{
			// If a warmup has been done, the teams may be locked now
			if (warmup_done && warmup_endtime && cvar("g_lockTeams"))
				centerprint(self, "You can't join a team\nThey have been locked after the warmup");
			else
			{
				// Choose the color...
				if (self.impulse == 1)
				{
					self.team = TEAM_COLOR1;
					centerprint(self, "You have joined the RED team");
				}
				else
				{
					self.team = TEAM_COLOR2;
					centerprint(self, "You have joined the BLUE team");
				}
				self.team_save = self.team;  // backup the team of the player

				// ...and join the game
				self.observer = 0;
				respawn(FALSE);
			}
		}
	}

	// If the player has just spawned into the arena
	if (!self.observer)
		bprint2(self.netname, " lives again!\n");

	if (self.impulse == IMP_IDENT_PLAYER)
		identify_player();

	self.impulse = IMP_NONE;
};

void() ObserverThink =
{
	local entity e;
	local float invcos,nvp,nvpmax,sp,svz;
	local vector f,vp,vs;

	self.flags = self.flags | FL_ONGROUND;

	svz = self.velocity_z * 0.75;
	self.velocity_z = 0;

	// v_forward is already normalized
	f_x = v_forward_x;
	f_y = v_forward_y;
	f_z = 0;
	invcos = vlen(f);
	if (invcos)
		invcos= 1/invcos;
	else
		invcos=0;
	f = f*invcos; // normalize f

	sp = f * self.velocity;
	vp = sp*f;
	nvp = vlen(vp);
	if (sp<0)
		nvp = nvp*(-1);
	vs = self.velocity - vp;

	vp = v_forward * (nvp * invcos);
	vp_z = vp_z + svz;
	nvp = vlen(vp);
	nvpmax = (320 - 100*(v_forward * '0 0 1'));
	if (nvp > nvpmax)
		vp = vp * (nvpmax/nvp);

	self.velocity = vp + vs;

	// look for doors, etc.
	e = findradius(self.origin,75);
	while (e != world) {
		if (e.classname == "door") {
			ObserverDoor(self, e);
			e = world;
		}
		if (e.classname == "trigger_teleport") {
			ObserverTeleporter(self,e);
			e = world;
		}
		e = e.chain;
		if (!e) e = world;
	}
};

void(entity player) BecomeObserver =
{
	player.health           = 999;
	player.armorvalue       = 0;
	player.frags			= -666;
	player.takedamage       = DAMAGE_NO;
	player.solid            = SOLID_NOT;
	player.movetype         = MOVETYPE_FLY;
	player.deadflag         = DEAD_NO;
	player.player_state     = PS_IDLE;
	player.team             = 0;
	player.nextthink        = time + 0.1;
	player.think			= ObserverThink;

	player.skin = 0;
	player.frame = 0;
	setmodel(player, "models/objects/eyes.md3");
	setsize(player, '-10 -10 -20', '10 10 28');

	player.weapon      = 0;
	player.currentammo = 0;

	player.observer    = 1;
	player.do_observer = 0;

	player.classname = "observer";
	player.reset     = SUB_Null;
};
