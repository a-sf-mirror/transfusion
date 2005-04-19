/*
Copyright (C) 2001-2002 Timothy Hale <timhale@planetblood.com>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

/*TODO: Organize Flat sprites */
#define MASKEDHEDGESMEDIUM	17  // MASKED - D_L > unnecessary?
#define MASKEDHEDGESSMALL	18  // MASKED - D_L > unnecessary?
#define TESTSUBJECTS		19  // FLAT, sits on brush
#define MASKEDBRICK_MEDIUM	51
#define MASKEDBRICK_SMALL	52
#define BARS				58
#define NET					112 // MASKED - need a custom model for this
#define TOMBCOVER			128
#define CURTAINRAGS			147 // MASKED
#define LIONSHIELD			165 // MASKED
#define SEWERLID			219
#define GOTHICMANTLE		227 // MASKED
#define WOODENBRIDGE        256 // MASKED
#define STAINEDGLASS        263 // GIBBABLE, TAGGED FUNNY
#define MONSTERPIC			269 // FACE
#define STOOL				284
#define GREYPIC_HUMAN		316 
#define LEVELEND			318 // FLAT, MUST
#define JOJOSIGN			356
#define OPHELIA             370 // MASKED
#define TRAINSCHEDULE		431
#define POSSUMSIGN			453
#define GRATEMASK			483 // MASKED, gibabble
#define SINKTOP				485
#define MASKEDGRILL			502
#define BLOOD_WASTEBARREL	505
#define SCATTEREDHAY		515 // MASKED
#define WINEGLASS1			521 // custom model
#define STATUE1				536 // BETTER NAME?
#define WINEGLASS2			574 // custom model
#define WREATH_STAND_ILM	575
#define SHIELDCREST			578 // MASKED
#define MEATBARREL			563 // BARREL THAT PRODUCES MASS GIB JUICE
#define GOTHICRAIL			588 // MASKED, BETTER NAME?
#define BRAINJAR			604
#define WINEBOTTLE_BROWN	605
#define WINEBOTTLE_BLUE		606
#define VOODOOWARD			607 // SKULL/CROSS THINGIE
#define SWAMPWEED			608
#define ARTPIC1				613
#define OLDLADYPIC			617
#define UGLYGUYPIC			621 // MY FAVE
#define RIP_WREATH			633
#define MISKATONICSIGN		646
#define RAILROADSIGN		647 // MASKED
#define CRUCIFIEDINNOCENT	648 // MASKED, REPLACE WITH THE QUAKE WALL ZOMBIE?
#define TABLE				649 // custom model needed
#define BLOODYCURTAINRAGS	651 // MASKED
#define FIRE_EXSTINGUISHER	658 // EXPLODABLE
#define ROUNDLIGHT			676
#define STATUE2				679
#define LEG					682 // GIB
#define STABBED_SKULL		685
#define HANGINGHALFSKELETON	689 // custom model needed
#define HANGINGHALFCORPSE	690 // custom model needed
#define TRAINWHEELS			708 // use a brush and carve
#define BLOODSPLAT1			713
#define BLOODSPLAT2			730
#define BLOODSPLAT3			732
#define PICKMANSIGN			740
#define AMONDTILLADOSIGN	741
#define NOTICESIGN			742
#define NEWSSIGN			743
#define WARNINGSIGN			744
#define SMOKE1				754 // this should be done with some sort of particle effect
#define SMOKE2				755
#define SMOKE3				756
#define SMOKE4				757 
#define CHAIR				758 // custom model needed
#define WINEBOTTLE			759
#define BLOODSPRAY1			775
#define BLOODSPRAY2			776
#define BLOODSPRAY3			777
#define INLOVINGMEMORY		789
#define IDISMEMBEREDMOMMA	790
#define SMALLROUNDLIGHT		795 
#define LONGLIGHT			796
#define FORMALDEHYDE		802 // Gibby
#define BLOODYGOBLET		803
#define ROCK1				804 // Gibby
#define ROCK2				805 // Gibby
#define ROCK3				806 // Gibby
#define ROCK4				808 // GIBBY
#define NOADMITSIGN			823
#define RANDOMITEM          832 // Can quake do this?
#define BULLETHOLE			838
#define SHROOM1             840
#define SHROOM2             841
#define SHROOM3             842
#define SHROOM4             843
#define UNDERCONSTRUCTION	844
#define BLUEBANNER			845 // LION
#define ORANGEBANNER		846
#define REDBANNER			847 // DOABLE
#define GREENBANNER			848
#define DUCKIE              852
#define SMILIE              853
#define UPSIDEDOWN_CORPSE	895
#define BLOODHAND			904 
#define FLAME_MEDIUM		908	// MUST, TOO EASY
#define BLOODSMEAR			929
#define BLOODSPLAT_MEDIUM	915
#define DANGER				933
#define DANGER_BLOODY		942 // MASKED
#define TICKETSIGN			943
#define LAMP				944 // SHOULD HAVE A LIGHT FLAG
#define POT1				961
#define DRIPSTAND_BADWATER	962
#define DRIPSTAND_BLOOD		963
#define CRACKEDWALL_GREEN	964
#define WELCOMETOHELL		974
#define JOJO_CIRCUSSIGN		981
#define STEELGATE			1044 // MASKED, BETTER NAME	
#define BUTTON				1046 // use a brush
#define SKULLBUTTON			1048 // use a brush
#define ELECTRICALOUTLET	1050
#define METALFENCE			1060
#define WATERVASE			1063
#define WEB_PARTIAL			1066
#define HANGINGWEB_MEDIUM	1067 // MASKED
#define HANGINGWEB_SMALL	1068 // MASKED
#define WEB					1069 // MASKED, GIBBABLE
#define SWITCH1_ON			1070 // use a brush
#define SWITCH1_OFF			1071 // use a brush
#define SWITCH2_ON			1072 // use a brush
#define SWITCH2_OFF			1073 // use a brush
#define SWITCH3_ON			1074 // use a brush
#define SWITCH3_OFF			1075 // use a brush
#define SWITCH4_ON			1076 // use a brush
#define SWITCH4_OFF			1077 // use a brush
#define LIGHTSWITCH_ON		1078 // use a brush
#define LIGHTSWITCH_OFF		1079 // use a brush
#define WALLCRACK			1127
#define BLOODSPLAT_TINY		1149
#define CLOCK				1165 // use a brush
#define CREMATORIUM			1169
#define ZOMBIECORPSE		1223 
#define GIB1				1268
#define GIB2				1269
#define GAMEEND_SWITCH		1348
#define TEXT_666			1407
#define BLOODFLOW			1413 // 1413-1417 the pool expands outward
#define PHANTOM_TEXT		1667
#define HEDGECLIPPERS		1708 // MASKED
#define AXE					1709 // MASKED
#define BROOM				1710 // MASKED
#define RAKE				1711 // MASKED
#define SHOVELBIG			1713 // MASKED
#define SAW					1714
#define PLIERS				1715
#define COATHOOK			1716 // NOTSURE
#define WASHHANDSSIGN		1719 //
#define CEMETERYSIGN		1726
#define FOOTSTEP_BLOOD		1902
#define FOOTSTEP_WATER		1903
#define FOOTSTEP_BROWN		1904
#define FOOTSTEP_GREY		1905
#define FOOTSTEP_GREEN		1906
#define GUTS1				2053
#define GUTS2				2054
#define GUTS3				2055
#define GUTS4				2056
#define BLOODYPULP1			2073
#define BLOODYPULP2			2074
#define BLOODYPULP3			2075
#define BLOODYPULP4			2076
#define CLEAVER				2139 // 2138 -2145 custom model
#define TEXTRED0			2190
#define TEXTBLUE0			2240
#define FLUORESCENTLIGHT1		2288 // use a brush		
#define BROKEFLUORESCENTLIGHT1	2289 // use a brush
#define FLUORESCENTLIGHT2		2290 // use a brush		
#define BROKEFLUORESCENTLIGHT2	2291 // use a brush
#define POT_SMALL			2295 // custom model
#define PAN					2304
#define POT2				2305
#define TRAINWHEEL			2320 //2320-2323
#define HANGINGMALECORPSE	2324 //2324-2329 - custom model
#define DEADINNOCENT1		2330 // DEADBODY - custom model
#define UPARROW_SMALL		2331
#define DOWNARROW_SMALL		2332
#define DEADINNOCENT2		2333
#define DEADINNOCENT3		2334 // custom model
#define SOUND				2519
#define SSOUND				2520
#define STAR_SKULL			2540
#define STAR_EYE			2541
#define STAR_FLAME			2542
#define STAR_DAGGER			2543
#define STAR_SPIDER			2544
#define STAR_MOON			2545
#define JUKEBOX				2546
#define CULTIST_CORPSE		2584
#define ZOMBIEHEAD			3405 // 3405-3421 - custom model
#define BARREL_SIDE			3490
#define PAIL				3540 // 3540-3548 - custom model
#define INNOCENT_CORPSE		3791
#define TEXT_A				3808 // LATER
#define	TEXT_Z				3833		

/* Keys - done */
#define SKULLKEY			2552
#define EYEKEY				2553
#define FLAMEKEY			2554 // custom model still needed
#define DAGGERKEY			2555 // custom model still needed
#define SPIDERKEY			2556 // custom model still needed
#define MOONKEY				2557 // custom model still needed

/* Weapons - done */
#define FLAREPISTOL		524 // 2
#define SHOTGUN			559 // 3
#define TOMMYGUN		558 // 4
#define NAPALMLAUNCHER  526 // 5
#define TNTSTICK		589 // 6
#define TNTBOX			809 // 6
#define TNTREMOTE		810 // 6
#define TNTPROXIMITY	811 // 6
#define SPRAYCAN		618 // 7
#define TESLACANNON		539 // 8
#define VOODOODOLL		525 // 9
#define LIFELEECH		800 // 0

/* Ammo - done */
#define FLARES			816
#define SHOTGUNSHELLS_MORE 812
#define TOMMYSHELLS		813
#define TOMMYCLIP		817
#define GASOLINE		801
#define TESLAAMMO		548
#define SHOTGUNSHELLS	619
#define TRAPPEDSOUL		820

/* Misc with an obvious acceptable conversion */
#define TEAMPOLE		753 // For team play. lotag = 145 for blue team; 146 for red team
#define AKIMBO			829 // Quad, etc
#define DEATHMASK		825  // INVULNERABILITY
#define PLAYERSTART1	2522 // "info_player_start"
#define PLAYERSTART2	2523 // "info_player_coop"
#define PLAYERSTART3	2524 // "info_player_coop"
#define PLAYERSTART4	2525 // "info_player_coop"
#define PLAYERSTART5	2526 // "info_player_coop"
#define PLAYERSTART6	2527 // "info_player_coop"
#define PLAYERSTART7	2528 // "info_player_coop"
#define PLAYERSTART8	2529 // "info_player_coop"

/* Armor - done */
#define FIREARMOR		2578 // REDISH
#define BODYARMOR		2586 // BLUE'ISH
#define SUPERARMOR		2594
#define SPIRITARMOR		2602 // UGLY SMILY
#define BASICARMOR		2628 // FLAT GREY

/* Powerups - done */
#define CRYSTALBALL			760
#define SHADOWCLOAK         768 // 768-771 - TESTME	
#define BEASTVISON			839
#define CLOAK_INVISIBLE		896
#define LIFEESSENCE		    2169
#define DOCTORSBAG		    519
#define REFLECTIVESHOT      2428 // TESTME
#define LIFESEED		    2433
#define MEDICINEPOUCH       822 // TESTME
#define JUMPINGBOOTS        827 
#define DIVINGSUIT          830 // TESTME

/* Enemies - done */ 
#define RAT					1745
#define BAT					1948
#define BONE_EEL            1870
#define BLACKSPIDER         1920 // The colors are taken from mapedit
#define REDSPIDER           1925
#define BROWNSPIDER         1935
#define CULTIST_ACTIVE		2820 // 2820 - 2909 CULTISTS pal defines what type
#define CULTIST_INACTIVE	2825 // brown = 0, black = 3, green = 11, red = 12, blue = 13   
#define CUTLIST_PRONE       3385
#define CHRYSALIDPOD		1792 // pal defines what type 
#define CHRYSALIDTENTACLE	1797 // 0 for green, 2 for fire
#define ZOMBIE		        1170
#define ZOMBIESLEEPING      1209
#define INNOCENT			3798
#define MIME                2400
#define HELLHOUND           1270
#define GILBEAST            1570
#define HAND                1980
#define ZOMBIEEMERGING		3054
#define GARGOYLE_STATUE     1530 // pal defines what type  
#define GARGOYLE    		1470 // 0 for regular, 5 for stone
#define LILCALEB            3870
#define BUTCHER             1370
#define PHANTASM            3060
#define SHIAL				1930
#define CERBERUS			2680
#define TCHERNOBOG			3140 
#define BEAST               2960

/* Lights */
#define HANGINGLIGHT		468 // custom model
#define FLAMINGTORCH1       506 // Done
#define FLAMINGTORCH2       507
#define FLAMINGTORCH3       508
#define FLAMINGTORCH4       509
#define BRASSTORCH			570
#define GOLDTORCH			571
#define GARGOYLETORCH		572 // custom model
#define THREE_CANDLE_STAND	580 // 580-583
#define CANDLEABRA			584 // 584-587
#define CANDLE				650 // SMALL LIGHT
#define LIGHTPOST			640 // 1800'S STYLE LIGHT
#define FLAME				2101 // 2101-2114
#define BIGFLAME			3566 // 3566-3579

/* Tombstones */
#define RIPSKULL			702 // TEXTURE ONLY??
#define RIPTOMBSTONE		704 
#define KLKTOMBSTONE		705
#define SKULLTOMBSTONE		706
#define DRAVENTOMBSTONE		1159

/* Atmospheric stuff (i.e. sets the blood "mood" - only stuff thats done goes here*/
#define SKULLSTICK1         257
#define SKULLSTICK2         259
#define SMALLVIAL           517
#define LARGEVASE1			537
#define TREE1				540 // Trees all done 
#define TREE2				541
#define TREE3				542
#define TREE4				543
#define TREE5				544
#define TREE6				545
#define TREE7				546
#define TREE8				547
#define CAULDRON1           550
#define CAULDRON2           551
#define TREE9				599
#define LARGE2HANDEDJUG     642
#define SEAWEED1            664
#define SEAWEED2            665
#define SEAWEED3            666
#define SEAWEED4            667
#define CROSSTOMBSTONE		678
#define HALFSKULL           683 
#define OVALTOMBSTONE		701
#define TILTEDCROSS 		703 // WOODEN CROSS
#define LARGEVASE2			739
#define SKULLSIDE			807
#define	BARREL1				907 // Which barrel is gibbable?
#define	BARREL2				925
#define POTTEDPLANT			1009
#define SMALLPLANT          1010
#define VASEPLANT           1013
#define FROZENCOW           1351 
#define SHOVEL				1712
#define LIGHTNING			2090 // EVENT_LIGHTING

/* WTF ??? 
784  BALL THING
3997  DIDN'T CONVERT
*/