#include "global.h"
#include "names.h"

// External prototypes- migrate these elsewhere?
extern void W_MusicanDSFX(long i, char *Name, FILE *f);
extern void W_OtherItems(long i, char *Name, FILE *f);
extern void E_Item(long i, char *Name, FILE *f);

void Duke3D_To_Quake2 (unsigned short i, FILE *f)
{
	switch (sprite[i].picnum)
	{

	case FIRSTGUNSPRITE:	//21
	case CHAINGUNSPRITE:	//22
    W_OtherItems(i, "weapon_lightning", f);
    return;
	
	case RPGSPRITE:			//23 
	W_OtherItems(i, "weapon_rocketlauncher", f);
    return;

	case FREEZESPRITE:		//24 
	W_OtherItems(i, "weapon_plasmagun", f);
    return;

	case SHRINKERSPRITE:	//25 
	W_OtherItems(i, "weapon_railgun", f);
    return;

	case HEAVYHBOMB:		//26
	case DEVISTATORAMMO:	//42
	case HBOMBAMMO:			//47
	W_OtherItems(i, "ammo_grenades", f);
    return;

	case TRIPBOMBSPRITE:	//27	
	W_OtherItems(i, "weapon_bfg", f);
    return;

    case SHOTGUNSPRITE:		//28	
	W_OtherItems(i, "weapon_shotgun", f);
    return;

    case DEVISTATORSPRITE:	//29	
	W_OtherItems(i, "weapon_grenadelauncher", f);
    return;

	case FREEZEAMMO:		//37	
	W_OtherItems(i, "ammo_cells", f);
    return;

    case AMMO:				//40	
	W_OtherItems(i, "ammo_bullets", f);
    return;

    case BATTERYAMMO:		//41	
	W_OtherItems(i, "ammo_lightning", f);
    return;

    case RPGAMMO:		    //44	
	W_OtherItems(i, "ammo_rockets", f);
    return;

	case GROWAMMO:		    //45
	case CRYSTALAMMO:	    //46
	W_OtherItems(i, "ammo_slugs", f);
    return;

	case SHOTGUNAMMO:	    //49
	W_OtherItems(i, "ammo_shells", f);
    return;

	case COLA:				//51
	W_OtherItems(i, "item_health_small", f);
    return;

    case SIXPAK:			//52
	W_OtherItems(i, "item_health_large", f);
    return;

	case FIRSTAID:			//53
	W_OtherItems(i, "holdable_medkit", f);
    return;

	case SHIELD:			//54
	W_OtherItems(i, "item_armor_combat", f);
    return;
    
	case STEROIDS:			//55
	W_OtherItems(i, "item_armor_body", f);
    return;

	case AIRTANK:			//56
	W_OtherItems(i, "item_breather", f);
    return;

	case JETPACK:			//57
	W_OtherItems(i, "item_pack", f);
    return;

	case HEATSENSOR:		//59
	W_OtherItems(i, "item_silencer", f);
    return;

	case ACCESSCARD:		//60
	W_OtherItems(i, "key_blue_key", f);
    return;

	case BOOTS:				//61
	W_OtherItems(i, "item_enviro", f);
    return;

	case ATOMICHEALTH:		//100
	W_OtherItems(i, "item_health_mega", f);
    return;

	case HOLODUKE:			//1348
	W_OtherItems(i, "item_power_shield", f);
    return;

	case APLAYERTOP:		//1400
	case APLAYER:			//1405
	case PLAYERONWATER:		//1420 The player starts
		
		if (sprite[i].lotag == 1)
			W_OtherItems(i, "info_player_coop", f);
		else  
			W_OtherItems(i, "info_player_deathmatch", f);
		return;
 
	case   OOZFILTER:		//1079
	case     SEENINE:		//1247
	return;

	case MUSICANDSFX: 
	W_MusicanDSFX(i, "target_speaker", f); // TESTME:

	default:
    W_OtherItems(i, "fix_me", f);
	} // switch

}