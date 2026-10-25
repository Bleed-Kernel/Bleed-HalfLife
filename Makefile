XASH_REPO     = https://github.com/FWGS/xash3d-fwgs.git
XASH_COMMIT   = d6b54aaf6c1d8518e08404a842f3f6ee02cef3cc
XASH_MODULES  = \
	3rdparty/library_suffix \
	3rdparty/bzip2/bzip2 \
	3rdparty/mainui \
	3rdparty/MultiEmulator \
	3rdparty/mpg123/mpg123 \
	3rdparty/opus/opus \
	3rdparty/opusfile/opusfile \
	3rdparty/libogg/libogg \
	3rdparty/vorbis/vorbis-src \
	3rdparty/extras/xash-extras
XASH          = external/xash3d-fwgs

HLSDK_REPO    = https://github.com/FWGS/hlsdk-portable.git
HLSDK_COMMIT  = 8a09758d2912d278423870391f6c25995de0000b
HLSDK_MODULES = freevgui
HLSDK         = external/hlsdk-portable

BLIBC_DIR    ?= $(if $(wildcard ../blibc/include/bleed),../blibc,external/blibc)
BLIBC_REPO    = https://github.com/Bleed-Kernel/blibc.git
KERNEL_DIR   ?= ../Bleed-Kernel
SYSROOT       = $(BLIBC_DIR)/sysroot

CRIME_REPO    = https://github.com/Bleed-Kernel/Crime-Scene.git
CRIME_DIR    ?= $(if $(wildcard ../Crime-Scene/Makefile),../Crime-Scene,external/crime-scene)
CRIME_OUT     = libcrime
AUDIO_REPO    = https://github.com/Bleed-Kernel/libaudio.git
AUDIO_DIR    ?= $(if $(wildcard ../libaudio/Makefile),../libaudio,external/libaudio)
AUDIO_OUT     = libaudio

CXX           = x86_64-elf-g++
override CC   = $(dir $(shell command -v $(CXX)))x86_64-elf-gcc
LD            = x86_64-elf-ld
AR            = x86_64-elf-ar
OBJCOPY       = x86_64-elf-objcopy
NM            = x86_64-elf-nm

BUILD         = build
GEN           = $(BUILD)/gen
GAME          = bin/halflife
SERVER        = bin/hlds
JOBS         ?= $(shell sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)

COMMON_FLAGS = \
	-D__bleed__=1 \
	-fno-stack-protector \
	-fno-stack-check \
	-fno-strict-aliasing \
	-fno-pic \
	-no-pie \
	-m64 \
	-O2 \
	-g \
	-nostdinc \
	-isystem $(SYSROOT)/include \
	-idirafter $(shell $(CC) -print-file-name=include)

CFLAGS   = $(COMMON_FLAGS) -std=gnu11
CXXFLAGS = $(COMMON_FLAGS) -std=gnu++11 -fno-exceptions -Wno-invalid-offsetof

LDFLAGS = \
	-static \
	-nostdlib \
	-no-pie \
	-m64

XASH_DEFS = \
	-D_GNU_SOURCE \
	-DALLOCA_H="<alloca.h>" \
	-DHAVE_STRNCASECMP=1 \
	-DHAVE_STRCASECMP=1 \
	-DHAVE_STRCASESTR=1 \
	-DHAVE_STRNLEN=1 \
	-DXASH_STATIC_LIBS=1 \
	-DXASH_GAMEDIR=\"valve\" \
	-DXASH_LOW_MEMORY=0 \
	-DXASH_MINIZ=1 \
	-DMINIZ_NO_ARCHIVE_APIS \
	-DXASH_BUILD_COMMIT=\"$(shell echo $(XASH_COMMIT) | cut -c1-8)\" \
	-DXASH_BUILD_BRANCH=\"bleed\" \
	-DXASH_BUILD_COMMIT_DATE=\"2026-10-21\"

XASH_INCS = \
	-I$(XASH)/public \
	-I$(XASH)/common \
	-I$(XASH)/pm_shared \
	-I$(XASH)/engine \
	-I$(XASH)/engine/common \
	-I$(XASH)/engine/common/imagelib \
	-I$(XASH)/engine/server \
	-I$(XASH)/engine/client \
	-I$(XASH)/engine/client/vgui \
	-I$(XASH)/engine/common/soundlib \
	-I$(XASH)/engine/platform \
	-I$(XASH)/filesystem \
	-I$(XASH)/3rdparty/library_suffix/include \
	-I$(XASH)/3rdparty/miniz \
	-I$(XASH)/3rdparty/bzip2/bzip2 \
	-I$(GEN)

obj = $(patsubst %.cpp,$(BUILD)/$(1)/%.o,$(patsubst %.c,$(BUILD)/$(1)/%.o,$(2)))
glob = $(shell find $(1) -name '$(2)' 2>/dev/null | sort)

ENGINE_COMMON_SRCS = \
	$(wildcard $(XASH)/engine/common/*.c) \
	$(wildcard $(XASH)/engine/common/imagelib/*.c) \
	$(wildcard $(XASH)/engine/common/soundlib/*.c) \
	$(wildcard $(XASH)/engine/common/http/*.c) \
	$(wildcard $(XASH)/engine/server/*.c) \
	$(XASH)/engine/platform/misc/lib_static.c \
	$(XASH)/3rdparty/library_suffix/src/library_suffix.c \
	$(XASH)/engine/platform/posix/sys_posix.c \
	$(XASH)/engine/platform/posix/con_posix.c

ENGINE_CLIENT_SRCS = \
	$(call glob,$(XASH)/engine/client,*.c) \
	$(XASH)/engine/platform/posix/id_posix.c \
	$(wildcard bleed/engine/*.c)

SERVER_ENGINE_DEFS = $(XASH_DEFS) -DXASH_DEDICATED=1 -DXASH_ENABLE_MAIN=1 -DENGINE_DLL=1
GAME_ENGINE_DEFS   = $(XASH_DEFS) -DXASH_ENABLE_MAIN=1 -DENGINE_DLL=1 -DXASH_REF_SOFT_ENABLED=1

CODEC_INCS = \
	-I$(XASH)/3rdparty/mpg123/mpg123/src/include \
	-I$(XASH)/3rdparty/opus/opus/include \
	-I$(XASH)/3rdparty/opusfile/opusfile/include \
	-I$(XASH)/3rdparty/libogg/libogg/include \
	-I$(XASH)/3rdparty/vorbis/vorbis-src/include \
	-I$(XASH)/3rdparty/MultiEmulator/include

GAME_ENGINE_INCS = $(XASH_INCS) $(CODEC_INCS) -Ibleed/engine -I$(CRIME_OUT)/include -I$(AUDIO_OUT)/include

SERVER_ENGINE_OBJS = $(call obj,engine-ded,$(ENGINE_COMMON_SRCS))
GAME_ENGINE_OBJS   = $(call obj,engine,$(ENGINE_COMMON_SRCS) $(ENGINE_CLIENT_SRCS))

PUBLIC_SRCS = $(wildcard $(XASH)/public/*.c)
MINIZ_SRCS  = $(XASH)/3rdparty/miniz/miniz.c
BZIP2_SRCS  = $(addprefix $(XASH)/3rdparty/bzip2/bzip2/,blocksort.c huffman.c crctable.c randtable.c compress.c decompress.c bzlib.c)

MPG123_SRCS = \
	$(XASH)/3rdparty/mpg123/stub.c \
	$(XASH)/3rdparty/mpg123/mpg123/src/compat/compat_str.c \
	$(addprefix $(XASH)/3rdparty/mpg123/mpg123/src/libmpg123/,dct64.c equalizer.c feature.c format.c frame.c \
		id3.c index.c layer3.c libmpg123.c optimize.c parse.c readers.c synth.c tabinit.c)
OGG_SRCS    = $(wildcard $(XASH)/3rdparty/libogg/libogg/src/*.c)
VORBIS_SRCS = \
	$(addprefix $(XASH)/3rdparty/vorbis/vorbis-src/lib/,mdct.c smallft.c block.c envelope.c window.c lsp.c \
		lpc.c analysis.c synthesis.c psy.c info.c floor1.c floor0.c res0.c mapping0.c registry.c codebook.c \
		sharedbook.c lookup.c bitrate.c vorbisfile.c)
OPUS_DIR    = $(XASH)/3rdparty/opus/opus
OPUS_SRCS   = \
	$(filter-out %/repacketizer_demo.c %/opus_demo.c %/opus_compare.c %/opus_custom_demo.c, \
		$(wildcard $(OPUS_DIR)/src/*.c $(OPUS_DIR)/celt/*.c $(OPUS_DIR)/silk/*.c $(OPUS_DIR)/silk/float/*.c)) \
	$(OPUS_DIR)/silk/x86/x86_silk_map.c \
	$(addprefix $(OPUS_DIR)/celt/x86/,pitch_sse.c pitch_sse2.c vq_sse2.c x86_celt_map.c x86cpu.c)
OPUSFILE_SRCS = $(addprefix $(XASH)/3rdparty/opusfile/opusfile/src/,info.c internal.c opusfile.c stream.c)
MULTIEMU_SRCS = $(wildcard $(XASH)/3rdparty/MultiEmulator/src/*.c)

BZIP2_DEFS  = -DBZ_NO_STDIO=1 -DBZ_UNIX=1
MPG123_DEFS = -DOPT_GENERIC -DREAL_IS_FLOAT
MPG123_INCS = -I$(GEN)/mpg123 -I$(XASH)/3rdparty/library_suffix/include \
	-I$(XASH)/3rdparty/mpg123/mpg123/src/include -I$(XASH)/3rdparty/mpg123/mpg123/src/libmpg123 \
	-I$(XASH)/3rdparty/mpg123/mpg123/src
OPUS_DEFS   = -DOPUS_BUILD -DFLOAT_APPROX -DPACKAGE_VERSION=\"1.4.0\" -DCUSTOM_MODES -DENABLE_HARDENING \
	-DHAVE_LRINT=1 -DHAVE_LRINTF=1 -DVAR_ARRAYS=1 \
	-DOPUS_X86_MAY_HAVE_SSE=1 -DOPUS_X86_PRESUME_SSE=1 -DOPUS_X86_MAY_HAVE_SSE2=1 -DOPUS_X86_PRESUME_SSE2=1
OPUS_INCS   = -I$(OPUS_DIR) -I$(OPUS_DIR)/include -I$(OPUS_DIR)/celt -I$(OPUS_DIR)/silk -I$(OPUS_DIR)/silk/float \
	-I$(OPUS_DIR)/silk/x86 -I$(OPUS_DIR)/celt/x86
OGG_INCS    = -I$(GEN) -I$(XASH)/3rdparty/libogg/libogg/include
VORBIS_INCS = $(OGG_INCS) -I$(XASH)/3rdparty/vorbis/vorbis-src/include -I$(XASH)/3rdparty/vorbis/vorbis-src/lib
OPUSFILE_INCS = $(OGG_INCS) -I$(OPUS_DIR)/include -I$(XASH)/3rdparty/opusfile/opusfile/include
MULTIEMU_INCS = -I$(XASH)/3rdparty/MultiEmulator/include -I$(XASH)/3rdparty/MultiEmulator/src

lib_objs = $(call obj,lib/$(1),$(2))

SERVER_ARCHIVES = $(BUILD)/libpublic.a $(BUILD)/libminiz.a $(BUILD)/libbzip2.a
GAME_ARCHIVES   = $(SERVER_ARCHIVES) $(BUILD)/libmpg123.a $(BUILD)/libopusfile.a $(BUILD)/libopus.a \
	$(BUILD)/libvorbis.a $(BUILD)/libogg.a $(BUILD)/libmultiemu.a

# --- the engines own libraries
FS_SRCS     = $(filter-out %/android.c,$(wildcard $(XASH)/filesystem/*.c)) $(wildcard $(XASH)/filesystem/*.cpp)
REF_SRCS    = $(wildcard $(XASH)/ref/soft/*.c) $(wildcard $(XASH)/ref/common/*.c)
REF_INCS    = -I$(XASH)/ref/soft -I$(XASH)/ref/common $(XASH_INCS)

# --- hlsdk, the game. the server is the game logic, the client is the hud etc
HLSDK_INCS = \
	-I$(HLSDK)/dlls \
	-I$(HLSDK)/common \
	-I$(HLSDK)/engine \
	-I$(HLSDK)/pm_shared \
	-I$(HLSDK)/game_shared \
	-I$(HLSDK)/public

HLSDK_DEFS = \
	-D_GNU_SOURCE \
	-DLINUX=1 -D_LINUX=1 \
	-Dstricmp=strcasecmp -Dstrnicmp=strncasecmp -D_snprintf=snprintf -D_vsnprintf=vsnprintf \
	-DCLIENT_WEAPONS=1 \
	-DCROWBAR_FIX_RAPID_CROWBAR=1 \
	-DSPEAKABLE_TARGETS=1 \
	-DHD_HUD_DEFAULT=1

SERVER_SRCS = \
	$(filter-out $(addprefix $(HLSDK)/dlls/,mpstubb.cpp stats.cpp Wxdebug.cpp),$(call glob,$(HLSDK)/dlls,*.cpp)) \
	$(wildcard $(HLSDK)/pm_shared/*.c) \
	$(HLSDK)/public/safe_snprintf.c \
	$(HLSDK)/game_shared/voice_gamemgr.cpp \
	$(HLSDK)/game_shared/vcs_info.c \
	$(HLSDK)/external/openbsd/strlcpy.c \
	$(HLSDK)/external/openbsd/strlcat.c

CLIENT_EXCLUDE = $(HLSDK)/cl_dll/GameStudioModelRenderer_Sample.cpp \
	$(addprefix $(HLSDK)/game_shared/,voice_vgui_tweakdlg.cpp voice_gamemgr.cpp voice_status.cpp)
CLIENT_SRCS = \
	$(filter-out $(CLIENT_EXCLUDE),$(call glob,$(HLSDK)/cl_dll,*.cpp) $(wildcard $(HLSDK)/game_shared/*.cpp)) \
	$(HLSDK)/game_shared/vcs_info.c \
	$(HLSDK)/public/safe_snprintf.c \
	$(wildcard $(HLSDK)/pm_shared/*.c) \
	$(addprefix $(HLSDK)/dlls/,crossbow.cpp crowbar.cpp egon.cpp gauss.cpp glock.cpp handgrenade.cpp hornetgun.cpp \
		mp5.cpp python.cpp rpg.cpp satchel.cpp shotgun.cpp squeakgrenade.cpp tripmine.cpp) \
	$(HLSDK)/external/openbsd/strlcpy.c \
	$(HLSDK)/external/openbsd/strlcat.c
VGUI_DIR    = $(HLSDK)/freevgui
VGUI_SRCS   = $(wildcard $(VGUI_DIR)/*.cpp $(VGUI_DIR)/controls/*.cpp $(VGUI_DIR)/platform/common/*.cpp \
	$(VGUI_DIR)/platform/posix/*.cpp $(VGUI_DIR)/platform/xash3d-fwgs/*.cpp)
CLIENT_DEFS = $(HLSDK_DEFS) -DCLIENT_DLL -DINTERNAL_VGUI_SUPPORT
CLIENT_INCS = -I$(HLSDK)/cl_dll $(HLSDK_INCS) -I$(HLSDK)/utils/vgui/include
VGUI_DEFS   = -DINTERNAL_VGUI_SUPPORT
VGUI_INCS   = -I$(VGUI_DIR) -I$(HLSDK)/engine -I$(HLSDK)/common -I$(HLSDK)/public

# --- the menu
MENU_DIR    = $(XASH)/3rdparty/mainui
MENU_SRCS   = $(wildcard $(MENU_DIR)/*.cpp $(MENU_DIR)/miniutl/*.cpp $(MENU_DIR)/font/*.cpp $(MENU_DIR)/menus/*.cpp \
	$(MENU_DIR)/menus/dynamic/*.cpp $(MENU_DIR)/model/*.cpp $(MENU_DIR)/controls/*.cpp)
MENU_DEFS   = -DSTDINT_H="<cstdint>" -DMAINUI_USE_CUSTOM_FONT_RENDER=1 -DMAINUI_USE_STB=1 -DNO_STL=1
MENU_INCS   = -I$(MENU_DIR) -I$(MENU_DIR)/miniutl -I$(MENU_DIR)/font -I$(MENU_DIR)/controls -I$(MENU_DIR)/menus \
	-I$(MENU_DIR)/model -I$(MENU_DIR)/sdk_includes/common -I$(MENU_DIR)/sdk_includes/engine \
	-I$(MENU_DIR)/sdk_includes/public -I$(MENU_DIR)/sdk_includes/pm_shared

FS_OBJS     = $(call obj,fs,$(FS_SRCS))
REF_OBJS    = $(call obj,ref,$(REF_SRCS))
SERVER_OBJS = $(call obj,server,$(SERVER_SRCS))
CLIENT_OBJS = $(call obj,client,$(CLIENT_SRCS)) $(call obj,vgui,$(VGUI_SRCS))
MENU_OBJS   = $(call obj,menu,$(MENU_SRCS))

SERVER_LIBS = filesystem_stdio server
GAME_LIBS   = filesystem_stdio server client menu ref_soft

.PHONY: all source patches blibc crime audio install initrd clean distclean

all: source blibc crime audio
	@$(MAKE) --no-print-directory -j$(JOBS) $(GAME) $(SERVER) $(BUILD)/extras.pk3

source: $(XASH)/.patched $(HLSDK)/.patched

$(XASH)/.patched: bleed/xash3d.patch bleed/library_suffix.patch bleed/mainui.patch
	@if [ ! -d $(XASH) ]; then rm -rf $(XASH).tmp && git clone --filter=blob:none $(XASH_REPO) $(XASH).tmp && mv $(XASH).tmp $(XASH); fi
	cd $(XASH) && git checkout -q -f $(XASH_COMMIT) && git submodule update -q --init -f $(XASH_MODULES)
	cd $(XASH)/3rdparty/mainui && git submodule update -q --init -f
	cd $(XASH)/3rdparty/library_suffix && git checkout -q -f . && if [ -s $(abspath bleed/library_suffix.patch) ]; then git apply $(abspath bleed/library_suffix.patch); fi
	cd $(XASH)/3rdparty/mainui && git checkout -q -f . && if [ -s $(abspath bleed/mainui.patch) ]; then git apply $(abspath bleed/mainui.patch); fi
	cd $(XASH) && if [ -s $(abspath bleed/xash3d.patch) ]; then git apply $(abspath bleed/xash3d.patch); fi
	@touch $@

$(HLSDK)/.patched: bleed/hlsdk.patch
	@if [ ! -d $(HLSDK) ]; then rm -rf $(HLSDK).tmp && git clone --filter=blob:none $(HLSDK_REPO) $(HLSDK).tmp && mv $(HLSDK).tmp $(HLSDK); fi
	cd $(HLSDK) && git checkout -q -f $(HLSDK_COMMIT) && git submodule update -q --init -f $(HLSDK_MODULES)
	cd $(HLSDK) && if [ -s $(abspath bleed/hlsdk.patch) ]; then git apply $(abspath bleed/hlsdk.patch); fi
	@touch $@

# rewrites the patches from whats changed in external/
patches:
	cd $(XASH) && git diff --ignore-submodules > $(abspath bleed/xash3d.patch)
	cd $(XASH)/3rdparty/library_suffix && git diff > $(abspath bleed/library_suffix.patch)
	cd $(XASH)/3rdparty/mainui && git diff > $(abspath bleed/mainui.patch)
	cd $(HLSDK) && git diff --ignore-submodules > $(abspath bleed/hlsdk.patch)
	@touch $(XASH)/.patched $(HLSDK)/.patched

blibc:
	@if [ ! -d "$(BLIBC_DIR)" ]; then git clone $(BLIBC_REPO) $(BLIBC_DIR); fi
	@$(MAKE) -C $(BLIBC_DIR) --no-print-directory

crime: blibc
	@if [ ! -d "$(CRIME_DIR)" ]; then git clone $(CRIME_REPO) $(CRIME_DIR); \
	elif [ "$(CRIME_DIR)" = "external/crime-scene" ]; then cd $(CRIME_DIR) && git pull -q --ff-only; fi
	@$(MAKE) -C $(CRIME_DIR) --no-print-directory bin/libcrime.a BLIBC_DIR=$(abspath $(BLIBC_DIR))
	@mkdir -p $(CRIME_OUT)/include/crime
	@cp -p $(CRIME_DIR)/include/crime/*.h $(CRIME_OUT)/include/crime/
	@cmp -s $(CRIME_DIR)/bin/libcrime.a $(CRIME_OUT)/libcrime.a || cp -p $(CRIME_DIR)/bin/libcrime.a $(CRIME_OUT)/libcrime.a

audio: blibc
	@if [ ! -d "$(AUDIO_DIR)" ]; then git clone $(AUDIO_REPO) $(AUDIO_DIR); \
	elif [ "$(AUDIO_DIR)" = "external/libaudio" ]; then cd $(AUDIO_DIR) && git pull -q --ff-only; fi
	@$(MAKE) -C $(AUDIO_DIR) --no-print-directory bin/libaudio.a BLIBC_DIR=$(abspath $(BLIBC_DIR))
	@mkdir -p $(AUDIO_OUT)/include
	@cp -p $(AUDIO_DIR)/include/bleed_audio.h $(AUDIO_OUT)/include/
	@cmp -s $(AUDIO_DIR)/bin/libaudio.a $(AUDIO_OUT)/libaudio.a || cp -p $(AUDIO_DIR)/bin/libaudio.a $(AUDIO_OUT)/libaudio.a

$(BUILD)/engine-ded/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(SERVER_ENGINE_DEFS) $(XASH_INCS) -I$(GEN)/ded -MMD -MP -c $< -o $@

$(BUILD)/engine/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(GAME_ENGINE_DEFS) $(GAME_ENGINE_INCS) -I$(GEN)/game -MMD -MP -c $< -o $@

$(BUILD)/lib/public/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(XASH_DEFS) $(XASH_INCS) -MMD -MP -c $< -o $@

$(BUILD)/lib/miniz/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(XASH_DEFS) $(XASH_INCS) -MMD -MP -c $< -o $@

$(BUILD)/lib/bzip2/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(BZIP2_DEFS) -I$(GEN) -MMD -MP -c $< -o $@

$(BUILD)/lib/mpg123/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -D__bleed__=1 $(MPG123_DEFS) $(MPG123_INCS) -MMD -MP -c $< -o $@

$(BUILD)/lib/ogg/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(OGG_INCS) -MMD -MP -c $< -o $@

$(BUILD)/lib/vorbis/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -DHAVE_ALLOCA_H=1 $(VORBIS_INCS) -MMD -MP -c $< -o $@

$(BUILD)/lib/opus/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(OPUS_DEFS) $(OPUS_INCS) -MMD -MP -c $< -o $@

$(BUILD)/lib/opusfile/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(OPUSFILE_INCS) -MMD -MP -c $< -o $@

$(BUILD)/lib/multiemu/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(MULTIEMU_INCS) -MMD -MP -c $< -o $@

$(BUILD)/fs/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(XASH_DEFS) $(XASH_INCS) -MMD -MP -c $< -o $@

$(BUILD)/fs/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -fno-rtti $(XASH_DEFS) $(XASH_INCS) -MMD -MP -c $< -o $@

$(BUILD)/ref/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(XASH_DEFS) -DREF_DLL=1 -DXASH_REF_SOFT_ENABLED=1 $(REF_INCS) -MMD -MP -c $< -o $@

$(BUILD)/server/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(HLSDK_DEFS) $(HLSDK_INCS) -MMD -MP -c $< -o $@

$(BUILD)/server/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -fno-rtti $(HLSDK_DEFS) $(HLSDK_INCS) -MMD -MP -c $< -o $@

$(BUILD)/client/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(CLIENT_DEFS) $(CLIENT_INCS) -MMD -MP -c $< -o $@

$(BUILD)/client/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(CLIENT_DEFS) $(CLIENT_INCS) -MMD -MP -c $< -o $@

$(BUILD)/vgui/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(VGUI_DEFS) $(VGUI_INCS) -MMD -MP -c $< -o $@

$(BUILD)/menu/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -fno-rtti $(MENU_DEFS) $(MENU_INCS) -MMD -MP -c $< -o $@

# --- generated headers
$(GEN)/bz_version.h:
	@mkdir -p $(dir $@)
	echo '#define BZ_VERSION "1.1.0-fwgs"' > $@

$(GEN)/ogg/config_types.h: $(XASH)/3rdparty/libogg/libogg/include/ogg/config_types.h.in
	@mkdir -p $(dir $@)
	sed -e 's/@INCLUDE_INTTYPES_H@/1/; s/@INCLUDE_STDINT_H@/0/; s/@INCLUDE_SYS_TYPES_H@/0/' \
	    -e 's/@SIZE16@/int16_t/; s/@USIZE16@/uint16_t/; s/@SIZE32@/int32_t/; s/@USIZE32@/uint32_t/' \
	    -e 's/@SIZE64@/int64_t/; s/@USIZE64@/uint64_t/' $< > $@

MPG123_CONFIG = PORTABLE_API=1 IEEE_FLOAT=1 GAPLESS=1 FRAME_INDEX=1 INDEX_SIZE=1000 USE_NEW_HUFFTABLE=1 \
	NO_LAYER1=1 NO_LAYER2=1 NO_8BIT=1 NO_32BIT=1 NO_REAL=1 NO_SYNTH32=1 NO_NTOM=1 NO_DOWNSAMPLE=1 \
	NO_EQUALIZER=1 NO_ICY=1 NO_STRING=1 NO_ID3V2=1 NO_MOREINFO=1 NO_WARNING=1 NO_ERRORMSG=1 NO_ERETURN=1 \
	HAVE_STRERROR=1 HAVE_SYS_TYPES_H=1 HAVE_UNISTD_H=1 HAVE_STRTOK_R=1

$(GEN)/mpg123/config.h: $(XASH)/3rdparty/mpg123/mpg123/src/config.h.in Makefile
	@mkdir -p $(dir $@)
	awk -v defs="$(MPG123_CONFIG)" 'BEGIN { n = split(defs, a, " "); for (i = 1; i <= n; i++) { split(a[i], kv, "="); d[kv[1]] = kv[2] }; print "#include \"build.h\"" } \
	    /^[ \t]*#[ \t]*undef[ \t]+[A-Za-z0-9_]+[ \t]*$$/ { name = $$NF; if (name in d) print "#define " name " " d[name]; else print "/* " $$0 " */"; next } { print }' $< > $@

$(GEN)/ded/generated_library_tables.h: Makefile
	@mkdir -p $(dir $@)
	{ for l in $(SERVER_LIBS); do echo "extern table_t lib_$${l}_exports[];"; done; \
	  echo 'struct { const char *name; void *func; } libs[] = {'; \
	  for l in $(SERVER_LIBS); do echo "{ \"$$l\", &lib_$${l}_exports },"; done; \
	  echo '{ 0, 0 } };'; } > $@

$(GEN)/game/generated_library_tables.h: Makefile
	@mkdir -p $(dir $@)
	{ for l in $(GAME_LIBS); do echo "extern table_t lib_$${l}_exports[];"; done; \
	  echo 'struct { const char *name; void *func; } libs[] = {'; \
	  for l in $(GAME_LIBS); do echo "{ \"$$l\", &lib_$${l}_exports },"; done; \
	  echo '{ 0, 0 } };'; } > $@

$(SERVER_ENGINE_OBJS): $(GEN)/ded/generated_library_tables.h
$(GAME_ENGINE_OBJS): $(GEN)/game/generated_library_tables.h
$(call lib_objs,bzip2,$(BZIP2_SRCS)): $(GEN)/bz_version.h
$(call lib_objs,mpg123,$(MPG123_SRCS)): $(GEN)/mpg123/config.h
$(call lib_objs,ogg,$(OGG_SRCS)) $(call lib_objs,vorbis,$(VORBIS_SRCS)) $(call lib_objs,opusfile,$(OPUSFILE_SRCS)) \
	$(GAME_ENGINE_OBJS): $(GEN)/ogg/config_types.h

# --- archives
$(BUILD)/libpublic.a:   $(call lib_objs,public,$(PUBLIC_SRCS))
$(BUILD)/libminiz.a:    $(call lib_objs,miniz,$(MINIZ_SRCS))
$(BUILD)/libbzip2.a:    $(call lib_objs,bzip2,$(BZIP2_SRCS))
$(BUILD)/libmpg123.a:   $(call lib_objs,mpg123,$(MPG123_SRCS))
$(BUILD)/libogg.a:      $(call lib_objs,ogg,$(OGG_SRCS))
$(BUILD)/libvorbis.a:   $(call lib_objs,vorbis,$(VORBIS_SRCS))
$(BUILD)/libopus.a:     $(call lib_objs,opus,$(OPUS_SRCS))
$(BUILD)/libopusfile.a: $(call lib_objs,opusfile,$(OPUSFILE_SRCS))
$(BUILD)/libmultiemu.a: $(call lib_objs,multiemu,$(MULTIEMU_SRCS))
$(GAME_ARCHIVES):
	rm -f $@
	$(AR) rcs $@ $^

# --- the dlopen libraries as one object each
c_exports = $(NM) -g --defined-only $(1) | awk '$$2 == "T" && $$3 !~ /^_Z/ { print $$3 }' | sort > $(2)

$(BUILD)/libs/filesystem_stdio.exports: $(XASH)/filesystem/exports.txt Makefile
	@mkdir -p $(dir $@)
	{ cat $(XASH)/filesystem/exports.txt; echo CreateInterface; } | sort -u > $@

$(BUILD)/libs/menu.exports: $(MENU_DIR)/exports.txt Makefile
	@mkdir -p $(dir $@)
	sort -u $(MENU_DIR)/exports.txt > $@

$(BUILD)/libs/server.all.o:   $(SERVER_OBJS)
$(BUILD)/libs/client.all.o:   $(CLIENT_OBJS)
$(BUILD)/libs/ref_soft.all.o: $(REF_OBJS)
$(BUILD)/libs/server.all.o $(BUILD)/libs/client.all.o $(BUILD)/libs/ref_soft.all.o:
	@mkdir -p $(dir $@)
	$(LD) -r -o $@ $^

$(BUILD)/libs/%.exports: $(BUILD)/libs/%.all.o Makefile
	$(call c_exports,$<,$@)

$(BUILD)/libs/%_exports.c: $(BUILD)/libs/%.exports
	{ sed 's/.*/extern void &(void);/' $<; \
	  echo 'struct { const char *name; void *func; } lib_$*_exports[] = {'; \
	  sed 's/.*/{ "&", \&& },/' $<; \
	  echo '{ 0, 0 } };'; } > $@

$(BUILD)/libs/%_exports.o: $(BUILD)/libs/%_exports.c
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/libs/filesystem_stdio.lib.o: $(FS_OBJS)
$(BUILD)/libs/menu.lib.o: $(MENU_OBJS)
$(BUILD)/libs/server.lib.o: $(BUILD)/libs/server.all.o
$(BUILD)/libs/client.lib.o: $(BUILD)/libs/client.all.o
$(BUILD)/libs/ref_soft.lib.o: $(BUILD)/libs/ref_soft.all.o

$(BUILD)/libs/%.lib.o: $(BUILD)/libs/%_exports.o
	$(LD) -r --force-group-allocation -o $@.unstripped $^
	$(OBJCOPY) -G lib_$*_exports $@.unstripped $@

ICONS = $(wildcard res/icon.png res/icon-16.png res/icon-32.png res/icon-48.png)

define embed_icons
	@if [ -f res/icon.png ]; then \
		$(OBJCOPY) --add-section .bleed.icon=res/icon.png \
			--set-section-flags .bleed.icon=noload,readonly $(1) || exit 1; \
	fi
	@for px in 16 32 48; do \
		if [ -f res/icon-$$px.png ]; then \
			$(OBJCOPY) --add-section .bleed.icon$$px=res/icon-$$px.png \
				--set-section-flags .bleed.icon$$px=noload,readonly $(1) || exit 1; \
		fi; \
	done
	@$(OBJCOPY) --add-section .bleed.app=res/app.txt \
		--set-section-flags .bleed.app=noload,readonly $(1)
endef

$(BUILD)/hlds.debug: $(SERVER_ENGINE_OBJS) $(addprefix $(BUILD)/libs/,$(addsuffix .lib.o,$(SERVER_LIBS))) $(SERVER_ARCHIVES)
	$(CXX) $(LDFLAGS) -o $@ $(SYSROOT)/lib/start.o $(filter %.o,$^) $(SERVER_ARCHIVES) $(SYSROOT)/lib/blibc.a -lgcc

$(BUILD)/halflife.debug: $(GAME_ENGINE_OBJS) $(addprefix $(BUILD)/libs/,$(addsuffix .lib.o,$(GAME_LIBS))) $(GAME_ARCHIVES) \
		$(CRIME_OUT)/libcrime.a $(AUDIO_OUT)/libaudio.a res/app.txt $(ICONS)
	$(CXX) $(LDFLAGS) -o $@ $(SYSROOT)/lib/start.o $(filter %.o,$^) $(GAME_ARCHIVES) \
		$(CRIME_OUT)/libcrime.a $(AUDIO_OUT)/libaudio.a $(SYSROOT)/lib/blibc.a -lgcc
	$(call embed_icons,$@)

bin/%: $(BUILD)/%.debug
	@mkdir -p bin
	x86_64-elf-strip -o $@ $<

$(BUILD)/extras.pk3: $(XASH)/.patched
	@mkdir -p $(dir $@)
	rm -f $@
	cd $(XASH)/3rdparty/extras/xash-extras && zip -q -r -X $(abspath $@) . -x 'scripts/*' -x '.*' -x '*/.*' -x '*.svg'

install: all
	cp $(GAME) $(SERVER) $(KERNEL_DIR)/initrd/bin/

GAME_DATA = hlx
initrd: source
	@test -n "$(INITRD)" || { echo "make initrd INITRD=<the kernels initrd folder>"; exit 1; }
	@test -d $(GAME_DATA)/valve || { echo "[HALFLIFE] ERROR: no game files, put Half-Lifes valve folder in $(abspath $(GAME_DATA))/valve"; exit 1; }
	@$(MAKE) --no-print-directory $(BUILD)/extras.pk3
	@echo "[HALFLIFE] Copying the game files into the initrd"
	@mkdir -p $(INITRD)/halflife
	@rsync -a --delete --exclude .DS_Store --exclude '._*' --exclude valve/extras.pk3 $(GAME_DATA)/ $(INITRD)/halflife/
	@cp $(BUILD)/extras.pk3 $(INITRD)/halflife/valve/extras.pk3

clean:
	rm -rf $(BUILD) bin

distclean: clean
	rm -rf external $(CRIME_OUT) $(AUDIO_OUT)

.PRECIOUS: $(BUILD)/libs/%_exports.c

-include $(shell find $(BUILD) -name '*.d' 2>/dev/null)
