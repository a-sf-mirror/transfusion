/*  Copyright (C) 2003  Timothy Hale

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

// Shared cultist functions
void () cultist_attack;      //
void () cultist_die;         // Brown, Black, Blue, Green
void () cultist_fireShotgun; // Brown, Red
void () cultist_pain;        //
void () cultist_stand;       //
void () cultist_throw_TNT;   // Brown, Green
void () cultist_TNT_touch;   // Brown, Green


void () cultist_attack =
{
    local float r;
/*
    if (range(self.enemy) == RANGE_MELEE) // A jump back hack, need to smooth this out over frames
    {
        // Need to actually check if he can back up, if not go ahead and use the weapon
        ai_back(100);
        return;
    }
*/
    r = random();

    if (self.pain_finished < time && self.attack_finished < time)// To avoid several sounds at once
    if (r <= 0.05)
        {
            sound (self, CHAN_AUTO, "cultist/cultglo1.wav", 1, ATTN_NORM);
            self.attack_finished = time + 3.46;
        }
    else if (r <= 0.10)
        {
            sound (self, CHAN_AUTO, "cultist/cultglo2.wav", 1, ATTN_NORM);
            self.attack_finished = time + 3.21;
        }
    else if (r <= 0.15)
        {
            sound (self, CHAN_AUTO, "cultist/cultglo3.wav", 1, ATTN_NORM);
            self.attack_finished = time + 2.27;
        }
    else if (r <= 0.20)
        {
            sound (self, CHAN_AUTO, "cultist/cultglo4.wav", 1, ATTN_NORM);
            self.attack_finished = time + 2.27;
        }
    else
        self.attack_finished = time + 2;
};


void () cultist_die =
{
    self.effects = 0;
    if (self.health < -40)
    {
        sound (self, CHAN_VOICE, "cultist/cultdie3.wav", 1, ATTN_NORM);
        RandomHumanGibs ();
        remove (self);
        return;
    }

    if (random () < 0.5)
        sound (self, CHAN_VOICE, "cultist/cultdie1.wav", 1, ATTN_NORM);
    else
        sound (self, CHAN_VOICE, "cultist/cultdie2.wav", 1, ATTN_NORM);

    self.solid = SOLID_NOT;

};

void () cultist_fireShotgun =
{
    local float r;
    local vector dir;
    local vector spread;

    self.effects = self.effects | EF_MUZZLEFLASH;

    makevectors (self.v_angle); // TESTME: Is this needed?

    r = random();

    if (r < 0.5)
        sound (self, CHAN_AUTO, "cultist/cultatt1.wav", 1, ATTN_NORM);
    else
        sound (self ,CHAN_AUTO, "cultist/cultatt2.wav", 1, ATTN_NORM);

    dir = (self.enemy.origin - self.origin);
    dir = normalize (dir);

    FireBullets (self.origin, dir, 8, 8, '0.1 0.1 0');  // 8 "shot pellets" per shell
};

void () cultist_pain =
{
    local float r;

    // don't make multiple pain sounds right after each other
    if (self.pain_finished > time)
        return;

    r = random();

    if (self.deathtype == "fire" && (self.health / self.max_health) <= 0.35)
    {
        if (r < 0.33)
            {sound (self,2,"cultist/cultfir1.wav",1,1); self.pain_finished = (time + 3.2);}
        else if (r < 0.66)
            {sound (self,2,"cultist/cultfir2.wav",1,1);    self.pain_finished = (time + 4.62);}
        else
            {sound (self,2,"cultist/cultfir3.wav",1,1);    self.pain_finished = (time + 3.62);}
    }

    else if (r < 0.25)
        {sound (self,2,"cultist/cultpan1.wav",1,1);    self.pain_finished = (time + 1.38);}
    else if (r < 0.5)
        {sound (self,2,"cultist/cultpan2.wav",1,1);    self.pain_finished = (time + 1.35);}
    else if (r < 0.75)
        {sound (self,2,"cultist/cultpan3.wav",1,1);    self.pain_finished = (time + 1.4);}
    else
        {sound (self,2,"cultist/cultpan4.wav",1,1);    self.pain_finished = (time + 1.29);}
};


void () cultist_stand =
{
    local float     r;

    r = random();

    if (r <= 0.02)
        sound (self, CHAN_WEAPON, "cultist/cultspt1.wav", 1, ATTN_NORM);

    else if (r <= 0.04)
        sound (self, CHAN_WEAPON, "cultist/cultspt2.wav", 1, ATTN_NORM);

    else if (r <= 0.06)
        sound (self, CHAN_WEAPON, "cultist/cultspt3.wav", 1, ATTN_NORM);

    else if (r <= 0.08)
        sound (self, CHAN_WEAPON, "cultist/cultspt4.wav", 1, ATTN_NORM);

    else if (r <= 0.1)
        sound (self, CHAN_WEAPON, "cultist/cultspt5.wav", 1, ATTN_NORM);
};

//--- Function used by brown, black and green cultists

void () cultist_throw_TNT =
{
    local    entity missile;
    local    vector delta;
    local     float dist;

    sound (self, CHAN_WEAPON, "cultist/culttoss.wav", 1, ATTN_NORM);

    missile = spawn ();
    missile.owner = self;
    missile.movetype = MOVETYPE_BOUNCE;
    missile.solid = SOLID_BBOX;

    // set missile speed

    makevectors (self.angles);

    delta = (self.enemy.origin - self.origin);
    dist = vlen(delta);

    missile.velocity = normalize(self.enemy.origin - self.origin);
    missile.velocity = missile.velocity * dist; // instead of distance, was 600
    missile.velocity_z = 425;

    missile.avelocity = '300 300 300';

    missile.angles = vectoangles(missile.velocity);

    missile.touch = cultist_TNT_touch;

    setmodel (missile, "models/weapons/grenades/gr_tnt.md3");
    setsize (missile, '0 0 0', '0 0 0');
    setorigin (missile, self.origin);

};

void () cultist_TNT_touch =
{
    sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);
    T_RadiusDamage (self, self.owner, 130, world, "grenade"); // FIXME: Make w_bomb.qc defines global?
    BecomeExplosion ();
};
