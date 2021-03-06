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

$cd id1/models/flag
$base base
$skin skin

void(entity flg) RegenFlag =
{
	flg.movetype = MOVETYPE_TOSS;
	flg.solid = SOLID_TRIGGER;
	if (flg.owner)
		flg.owner.effects = flg.owner.effects - (flg.owner.effects & EF_DIMLIGHT);
	flg.effects = flg.effects | EF_DIMLIGHT;
	if (flg.team == TEAM_COLOR1)
		flg.effects = flg.effects | EF_RED;
	else
		flg.effects = flg.effects | EF_BLUE;
	setorigin(flg, flg.oldorigin);
	flg.angles = flg.mangle;
	flg.cnt = FLAG_AT_BASE; // it's at home base
	flg.owner = world;
	flg.velocity = '0 0 0';
	sound(flg, CHAN_ITEM, "bludbath/respawn2.wav", 1, ATTN_NORM); // play respawn sound
};

void(entity flg) TeamCaptureReturnFlag =
{
	local entity p;

	RegenFlag(flg);

	p = find(world, classname, "player");
	while (p != world) {
		if (p.team != flg.team)
			centerprint(p, "Enemy flag has been returned to base!");
		else if (p.team == flg.team)
			centerprint(p, "Your flag has been returned to base!");
		p = find(p, classname, "player");
	}
};

void() TeamCaptureRegenFlags =
{
	local entity f;
	f = find(world, classname, "item_flag_team1");
	if (f != world)
		RegenFlag(f);
	f = find(world, classname, "item_flag_team2");
	if (f != world)
		RegenFlag(f);
};

void() CTF_FlagReset =
{
	RegenFlag(self);
};

void() CTF_FlagTouch =
{
	local entity p;

	if (other.classname != "player")
		return;

	if (other.health <= 0)
		return;

	if (self.team == other.team)
	{
		// same team, if the flag is *not* at the base, return
		// it to base.  we overload the 'cnt' field for this
		if (self.cnt == FLAG_AT_BASE)
		{
			// the player doesn't have the enemy flag. Nothing to do...
			if (!(other.items & IT_ENEMY_FLAG))
				return;
			other.items = other.items - IT_ENEMY_FLAG;
			// The score stays 0/0 until the warmup is finished
			if (warmup_done)
			{
				if (self.team == TEAM_COLOR1)
					team1score = team1score + 1;
				else
					team2score = team2score + 1;
			}
			// the flag is at home base.  if the player has the enemy
			// flag, he's just won!
			bprint(other.netname);
			if (other.team == TEAM_COLOR1)
				bprint(" �������� the ���� flag!\n"); // blue
			else
				bprint(" �������� the ��� flag!\n"); // red
			Cl_PrintTeamScores();
			sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NONE);
			// other gets another 10 frag bonus
			other.frags = other.frags + TEAM_CAPTURE_CAPTURE_BONUS;
			// respawn flags
			TeamCaptureRegenFlags();
			return;  // its at home base already
		}
		// hey, its not home.  return it by teleporting it back
		bprint(other.netname);
		if (other.team == TEAM_COLOR1)
			bprint(" �������� the ��� flag!\n"); // red
		else
			bprint(" �������� the ���� flag!\n"); // blue
		other.frags = other.frags + TEAM_CAPTURE_RECOVERY_BONUS;
		sound(self, CHAN_ITEM, self.noise1, 1, ATTN_NONE);
		TeamCaptureReturnFlag(self);
		return;
	}
	// hey, its not our flag, pick it up
	bprint(other.netname);
	if (other.team == TEAM_COLOR1)
		bprint(" ��� the ���� flag!\n"); // blue
	else
		bprint(" ��� the ��� flag!\n"); // red

	centerprint(other, "��� ��� ��� ����� ����\n\n������ �� ����");  // == "YOU GOT THE ENEMY FLAG!\n\nRETURN TO BASE!"
	sound(self, CHAN_ITEM, self.noise, 1, ATTN_NONE);

	other.items = other.items + IT_ENEMY_FLAG;

	// pick up the flag
	self.cnt = FLAG_CARRIED;
	self.movetype = MOVETYPE_NOCLIP;
	self.solid = SOLID_NOT;
	self.owner = other;

	// We remove the glow on the flag and transfers the EF_DIMLIGHT effect to the player
	self.effects = self.effects - (self.effects & (EF_DIMLIGHT | EF_RED | EF_BLUE));
	self.owner.effects = self.owner.effects | EF_DIMLIGHT;

	p = find(world, classname, "player");
	while (p != world) {
		if (p != other) {
			if ((p.team == TEAM_COLOR1 && other.team == TEAM_COLOR2) ||
				(p.team == TEAM_COLOR2 && other.team == TEAM_COLOR1))
				centerprint(p, "Your flag has been taken!");
			else if (p.team == other.team)
				centerprint(p, "Your team has the enemy flag!");
		}
		p = find(p, classname, "player");
	}
};

void(entity flg) TeamDropFlag =
{
	local entity p;

	p = flg.owner;

	bprint(p.netname);
	if (p.team == TEAM_COLOR1)
		bprint(" ���� the ���� flag!\n"); // blue
	else
		bprint(" ���� the ��� flag!\n"); // red
	p.effects = p.effects - (p.effects & EF_DIMLIGHT);

	flg.origin = p.origin - '0 0 24';
	flg.cnt = FLAG_DROPPED;
	flg.velocity_z = 300;
	flg.velocity_x = 0;
	flg.velocity_y = 0;
	flg.flags = FL_ITEM;
	flg.solid = SOLID_TRIGGER;
	flg.movetype = MOVETYPE_TOSS;
	flg.effects = flg.effects | EF_DIMLIGHT;
	if (flg.team == TEAM_COLOR1)
		flg.effects = flg.effects | EF_RED;
	else
		flg.effects = flg.effects | EF_BLUE;
	setsize(flg, '-16 -16 0', '16 16 74');

	// return it after so long
	flg.search_time = time + TEAM_CAPTURE_FLAG_RETURN_TIME;
};

void() CTF_PlayerDropFlag =
{
	local string kn;
	local entity e;

	if (!(self.items & IT_ENEMY_FLAG))
		return;
	if (self.team == TEAM_COLOR1)
		kn = "item_flag_team2";
	else
		kn = "item_flag_team1";
	self.items = self.items - IT_ENEMY_FLAG;
	e = find(world, classname, kn);
	if (e != world)
		TeamDropFlag(e);
};

void() CTF_FlagThink =
{
	local entity e;
	local vector v;
	local float f;

	self.nextthink = time + 0.1;

	if (self.cnt == FLAG_AT_BASE)
		return; // just sitting around waiting to be picked up

	if (self.cnt == FLAG_DROPPED) {
		if (time - self.search_time > TEAM_CAPTURE_FLAG_RETURN_TIME)
			TeamCaptureReturnFlag(self);
		return;
	}

	if (self.cnt != FLAG_CARRIED)
		objerror("Flag in invalid state\n");

	// We must manage the flag ourselves
	e = self.owner;
	if ((e.classname != "player") || (e.deadflag)) {
		TeamDropFlag(self);
		return;
	}
	makevectors(e.angles);
	v = v_forward;
	v_z = (-1) * v_z; // reverse z component

	f = 14;
	if (self.owner.frame >= PLAYER_PITCH_PAIN_START && self.owner.frame <= PLAYER_PAIN_END) {
		if (self.owner.frame >= PLAYER_PITCH_PAIN_START && self.owner.frame <= PLAYER_PITCH_PAIN_END) {
			if      (self.owner.frame == PLAYER_PITCH_PAIN_START) f = f + 2;
			else if (self.owner.frame == PLAYER_PITCH_PAIN_START+1) f = f + 8;
			else if (self.owner.frame == PLAYER_PITCH_PAIN_START+2) f = f + 12;
			else if (self.owner.frame == PLAYER_PITCH_PAIN_START+3) f = f + 10;
			else if (self.owner.frame == PLAYER_PITCH_PAIN_END) f = f + 4;
		} else if (self.owner.frame >= PLAYER_PAIN_START && self.owner.frame <= PLAYER_PAIN_END) {
			if      (self.owner.frame == PLAYER_PAIN_START) f = f + 2;
			else if (self.owner.frame == PLAYER_PAIN_START+1) f = f + 10;
			else if (self.owner.frame == PLAYER_PAIN_START+2) f = f + 10;
			else if (self.owner.frame == PLAYER_PAIN_START+3) f = f + 8;
			else if (self.owner.frame == PLAYER_PAIN_END) f = f + 2;
		}
	}
	else if (self.owner.frame >= PLAYER_ATTACK_START && self.owner.frame <= PLAYER_ATTACK_END) f = f + 6;

	self.origin = e.origin + '0 0 -16' - f*v + v_right * 22;
	self.angles = e.angles + '0 0 -45';
	setorigin(self, self.origin);
	self.nextthink = time + 0.01;
};

void() place_flag = {
	setmodel(self, "models/objects/flag.md3");
	setsize(self, '-3 -20 0', '4 20 55');

	self.mdl = self.model;      // so it can be restored on respawn
	self.flags = FL_ITEM;       // make extra wide
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_TOSS;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	self.think = CTF_FlagThink;
	self.touch = CTF_FlagTouch;
	self.nextthink = time + 0.1;
	self.cnt = FLAG_AT_BASE;
	self.mangle = self.angles;
	self.effects = self.effects | EF_DIMLIGHT;
	if (self.team == TEAM_COLOR1)
		self.effects = self.effects | EF_RED;
	else
		self.effects = self.effects | EF_BLUE;
	if (!droptofloor()) {
		dprint("Flag fell out of level at ");
		dprint(vtos(self.origin));
		dprint("\n");
		remove(self);
		return;
	}
	self.oldorigin = self.origin; // save for flag return
};

// ZOID Capture the flag
void() item_flag_team1 =
{
	// If CTF is not the current mode
	if (gametype != GT_CAPTURE_THE_FLAG)
	{
		remove(self);
		return;
	}

	precache_model("models/objects/flag.md3");

	precache_sound("thevoice/8000.wav");  // "Red captures the flag"
	precache_sound("thevoice/8002.wav");  // "Red returns the flag"
	precache_sound("thevoice/8006.wav");  // "Red flag stolen"

	precache_sound("bludbath/respawn2.wav");  // Respawn sound

	self.noise = "thevoice/8006.wav";
	self.noise1 = "thevoice/8002.wav";
	self.noise2 = "thevoice/8000.wav";

	self.team = TEAM_COLOR1;
	self.skin = 0;
	self.nextthink = time + 0.2;    // items start after other solids
	self.think = place_flag;
	self.reset = CTF_FlagReset;
};

void() item_flag_team2 =
{
	// If CTF is not the current mode
	if (gametype != GT_CAPTURE_THE_FLAG)
	{
		remove(self);
		return;
	}

	precache_model("models/objects/flag.md3");

	precache_sound("thevoice/8001.wav");  // "Blue captures the flag"
	precache_sound("thevoice/8003.wav");  // "Blue returns the flag"
	precache_sound("thevoice/8007.wav");  // "Blue flag stolen"

	precache_sound("bludbath/respawn2.wav");  // Respawn sound

	self.noise = "thevoice/8007.wav";
	self.noise1 = "thevoice/8003.wav";
	self.noise2 = "thevoice/8001.wav";
	self.team = TEAM_COLOR2;
	self.skin = 1;
	self.nextthink = time + 0.2;    // items start after other solids
	self.think = place_flag;
	self.reset = CTF_FlagReset;
};

/*QUAKED func_ctf_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
Only appears in CTF teamplay
*/
void() func_ctf_wall =
{
	if (gametype != GT_CAPTURE_THE_FLAG)
	{
		remove(self);
		return;
	}

	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;  // so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	setmodel(self, self.model);
};
