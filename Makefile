CROSS_COMPILE = armv7a-hardfloat-linux-gnueabi-
LD = $(CROSS_COMPILE)ld.gold
AS = $(CROSS_COMPILE)as
ANDROID_APK_NATIVE_LIB_DIR = ./apk/app/src/main/jniLibs
ANDROID_LIBNAME = libarcane.so
SOURCE = decypherArcane.s
OBJECT = decypherArcane.o

.PHONY: all
all: $(OBJECT)
	$(LD) -shared --dynamic-linker=/system/bin/linker --hash-style=sysv -o $(ANDROID_LIBNAME) $(OBJECT)
	mkdir -p $(ANDROID_APK_NATIVE_LIB_DIR)/armeabi{,-v7a}
	cp $(ANDROID_LIBNAME) $(ANDROID_APK_NATIVE_LIB_DIR)/armeabi
	cp $(ANDROID_LIBNAME) $(ANDROID_APK_NATIVE_LIB_DIR)/armeabi-v7a

.PHONY: install
install: all
	make -C apk

$(OBJECT): $(SOURCE)
	$(AS) -o $(OBJECT) $(SOURCE)

.PHONY: clean
clean:
	$(RM) $(OBJECT) $(ANDROID_LIBNAME)

.PHONY: distclean
distclean: clean
	$(RM) $(ANDROID_APK_NATIVE_LIB_DIR)/armeabi/$(ANDROID_LIBNAME)
	$(RM) $(ANDROID_APK_NATIVE_LIB_DIR)/armeabi-v7a/$(ANDROID_LIBNAME)
