ARCHS = arm64
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TOOL_NAME = mycontrold
mycontrold_FILES = daemon/main.mm daemon/HTTPServer.mm daemon/ScriptRunner.mm daemon/FileStore.mm daemon/ScreenCapture.mm
mycontrold_CFLAGS = -fobjc-arc -Wall -Wextra
mycontrold_FRAMEWORKS = Foundation UIKit CoreGraphics ImageIO QuartzCore
mycontrold_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk

SUBPROJECTS += app
include $(THEOS_MAKE_PATH)/aggregate.mk

before-package::
	@echo "Packaging MyControl 0.4.0"
