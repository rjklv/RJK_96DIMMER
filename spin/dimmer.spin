CON
        _clkmode = xtal1 + pll16x                                     'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

        txpin=30
        rxpin=31

        i2cSCLeeprom=28
        i2cSDAeeprom=29

con
        sctPhase0CLK = 6  
        sctPhase0SDI = 7
        sctPhase0LA = 8        

        sctPhase1CLK = 0  
        sctPhase1SDI = 1
        sctPhase1LA = 2        

        sctPhase2CLK = 3  
        sctPhase2SDI = 4
        sctPhase2LA = 5        

OBJ
        serial    : "my_PBnJ_serial"
        dmx       : "jm_dmxin"        
VAR
        long  sctState[3]
        long sctStack[32]
PUB main
        serial.start(rxpin,txpin,115_200)
        
        '' -- rx...... receive pin#
        '' -- led..... pin# to indicate dmx activity
        '' -- start... initial start byte value for stream
        '' -- level... initial value from all frames in buffer
        dmx.init(20, 21, 0, 0)
        
        cognew(doSCT,@sctStack)
        repeat
            'nasingdiong
        
pub doSCT|i
    dira[sctPhase0CLK]~~
    dira[sctPhase1CLK]~~
    dira[sctPhase2CLK]~~
    
    dira[sctPhase0SDI]~~
    dira[sctPhase1SDI]~~
    dira[sctPhase2SDI]~~
    
    dira[sctPhase0LA]~~
    dira[sctPhase1LA]~~
    dira[sctPhase2LA]~~            
    
    repeat
        repeat i from 0 to 31
            sctState[0]:= |< i
            setsct
            waitcnt(clkfreq+cnt) 

pub setSCT
    repeat 32
      outa[sctPhase0CLK]~
      if sctState[0] & |< 31
        outa[sctPhase0SDI]~~
      else
        outa[sctPhase0SDI]~                
      sctState[0] <<= 1
      outa[sctPhase0CLK]~~
      
      outa[sctPhase1CLK]~
      if sctState[1] & |< 31
        outa[sctPhase1SDI]~~
      else
        outa[sctPhase1SDI]~                
      sctState[1] <<= 1
      outa[sctPhase1CLK]~~

      outa[sctPhase2CLK]~
      if sctState[2] & |< 31
        outa[sctPhase2SDI]~~
      else
        outa[sctPhase2SDI]~                
      sctState[2] <<= 1
      outa[sctPhase2CLK]~~

    outa[sctPhase0LA]~~      
    outa[sctPhase1LA]~~
    outa[sctPhase2LA]~~

    outa[sctPhase0LA]~
    outa[sctPhase1LA]~
    outa[sctPhase2LA]~
