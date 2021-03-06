CON
        _clkmode = xtal1 + pll16x                                     'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

        CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
        MS_001   = CLK_FREQ / 1_000
  
        txpin=30
        rxpin=31     
CON

    phasecount=MS_001*10
    
    phaseZeroIn1=4
    phaseZeroIn2=5
    phaseZeroIn3=6
var
    long generatorstack[32]
OBJ
        serial    : "my_PBnJ_serial"     
        
PUB main|i
    serial.start(rxpin,txpin,115_200)
        

    cognew(generate,@generatorstack)
    repeat

pub generate|phase1off,phase1on,phase2off,phase2on,phase3off,phase3on
    dira[phaseZeroIn1]~~
    dira[phaseZeroIn2]~~    
    dira[phaseZeroIn3]~~

    outa[phaseZeroIn1]~
    outa[phaseZeroIn2]~
    outa[phaseZeroIn3]~        
    
    phase1on:=cnt+phasecount
    phase1off:=phase1on+MS_001
    phase2on:=phase1on+constant(phasecount/3)
    phase2off:=phase2on+MS_001
    phase3on:=phase2on+constant(phasecount/3)
    phase3off:=phase3on+MS_001
    
    repeat
        waitcnt(phase1on)
        dira[phaseZeroIn1]~~
        phase1on+=phasecount
        waitcnt(phase1off)
        dira[phaseZeroIn1]~
        phase1off+=phasecount

        waitcnt(phase2on)
        dira[phaseZeroIn2]~~
        phase2on+=phasecount
        waitcnt(phase2off)        
        dira[phaseZeroIn2]~        
        phase2off+=phasecount

        waitcnt(phase3on)
        dira[phaseZeroIn3]~~       
        phase3on+=phasecount
        waitcnt(phase3off)        
        dira[phaseZeroIn3]~ 
        phase3off+=phasecount
        