# Based on the original Quake2 Makefile by Zoid
# Heavily hacked by Mathieu Olivier

ARCH := $(shell uname -m | sed -e s/i.86/i386/ -e s/sun4u/sparc/ -e s/sparc64/sparc/ -e s/arm.*/arm/ -e s/sa110/arm/ -e s/alpha/axp/)
OSTYPE := $(shell uname -s)

CC=gcc

CFLAGS_BASE=-fPIC -Wall -pipe -Dstricmp=strcasecmp
ifneq ($(ARCH),i386)
 CFLAGS_BASE+= -DC_ONLY
endif
CFLAGS_DEBUG=$(CFLAGS_BASE) -g
ifeq ($(ARCH),i386)
CFLAGS_RELEASE=$(CFLAGS_BASE) -O2 -ffast-math -funroll-loops \
	-fomit-frame-pointer -fexpensive-optimizations \
	-falign-loops=2 -falign-jumps=2 -falign-functions=2
endif

VERSION=0.01CVS

BUILD_DIR_DEBUG=debug-$(ARCH)
BUILD_DIR_RELEASE=release-$(ARCH)

LDFLAGS=-shared -lm
ifeq ($(OSTYPE),Linux)
 LDFLAGS+= -ldl
endif

SHLIBEXT=so


#############################################################################
# SETUP AND BUILD
#############################################################################

.PHONY : all debug release clean clean-debug clean-release

all: debug release

debug:
	@echo ""
	@echo "====== Debug DLL version $(VERSION) ======"
	@-mkdir -p $(BUILD_DIR_DEBUG)
	@echo "Compiling using $(CC)"
	@echo "Compiling with flags: $(CFLAGS_DEBUG)"
	@$(MAKE) $(BUILD_DIR_DEBUG)/game$(ARCH).$(SHLIBEXT) \
		BUILD_DIR=$(BUILD_DIR_DEBUG) \
		CFLAGS="$(CFLAGS_DEBUG) \
		-DLINUX_VERSION='\"$(VERSION) Debug\"'"

release:
	@echo ""
	@echo "====== Release DLL version $(VERSION) ======"
	@-mkdir -p $(BUILD_DIR_RELEASE)
	@echo "Compiling using $(CC)"
	@echo "Compiling with flags: $(CFLAGS_RELEASE)"
	@$(MAKE) $(BUILD_DIR_RELEASE)/game$(ARCH).$(SHLIBEXT) \
		BUILD_DIR=$(BUILD_DIR_RELEASE) \
		CFLAGS="$(CFLAGS_RELEASE) \
		-DLINUX_VERSION='\"$(VERSION)\"'"


#############################################################################
# GAME
#############################################################################

GAME_OBJS = \
	$(BUILD_DIR)/g_admin.o \
	$(BUILD_DIR)/g_ai.o \
	$(BUILD_DIR)/g_chase.o \
	$(BUILD_DIR)/g_cmds.o \
	$(BUILD_DIR)/g_combat.o \
	$(BUILD_DIR)/g_ctf.o \
	$(BUILD_DIR)/g_func.o \
	$(BUILD_DIR)/g_items.o \
	$(BUILD_DIR)/g_main.o \
	$(BUILD_DIR)/g_misc.o \
	$(BUILD_DIR)/g_monster.o \
	$(BUILD_DIR)/g_phys.o \
	$(BUILD_DIR)/g_save.o \
	$(BUILD_DIR)/g_spawn.o \
	$(BUILD_DIR)/g_svcmds.o \
	$(BUILD_DIR)/g_target.o \
	$(BUILD_DIR)/g_trigger.o \
	$(BUILD_DIR)/g_turret.o \
	$(BUILD_DIR)/g_utils.o \
	$(BUILD_DIR)/g_weapon.o \
	$(BUILD_DIR)/m_actor.o \
	$(BUILD_DIR)/m_berserk.o \
	$(BUILD_DIR)/m_boss2.o \
	$(BUILD_DIR)/m_boss3.o \
	$(BUILD_DIR)/m_boss31.o \
	$(BUILD_DIR)/m_boss32.o \
	$(BUILD_DIR)/m_brain.o \
	$(BUILD_DIR)/m_chick.o \
	$(BUILD_DIR)/m_flash.o \
	$(BUILD_DIR)/m_flipper.o \
	$(BUILD_DIR)/m_float.o \
	$(BUILD_DIR)/m_flyer.o \
	$(BUILD_DIR)/m_gladiator.o \
	$(BUILD_DIR)/m_gunner.o \
	$(BUILD_DIR)/m_hover.o \
	$(BUILD_DIR)/m_infantry.o \
	$(BUILD_DIR)/m_insane.o \
	$(BUILD_DIR)/m_medic.o \
	$(BUILD_DIR)/m_move.o \
	$(BUILD_DIR)/m_mutant.o \
	$(BUILD_DIR)/m_parasite.o \
	$(BUILD_DIR)/m_soldier.o \
	$(BUILD_DIR)/m_supertank.o \
	$(BUILD_DIR)/m_tank.o \
	$(BUILD_DIR)/p_client.o \
	$(BUILD_DIR)/p_hud.o \
	$(BUILD_DIR)/p_menu.o \
	$(BUILD_DIR)/p_trail.o \
	$(BUILD_DIR)/p_view.o \
	$(BUILD_DIR)/p_weapon.o \
	$(BUILD_DIR)/q_shared.o

$(BUILD_DIR)/game$(ARCH).$(SHLIBEXT) : $(GAME_OBJS)
	@echo "    Building $@ ..."
	@$(CC) $(LDFLAGS) -o $@ $(GAME_OBJS)

$(BUILD_DIR)/%.o : %.c
	@echo "    Compiling $@ ..."
	@$(CC) $(CFLAGS) -o $@ -c $<


#############################################################################
# MISC
#############################################################################

clean: clean-debug clean-release

clean-debug:
	$(MAKE) clean2 BUILD_DIR=$(BUILD_DIR_DEBUG)

clean-release:
	$(MAKE) clean2 BUILD_DIR=$(BUILD_DIR_RELEASE)

clean2:
	rm -f $(GAME_OBJS)
