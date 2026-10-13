ARCHS = arm64
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TOOL_NAME = mycontrold
mycontrold_FILES = daemon/main.mm daemon/HTTPServer.mm daemon/ScriptRunner.mm daemon/FileStore.mm daemon/TouchInjector.mm daemon/ScreenCapture.mm
mycontrold_CFLAGS = -fobjc-arc -Wall -Wextra
mycontrold_FRAMEWORKS = Foundation UIKit CoreGraphics IOSurface ImageIO QuartzCore
mycontrold_CODESIGN_FLAGS = -Sentitlements.plist
mycontrold_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk

before-package::
	@echo "Packaging MyControl 0.3.0"
