/*  Copyright (C) 2001-2006  Transfusion Code Team

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
#include "w_bomb.qh"

void() ShowThrowMeter =
{
	local   string  text;

	if (self.weaponentity.charge == 20)
		text = "žžžžžžžžžžžžžžžžž";
	else if (self.weaponentity.charge == 19)
		text = "žžžžžžžžžžžžžžžžž";
	else if (self.weaponentity.charge == 18)
		text = "žžžžžžžžžžžžžžžž ";
	else if (self.weaponentity.charge == 17)
		text = "žžžžžžžžžžžžžžž  ";
	else if (self.weaponentity.charge == 16)
		text = "žžžžžžžžžžžžžž   ";
	else if (self.weaponentity.charge == 15)
		text = "žžžžžžžžžžžžž    ";
	else if (self.weaponentity.charge == 14)
		text = "žžžžžžžžžžžž     ";
	else if (self.weaponentity.charge == 13)
		text = "žžžžžžžžžžž      ";
	else if (self.weaponentity.charge == 12)
		text = "žžžžžžžžžž       ";
	else if (self.weaponentity.charge == 11)
		text = "žžžžžžžžž        ";
	else if (self.weaponentity.charge == 10)
		text = "žžžžžžžž         ";
	else if (self.weaponentity.charge == 9)
		text = "žžžžžžž          ";
	else if (self.weaponentity.charge == 8)
		text = "žžžžžž           ";
	else if (self.weaponentity.charge == 7)
		text = "žžžžž            ";
	else if (self.weaponentity.charge == 6)
		text = "žžžž             ";
	else if (self.weaponentity.charge == 5)
		text = "žžž              ";
	else if (self.weaponentity.charge == 4)
		text = "žž               ";
	else if (self.weaponentity.charge == 3)
		text = "ž                ";
	else if (self.weaponentity.charge == 2)
		text = "                 ";
	else if (self.weaponentity.charge == 1)
		text = "                 ";
	else
		text = string_null;

	if (self.player_state == PS_CHARGE)
		centerprint2(self, "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", text);
	else
		centerprint(self, string_null);
};

void() Bomb_Uncharge =
{
	// Stop the fuse sound if any
	sound(self, CHAN_WEAPON, "misc/null.wav", 0, ATTN_NORM);

	self.weaponentity.charge = 0;
	self.weaponentity.tnt_time = 0;
};

void() Bomb_Explode =
{
	precache_sound("weapons/napalm/explodfl.wav");
	// Stop the fuse sound if any
	sound(self, CHAN_BODY, "misc/null.wav", 0, ATTN_NORM);

	// Make detonation sound
	if (self.netname == "Lit Spray Can") sound(self, CHAN_AUTO, "weapons/napalm/explodfl.wav", 1, ATTN_NORM);

	// Don't let grenade explode twice.
	self.takedamage = DAMAGE_NO;

	if (self.netname == "Napalm Ball")
	{
		local   float   radius, damage, burn;
		radius = self.dmg + 40;
		damage = self.dmg / 6;
		burn   = self.dmg / 12;
		BurnRadius(self, radius, damage, burn, world);
	}
	else if (self.netname == "Lit Spray Can")
		BurnRadius(self, 250, 20, 80, world);

	PsychoCaleb(self.owner);

	T_RadiusDamage(self, self.owner, self.dmg, DF_EXPLODE, world, "grenade");
	KillBurner(self);

	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord(MSG_BROADCAST, self.origin_x);
	WriteCoord(MSG_BROADCAST, self.origin_y);
	WriteCoord(MSG_BROADCAST, self.origin_z);
	BecomeExplosion();
};

void() Bomb_Trigger =
{
	self.takedamage = DAMAGE_NO;
	self.classname = "triggered_grenade";
	self.nextthink = time + 0.1;
	self.think = Bomb_Explode;
};

// This makes bomb take damage if in slime/lava.  Assumes 'self' == bomb
void() BombContents =
{
	// Dynamite will take damage then explode if in slime or lava.
	local float pc;

	pc = pointcontents(self.origin);
	if (pc == CONTENT_SLIME)
		T_Damage(self, world, world, 4, DF_ACID, "acid");
	else if (pc == CONTENT_LAVA)
		T_Damage(self, world, world, 10, DF_BURN, "fire");
};

void() BombThink =
{
	// the bomb must be able to "touch" the world
	self.owner = world;

	// Wait a little bit before making self solid as not to blow owner up!
	if (self.cnt >= 0.3)
		self.solid = SOLID_BBOX;

	self.cnt = self.cnt + 0.1;

	self.nextthink  = time + 0.1;
	if (!checkbottom(self) && self.netname == "TNT")
	{
		local float density;
		density = ceil(random() * 20);

		makevectors(self.angles);

		WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte(MSG_BROADCAST, TE_TEI_SMOKE);
		WriteCoord(MSG_BROADCAST, self.origin_x + v_right_x);
		WriteCoord(MSG_BROADCAST, self.origin_y + v_right_y);
		WriteCoord(MSG_BROADCAST, self.origin_z);
		WriteCoord(MSG_BROADCAST, 0);
		WriteCoord(MSG_BROADCAST, 0);
		WriteCoord(MSG_BROADCAST, density);
		WriteByte(MSG_BROADCAST, density);
	}
	BombContents();
};

/*
================
GrenadeTouch

"Touch" function for grenades
================
*/
void() GrenadeTouch =
{
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

// Dynamite stuff.
void() DynaTouch =
{
	// Normal grenades are the only ones which can explode on touch
	if (self.style == TNT_TYPE_NORMAL)
	{
		// Rebound if it hits the ceiling.  Otherwise, explode.
		traceline(self.origin - self.dest*4, self.origin + self.dest*16, TRUE, self);
		if (trace_fraction == 1 || trace_plane_normal_z >= 0)
		{
			Bomb_Explode();
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
		Bomb_Trigger();
		return;
	}

	if (self.t_width <= time)
	{
		self.t_width    = time + 3;
		sound(self, CHAN_BODY, "weapons/tnt/tntfuse.wav", 0.5, ATTN_NORM);
	}
	self.dest = normalize(self.velocity);

	BombThink();
};

/*
================
Bomb_Fire

Fire a bomb
================
*/
void() Bomb_Fire =
{
	if (self.weapon == IT_PROXIMITY_BOMB && !(self.flags & FL_INFINATE_AMMO))
		self.currentammo = self.ammo_tnt_proxy = self.ammo_tnt_proxy - 1;
	else if (self.weapon == IT_REMOTE_DETONATOR && !(self.flags & FL_INFINATE_AMMO))
		self.currentammo = self.ammo_tnt_remote = self.ammo_tnt_remote - 1;
	else if (self.weapon == IT_TNT && !(self.flags & FL_INFINATE_AMMO))
		self.currentammo = self.ammo_tnt_bundle = self.ammo_tnt_bundle - 1;
	else  if (!(self.flags & FL_INFINATE_AMMO)) // && (self.weapon == IT_SPRAY_CAN)
	{
		// If we have at least one full spray can, we use it
		if (self.currentammo >= 48)
				self.ammo_spray = self.ammo_spray - 48;
		// Else, we burn our last one
		else
			self.ammo_spray = 0;

		self.currentammo = self.ammo_spray;
	}

	sound(self, CHAN_AUTO, "weapons/tnt/tnttoss.wav", 1, ATTN_NORM);

	newmis = spawn();
	newmis.enemy = self;
	newmis.solid = SOLID_NOT;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.classname = "grenade";
	newmis.cnt = 0;                     // Set up for frame count skip

	// Wiggle player's screen just a little during toss
	self.punchangle_x = -2;

	// set newmis speed
	makevectors(self.v_angle);

	if (self.weaponentity.charge)
	{
		// TNT Charge/throw meter power.
		local   float   mspeed, mup;

		mspeed = 200 + (self.weaponentity.charge * 40); // was * 35
		/*if (mspeed < 230)
			mspeed = 230;  // don't throw the grenade on our own feet !
			//if there is a charge, the min is already 235, so I'll just comment this out for now
		*/
		mup = mspeed / 2; // was  / 1.75

		if (self.v_angle_x)
			newmis.velocity = v_forward * mspeed + v_up * mup + crandom() * v_right * 10 + crandom() * v_up * 10;
		else
		{
			newmis.velocity = aim(self, 10000);
			newmis.velocity = newmis.velocity * mspeed;
			newmis.velocity_z = mup;
		}
	}
	else
		newmis.velocity = '0 0 0';

	newmis.touch = GrenadeTouch;

	// Explodes as soon as it takes 1 point of damage
	newmis.takedamage = DAMAGE_YES;
	newmis.health = 1;
	newmis.th_die = Bomb_Trigger;  // do not make it explode directly

	newmis.reset = SUB_Remove;

	newmis.nextthink = 0.1;
	newmis.think     = BombThink;

	setorigin(newmis, W_Origin() + v_forward * 15 + v_right * 6 + v_up * 16);

	self.player_state = PS_FIRE;

	// If we fire a proximity bomb
	if (self.weapon == IT_PROXIMITY_BOMB)
	{
		newmis.pausetime = time + 2.5;
		newmis.style =	TNT_TYPE_NORMAL;
		newmis.think = ProxyBombThink;
		newmis.think1 = ProxyBombArmed;
		newmis.netname = "Proximity Bomb";
		newmis.dmg = DMG_PROXIMITY_BOMB;
		newmis.avelocity = '0 300 0';
		newmis.angles = '0 0 0';
		newmis.model = "models/weapons/grenades/gr_proxy.md3";
	}
	// else if we fire a remote detonator
	else if (self.weapon == IT_REMOTE_DETONATOR)
	{
		newmis.netname = "Remote Detonator";
		newmis.style = TNT_TYPE_NORMAL;
		newmis.dmg = DMG_REMOTE_DETONATOR;
		newmis.avelocity = '0 300 0';
		newmis.angles = '0 0 0';
		newmis.model = "models/weapons/grenades/gr_remote.md3";
	}
	// Else, it's TNT or a spray can!
	else
	{
		newmis.style     = self.weaponentity.tnt_type;
		newmis.pausetime = self.weaponentity.tnt_time;
		newmis.think     = DynaThink;
		newmis.touch     = DynaTouch;
		newmis.dest      = normalize(newmis.velocity);

		if (self.weapon == IT_SPRAY_CAN)
		{
			newmis.netname   = "Lit Spray Can";
			newmis.dmg       = DMG_SPRAY_CAN;
			newmis.model     = "models/weapons/grenades/gr_aerosol.md3";
		}
		else
		{
			newmis.netname   = "TNT";
			newmis.dmg       = DMG_TNT;
			newmis.model     = "models/weapons/grenades/gr_tnt.md3";
			newmis.angles    = vectoangles(newmis.velocity);
		}
	}

	setmodel(newmis, newmis.model);
	setsize(newmis, '0 0 0', '15 15 15');

	// If we have no more dynamite, we "lose" the weapon
	// (expect for remote detonators: we always have the remote)
	if (self.currentammo == 0 && self.weapon != IT_REMOTE_DETONATOR)
	{
		self.items = self.items - self.weapon;
		remove(self.weaponentity);
		W_DrawWeapon(W_BestWeapon());
	}
};
