TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = MobilePhone

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CallEndTime

CallEndTime_FILES = Sources/Tweak.swift Sources/Tweak.S
CallEndTime_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
