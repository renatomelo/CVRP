#Fork of Makefile-with-Lemon-installed. By mhmulati.

#================= GUROBI =====================================================
VERSION := $(shell gurobi_cl --version | cut -c 26,28,30 | head -n 1)
FLAGVERSION := $(shell gurobi_cl --version | cut -c 26,28 | head -n 1)
OPTS_FLAGS := -O3 -w -fforce-addr -funroll-loops -frerun-cse-after-loop \
      -finline-limit=100000 -frerun-loop-opt -fno-trapping-math \
			-funsafe-math-optimizations -ffast-math -fno-math-errno \
			-mtune=x86-64
			
ifeq ($(shell uname), Darwin)
        $(info )
        $(info *)
        $(info *        Makefile for MAC OS environment)
        $(info *)
	PLATFORM = mac64
	ifneq ($(RELEASE), 11)
                # The next variable must be used to compile *and* link the obj. codes
		CPPSTDLIB = -stdlib=libc++
	else
                $(info )
                $(info *    Gurobi library is not compatible with code)
                $(info *    generated by clang c++11 in MAC OS.)
                $(info *    Please, verify if it is compatible now.)
                $(info *)
                $(info *    >>>>> Aborted <<<<<)
                $(info *)
                $(error *)
		CPPSTDLIB = -stdlib=libc++ -std=c++11
	endif
	CC      = g++
	#CC_ARGS    = -Wall -m64 -O3 -Wall $(CPPSTDLIB)  -Wno-c++11-extensions
	CC_ARGS    =  -m64  $(OPTS_FLAGS) -w -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=0 
	RELEASE := $(shell uname -r | cut -f 1 -d .)
	CC_LIB   = -lm -lpthread $(CPPSTDLIB)
	GUROBI_DIR = /Library/gurobi$(VERSION)/$(PLATFORM)
else
        $(info )
        $(info *)
        $(info *        Makefile for LINUX environment)
        $(info *)
	PLATFORM = linux64
	CC      = g++
	#CC_ARGS    = -m64 -O2 -Wall -std=c++11
	CC_ARGS    = -m64 $(OPTS_FLAGS) -w -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=0 
	RELEASE := $(shell uname -r | cut -f 1 -d .)
	CC_LIB   = -lm -lpthread
	GUROBI_DIR = /home/matheus/gurobi$(VERSION)/$(PLATFORM)
endif
GUROBI_INC = -I$(GUROBI_DIR)/include/
GUROBI_LIB = -L$(GUROBI_DIR)/lib/  -lgurobi_c++ -lgurobi$(FLAGVERSION)  $(CPPSTDLIB)
#================= LEMON =====================================================

LEMONDIR  = /home/matheus/lemon
LEMONINCDIR  = -I$(LEMONDIR)/include
LEMONLIBDIR  = -L$(LEMONDIR)/lib

#================= CVRPSEP =====================================================
CVRPSEPDIR  = CVRPSEP
CVRPSEPINCDIR  = -I$(CVRPSEPDIR)/include
CVRPSEPLIBDIR  = $(CVRPSEPDIR)/lib/libCVRPSEP.a

#================= DINPROG =====================================================
DINPROGDIR  = DinProg
DINPROGINCDIR  = -I$(DINPROGDIR)/include
DINPROGSOURCESDIR  = $(DINPROGDIR)/source
DINPROGSOURCES = $(wildcard $(DINPROGSOURCESDIR)/*.cpp)
DINPROGOBJLIB = $(DINPROGSOURCES:.cpp=.o)
DINPROGLIBDIR  = dinprog.a

#================= SCIP =====================================================
SCIPINC  = -Isrc -DWITH_SCIPDEF -I/home/matheus/scip/scip-4.0.0/src -DNDEBUG -DROUNDING_FE  -DNPARASCIP -DWITH_ZLIB  -DWITH_GMP  -DWITH_READLINE
SCIPLIB = -L/home/matheus/scip/scip-4.0.0/lib/static -ldl -lscip.linux.x86_64.gnu.opt -lobjscip.linux.x86_64.gnu.opt -llpicpx.linux.x86_64.gnu.opt -lnlpi.cppad.linux.x86_64.gnu.opt -ltpinone.linux.x86_64.gnu.opt -O3 -fomit-frame-pointer -mtune=native -lcplex.linux.x86_64.gnu -lm -m64  -lz -lzimpl.linux.x86_64.gnu.opt  -lgmp -lreadline -lncurses -lm -m64  -lz -lzimpl.linux.x86_64.gnu.opt  -lgmp -lreadline -lncurses
#---------------------------------------------
# define includes and libraries

INC = $(GUROBI_INC) $(LEMONINCDIR) $(DINPROGINCDIR) $(CVRPSEPINCDIR) $(SCIPINC)
LIB = $(CC_LIB) $(GUROBI_LIB)  $(LEMONLIBDIR) $(SCIPLIB) -lemon 


# g++ -m64 -g -o exe readgraph.cpp viewgraph.cpp adjacencymatrix.cpp ex_fractional_packing.o -I/Library/gurobi600/mac64/include/ -L/Library/gurobi600/mac64/lib/ -lgurobi_c++ -lgurobi60 -stdlib=libstdc++ -lpthread -lm
# g++ -m64 -g -c adjacencymatrix.cpp -o adjacencymatrix.o -I/Library/gurobi600/mac64/include/  -stdlib=libstdc++ 

MYLIBSOURCES = mygraphlib.cpp geompack.cpp myutils.cpp conspool.cpp varpool.cpp cvrpalgsscip.cpp cvrpcutscallbackscip.cpp  cvrpbranchingrule.cpp dpcaller.cpp cvrppricerscip.cpp cvrpbranchingmanager.cpp
MYOBJLIB = $(MYLIBSOURCES:.cpp=.o)

EX =  cvrp.cpp
OBJEX = $(EX:.cpp=.o)

EXE = $(EX:.cpp=.e)

all: mylib.a $(OBJEX) $(EXE)

mylib.a: $(MYOBJLIB) $(MYLIBSOURCES)
	#libtool -o $@ $(MYOBJLIB)
	ar cru $@ $(MYOBJLIB)
	#ar cr $@ $(MYOBJLIB)  # by mhmulati, https://bugzilla.redhat.com/show_bug.cgi?id=1155273

dinprog.a: $(DINPROGOBJLIB) $(DINPROGSOURCES)
	ar cru $@ $(DINPROGOBJLIB)
	
%.o: %.cpp 
	$(CC) $(CC_ARGS) -c $^ $(INC) -o $@  

%.e: %.o  mylib.a $(DINPROGLIBDIR)
	$(CC) $(CC_ARGS) $^ -o $@ $(DINPROGLIBDIR) $(CVRPSEPLIBDIR) $(LIB) 

.cpp.o:
	$(CC) -c $(CARGS) $< -o $@

clean:
	rm -f $(OBJ) $(MYOBJLIB) $(EXE) $(OBJEX) *~ core mylib.a