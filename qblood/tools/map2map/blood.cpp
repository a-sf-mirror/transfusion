char Entity[20]="";
switch
{
case: LEVELEND		318
case: GRATEMASK		483
case: GARGOYLETORCH	572
case: SKULLBUTTON		1048
case: SOUND			2519
case: SSOUND			2520
case: PLAYERSTART1	2522
case: PLAYERSTART2	2523
case: PLAYERSTART3	2524
case: PLAYERSTART4	2525
case: PLAYERSTART5	2526
case: PLAYERSTART6	2527
case: PLAYERSTART7	2528
case: PLAYERSTART8	2529

/* Weapons */
case: FLAREPISTOL		524 // 2
case: SHOTGUN			559 // 3
case: TOMMYGUN		558 // 4
case: NAPALMLAUNCHER  526 // 5
case: TNT				809 // 6
case: TNTREMOTE		810 // 6
case: TNTPROXIMITY	811 // 6
case: SPRAYCAN		618 // 7
case: TESLACANNON		539 // 8
case: VOODOODOLL		525 // 9

/* Ammo */
case: FLARES			816
case: SHOTGUNSHELLS_MORE 812
case: TOMMYCLIP		817
case: GASOLINE		801
case: TESLAAMMO		548

/* Misc with an obvious acceptable conversion */
case: AKIMBO			829  // QUAD, DUH!
case: DEATHMASK		825  // INVULNERABILITY

/* Armor */
case: FIREARMOR		2578 // REDISH
case: BODYARMOR		2586 // BLUE'ISH
case: SUPERARMOR		2594
case: SPIRITARMOR		2602 // UGLY SMILY
case: BASICARMOR		2628 // FLAT GREY

/* Health */
case: LIFEESSENCE		2169
case: DOCTORSBAG		519

/* Enemies */
case: CULTIST				2825 // What flag makes it black/red/blue/brown???
case: CHRYSALIDPOD		1792  
case: CHRYSALIDTENTACLE	1797

default: Entity = "fix_me";

}