#include "global.h"
#include "blood.h"
#include "extern.h"

void Blood_To_qBlood (unsigned short i, FILE *f)
{
	switch (sprite[i].picnum)
	{

/* Weapons */
	case FLAREPISTOL:	//524 Weapon # 2
		W_OtherItems(i, "weapon_flaregun", f);
		return;

	case SHOTGUN:		//559 Weapon # 3
		W_OtherItems(i, "weapon_supershotgun", f);
		return;

	case TOMMYGUN:		//558 Weapon # 4
		W_OtherItems(i, "weapon_nailgun", f);
		return;

	case NAPALMLAUNCHER://526 Weapon # 5
		W_OtherItems(i, "weapon_rocketlauncher", f);
		return;

	case TNTSTICK:		//589 Weapon # 6
		W_OtherItems(i, "item_tnt", f); 
		return;

	case TNTBOX:		//809 Weapon # 6
		W_OtherItems(i, "weapon_grenadelauncher", f);
		return;

	case TNTREMOTE:		//810 Weapon # 6
		W_OtherItems(i, "weapon_remote", f);
		return;
		
	case TNTPROXIMITY:	//811 Weapon # 6
		W_OtherItems(i, "weapon_proximity", f);
		return;

	case SPRAYCAN:		//618 Weapon # 7
		W_OtherItems(i, "weapon_supernailgun", f);
		return;

	case TESLACANNON:	//539 Weapon # 8
		W_OtherItems(i, "weapon_lightning", f);
		return;

	case VOODOODOLL:	//525 Weapon # 9
		W_OtherItems(i, "weapon_voodoodoll", f);
		return;
    
    case LIFELEECH:	    //800 Weapon # 0
		W_OtherItems(i, "weapon_lifeleech", f);
		return;


/*	
item_spikes 	a "few bullets" (i_fewblt.mdl)
item_soul	Trapped Soul (soul.mdl) NOT DONE

/* Ammo */
	case FLARES:		//816
		W_OtherItems(i, "item_flares", f);
		return;

	case SHOTGUNSHELLS_MORE://812
		W_OtherItems(i, "item_shells *BIG*", f); //FIXME
		return;

	case TOMMYCLIP:		//817
		W_OtherItems(i, "item_spikes *BIG*", f); //FIXME
		return;

	case GASOLINE:		//801
		W_OtherItems(i, "item_rockets", f);
		return;

	case TESLAAMMO:		//548
		W_OtherItems(i, "item_cells", f);
		return;

	case SHOTGUNSHELLS:	//619
		W_OtherItems(i, "item_shells", f);
		return;

/* Misc with an obvious acceptable conversion */
	case AKIMBO:		//829   
		W_OtherItems(i, "item_artifact_super_damage", f);
		return;
	
	case DEATHMASK:		//825   
		W_OtherItems(i, "item_artifact_invulnerability", f);
		return;
	
	case DMSPAWN:		//753  TESTME: I need to validate this
		W_OtherItems(i, "info_player_deathmatch", f);
		return;
	
	case PLAYERSTART1:	//2522
        W_OtherItems(i, "info_player_start", f);
        W_OtherItems(i, "info_player_deathmatch", f);
    	return;
    
    // TODO: It seem there's a flag for DM with the player starts
	case PLAYERSTART2:	//2523  
	case PLAYERSTART3:	//2524  
	case PLAYERSTART4:	//2525  
	case PLAYERSTART5:	//2526  
	case PLAYERSTART6:	//2527  
	case PLAYERSTART7:	//2528  
	case PLAYERSTART8:	//2529  
		W_OtherItems(i, "info_player_coop", f);
		return;

/* Armor */
	case FIREARMOR:		//2578 // REDISH
		W_OtherItems(i, "item_armor2", f);
		return;

	case BODYARMOR:		//2586 // BLUE'ISH
		W_OtherItems(i, "item_armor1", f);
		return;

	case SUPERARMOR:	//2594
		W_OtherItems(i, "item_armorInv", f);
		return;

	case SPIRITARMOR:	//2602 // UGLY SMILY
		W_OtherItems(i, "item_armor4", f);
		return;

	case BASICARMOR:	//2628 // FLAT GREY
		W_OtherItems(i, "item_armor0", f);
		return;

/* Health */
	case LIFEESSENCE:	//2169
		W_OtherItems(i, "item_health *ROTTEN*", f); //FIXME
		return;
		
	case DOCTORSBAG:	//519
		W_OtherItems(i, "item_artifact_bag", f);
		return;

	case LIFESEED:		//2433
		W_OtherItems(i, "item_health *MEGA*", f); //FIXME
		return;

/* Enemies */
	case RAT:				//1745
	case BAT:				//1948
	case CHRYSALIDPOD:		//1792  
	case CHRYSALIDTENTACLE:	//1797
		W_OtherItems(i, "monster_dog", f);
		return;
		
	case CULTIST_ACTIVE:	//2820 // 2820 - 2909 CULTISTS
	case CULTIST_INACTIVE:	//2825 // What flag makes it black/red/blue/brown???
		W_OtherItems(i, "monster_enforcer", f);
		return;
	
	case RUNNINGZOMBIE:		//1170
	case EMERGINGZOMBIE:	//3054
		W_OtherItems(i, "monster_zombie", f);
		return;

	case INNOCENT:			//3798
	
	default:
	return; // The next was for testing
    W_OtherItems(i, "fix_me", f);

	} // switch

} // Blood_To_qBlood

/*
void Blood_To_Halflife (/*unsigned short i, FILE *f/)
{
	printf("Not until qBlood is done!\n");
}


void Blood_To_Quake2 (/*unsigned short i, FILE *f/)
{
	printf("Not until qBlood is done!\n");
}


void Blood_To_Quake3 (/*unsigned short i, FILE *f/)
{
	printf("Not until until the Quake 2 source is GPL!\n");
}


void Blood_To_Hexen2 (/*unsigned short i, FILE *f/)
{
	printf("Not until I get a wild hair!\n");
}


void Blood_To_Heretic2 (/*unsigned short i, FILE *f/)
{
	printf("Not until I get a really wild hair!\n");
}


void Blood_To_Return_To_Castle_Wolfenstein (/*unsigned short i, FILE *f/)
{
	printf("Not until the Quake 3 source is GPL!\n");
}
*/