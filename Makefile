ARCHS = arm64
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ChinaMobileAdBlock

ChinaMobileAdBlock_FILES = ChinaMobileAdBlock.xm
ChinaMobileAdBlock_CFLAGS = -fobjc-arc
ChinaMobileAdBlock_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
