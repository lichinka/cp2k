DIMS         = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 
DIMS_INDICES = $(foreach m,$(DIMS),$(foreach n,$(DIMS),$(foreach k,$(DIMS),$m_$n_$k)))

SI = 1
EI = $(words $(DIMS_INDICES))
INDICES = $(wordlist $(SI),$(EI),$(DIMS_INDICES))

OUTDIR=output_cray.gnu

SRCFILES=$(patsubst %,tiny_find_%.f90,$(INDICES)) 
OBJFILES=$(patsubst %,$(OUTDIR)/tiny_find_%.o,$(INDICES)) 
OUTFILES=$(OBJFILES:.o=.out) 

EXE=$(OUTDIR)/tiny_find_$(firstword $(INDICES))__$(lastword $(INDICES)).x 

.PHONY: bench $(EXE:.x=.f90) 
all: bench 

DATATYPE=REAL(KIND=KIND(0.0D0))
include ../make.gen

bench: $(EXE) 
	 rm -f $(OUTFILES) 
	 export OMP_NUM_THREADS=16 ; ./$< 

$(EXE): $(OBJFILES) $(EXE:.x=.f90)
	 ftn -O2 -funroll-loops -ffast-math -ftree-vectorize -cpp -finline-functions -fopenmp -march=native $^ -o $@  

compile: $(OBJFILES) 
$(OUTDIR)/%.o: %.f90 
	 ftn -O2 -funroll-loops -ffast-math -ftree-vectorize -cpp -finline-functions -fopenmp -march=native -c $< -o $@ 

source: $(SRCFILES) 
%.f90: 
	 .././tiny_gen.x `echo $* | awk -F_ '{ print $$3" "$$4" "$$5 }'` 1 1 > $@ 

