from conans import ConanFile
from conans.tools import download, unzip
import os

VERSION = "0.0.5"


class CMakeUnitConan(ConanFile):
    name = "cmake-unit"
    version = os.environ.get("CONAN_VERSION_OVERRIDE", VERSION)
    generators = "cmake"
    requires = ("cmake-include-guard/master@smspillaz/cmake-include-guard",
                "cmake-call-function/master@smspillaz/cmake-call-function",
                "cmake-opt-arg-parsing/master@smspillaz/cmake-opt-arg-parsing",
                "cmake-forward-cache/master@smspillaz/cmake-forward-cache",
                "cmake-spacify-list/master@smspillaz/cmake-spacify-list",
                "cmake-forward-arguments/master@smspillaz/cmake-forward-arguments")
    url = "http://github.com/polysquare/cmake-unit"
    license = "MIT"
    options = {
        "dev": [True, False]
    }
    default_options = "dev=False"

    def requirements(self):
        if self.options.dev:
            self.requires("cmake-module-common/master@smspillaz/cmake-module-common")

    def source(self):
        zip_name = "cmake-unit.zip"
        download("https://github.com/polysquare/"
                 "cmake-unit/archive/{version}.zip"
                 "".format(version="v" + VERSION),
                 zip_name)
        unzip(zip_name)
        os.unlink(zip_name)

    def package(self):
        self.copy(pattern="*.cmake",
                  dst="cmake/cmake-unit",
                  src="cmake-unit-" + VERSION,
                  keep_path=True)
