# Makefile for pybindstan
#
# This Makefile generates code and builds the libraries used by pybindstan
#
# Code generation rules appear in this Makefile. One pybindstan-specific library
# is built using rules defined in this Makefile. Other libraries used by all
# Stan interfaces are built using rules defined in `Makefile.libraries`.  This
# Makefile calls `make` to run `Makefile.libraries`. Note that some rules in
# this Makefile copy libraries built by the other Makefile into their
# pybindstan-specific directories.

PYBIND11_VERSION := 2.6.2
RAPIDJSON_VERSION := 1.1.0
STAN_VERSION := 2.27.0
STANC_VERSION := 2.27.0
MATH_VERSION := 4.1.0
# NOTE: boost, eigen, sundials, and tbb versions must match those found in Stan Math
BOOST_VERSION := 1.75.0
EIGEN_VERSION := 3.3.9
SUNDIALS_VERSION := 5.7.0
TBB_VERSION := 2020.3
PYBIND11_ARCHIVE := build/archives/pybind11-$(PYBIND11_VERSION).tar.gz
RAPIDJSON_ARCHIVE := build/archives/rapidjson-$(RAPIDJSON_VERSION).tar.gz

STAN_ARCHIVE := build/archives/stan-v$(STAN_VERSION).tar.gz
MATH_ARCHIVE := build/archives/math-v$(MATH_VERSION).tar.gz
HTTP_ARCHIVES := $(STAN_ARCHIVE) $(MATH_ARCHIVE) $(PYBIND11_ARCHIVE) $(RAPIDJSON_ARCHIVE)
HTTP_ARCHIVES_EXPANDED := build/stan-$(STAN_VERSION) build/math-$(MATH_VERSION) build/pybind11-$(PYBIND11_VERSION) build/rapidjson-$(RAPIDJSON_VERSION)

SUNDIALS_LIBRARIES := pybindstan/lib/libsundials_nvecserial.a pybindstan/lib/libsundials_cvodes.a pybindstan/lib/libsundials_idas.a pybindstan/lib/libsundials_kinsol.a
TBB_LIBRARIES := pybindstan/lib/libtbb.so
ifeq ($(shell uname -s),Darwin)
  TBB_LIBRARIES += pybindstan/lib/libtbbmalloc.so pybindstan/lib/libtbbmalloc_proxy.so
endif
STAN_LIBRARIES := $(SUNDIALS_LIBRARIES) $(TBB_LIBRARIES)
LIBRARIES := $(STAN_LIBRARIES)
INCLUDES_STAN_MATH_LIBS := pybindstan/include/boost pybindstan/include/Eigen pybindstan/include/sundials pybindstan/include/tbb
INCLUDES_STAN := pybindstan/include/stan pybindstan/include/stan/math $(INCLUDES_STAN_MATH_LIBS)
INCLUDES := pybindstan/include/pybind11 pybindstan/include/rapidjson $(INCLUDES_STAN)
STANC := pybindstan/stanc
PRECOMPILED_OBJECTS = pybindstan/stan_services.o

default: $(LIBRARIES) $(INCLUDES) $(STANC) $(PRECOMPILED_OBJECTS)


###############################################################################
# Download archives via HTTP and extract them
###############################################################################
build/archives:
	@mkdir -p build/archives

$(PYBIND11_ARCHIVE): | build/archives
	@echo downloading $@
	curl --silent --location https://github.com/pybind/pybind11/archive/v$(PYBIND11_VERSION).tar.gz -o $@

$(RAPIDJSON_ARCHIVE): | build/archives
	@echo downloading $@
	@curl --silent --location https://github.com/Tencent/rapidjson/archive/v$(RAPIDJSON_VERSION).tar.gz -o $@

$(STAN_ARCHIVE): | build/archives
	@echo downloading $@
	@curl --silent --location https://github.com/stan-dev/stan/archive/v$(STAN_VERSION).tar.gz -o $@

$(MATH_ARCHIVE): | build/archives
	@echo downloading $@
	@curl --silent --location https://github.com/stan-dev/math/archive/v$(MATH_VERSION).tar.gz -o $@

build/pybind11-$(PYBIND11_VERSION): $(PYBIND11_ARCHIVE)
build/rapidjson-$(RAPIDJSON_VERSION): $(RAPIDJSON_ARCHIVE)
build/stan-$(STAN_VERSION): $(STAN_ARCHIVE)
build/math-$(MATH_VERSION): $(MATH_ARCHIVE)

$(HTTP_ARCHIVES_EXPANDED):
	@echo extracting archive $<
	tar -C build -zxf $<
	touch $@

###############################################################################
# Download and install stanc
###############################################################################
ifeq ($(shell uname -s),Darwin)
build/stanc:
	curl --location https://github.com/stan-dev/stanc3/releases/download/v$(STANC_VERSION)/mac-stanc -o $@ --retry 5 --fail
else
build/stanc:
	curl --location https://github.com/stan-dev/stanc3/releases/download/v$(STANC_VERSION)/linux-stanc -o $@ --retry 5 --fail
endif

$(STANC): build/stanc
	rm -f $@ && cp -r $< $@ && chmod u+x $@

###############################################################################
# pybind11
###############################################################################
pybindstan/include/pybind11: build/pybind11-$(PYBIND11_VERSION)/include/pybind11 | build/pybind11-$(PYBIND11_VERSION)
	@mkdir -p pybindstan/include
	@rm -rf $@
	cp -r $< $@

build/pybind11-$(PYBIND11_VERSION)/include/pybind11: | build/pybind11-$(PYBIND11_VERSION)

###############################################################################
# rapidjson
###############################################################################
pybindstan/include/rapidjson: build/rapidjson-$(RAPIDJSON_VERSION)/include/rapidjson | build/rapidjson-$(RAPIDJSON_VERSION)
	@mkdir -p pybindstan/include
	@rm -rf $@
	cp -r $< $@

build/rapidjson-$(RAPIDJSON_VERSION)/include/rapidjson: | build/rapidjson-$(RAPIDJSON_VERSION)

###############################################################################
# Make local copies of C++ source code used by Stan
###############################################################################

pybindstan/include/stan: | build/stan-$(STAN_VERSION)
	@mkdir -p pybindstan/include
	@rm -rf $@
	cp -r build/stan-$(STAN_VERSION)/src/stan $@

pybindstan/include/stan/math: | build/math-$(MATH_VERSION)
	@mkdir -p pybindstan/include/stan
	@rm -rf $@ pybindstan/include/stan/math.hpp pybindstan/include/stan/math
	cp build/math-$(MATH_VERSION)/stan/math.hpp pybindstan/include/stan
	cp -r build/math-$(MATH_VERSION)/stan/math pybindstan/include/stan

pybindstan/include/boost: | build/math-$(MATH_VERSION)
	@mkdir -p pybindstan/include
	@rm -rf $@
	cp -r build/math-$(MATH_VERSION)/lib/boost_$(BOOST_VERSION)/boost $@

EIGEN_INCLUDES := Eigen unsupported
pybindstan/include/Eigen: | build/math-$(MATH_VERSION)
	@mkdir -p pybindstan/include
	@rm -rf $(addprefix pybindstan/include/,$(EIGEN_INCLUDES))
	cp -r $(addprefix build/math-$(MATH_VERSION)/lib/eigen_$(EIGEN_VERSION)/,$(EIGEN_INCLUDES)) pybindstan/include

SUNDIALS_INCLUDES := cvodes idas kinsol nvector sundials sunlinsol sunmatrix sunmemory sunnonlinsol stan_sundials_printf_override.hpp sundials_debug.h
pybindstan/include/sundials: | build/math-$(MATH_VERSION)
	@mkdir -p pybindstan/include
	@rm -rf $(addprefix pybindstan/include/,$(SUNDIALS_INCLUDES))
	cp -r $(addprefix build/math-$(MATH_VERSION)/lib/sundials_$(SUNDIALS_VERSION)/include/,$(SUNDIALS_INCLUDES)) pybindstan/include

pybindstan/include/tbb: | build/math-$(MATH_VERSION)
	@mkdir -p pybindstan/include
	@rm -rf tbb
	cp -r build/math-$(MATH_VERSION)/lib/tbb_$(TBB_VERSION)/include/tbb pybindstan/include

###############################################################################
# Make local copies of shared libraries built by Stan Math's Makefile rules
###############################################################################

pybindstan/lib/%: build/math-$(MATH_VERSION)/lib/sundials_$(SUNDIALS_VERSION)/lib/%
	mkdir -p pybindstan/lib
	cp $< $@

# Stan Math builds a library with suffix .so.2 by default. Python prefers .so.
# Do not use symlinks since these will be ignored by Python wheel builders
# WISHLIST: Understand why Python needs both .so and .so.2.
ifeq ($(shell uname -s),Darwin)
pybindstan/lib/libtbb.so: build/math-$(MATH_VERSION)/lib/tbb/libtbb.dylib
	cp $< pybindstan/lib/$(notdir $<)
	@rm -f $@
	cd $(dir $@) && cp $(notdir $<) $(notdir $@)

pybindstan/lib/libtbb%.so: build/math-$(MATH_VERSION)/lib/tbb/libtbb%.dylib
	cp $< pybindstan/lib/$(notdir $<)
	@rm -f $@
	cd $(dir $@) && cp $(notdir $<) $(notdir $@)
else
pybindstan/lib/libtbb.so: build/math-$(MATH_VERSION)/lib/tbb/libtbb.so.2
	cp $< pybindstan/lib/$(notdir $<)
	@rm -f $@
	cd $(dir $@) && cp $(notdir $<) $(notdir $@)

pybindstan/lib/libtbb%.so: build/math-$(MATH_VERSION)/lib/tbb/libtbb%.so.2
	cp $< pybindstan/lib/$(notdir $<)
	@rm -f $@
	cd $(dir $@) && cp $(notdir $<) $(notdir $@)
endif

###############################################################################
# Build Stan-related shared libraries using Stan Math's Makefile rules
###############################################################################
# The file `Makefile.libraries` is a trimmed version of Stan Math's `makefile`,
# which uses the `include` directive to add rules from the `make/libraries`
# file (in Stan Math). `make/libraries` has all the rules required to build
# libsundials, libtbb, etc.
export MATH_VERSION

# locations where Stan Math's Makefile expects to output the shared libraries
SUNDIALS_LIBRARIES_BUILD_LOCATIONS := $(addprefix build/math-$(MATH_VERSION)/lib/sundials_$(SUNDIALS_VERSION)/lib/,$(notdir $(SUNDIALS_LIBRARIES)))
ifeq ($(shell uname -s),Darwin)
  TBB_LIBRARIES_BUILD_LOCATIONS := build/math-$(MATH_VERSION)/lib/tbb/libtbb.dylib build/math-$(MATH_VERSION)/lib/tbb/libtbbmalloc.dylib build/math-$(MATH_VERSION)/lib/tbb/libtbbmalloc_proxy.dylib
else
  TBB_LIBRARIES_BUILD_LOCATIONS := build/math-$(MATH_VERSION)/lib/tbb/libtbb.so.2 build/math-$(MATH_VERSION)/lib/tbb/libtbbmalloc.so.2 build/math-$(MATH_VERSION)/lib/tbb/libtbbmalloc_proxy.so.2
endif

$(TBB_LIBRARIES_BUILD_LOCATIONS) $(SUNDIALS_LIBRARIES_BUILD_LOCATIONS): | build/math-$(MATH_VERSION)
	$(MAKE) -f Makefile.libraries $@

# the following rule is required for parallel make
build/math-$(MATH_VERSION)/lib/tbb/libtbbmalloc_proxy.dylib: build/math-$(MATH_VERSION)/lib/tbb/libtbbmalloc.dylib

###############################################################################
# Precompile pybindstan-related objects, eventually linked in pybindstan/models.py
###############################################################################


PYTHON_CXX ?= $(shell python3 -c 'import sysconfig;print(" ".join(sysconfig.get_config_vars("CXX")))')
PYTHON_CFLAGS ?= $(shell python3 -c 'import sysconfig;print(" ".join(sysconfig.get_config_vars("CFLAGS")))')
PYTHON_CCSHARED ?= $(shell python3 -c 'import sysconfig;print(" ".join(sysconfig.get_config_vars("CCSHARED")))')
PYTHON_INCLUDE ?= -I$(shell python3 -c'import sysconfig;print(sysconfig.get_path("include"))')
PYTHON_PLATINCLUDE ?= -I$(shell python3 -c'import sysconfig;print(sysconfig.get_path("platinclude"))')

# the following variables should match those in pybindstan/models.py
# One include directory is absent: `model_directory_path` as this only
# exists when the extension module is ready to be linked
pybindstan_EXTRA_COMPILE_ARGS ?= -O3 -std=c++14
pybindstan_MACROS = -DBOOST_DISABLE_ASSERTS -DBOOST_PHOENIX_NO_VARIADIC_EXPRESSION -DSTAN_THREADS -D_REENTRANT -D_GLIBCXX_USE_CXX11_ABI=0
pybindstan_INCLUDE_DIRS = -Ipybindstan -Ipybindstan/include

pybindstan/stan_services.o: pybindstan/stan_services.cpp pybindstan/socket_logger.hpp pybindstan/socket_writer.hpp | $(INCLUDES)

pybindstan/stan_services.o:
	# -fvisibility=hidden required by pybind11
	$(PYTHON_CXX) \
		$(PYTHON_CFLAGS) \
		$(PYTHON_CCSHARED) \
		$(pybindstan_MACROS) \
		$(pybindstan_INCLUDE_DIRS) \
		$(PYTHON_INCLUDE) \
		$(PYTHON_PLATINCLUDE) \
		-fvisibility=hidden \
		-c $< -o $@ \
		$(pybindstan_EXTRA_COMPILE_ARGS)
