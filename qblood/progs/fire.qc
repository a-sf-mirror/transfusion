//==========================================================================
//  fire.qc -- by Patrick Martin                Last updated:  7-11-2001
//--------------------------------------------------------------------------
//  Fire acts like poison.  When a target is infected, it burns.
//  The target loses one hit point for each frame it burns.
//  The flames can be snuffed by diving under the surface of
//  water or other liquid.
//
//  FIXME:  Use time instead of hit points.
//==========================================================================

#include "common.qh"

//--------------------//
//  NEW EDICT FIELDS  //
//--------------------//
.entity burner;         // The flame generator linked on an entity.

// FIXME:  Moved these elsewhere.
.float      armor_fire;
.float      armor_body;
.float      armor_mind;


//==========================================================================
//  Frame Data

//  Frame Macros for modified 'flame2.mdl'.
$cd id1/models/flame2
$origin 0 0 12
$base base		
$skin skin

// These are grouped scenes.
$frame  flame
$frame  flameb

// These scenes are not grouped.
$frame  ember1 ember2 ember3 ember4 ember5 ember6


//==========================================================================
//  General Fire Code

//----------------------------------------------------/ New Code /--------//
//  This precaches the fire-related files used by the fire code.
//------------------------------------------------------------------------//
void() PM_PrecacheFire =
{
    precache_model ("progs/flame2.mdl");

    // FIXME:  Maybe place elsewhere with flaregun item code.
    precache_model ("progs/s_oldexp.spr");
    precache_sound2 ("weapons/flaregun/burstflm.wav");
};

//----------------------------------------------------/ New Code /--------//
//  This spawns and returns a brand new flame.
//------------------------------------------------------------------------//
entity(entity attacker, entity victim, vector spot) PM_NewFire =
{
    local   entity  fire;

    fire = spawn();
    setmodel (fire, "progs/flame2.mdl");
    setsize (fire, '0 0 0', '0 0 0');
    setorigin (fire, spot);

    fire.solid      = SOLID_NOT;
    fire.takedamage = DAMAGE_NO;
    fire.frame      = $flame;
    fire.owner      = attacker;
    fire.enemy      = victim;
    fire.classname  = "fire";
    fire.netname    = "fire";

    return fire;
};


//==========================================================================
//  ???

void(entity targ, entity inflictor, entity attacker, float damage,
    float dflags, string dtype) T_NewDamage;

//----------------------------------------------------/ New Code /--------//
//  This makes an entity do a think function right now.
//------------------------------------------------------------------------//
void(entity ent, void() thinkst) PM_Think =
{
    local   entity  oself;

    oself = self;
    self = ent;
    thinkst ();
    self = oself;
};

//----------------------------------------------------/ New Code /--------//
//  This checks if a given point in space is in water.
//------------------------------------------------------------------------//
float(vector vec) PM_VecInWater =
{
    local   float   content;

    content = pointcontents (vec);

    if (content == CONTENT_WATER)
        return TRUE;
    if (content == CONTENT_SLIME)
        return TRUE;
    if (content == CONTENT_LAVA)
        return TRUE;

    // Not in water.
    return FALSE;
};

//----------------------------------------------------/ New Code /--------//
//  This returns the water level of an entity.
//------------------------------------------------------------------------//
float(entity ent) PM_WaterLevel =
{
    local   vector  spot;

    spot = ent.origin;
    spot_z = ent.origin_z + ent.view_ofs_z;
    if (PM_VecInWater (spot))
        return 3;
    spot_z = ent.origin_z + (ent.mins_z + ent.maxs_z) * 0.5;
    if (PM_VecInWater (spot))
        return 2;
    spot_z = ent.origin_z + ent.mins_z + 1;
    if (PM_VecInWater (spot))
        return 1;
    return 0;
};


//==========================================================================
//  Fire Damage

void(entity victim, entity attacker, float burn) PM_Ignite;

void(entity ent) PM_RemoveFlares;
void() muzzleflash;

#ifndef QUAKEWORLD
//----------------------------------------------------/ New Code /--------//
//  This checks if entity resists fire.
//------------------------------------------------------------------------//
float(entity ent) PM_FireResistant =
{
    if (ent.classname == "monster_shambler")
        return TRUE;

    // Everything not listed takes normal damage from fire.
    return FALSE;
};
#endif

//----------------------------------------------------/ New Code /--------//
//  This damages a single entity and possibly sets it on fire.
//------------------------------------------------------------------------//
void(entity victim, entity fire, float damage, float burn) PM_BurnDamage =
{
    // Set victim on fire first.
    if (burn > 0)
        PM_Ignite (victim, fire.owner, burn);

    // Apply damage next immediately.
    if (damage > 0)
        T_NewDamage (victim, fire, fire.owner, damage, DF_FIRE, fire.deathtype);
};

//----------------------------------------------------/ New Code /--------//
//  This damages and ignites entities within a certain radius.
//
//  NOTE:  Targets take damage multipled by a fraction equal to
//         one minus the distance divided by the radius.  At the
//         point of fire's origin, damage is 100%.  At maximum
//         distance (i.e, equal to radius), damage is 0%.
//------------------------------------------------------------------------//
void(entity fire, float damage, float burn, entity ignore) PM_BurnRadius =
{
    local   float   fade;       // Distance multiplier.
    local   float   radius;

    if (fire.height > 0)
    {
        radius = fire.height;
        fade = 0.5;     // Targets take 50% damage at maximum distance.
    }
    else
    {
        // Emulate default radius damage.
        fade = floor(damage + burn);
        if (fade <= 0)
            return;     // Too weak to damage.

        radius = fade + 40;
        fade = radius * 0.5 / fade;
    }

    local   entity  head;

    head = findradius(fire.origin, radius);

    // General case -- radius damage decreases linearly from the center.
    local   vector  org;
    local   float   dist;

    while (head)
    {
        if (head != ignore)
            if (CanDamage (head, fire))
            {
                org = head.origin + (head.mins + head.maxs)*0.5;
                dist = vlen (fire.origin - org);
                dist = 1 - (dist * fade / radius);
//                if (head == fire.owner)
//                    dist = dist * 0.5;  // Attacker takes 1/2 damage.
                PM_BurnDamage (head, fire, damage * dist, burn * dist);
            }

        head = head.chain;
    }
};


//==========================================================================
//  Custom Explosions

//----------------------------------------------------/ New Code /--------//
//  This makes some smoke.
//
//  FIXME:  Useless in QW.
//------------------------------------------------------------------------//
void(entity fire) PM_MakeSmoke =
{
    #ifndef QUAKEWORLD
    particle (fire.origin, '0 0 100', 6, 50);
    #endif
};

//----------------------------------------------------/ New Code /--------//
//  This make some steam.
//------------------------------------------------------------------------//
void(entity fire) PM_MakeSteam =
{
    sound (fire, CHAN_AUTO, "player/slimbrn2.wav", 1, ATTN_NORM);
    PM_MakeSmoke (fire);
};


//==========================================================================
//  Burn Control

//----------------------------------------------------/ New Code /--------//
//  This extinguishes the fire burning on a player (or other entity).
//  This function should be called whenever the fire burning on an
//  entity must be removed immediately.
//
//  Examples who and when this should be called for:
//  * All players (and their surrogates) when the level ends.
//  * Anytime a player respawns after dying (from the 'kill' command).
//------------------------------------------------------------------------//
void(entity ent) PM_KillBurner =
{
    // Check if the entity is linked to a burning flame.
    if (ent.burner)
    {
        // Unlink and remove the burning flame.
        remove (ent.burner);
        ent.burner = world;
    }

    // Remove the flares too.
    PM_RemoveFlares (ent);
};

//----------------------------------------------------/ New Code /--------//
//  This checks if 'ent' is on fire and burning.
//------------------------------------------------------------------------//
float(entity ent) PM_IsBurning =
{
    return ent.burner;
};

//----------------------------------------------------/ New Code /--------//
//  These animate the embers that rise from a burning entity.
//------------------------------------------------------------------------//
void()  m_ember1 =[   $ember1,    m_ember2] {};
void()  m_ember2 =[   $ember2,    m_ember3] {};
void()  m_ember3 =[   $ember3,    m_ember4] {};
void()  m_ember4 =[   $ember4,    m_ember5] {};
void()  m_ember5 =[   $ember5,    m_ember6] {};
void()  m_ember6 =[   $ember6,    SUB_Remove] {};

//----------------------------------------------------/ New Code /--------//
//  This makes flaming embers rise from a burning victim.
//
//  NOTE:  Assumes 'self' == flame generator!
//------------------------------------------------------------------------//
void() PM_MakeEmbers =
{
    local   entity  fire;       // The new fire that will be created.
    local   vector  spot;       // The spot where the new fire will appear.
    local   float   loop, r;

    #ifdef QUAKEWORLD
    if ((floor(time * 10) & 3) == 0)
        return;     // No flames on each 4th frame.
    loop = 1;
    #else
    if (deathmatch || coop)
    {
        // In netgames, keep flames down to a minimum.
        if ((floor(time * 10) & 3) == 0)
            return;     // No flames on each 4th frame.
        loop = 1;
    }
    else if (self.dmg > 100)
        loop = 2;
    else if (self.dmg > 50)
    {
        if (floor(time * 10) & 1)
            loop = 2;
        else
            loop = 1;
    }
    else
        loop = 1;
    #endif

    while (loop > 0)
    {
        spot   = self.enemy.size * 0.5;
        spot_x = spot_x * (random() - 0.5);
        spot_y = spot_y * (random() - 0.5);
        spot_z = spot_z * (random() - 0.5);
        spot   = spot + self.enemy.origin +
            (self.enemy.mins + self.enemy.maxs) * 0.5;

        // Create the fire.
        fire = spawn();
        setmodel (fire, "progs/flame2.mdl");
        setsize (fire, '0 0 0', '0 0 0');
        setorigin (fire, spot);

        fire.solid      = SOLID_NOT;
        fire.takedamage = DAMAGE_NO;
        fire.frame      = $ember1;
        fire.owner      = self.enemy;
        fire.movetype   = MOVETYPE_FLY;
        fire.velocity   = '0 0 100';

        // Animate the flame.
        r = random() * 3;
        if (r > 2)
            PM_Think (fire, m_ember3);
        else if (r > 1)
            PM_Think (fire, m_ember2);
        else
            PM_Think (fire, m_ember1);

        // Advance the loop.
        loop = loop - 1;
    }
};

//----------------------------------------------------/ New Code /--------//
//  This keeps the fire on an entity burning.
//------------------------------------------------------------------------//
void() PM_Burn =
{
    // Check for removal.
    if (self.dmg <= 0)
    {
        // Fuel is all gone.
        self.enemy.burner = world;
        remove (self);
        return;
    }
    if (self.enemy.think == SUB_Remove)
        if (self.enemy.nextthink + 1 < time)
        {
            // Enemy will be removed from the game.
            self.enemy.burner = world;
            remove (self);
            return;
        }

    // Check if victim is deep enough in water.
    local   vector  spot;

    if (self.enemy.view_ofs == '0 0 0')
        spot = self.enemy.origin + (self.enemy.mins + self.enemy.maxs) * 0.5;
    else
        spot = self.enemy.origin + self.enemy.view_ofs;

    if (PM_VecInWater (spot))
    {
        // Victim is submerged under some liquid.
        setorigin (self, spot);     // So steam comes from enemy.

        // Put out the fire and make some steam.
        self.enemy.burner = world;
        PM_MakeSteam (self);
        remove (self);
        return;
    }

    // Don't let victim burn for more than 20 seconds (default).
    // 200 * 0.1 sec. = 20 sec.
    if (self.dmg > 200)
        self.dmg = 200;

    // Keep on burning.
    PM_MakeEmbers ();

    if (self.wait < time)
    {
        // Damage the victim.
        local   float   damage, dflags;

        damage = 1;
        if (damage > self.dmg)
            damage = self.dmg;
        self.dmg = self.dmg - damage;   // Update the burn damage limit.

        dflags = DF_FIRE | DF_MIN_PAIN;
        self.lefty = self.lefty + (damage * 0.5);
        if (self.lefty >= 1)
            self.lefty = self.lefty - floor(self.lefty);
        else
            dflags = dflags | DF_ALT_SAVE;

        #ifndef QUAKEWORLD
        if (!PM_FireResistant (self.enemy))
        #endif
            T_NewDamage (self.enemy, self.enemy, self.owner, damage, dflags, "fire");

        // The fire can burn again after a moment.
        self.wait = 0;
    }

    self.nextthink  = time + 0.1;
};

//----------------------------------------------------/ New Code /--------//
//  This sets the victim on fire.
//------------------------------------------------------------------------//
void(entity victim, entity attacker, float burn) PM_Ignite =
{
    // Check for fire immunity.
    if (!victim.takedamage)
        return;     // Immune to damage.

    // FIXME:  If not a creature, don't burn.

    // Check if the entity is linked to a burning flame.
    if (victim.burner)
    {
        // Add fuel to fire.  Yes, fire can be stolen by another attacker.
        victim.burner.dmg   = victim.burner.dmg + burn;
        victim.burner.owner = attacker;
        return;
    }

    // Spawn the burner (flame generator).
    local   entity  fire;

    fire = spawn();
    setmodel (fire, string_null);
    setsize (fire, '0 0 0', '0 0 0');
    setorigin (fire, VEC_ORIGIN);       // Doesn't matter where it is.
    fire.solid      = SOLID_NOT;
    fire.takedamage = DAMAGE_NO;
    fire.frame      = 0;
    fire.owner      = attacker;
    fire.enemy      = victim;
    fire.classname  = "burner";
    fire.deathtype  = "fire";
    fire.wait       = time;
    fire.dmg        = burn;
//    fire.cnt        = 0;
    fire.lefty      = 0;
    fire.nextthink  = 0.1;      // ASAP
    fire.think      = PM_Burn;

    victim.burner   = fire;     // Link entity to fire.
};


//==========================================================================
//  Flaming Death

// NOTE:  Used by monsters only.

#ifndef QUAKEWORLD
void() PM_BecomeOldExplosion;
//----------------------------------------------------/ New Code /--------//
//  The creates an explosion entity from scratch.
//------------------------------------------------------------------------//
void(vector spot) PM_MakeExplosion =
{
    local   entity  e;

    e = spawn();
    setmodel (e, "progs/s_explod.spr");
    setsize (e, '0 0 0', '0 0 0');        
    setorigin (e, spot);

    PM_Think (e, PM_BecomeOldExplosion);
};

//----------------------------------------------------/ New Code /--------//
//  This makes the death flame produce a little smoke and embers
//  before it disappears.
//------------------------------------------------------------------------//
void() PM_DeathFlameDying =
{
    if (self.wait <= time)
    {
        // Done burning.
        remove (self);
        return;
    }

    local   vector  spot;

    makevectors (self.enemy.angles);
    spot = self.enemy.origin + (v_forward * self.dest_x) +
        (v_right * self.dest_y) + (v_up * self.dest_z);
    setorigin (self, spot);

    // Make a thin trail of smoke above the flame, plus a few embers.
    local   float   ftime;
    ftime = floor(time * 10);
    if (ftime & 1)
    {
        particle (spot, '0 0 100', 6, 5);
        if (!PM_VecInWater (spot))
            if ((ftime & 2) || (random() < 0.5))
                PM_MakeEmbers ();
    }

    self.nextthink = time + 0.1;
};

//----------------------------------------------------/ New Code /--------//
//  This checks if the death flame should stop burning.
//------------------------------------------------------------------------//
float() PM_EndDeathFlame =
{
    // Stop burning once the enemy is really dead.
    if (self.enemy.deadflag == DEAD_DEAD)
        return TRUE;

    // If solid-only burn is on, then stop once enemy becomes non-solid.
    if (self.style)
        if (self.enemy.solid == SOLID_NOT)
            return TRUE;

    // Keep on burning.
    return FALSE;
};

//----------------------------------------------------/ New Code /--------//
//  This makes the death flame burn.
//------------------------------------------------------------------------//
void() PM_DeathFlameThink =
{
    if (PM_EndDeathFlame ())
    {
        // Done burning.
        if (self.model == self.mdl)
        {
            PM_MakeExplosion (self.origin);
            setmodel (self, string_null);
        }
        self.think = PM_DeathFlameDying;
        self.wait = time + 1 + random() * 2;
        PM_DeathFlameDying ();
        return;
    }

    // Make the flame stick to its target.
    local   vector  spot;

    makevectors (self.enemy.angles);
    spot = self.enemy.origin + (v_forward * self.dest_x) +
        (v_right * self.dest_y) + (v_up * self.dest_z);
    setorigin (self, spot);

    // Make a thin trail of smoke above the flame, plus a few embers.
    particle (spot + '0 0 24', '0 0 100', 6, 5);
    if (floor(time * 10) & 1)
        PM_MakeEmbers ();

    // In case enemy is not dead, do some damage.
    if (self.enemy.takedamage)
        T_Damage (self.enemy, self, self.owner, 1);

    // Flame has different effects depending on its contents.
    if (PM_VecInWater (spot))
    {
        // Hide the flame and make more steam in its place.
        if (self.model == self.mdl)
        {
            setmodel (self, string_null);
            sound (self, CHAN_AUTO, "player/slimbrn2.wav", 1, ATTN_NORM);
        }
        particle (spot, '0 0 100', 6, 50);
    }
    else
    {
        if (self.model != self.mdl)
        {
            PM_MakeExplosion (spot);
            setmodel (self, self.mdl);
        }

        // Burn nearby enemies.
        local   entity  head;

        head = findradius(self.origin, 60);
        while (head)
        {
            if (head != self.enemy)
                if (CanDamage (head, self))
                    T_Damage (head, self, self.owner, 1);

            head = head.chain;
        }
    }

    self.nextthink = time + 0.1;
};

//----------------------------------------------------/ New Code /--------//
//  This spawns a large burning flame on a dying target.  This should
//  be called ONLY from the target's 'th_die()' function.
//
//  NOTE:  Assumes 'self' == dying victim to be burned!
//------------------------------------------------------------------------//
void(vector offset) PM_DeathFlame =
{
    // Make some fire!
    local   entity  fire;       // The new fire that will be created.
    local   vector  spot;       // The spot where the new fire will appear.

    // Get the spot where the fire will erupt.
    spot = self.origin + offset;

    // Make a small flaming explosion.
    PM_MakeExplosion (spot);

    // Remove flame generator if any... since this is a bigger fire.
    PM_KillBurner (self);

    // Create the fire.
    fire = PM_NewFire (self.enemy, self, spot);
    fire.frame      = $flameb;  // Use a *big* flame.
    fire.effects    = fire.effects | EF_DIMLIGHT;
    fire.mdl        = fire.model;
    fire.dest       = offset;
    fire.nextthink  = 0.1;  // ASAP
    fire.think      = PM_DeathFlameThink;

    // HACK:  Zombie...
    if (self.classname != "monster_zombie")
        fire.style = TRUE;
    else
        fire.style = FALSE;

    // Play some sound.
    sound (fire, CHAN_AUTO, "weapons/flaregun/burstflm.wav", 1, ATTN_NORM);
};
#endif


////////////////////////////////////////////////////////////////////////////
//  Flame weapons (flares and napalm)
////////////////////////////////////////////////////////////////////////////

.float  flare_time;     // Used so only one flare can burn per frame.


//==========================================================================
//  Embers

// FIXME:  Embers can be done much more efficiently with a TE -- use
//         a custom engine.

//----------------------------------------------------/ New Code /--------//
//  This enforces air resistance on embers and updates their angles.
//------------------------------------------------------------------------//
void() PM_EmberThink =
{
    if (self.pausetime <= time)
    {
        m_ember4 ();
        return;
    }

    local   vector  dir;

    dir = normalize (self.velocity);

    // Cheap hack -- apply air resistance by reducing velocity.
    self.velocity = self.velocity * 0.75;

    // Update angles to its current direction.
    self.angles = vectoangles(dir) + '90 0 0';

    // Think again next frame.
    self.nextthink = time + 0.1;
};

//----------------------------------------------------/ New Code /--------//
//  This throws a shower of embers.
//------------------------------------------------------------------------//
void(float ents) PM_ThrowEmbers =
{
    // Not in QuakeWorld!
    #ifdef QUAKEWORLD
    return;
    #endif

    local   entity  fire;
    local   vector  dir;
    local   float   loop;

    // Make fewer embers in netgames.
    #ifndef QUAKEWORLD
    if (deathmatch || coop)
        ents = floor(ents * 0.5);
    #endif

    loop = ents * 6;
    while (loop > 0)
    {
        // Get initial direction.
        dir_x = (random() - 0.5) * 180;
        dir_y = random() * 360;
        dir_z = 0;
        makevectors (dir);
        dir = v_forward;

        traceline (self.origin, self.origin + dir*64, FALSE, other);
        if (trace_fraction == 1.0)
        {
            // Ember will not impact the wall immediately.
            fire = PM_NewFire (other, other, self.origin);
            fire.frame    = 5;
            fire.solid    = SOLID_BBOX;
            fire.movetype = MOVETYPE_TOSS;

            fire.velocity = dir * (200 + random() * 800);
            fire.angles = vectoangles(dir) + '90 0 0';

            #ifdef QUAKEWORLD
            fire.pausetime = time + random();
            #else
            // Make embers disappear faster in netgames.
            if (deathmatch || coop)
                fire.pausetime = time + random();
            else
                fire.pausetime = time + 3 + random() * 2;
            #endif

            fire.touch = SUB_Remove;
            fire.nextthink = time + 0.1;
            fire.think = PM_EmberThink;

            ents = ents - 1;
            if (ents <= 0)
                return;
        }

        loop = loop - 1;
    }
};


//==========================================================================
//  Standard Flares

//----------------------------------------------------/ New Code /--------//
//  This removes all flares from a single entity.
//  This should be called when a player disconnects from the server.
//------------------------------------------------------------------------//
void(entity ent) PM_RemoveFlares =
{
    local   entity  head;

    head = find (world, classname, "flare");
    while (head)
    {
        if (head.enemy == ent)
        {
            // Can't remove now, we need head for finding more flares.
            head.nextthink  = time + 0.1;
            head.think      = SUB_Remove;
        }
        head = find (head, classname, "flare");
    }
};

//----------------------------------------------------/ New Code /--------//
//  This causes the flare to emit sparks.
//------------------------------------------------------------------------//
void() PM_FlareSpark =
{
// FIXME:  Use better particle effects -- custom source port recommended.

// FIXME(2):  Currently, this does NOTHING in QW.  Without a particle
//   function, the only way to produce a spawn shower is to create an
//   entity for each spark, and that is bad for netplay.

    #ifndef QUAKEWORLD
    particle (self.origin, '0 0 50', 151, 32);
    #endif
};

//----------------------------------------------------/ New Code /--------//
//  This makes the flare stick to its target.
//
//  FIXME:  If the game has client prediction, the flare can appear to
//    lag for the client stuck by said the flare, since the client's view
//    may not match his true origin.  Of course, other clients can see
//    the flare sticking perfectly to the client.
//
//  PM -- I assume QuakeWorld has client prediction like in Quake2.
//------------------------------------------------------------------------//
void() PM_FlareStick =
{
    local   vector  spot;
    local   float   dist, least;

    // Find maximum distance from origin the flare is allowed to go.
    dist = self.enemy.maxs_x - self.enemy.mins_x;
    least = self.enemy.maxs_y - self.enemy.mins_y;
    if (least < dist)
        dist = least;
    least = self.enemy.maxs_z - self.enemy.mins_z;
    if (least < dist)
        dist = least;
    dist = dist / 4;

    // Get the proper angles.
    spot_x = self.enemy.angles_x - self.dest_x;
    spot_y = self.enemy.angles_y + self.dest_y;
    spot_z = 0;

    // Place the flare.
    makevectors (spot);
    spot = (self.enemy.origin + (self.enemy.mins + self.enemy.maxs)*0.5) +
        (v_forward * dist);
    setorigin (self, spot);
};

//----------------------------------------------------/ New Code /--------//
//  Here, the flare sticks and burns its target.
//------------------------------------------------------------------------//
void() PM_FlareThink =
{
    if (self.cnt <= 0)
    {
        remove (self);
        return;
    }
    if (self.enemy.health <= 0)
    {
        remove (self);
        return;
    }

    // Make the flame stick to its target.
    PM_FlareStick ();
    PM_FlareSpark ();

    local   float   damage, nextframe;

    nextframe = time + 0.1;

    damage = 1;
    if (damage > self.cnt)
        damage = self.cnt;
    self.cnt = self.cnt - damage;

    if (self.enemy.flare_time <= time)
    {
        // Only one flare can damage at any given frame.
        self.enemy.flare_time = nextframe;

        // Do burn damage if not already burning.
        if (!self.enemy.burner)
        {
            #ifndef QUAKEWORLD
            if (!PM_FireResistant (self.enemy))
            #endif
                T_NewDamage (self.enemy, self, self.owner, damage, DF_MIN_PAIN | DF_FIRE, "fire");
        }
    }

    self.nextthink = nextframe;
};

//----------------------------------------------------/ New Code /--------//
//  Called when flare impacts.
//------------------------------------------------------------------------//
void() PM_FlareTouch =
{
    if (other.solid == SOLID_TRIGGER)
        return; // trigger field, do nothing

    #ifdef QUAKEWORLD
    if (self.voided)
        return;
    self.voided = 1;
    #endif

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
        remove(self);
        return;
    }

    // hit something that bleeds
    if (other.takedamage)
    {
        if (other.flags & FL_MONSTER)
        {
            PM_BurnDamage (other, self, self.dmg, 0);

            // Change flare properties so it can stick without interference.
            self.velocity   = '0 0 0';
            self.solid      = SOLID_NOT;
            self.movetype   = MOVETYPE_NONE;
            self.enemy      = other;
            self.angles     = '180 0 0';    // Turn flame upside-down.

            // Find difference of angles between the directions of the
            // enemy and the flare.
            self.dest   = other.origin + (other.mins + other.maxs)*0.5;
            self.dest   = normalize(self.origin - self.dest);
            self.dest   = vectoangles (self.dest);
            self.dest   = self.dest - other.angles;

            // Make the flame stick to its target.
            PM_FlareStick ();
            self.nextthink  = 0.1;
            self.think      = PM_FlareThink;

            return;
        }

        // Just set the target on fire.
        PM_BurnDamage (other, self, self.dmg, self.cnt);
    }

    PM_FlareSpark ();   // Throw a few sparks.
    remove (self);
};

//----------------------------------------------------/ New Code /--------//
//  Create and launch a fire.
//------------------------------------------------------------------------//
void(entity attacker, vector org, vector dir, float sped, float damage)
    PM_FireFlare =
{
    local   entity  fire;

    fire = PM_NewFire(attacker, attacker, org);
    #ifdef QUAKEWORLD
    fire.voided     = 0;
    #endif
    fire.skin       = 1;        // FIXME:  Temporary purple skin
    fire.effects    = fire.effects | EF_DIMLIGHT;
    fire.movetype   = MOVETYPE_FLYMISSILE;
    fire.solid      = SOLID_BBOX;
    fire.angles     = vectoangles(dir) + '90 0 0';
    fire.velocity   = dir * sped;
    fire.touch      = PM_FlareTouch;
    fire.nextthink  = time + (8000 / sped);
    fire.think      = SUB_Remove;
    fire.classname  = "flare";
    fire.netname    = "flare";
    fire.dmg        = damage;
    fire.cnt        = 50;       // Flares last five seconds.
};


//==========================================================================
//  Alt-mode Flares

//----------------------------------------------------/ New Code /--------//
//  This animates the napalm cloud, and makes it burn things around it.
//------------------------------------------------------------------------//
void() PM_OldExThink =
{
    if (self.frame >= 5)
    {
        remove (self);
        return;
    }
    self.frame = self.frame + 1;

    // Think again next frame.
    self.nextthink = time + 0.1;
};

//----------------------------------------------------/ New Code /--------//
//  Turns entity into a flaming napalm cloud.
//------------------------------------------------------------------------//
void() PM_BecomeOldExplosion =
{
    self.movetype   = MOVETYPE_NONE;
    self.velocity   = '0 0 0';
    self.touch      = SUB_Null;
    self.frame      = 0;
    setmodel (self, "progs/s_oldexp.spr");
    self.solid      = SOLID_NOT;

    self.nextthink  = time + 0.1;
    self.think      = PM_OldExThink;
};

//----------------------------------------------------/ New Code /--------//
//  Called when flare impacts.
//------------------------------------------------------------------------//
void() PM_AltFlareTouch =
{
    if (other.solid == SOLID_TRIGGER)
        return; // trigger field, do nothing

    #ifdef QUAKEWORLD
    if (self.voided)
        return;
    self.voided = 1;
    #endif

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
        remove(self);
        return;
    }

    // Explode!
    muzzleflash ();     // In qblood's 'player.qc'.

    // Do the damage.
    self.height = 80;
    PM_BurnRadius (self, self.dmg, self.cnt, other);
    self.origin = self.origin - 8*normalize(self.velocity);
    if (other.takedamage)
        PM_BurnDamage (other, self, self.dmg, self.cnt);

    // Make some fire.
    self.solid = SOLID_NOT;     // So embers can't touch 'self'.
    PM_ThrowEmbers (2);     // NOTE:  Used to throw 4.
    sound (self, CHAN_AUTO, "weapons/napalm/explodfs.wav", 1, ATTN_NORM);
    PM_BecomeOldExplosion ();
};

//----------------------------------------------------/ New Code /--------//
//  This causes the flare to change its path in mid-flight.
//------------------------------------------------------------------------//
void() PM_AltFlareThink =
{
    local   vector  dir, vec;

    dir = normalize (self.velocity);
    vec = vectoangles (dir);

    vec_x = 0 - vec_x;
    makevectors (vec);
    dir = (v_forward * self.dest_x) + (v_right * self.dest_y) +
        (v_up * self.dest_z);
    self.velocity = dir * self.speed;
    dir = normalize (self.velocity);
    self.angles = vectoangles(dir) + '90 0 0';

    self.nextthink = self.pausetime;
    self.think = SUB_Remove;
};

//----------------------------------------------------/ New Code /--------//
//  Create and launch a small fireball.
//------------------------------------------------------------------------//
void(entity attacker, vector org, vector dir, float sped, float damage,
    float burn) PM_FireAltFlares =
{
    local   entity  fire;
    local   vector  spread;
    local   float   loop;

    loop = 8;
    while (loop > 0)
    {
        fire = PM_NewFire(attacker, attacker, org);
        #ifdef QUAKEWORLD
        fire.voided     = 0;
        #endif
        fire.movetype   = MOVETYPE_FLYMISSILE;
        fire.skin       = 1;
	fire.effects    = fire.effects | EF_DIMLIGHT;
	fire.solid      = SOLID_BBOX;
        fire.angles     = vectoangles(dir) + '90 0 0';
        fire.velocity   = dir * sped;
        fire.touch      = PM_AltFlareTouch;
        fire.nextthink  = time + 0.4;   // Approximate time alt-flares split.
        fire.think      = PM_AltFlareThink;
        fire.pausetime  = time + (8000 / sped);
        fire.cnt        = burn;
        fire.dmg        = damage;
        fire.speed      = sped;

        if (loop == 8)
            fire.dest   = '1 0 0.15';
        else if (loop == 7)
            fire.dest   = '1 0.15 0';
        else if (loop == 6)
            fire.dest   = '1 0 -0.15';
        else if (loop == 5)
            fire.dest   = '1 -0.15 0';
        else if (loop == 4)
            fire.dest   = '1 0.05 0.05';
        else if (loop == 3)
            fire.dest   = '1 -0.05 0.05';
        else if (loop == 2)
            fire.dest   = '1 -0.05 -0.05';
        else if (loop == 1)
            fire.dest   = '1 0.05 -0.05';
        else
            fire.dest   = '1 0 0';      // This shouldn't happen.

        loop = loop - 1;
    }
};


//===========================/  END OF FILE  /===========================//
