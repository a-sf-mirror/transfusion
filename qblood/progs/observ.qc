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
};

void(entity player) BecomeObserver =
{
	player.health           = 999;
	player.armorvalue       = 0;
	player.frags			= -666;
	player.takedamage		= DAMAGE_NO;
	player.solid			= SOLID_NOT;
	player.movetype			= MOVETYPE_NOCLIP;
	player.flags			= FL_CLIENT | FL_NOTARGET;
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
