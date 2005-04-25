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
==============================================================================

            SOURCE FOR GLOBALVARS_T C STRUCTURE

==============================================================================
*/

//
// system globals
//
entity  self;
entity  other;
entity  world;
float   time;
float   frametime;

float   force_retouch;  // force all entities to touch triggers
                        // next frame.  this is needed because
                        // non-moving things don't normally scan
                        // for triggers, and when a trigger is
                        // created (like a teleport trigger), it
                        // needs to catch everything.
                        // decremented each frame, so set to 2
                        // to guarantee everything is touched
string  mapname;

float   deathmatch;
float   coop;
float   teamplay;

float   serverflags;    // propagated from level to level, used to
                        // keep track of completed episodes

float   total_secrets;
float   total_monsters;

float   found_secrets;      // number of secrets found
float   killed_monsters;    // number of monsters killed


// spawnparms are used to encode information about clients across server
// level changes
float   parm1, parm2, parm3, parm4, parm5, parm6, parm7, parm8, parm9, parm10, parm11, parm12, parm13, parm14, parm15, parm16;

//
// global variables set by built in functions
//
vector  v_forward, v_up, v_right;   // set by makevectors()

// set by traceline / tracebox
float   trace_allsolid;
float   trace_startsolid;
float   trace_fraction;
vector  trace_endpos;
vector  trace_plane_normal;
float   trace_plane_dist;
entity  trace_ent;
float   trace_inopen;
float   trace_inwater;

entity  msg_entity;     // destination of single entity writes

//
// required prog functions
//
void()  main;                       // only for testing

void()  StartFrame;

void()  PlayerPreThink;
void()  PlayerPostThink;

void()  ClientKill;
void()  ClientConnect;
void()  PutClientInServer;  // call after setting the parm1... parms
void()  ClientDisconnect;

void()  SetNewParms;        // called when a client first connects to
                            // a server. sets parms so they can be
                            // saved off for restarts

void()  SetChangeParms;     // call to set parms for self so they can
                            // be saved for a level transition


//================================================
void    end_sys_globals;    // flag for structure dumping
//================================================

/*
==============================================================================

            SOURCE FOR ENTVARS_T C STRUCTURE

==============================================================================
*/

//
// system fields (*** = do not set in prog code, maintained by C code)
//
.float  modelindex;     // *** model index in the precached list
.vector absmin, absmax; // *** origin + mins / maxs

.float  ltime;          // local time for entity

.float  movetype;
.float  solid;

.vector origin;         // ***
.vector oldorigin;      // ***
.vector velocity;
.vector angles;
.vector avelocity;

.vector punchangle;     // temp angle adjust from damage or recoil

.string classname;      // spawn function
.string model;
.float  frame;
.float  skin;
.float  effects;

.vector mins, maxs;     // bounding box extents relative to origin
.vector size;           // maxs - mins

.void() touch;
.void() use;
.void() think;
.void() blocked;        // for doors or plats, called when can't push other

.float  nextthink;
.entity groundentity;

// stats
.float  health;
.float  frags;
.float  weapon;         // one of the IT_FLAREGUN, etc flags
.string weaponmodel;
.float  weaponframe;
.float  currentammo;
.float  ammo_shells, ammo_nails, ammo_rockets, ammo_cells;

.float  items;          // bit flags

.float  takedamage;
.entity chain;
.float  deadflag;

.vector view_ofs;       // add to origin to get eye point


.float  button0;        // fire
.float  button1;        // use
.float  button2;        // jump

.float  impulse;        // weapon changes

.float  fixangle;
.vector v_angle;        // view / targeting angle for players
.float  idealpitch;     // calculated pitch angle for lookup up slopes

.string netname;

.entity enemy;

.float  flags;

.float  colormap;
.float  team;

.float  max_health;     // players maximum health is stored here

.float  teleport_time;  // don't back up

.float  armortype;      // save this fraction of incoming damage
.float  armorvalue;

.float  waterlevel;     // 0 = not in, 1 = feet, 2 = wast, 3 = eyes
.float  watertype;      // a contents value

.float  ideal_yaw;
.float  yaw_speed;

.entity aiment;

.entity goalentity;     // a movetarget or an enemy

.float  spawnflags;

.string target;
.string targetname;

// damage is accumulated through a frame. and sent as one single
// message, so the super shotgun doesn't generate huge messages
.float  dmg_take;
.float  dmg_save;
.entity dmg_inflictor;

.entity owner;          // who launched a missile
.vector movedir;        // mostly for doors, but also used for waterjump

.string message;        // trigger messages

.float  sounds;         // either a cd track number or sound number

.string noise, noise1, noise2, noise3;  // contains names of wavs to play

//================================================
void    end_sys_fields;         // flag for structure dumping
//================================================

/*
==============================================================================

                VARS NOT REFERENCED BY C CODE

==============================================================================
*/

//
// globals
//
float   gameover;           // set when a rule exits

string  nextmap;

string  string_null;        // null string, nothing should be held here

entity  newmis;             // launch_spike sets this after spawning it

entity  activator;          // the entity that activated a trigger or brush

entity  damage_attacker;    // set by T_Damage
entity  damage_inflictor;

float   warmup_done;        // set to TRUE when the warmup has been done
float   warmup_counttime;   // used by the warmup countdown
float   warmup_endtime;     // set to 0 before AND after the warmup

float   starttime;          // when the game actually started

// cvars checked each frame
float timelimit;
float fraglimit;
float skill;
float skillbit;

float friendlyfire;

// USE THIS VARIABLE TO KNOW THE CURRENT GAME TYPE. The other ones are considered obsolete
// Set once for the entire game (when the world is spawned). cf GT_* values in common.qh
float gametype;

float intermission_running;

float modelindex_eyes, modelindex_player;

// Team scores
float team1score;
float team2score;

// Weapons that can be found into the current map (i.e. their resources
// have been precached). Used for the warmup and the "give all" cheat
float available_weapons;

// Number of the current map in the map cycle
float map_cycle;

//
// globals
//
float current_yaw;

//
// when a monster becomes angry at a player, that monster will be used
// as the sight target the next frame so that monsters near that one
// will wake up even if they wouldn't have noticed the player
//
entity sight_entity;
float sight_entity_time;
float movedist;

//================================================

//
// world fields (FIXME: make globals)
//
.string     wad;        // FIXME: It doesn't seem to be used anymore
.string     map;
.float      worldtype;  // 0=medieval 1=metal 2=base

//================================================

.string     killtarget;

//
// combat
//

// Custom ammo.
// NOTE:  The existing Quake ammo are used for the following weapons.
//   ammo_shells  -> sawed-off shotgun
//   ammo_nails   -> tommy sub-machinegun
//   ammo_rockets -> napalm launcher (a.k.a. incinerator)
//   ammo_cells   -> tesla cannon
.float      ammo_flare;         // flare gun
.float      ammo_tnt_bundle;    // standard dynamite
.float      ammo_tnt_proxy;     // proxy bombs
.float      ammo_tnt_remote;    // pipebombs
.float      ammo_spray;         // spray can
.float      ammo_voodoo;        // voodoo doll
.float      ammo_leech;         // leech life

.float      armor_fire;
.float      armor_body;
.float      armor_mind;

.float      remain_arm;
.float      remain_dmg;

.float      reflect_finished;

.float      charge;
.float      powertime;
.float      tnt_time;
.float      tnt_type;

.float      idle_time;
.float      idle_done;

.float      voice_finished;

.float      newweapon;      // used during the draw/holster weapon process

.entity     leech_sentry;

.void()     reset;          // Used by the warmup code. Most of the time, it resets
                            // the entity to its original state or just remove it

.float      team_save;      // Backup of the "team" property

// QuakeC extensions
.float      button3;        // altfire; DP_INPUTBUTTONS extension
.float      button4;        // use; DP_INPUTBUTTONS extension
.float      alpha;          // controls opacity of the entity (0.0 or 1.0 is solid, -1 is invisible); DP_ENT_ALPHA extension
.float      glow_color;     // Glowing light effect, paletted color (note: 0 and 254 are white); DP_ENT_GLOW extension
.float      glow_size;      // 0 or higher (Darkplaces imposes a 1020 limit); DP_ENT_GLOW extension
.float      glow_trail;     // If true, leave a trail of particles of the same color as the light; DP_ENT_GLOW extension
.float      scale;          // Rendering scale of the object (0 is forced to 1); DP_ENT_SCALE extension

//
// Fire
//
.entity     burner;         // The flame generator linked on an entity


//
// quakeed fields
//
.float      light_lev;  // not used by game, but parsed by light util
.float      style;      // mainly used for the light styles


//
// monster ai
//
.void()		th_arise;	//make the zombie arise out of the ground
.void()		th_fall;	//zombie falls backwards
.void()		th_standup;	//zombie stands back up from being knocked down
.void()		th_hide;	//since a zombie is underground, it doesn't really stand
.void()     th_stand;
.void()     th_walk;
.void()     th_run;
.void()     th_missile;
.void()     th_melee;
.void(entity attacker, float damage) th_pain;
.void()     th_die;

.entity     oldenemy;   // mad at this player before taking damage

.float      speed;

.float      lefty;

.float      search_time;
.float      attack_state;

//new animation variables
.string		last_action;	//transition to new anim_type, starts frame at 1
.string		anim_type;		//animation type: stand,walk,run,pain,death,attack
.float		anim_end;		//last animation $frame name
.float		anim_end_num;	//number associated with the last $frame
.float		anim_time;		//the length in seconds of one animation cycle


//
// player only fields
//

// Menu / voting system
.float      menu_index;
.float      vote_map;
.float      vote_gametype;
.float      vote_fraglimit;
.float      vote_timelimit;
.float      vote_warmup;
.float      vote_options;

// Observer
.float      observer;
.float      do_observer;

.float      items2;	//keys
.float		spawnposition;
.float		spawposition;	//spawn position
.float		spawntype;	// for SP & BB & Coop spawn values

.float      player_state;   // cf PS_*

.float      attack_finished;
.float      pain_finished;

.float      healamount, healtype;
.float      dmgtime;

.float      invincible_finished;
.float      invisible_finished;
.float      akimbo_finished;
.float      poison;         // for spider bites / choking hands

.float      invincible_time, invincible_sound;
.float      invisible_time, invisible_sound;
.float      fly_sound;

.float      show_hostile;   // set to time+0.2 whenever a client fires a
                            // weapon or takes damage.  Used to alert
                            // monsters that otherwise would let the player go
                            // FIXME: check that we set it somewhere and use it

.float      jump_flag;      // player jump flag
.float      swim_flag;      // player swimming sound flag
.float      air_finished;   // when time > air_finished, start drowning
.string     deathtype;      // keeps track of how the player died

//
// object stuff
//
.string     mdl;
.vector     mangle;         // angle at start

.float      t_length, t_width;
.float      anim_len;       // animation length


//
// doors, etc
//
.vector     dest, dest1, dest2;
.float      wait;           // time from firing to restarting
.float      delay;          // time from activation to firing
.entity     trigger_field;  // door's trigger entity
.string     noise4;

// rotation variables
.vector     neworigin;
.vector     rotate;
.float      endtime;
.float      rotate_type;
.string     group;
.string     event;
.string     path;
.float      duration;

//
// monsters
//
.float      pausetime;
.entity     movetarget;

//
// doors
//
.float      aflag;
.float      dmg;            // damage done by door when hit

//
// misc
//
.float      cnt;            // misc flag

//
// subs
//
.void()     think1;
.vector     finaldest, finalangle;

//
// triggers
//
.float      count;          // for counting triggers


//
// plats / doors / buttons
//
.float      lip;
.float      state;
.vector     pos1, pos2;     // top and bottom positions
.float      height;

//
// sounds
//
.float      distance;


//===========================================================================


//
// builtin functions
//

void(vector ang)  makevectors                   = #1;  // sets v_forward, etc globals
void(entity e, vector o) setorigin              = #2;
void(entity e, string m) setmodel               = #3;  // set movetype and solid first
void(entity e, vector min, vector max) setsize  = #4;
void() break                                    = #6;
float() random                                  = #7;  // returns 0 - 1
#ifdef NO_FRIKBOT
void(entity e, float chan, string samp, float vol, float atten) sound = #8;
#endif
vector(vector v) normalize          = #9;
void(string e) error                = #10;
void(string e1, string e2) error2   = #10;
void(string e) objerror             = #11;
float(vector v) vlen                = #12;
float(vector v) vectoyaw            = #13;
entity() spawn                      = #14;
void(entity e) remove               = #15;

/*
    sets trace_* globals
    nomonsters can be:
    An entity will also be ignored for testing if forent == test,
    forent->owner == test, or test->owner == forent
    a forent of world is ignored
*/
void(vector v1, vector v2, float nomonsters, entity forent) traceline = #16;

entity() checkclient                                                = #17;  // returns a client to look for
entity(entity start, .string fld, string match) find                = #18;
string(string s) precache_sound                                     = #19;
string(string s) precache_model                                     = #20;
#ifdef NO_FRIKBOT
void(entity client, string s)stuffcmd                               = #21;
#endif
entity(vector org, float rad) findradius                            = #22;
void(string s) bprint                                               = #23;
void(string s1, string s2) bprint2                                  = #23;
void(string s1, string s2, string s3) bprint3                       = #23;
void(string s1, string s2, string s3, string s4) bprint4            = #23;
void(string s1, string s2, string s3, string s4, string s5) bprint5 = #23;
#ifdef NO_FRIKBOT
void(entity client, string s) sprint                                = #24;
void(entity client, string s1, string s2) sprint2                   = #24;
void(entity client, string s1, string s2, string s3) sprint3        = #24;
#endif
void(string s) dprint                                               = #25;
string(float f) ftos                                                = #26;
string(vector v) vtos                                               = #27;
void() coredump                                                     = #28;  // prints all edicts
void() traceon                                                      = #29;  // turns statment trace on
void() traceoff                                                     = #30;
void(entity e) eprint                                               = #31;  // prints an entire edict
float(float yaw, float dist) walkmove                               = #32;  // returns TRUE or FALSE
float() droptofloor                                                 = #34;  // TRUE if landed on floor
void(float style, string value) lightstyle                          = #35;
float(float v) rint                                                 = #36;  // round to nearest int
float(float v) floor                                                = #37;  // largest integer <= v
float(float v) ceil                                                 = #38;  // smallest integer >= v
float(entity e) checkbottom                                         = #40;  // true if self is on ground
float(vector v) pointcontents                                       = #41;  // returns a CONTENT_*
float(float f) fabs                                                 = #43;
#ifdef NO_FRIKBOT
vector(entity e, float speed) aim                                   = #44;  // returns the shooting vector
#endif
float(string s) cvar                                                = #45;  // return cvar.value
void(string s) localcmd                                             = #46;  // put string into local que
entity(entity e) nextent                                            = #47;  // for looping through all ents
void(vector o, vector d, float color, float count) particle         = #48;  // start a particle effect
void() ChangeYaw                                                    = #49;  // turn towards self.ideal_yaw at self.yaw_speed
vector(vector v) vectoangles                                        = #51;

#ifdef NO_FRIKBOT
//
// direct client message generation
//
void(float to, float f) WriteByte       = #52;
void(float to, float f) WriteChar       = #53;
void(float to, float f) WriteShort      = #54;
void(float to, float f) WriteLong       = #55;
void(float to, float f) WriteCoord      = #56;
void(float to, float f) WriteAngle      = #57;
void(float to, string s) WriteString    = #58;
void(float to, entity s) WriteEntity    = #59;
#endif

void(float step) movetogoal             = #67;
string(string s) precache_file          = #68;  // no effect except for -copy
void(entity e) makestatic               = #69;
void(string s) changelevel              = #70;
// #71 was removed
void(string var, string val) cvar_set   = #72;  // sets cvar.value

#ifdef NO_FRIKBOT
// The various versions of centerprint (sprint, but in middle)
void(entity client, string s) centerprint                           = #73;
void(entity client, string s1, string s2) centerprint2              = #73;
void(entity client, string s1, string s2, string s3) centerprint3   = #73;
#endif

void(vector pos, string samp, float vol, float atten) ambientsound  = #74;

#ifdef NO_FRIKBOT
void(entity e) setspawnparms = #78;  // set parm1... to the values at level start for coop respawn
#endif

// QC extensions
float(string name, string value) registercvar   = #93;
float(string s) checkextension                  = #99;

// concatenates two strings (for example "abc", "def" would return "abcdef") and returns as a tempstring
string(string s1, string s2) strcat             = #115; 

/*
    Temporary entities were simplified.  Here's the simpler functions...
*/

//creates a blood effect
void(vector org, vector velocity, float howmany) te_blood = #405;

//creates an exploding shower of blood, for making gibbings more convincing.	
void(vector mincorner, vector maxcorner, float explosionspeed, float howmany) te_bloodshower = #406;

//creates a colored explosion effect
void(vector org, vector color) te_explosionrgb = #407;

//creates a cloud of particles, useful for forcefields but quite customizable.
void(vector mincorner, vector maxcorner, vector vel, float howmany, float color, float gravityflag, float randomveljitter) te_particlecube = #408;

//creates a shower of rain, the rain will appear either at the top (if falling down) or bottom (if falling up) of the cube.
void(vector mincorner, vector maxcorner, vector vel, float howmany, float color) te_particlerain = #409;

//creates a shower of snow, the snow will appear either at the top (if falling down) or bottom (if falling up) of the cube
void(vector mincorner, vector maxcorner, vector vel, float howmany, float color) te_particlesnow = #410;

//creates a customized light flash.
void(vector org, float radius, float lifetime, vector color) te_customflash = #417;
