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


void(float damage) Voodoo_ApplyDamage;


//============================================================================

// ----- Voodoo Doll model ----- //

$modelname v_voodoo

// idle
$frame voodoo_idle1

#ifndef NEW_MODELS
// stab stomach
$frame voodoo_stomach1 voodoo_stomach2 voodoo_stomach3 voodoo_stomach4

// stab eye
$frame voodoo_eye1 voodoo_eye2 voodoo_eye3 voodoo_eye4

// stab shoulder
$frame voodoo_shlder1 voodoo_shlder2 voodoo_shlder3 voodoo_shlder4

// stab groin
$frame voodoo_groin1 voodoo_groin2 voodoo_groin3 voodoo_groin4

// sit-up animation
$frame voodoo_situp1 voodoo_situp2 voodoo_situp3

// alt-fire mode
$frame voodoo_alt1 voodoo_alt2 voodoo_alt3 voodoo_alt4 voodoo_alt5
$frame voodoo_alt6 voodoo_alt7 voodoo_alt8

// draw
$frame voodoo_draw1 voodoo_draw2 voodoo_draw3 voodoo_draw4

// holster
$frame voodoo_holster1 voodoo_holster2 voodoo_holster3 voodoo_holster4


#else
// draw
$frame voodoo_draw1 voodoo_draw2 voodoo_draw3

// stab stomach
$frame voodoo_stomach1 voodoo_stomach2 voodoo_stomach3 voodoo_stomach4

// stab eye
$frame voodoo_eye1 voodoo_eye2 voodoo_eye3 voodoo_eye4

// stab shoulder
$frame voodoo_shlder1 voodoo_shlder2 voodoo_shlder3 voodoo_shlder4

// stab groin
$frame voodoo_groin1 voodoo_groin2 voodoo_groin3 voodoo_groin4 voodoo_groin5
$frame voodoo_groin6

// miss stab
$frame voodoo_thumb1 voodoo_thumb2 voodoo_thumb3 voodoo_thumb4

// sit-up animation
$frame voodoo_situp1 voodoo_situp2

// alt-fire mode
$frame voodoo_alt1 voodoo_alt2 voodoo_alt3 voodoo_alt4 voodoo_alt5
$frame voodoo_alt6 voodoo_alt7 voodoo_alt8 voodoo_alt9 voodoo_alt10

// holster
$frame voodoo_holster1 voodoo_holster2 voodoo_holster3
#endif


// ----- Player related code ----- //

void() player_voodoo =
{
    self.weaponframe = self.weaponframe + 1;
#ifndef NEW_MODELS
    if (self.weaponframe == $voodoo_situp1 ||
#else
    if (self.weaponframe == $voodoo_thumb1 ||
#endif
        self.weaponframe == $voodoo_groin1 ||
        self.weaponframe == $voodoo_eye1   ||
        self.weaponframe == $voodoo_shlder1 )
    {
        player_run ();
        self.weaponframe = $voodoo_idle1;
    }
};

void() player_voodoo1 = [$attack1, player_voodoo2] { player_voodoo (); };
void() player_voodoo2 = [$attack2, player_voodoo1] { player_voodoo (); };

void() player_altvoodoo1 = [$attack2, player_altvoodoo2] { self.weaponframe = $voodoo_alt1; };
void() player_altvoodoo2 = [$attack2, player_altvoodoo3] { self.weaponframe = $voodoo_alt2; };
void() player_altvoodoo3 = [$attack2, player_altvoodoo4] { self.weaponframe = $voodoo_alt3; };
void() player_altvoodoo4 = [$attack2, player_altvoodoo5] { self.weaponframe = $voodoo_alt4; };
#ifndef NEW_MODELS
void() player_altvoodoo5 = [$attack1, player_altvoodoo6]
{
    local float damage;

    self.weaponframe = $voodoo_alt5;
    damage = self.ammo_voodoo;
    Voodoo_ApplyDamage (damage);
};
void() player_altvoodoo6 = [$attack1, player_altvoodoo7] { self.weaponframe = $voodoo_alt6; };
void() player_altvoodoo7 = [$attack2, player_altvoodoo8] { self.weaponframe = $voodoo_alt7; };
void() player_altvoodoo8 = [$attack2, player_altvoodoo9] { self.weaponframe = $voodoo_alt8; };
void() player_altvoodoo9 = { W_DrawWeapon (W_BestWeapon ()); };
#else
void() player_altvoodoo5  = [$attack1, player_altvoodoo6 ] { self.weaponframe = $voodoo_alt5;  };
void() player_altvoodoo6  = [$attack1, player_altvoodoo7 ] { self.weaponframe = $voodoo_alt6;  };
void() player_altvoodoo7  = [$attack2, player_altvoodoo8 ]
{
    local float damage;

    self.weaponframe = $voodoo_alt7;
    damage = self.ammo_voodoo;
    Voodoo_ApplyDamage (damage);
};
void() player_altvoodoo8  = [$attack2, player_altvoodoo9 ] { self.weaponframe = $voodoo_alt8;  };
void() player_altvoodoo9  = [$attack2, player_altvoodoo10] { self.weaponframe = $voodoo_alt9;  };
void() player_altvoodoo10 = [$attack2, player_altvoodoo11] { self.weaponframe = $voodoo_alt10; };
void() player_altvoodoo11 = { W_DrawWeapon (W_BestWeapon ()); };
#endif

// Draw
void() player_voodoodraw1 = [$attack2, player_voodoodraw2] { self.weaponframe = $voodoo_draw1; };
void() player_voodoodraw2 = [$attack2, player_voodoodraw3] { self.weaponframe = $voodoo_draw2; };
#ifndef NEW_MODELS
void() player_voodoodraw3 = [$attack2, player_voodoodraw4] { self.weaponframe = $voodoo_draw3; };
void() player_voodoodraw4 = [$attack2, player_run        ] { self.weaponframe = $voodoo_draw4; };
#else
void() player_voodoodraw3 = [$attack2, player_run        ] { self.weaponframe = $voodoo_draw3; };
#endif

// Holster
void() player_voodooholster1 = [$attack2, player_voodooholster2] { self.weaponframe = $voodoo_holster1; };
void() player_voodooholster2 = [$attack2, player_voodooholster3] { self.weaponframe = $voodoo_holster2; };
void() player_voodooholster3 = [$attack2, player_voodooholster4] { self.weaponframe = $voodoo_holster3; };
#ifndef NEW_MODELS
void() player_voodooholster4 = [$attack2, player_voodooholster5] { self.weaponframe = $voodoo_holster4; };
void() player_voodooholster5 = [$attack2, player_run           ] { W_DrawWeapon (self.newweapon); };
#else
void() player_voodooholster4 = [$attack2, player_run           ] { W_DrawWeapon (self.newweapon); };
#endif


//============================================================================

/*
================
Voodoo_ApplyDamage

Apply the spiritual damage of the voodoo doll
================
*/
void(float damage) Voodoo_ApplyDamage =
{
    local entity targ;

    targ = SUB_GetPointedPlayer (0.15);

    // If we had a target that can be damaged and seems alive
    if (targ != world && targ.takedamage)
    {
        SpawnBlood (targ.origin, '0 0 0', damage);
    }
    // Else, WE take the damage
    else
    {
        targ = self;
        damage = 1;
    }

    // We don't consume ammo if we don't hit a target (except for altfire)
    if (self.player_state == PS_ALTFIRE)
        self.ammo_voodoo = 0;
    else if (targ != self)
        self.ammo_voodoo = self.ammo_voodoo - damage / 4;
    self.currentammo = self.ammo_voodoo;

    T_Damage (targ, self, self, damage, DF_MIND, "voodoo");
};


/*
================
Voodoo_Stab

Do a normal attack with the voodoo doll
================
*/
float() Voodoo_Stab =
{
    local float damage;
    local float stab_type;

    stab_type = random()*4;
    damage = random();
    if (stab_type >= 3) // Stab Groin
    {
        self.weaponframe = $voodoo_groin1;
        damage = damage*49 + 4;
    }
    else if (stab_type >= 2) // Stab Shoulder (supposed to make player lower weapon in MP mode)
    {
        self.weaponframe = $voodoo_shlder1;
        damage = damage*9 + 4;
    }
    else if (stab_type >= 1) // Stab Chest
    {
        self.weaponframe = $voodoo_stomach1;
        damage = damage*17 + 4;
    }
    else if (stab_type < 1) // Stab Eye (supposed to blind player in MP mode)
    {
        self.weaponframe = $voodoo_eye1;
        damage = damage*11 + 4;
    }
    else
        sprint (self, "There's a problem with the voodoo doll code\n");

    // Play the appropriate sound
    if (stab_type >= 3)  // Stab Groin
        sound (self, CHAN_WEAPON, "weapons/voodoodl/voolaugh.wav", 1, ATTN_NORM);
    else
        sound (self, CHAN_WEAPON, "weapons/voodoodl/voostab.wav", 1, ATTN_NORM);

    return damage;
};


/*
============
Voodoo_Attack

Attack code for the voodoo doll
============
*/
void() Voodoo_Attack =
{
    local float damage;

    muzzleflash ();

    // Alt-fire mode
    if (self.button3 && self.ammo_voodoo >= 1)
    {
        self.player_state = PS_ALTFIRE;

        sound (self, CHAN_WEAPON, "weapons/voodoodl/voochant.wav", 1, ATTN_NORM);
        player_altvoodoo1 ();

        self.attack_finished = time + 1.5;
    }

    // Normal fire mode
    else
    {
        self.player_state = PS_FIRE;

        damage = Voodoo_Stab ();
        self.nextthink = time + 0.1;
        self.think = player_voodoo1;
        Voodoo_ApplyDamage (damage);

        self.attack_finished = time + 0.5;
    }
};


/*
============
Voodoo_Draw

Draw code for the voodoo doll
============
*/
void() Voodoo_Draw =
{
    self.weapon = IT_VOODOO_DOLL;
    self.currentammo = self.ammo_voodoo;
    self.items = self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_CELLS | IT_ROCKETS));

    Voodoo_UpdateView ();

    #ifndef NEW_MODELS
    self.attack_finished = time + 0.4;
    #else
    self.attack_finished = time + 0.3;
    #endif
    player_voodoodraw1 ();
};


/*
============
Voodoo_Holster

Holster code for the voodoo doll
============
*/
void() Voodoo_Holster =
{
    #ifndef NEW_MODELS
    self.attack_finished = time + 0.4;
    #else
    self.attack_finished = time + 0.3;
    #endif
    player_voodooholster1 ();
};


/*
============
Voodoo_UpdateView

Choose the right voodoo doll model to display
============
*/
void() Voodoo_UpdateView =
{
    #ifndef NEW_MODELS
    self.weaponmodel = "progs/v_voodoo.mdl";
    #else
    self.weaponmodel = "models/weapons/v_voodoo.md3";
    #endif
    self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};
