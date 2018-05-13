;===============================================================================
;Main IRQ routine
;===============================================================================
IRQMain                         dec             VICIRQRequest                   ;IRQ accepted
                                jsr             ScoreSound2                     ;Test if score effect's second
                                                                                ;half should be played
                                jsr             FadeSound2                      ;Play fade sound, if needed
                                lda             IRQBackgroundColor              ;Sets lightblue background
                                sta             BackgroundColor                 

                                lda             IsFlappyDead                    ;Is flappy dead?
                                beq             IRQMainDoScroll                 ;No, scroll the screen
                                lda             ScrollX                         ;If so, we scroll to schar perfect state
                                beq             IRQMainSkipScroll               ;(Scroll pos = 0)
IRQMainDoScroll                 dec             ScrollX                         ;Scroll one pixel to right
                                lda             ScrollX                         
                                and             #7                              
                                sta             ScrollX                         

                                lda             VICControlRegister2             
                                and             #%11111000                      
                                ora             ScrollX                         
                                sta             VICControlRegister2             

IRQMainSkipScroll               ldx             GameMode                        ;Go to do some game mode specific
                                lda             GameModeIRQAddressesLo,x        ;stuff
                                sta             IRQJump+1                       
                                lda             GameModeIRQAddressesHi,x        
                                sta             IRQJump+2                       
IRQJump                         jsr             GameJump

                                inc             GameModeCounterLo               ;Increment game mode counter
                                bne             NoCarryOnGMCounter              
                                inc             GameModeCounterHi               
                                bne             NoCarryOnGMCounter              
                                inc             GameModeCounterHi               
NoCarryOnGMCounter              lda             GameModeFinishLimit             ;If there is a game mode finish limit...
                                beq             NoGameModeFinishLimit           
                                inc             GameModeFinishCounter           ;...we also incement the finish counter
NoGameModeFinishLimit           jsr             UpdateJoyState                  ;Read joy state
                                jmp             KernalIRQExit                   ;return from IRQ

;===============================================================================
;Set background color on raster row
;In:  AC: IRQ routine (lower 8 bits)
;     YR: IRQ routine (higher 8 bits)
;     XR: raster row (lower 8 bits)
;===============================================================================
SetRasterIRQ
                                stx             VICIRQRasterLow                 
                                sta             IRQVector                       
                                sty             IRQVector + 1
                                rts

;===============================================================================
;Set background color on raster row
;In:  AC: color
;     XR: raster row (lower 8 bits)
;===============================================================================
SetBackgroundOnRaster           cpx             VICIRQRasterLow                 ;Wait for raster line
                                bne             SetBackgroundOnRaster           
                                sta             BackgroundColor                 ;Set color
                                rts

;===============================================================================
;Intro IRQ routine
;===============================================================================
IRQIntro                        lda             GameModeCounterHi               ;In the first 8 frames
                                bne             IRQIntroNoFade                  ;Character colors of the last 4 lines
                                lda             GameModeCounterLo               ;also have to fade in 
                                cmp             #8                              ;from black to yellow
                                bcs             IRQIntroNoFade                  
                                lda             IRQCharColor                    
                                ldy             #160                            
IRQIntroSetCharColor            sta             $db47,y
                                dey
                                bne             IRQIntroSetCharColor            
IRQIntroNoFade                  jsr             SetIntroSprites1                ;Set intro sprites
                                ldx             #88                             ;Set raster irq at row 88th
                                lda             #<IRQIntroTitles                ;To draw title sprites
                                ldy             #>IRQIntroTitles                
                                jmp             SetRasterIRQ                    

;===============================================================================
;Get Ready IRQ routine
;===============================================================================
IRQGetReady                     jsr             SetGetReadySprites1             ;Draw title sprites 'Get ready'  
                                lda             #0                              
                                jsr             FadeSound                       ;Play fade sound
                                lda             GameModeFinishLimit             ;Finish state?
                                bne             IRQGetReadyFinishState          ;Yes, jump
                                lda             GameModeCounterHi               ;Otherwise, after the 16th frame
                                bne             IRQGetReadyShowHint             ;Show hints about how to
                                lda             GameModeCounterLo               ;control the game
                                cmp             #16                             
                                bcc             IRQGetReadyFinishState          
IRQGetReadyShowHint             ldx             #106                            ;Set raster irq at row 106th
                                lda             #<IRQGetReadyHints              ;To draw hint sprites
                                ldy             #>IRQGetReadyHints              
                                jmp             SetRasterIRQ                    
IRQGetReadyFinishState          ldx             #106                            ;Set raster irq at row 106th
                                lda             #<IRQGetReadyColoring           ;To not show anyting
                                ldy             #>IRQGetReadyColoring           
                                jmp             SetRasterIRQ                    

;===============================================================================
;IRQ game
;===============================================================================
IRQGame                         jsr             SetGameSprites                  ;Draw score
                                lda             IsFlappyDead                    ;Is flappy dead?
                                beq             IRQGameFlappyIsAlive            ;No, jump
                                jmp             IRQGameEnd                      ;Yes, jump :-)

IRQGameFlappyIsAlive            dec             PipePosition                    ;So flappy is still living
                                lda             ScrollX                         ;So in scroll states 0-6 we copy
                                eor             #7                              ;3 rows o the buffer 
                                bne             ScreenCopy                      ;(and move with one char to left, of course)

                                lda             CurrentScreenHi                 ;In the 7th state, we change buffer to screen
                                sta             CurrentBufferHi                 
                                sta             ZPBufferHi                      
                                eor             #$28                            
                                sta             CurrentScreenHi                 
                                sta             ZPScreenHi                      
                                ldy             #0                              
                                sty             ZPBufferLo                      
                                iny
                                sty             ZPScreenLo                      
                                lda             VICAddresses                    ;...and switch between screens at $0400 and $2c00
                                eor             #%10100000                      
                                sta             VICAddresses                    
                                lda             GameMode                        
                                cmp             #GameModeGame                   
                                beq             PipeHandling                    ;always jump
                                bne             IRQGameEnd                      

ScreenCopy                      ldx             #3                              ;3 rows will be copied
ScreenCopyRow                   ldy             #0
ScreenCopyColumn                lda             (ZPScreenLo),y
                                sta             (ZPBufferLo),y                  
                                iny
                                cpy             #39                             
                                bne             ScreenCopyColumn                
                                lda             #32                             ;space to last column
                                sta             (ZPBufferLo),y                  
                                lda             ZPBufferLo                      ;increment screen and buffer by 40
                                clc
                                adc             #40                             
                                sta             ZPScreenLo                      
                                inc             ZPScreenLo                      
                                sta             ZPBufferLo                      
                                bcc             ScreenCopyNoCarry               
                                inc             ZPScreenHi                      
                                inc             ZPBufferHi                      
ScreenCopyNoCarry               dex
                                bne             ScreenCopyRow                   
                                beq             IRQGameEnd                      ;After copyin, jump to the end

PipeHandling                    ldx             ColumnCounter                   ;if column counter is in the range
                                cpx             #04                             ;from 0 to 3, we have to draw
                                bcs             NoPipeToDraw                    ;a new column to the pipe
                                ldy             CurrentPipeIndex                ;(A pipe is 4-char-wide);
                                cpx             #0                              ;If column is zero, get some
                                bne             NoNewRandomPipe                 ;random number for a new pipe
                                lda             SIDChannel3Oscillator           
                                lsr
                                lsr
                                lsr
                                lsr
                                lsr
                                sta             PipeHeights,y                   ;To set a new height
                                lsr
                                clc
                                adc             PipeHeights,y                   
                                sta             PipeHeights,y                   
NoNewRandomPipe                 lda             PipeHeights,y
                                jsr             RenderPipe                      ;Render pipe's column
NoPipeToDraw                    ldx             ColumnCounter                   
                                inx
                                cpx             #14                             ;14 column between to pipes
                                bne             NoNewPipe                       
                                ldx             #0                              
                                inc             CurrentPipeIndex                
                                lda             CurrentPipeIndex                
                                and             #3                              
                                sta             CurrentPipeIndex                ;To the next pipe
NoNewPipe                       stx             ColumnCounter                   ;(4 pipes can be on the screen at the same time)

IRQGameEnd                      ldx             #169                            ;Set raster irq at row 169th...
                                lda             #<IRQCloudsAndBuildings         ;...to draw buildings
                                ldy             #>IRQCloudsAndBuildings         
                                jmp             SetRasterIRQ                    

;===============================================================================
;Game Over IRQ routine
;===============================================================================
IRQGameOver                     jsr             SetGameOverSprites1             ;Show game over title
                                lda             #0                              
                                jsr             FadeSound                       ;Play fade sound
                                ldx             #106                            ;Set raster irq at row 106th
                                lda             #<IRQGameOverTable              ;To show game over table and 
                                ldy             #>IRQGameOverTable              ;some more sprites on it.
                                jmp             SetRasterIRQ                    
                                
;===============================================================================
;Raster irq routine "Titles" at row 88
;===============================================================================
IRQIntroTitles                  dec             VICIRQRequest                   ;Accept irq
                                jsr             SetIntroSprites2                ;Show about stuff
                                lda             #16                             
                                jsr             FadeSound                       ;Play fade sound
                                lda             #32                             
                                jsr             FadeSound                       ;Play fade sound
                                ldx             #169                            ;Set raster irq at row 169th...
                                lda             #<IRQCloudsAndBuildings         ;...to draw buildings
                                ldy             #>IRQCloudsAndBuildings         
                                jsr             SetRasterIRQ                    
                                jmp             KernalIRQExit                   

;===============================================================================
;Raster irq routine "Hints" at row 106
;===============================================================================
IRQGetReadyHints                dec             VICIRQRequest                   ;Accept irq
                                lda             #Orange                         
                                sta             SpriteMultiColor0               
                                lda             #White                          
                                sta             SpriteMultiColor1               
                                jsr             SetGetReadySprites2             ;Show sprites
                                ldx             #169                            ;Set raster irq at row 169th
                                lda             #<IRQCloudsAndBuildings         ;Set raster irq at row 169th...
                                ldy             #>IRQCloudsAndBuildings         ;...to draw buildings
                                jsr             SetRasterIRQ                    
                                jmp             KernalIRQExit                   

;===============================================================================
;Raster irq routine Get ready colors at row 106
;===============================================================================
IRQGetReadyColoring             dec             VICIRQRequest                   ;Accept irq
                                lda             #Orange                         ;Set colors
                                sta             SpriteMultiColor0               
                                lda             #White                          
                                sta             SpriteMultiColor1               
                                ldx             #169                            ;Set raster irq at row 169th
                                lda             #<IRQCloudsAndBuildings         ;Set raster irq at row 169th...
                                ldy             #>IRQCloudsAndBuildings         ;...to draw buildings
                                jsr             SetRasterIRQ                    
                                jmp             KernalIRQExit                   

;===============================================================================
;Raster irq routine Get ready colors at row 106
;===============================================================================
IRQGameOverTable                dec             VICIRQRequest                   ;Accept irq
                                lda             #Orange                         ;Set colors
                                sta             SpriteMultiColor0               
                                lda             #White                          
                                sta             SpriteMultiColor1               
                                lda             GameOverIsTableDrawn            ;Game ver table is on the screen?
                                beq             IRQGameOverTableExit            ;No, jump
                                jsr             SetGameOverSprites2             ;Yes, draw sprites on it
IRQGameOverTableExit            ldx             #169                            ;Set raster irq at row 169th...
                                lda             #<IRQCloudsAndBuildings         ;...to draw buildings
                                ldy             #>IRQCloudsAndBuildings         
                                jsr             SetRasterIRQ                    
                                jmp             KernalIRQExit                   

;===============================================================================
;Raster irq routine "Background" at row 169
;===============================================================================
IRQCloudsAndBuildings           dec             VICIRQRequest                   ;Accept irq
                                jsr             SetBuildingSprites              ;Show buildings
                                ldx             #174                            
                                lda             IRQCloudBackgroundColor         ;Some clouds...
                                jsr             SetBackgroundOnRaster           
                                ldx             #175                            
                                lda             IRQBackgroundColor              ;...and some skyes...
                                jsr             SetBackgroundOnRaster           
                                ldx             #176                            
                                lda             IRQCloudBackgroundColor         ;...and some clouds...
                                jsr             SetBackgroundOnRaster           
                                ldx             #177                            
                                lda             IRQBackgroundColor              ;...and some skyes again...
                                jsr             SetBackgroundOnRaster           
                                ldx             #178                            
                                lda             IRQCloudBackgroundColor         ;...and finally, clouds!
                                jsr             SetBackgroundOnRaster           
                                ldx             #200                            ;Set raster irq at row 200th
                                lda             #<IRQGrass                      ;to show hills and grass
                                ldy             #>IRQGrass                      
                                jsr             SetRasterIRQ                    
                                jmp             KernalIRQExit                   

;===============================================================================
;Raster irq routine "Grass background" at row 200
;===============================================================================
IRQGrass                        dec             VICIRQRequest                   ;Accept IRQ
                                ldx             #202                            
                                lda             IRQGrassBackgroundColor         
                                jsr             SetBackgroundOnRaster           ;Show some green
                                jsr             SetHillSprites                  ;Draw hills
                                ldx             #250                            ;Set raster irq at row 250th
                                lda             #<IRQMain                       ;for main IRQ routine
                                ldy             #>IRQMain                       
                                jsr             SetRasterIRQ                    
                                jmp             KernalIRQExit                   

;===============================================
;Pipe render
;In: AC: current barrier height
;    XR: current column of barrier (0-3)
;===============================================
RenderPipe                      sta             CurrentPipeHeight               ;Store current barrier height
                                lda             #0                              ;Vertical barrier part index set to 0
                                sta             PipePartIndex                   
                                lda             #39                             
                                sta             ZPIndex0Lo                      ;Render to last column of the current screen
                                lda             CurrentScreenHi                 
                                sta             ZPIndex0Hi                      
                                ldy             #0                              ;Start at row 0
RenderPipeNextRow               tya                                             ;And save to stack
                                pha
                                cpy             CurrentPipeHeight               ;If rowindex is less than
                                bcc             RenderPipeNoNewPart             ;Current part of the barrier then jump
                                inx                                             ;Else get a new character from barrier characters
                                inx
                                inx
                                inx
                                ldy             PipePartIndex                   ;And set a new part index
                                inc             PipePartIndex                   
                                lda             PipePartsDelta,y                
                                clc
                                adc             CurrentPipeHeight               
                                sta             CurrentPipeHeight               
RenderPipeNoNewPart             lda             PipeChars,x                     ;Load a new character
                                ldy             #0                              ;And write it to the screen
                                sta             (ZPIndex0Lo),y                  
                                lda             #40                             ;Next row
                                clc
                                adc             ZPIndex0Lo                      
                                sta             ZPIndex0Lo                      
                                bcc             RenderPipeNoCarry               
                                inc             ZPIndex0Hi                      
RenderPipeNoCarry               pla                                             ;load rowindex to YR from stack
                                tay
                                iny
                                cpy             #21                             ;21 rows
                                bcc             RenderPipeNextRow               
                                rts

;===============================================================================
;Update joystick state
;===============================================================================
UpdateJoyState                  lda             Joy2Port                        ;Read joy 2 port
                                and             Joy2FireMask                    ;Joy pressed?
                                bne             JoyFireIsReleased               ;No
                                lda             IsJoyFireReaded                 ;Already handled?
                                bne             JoyFireAlreadyReaded            ;Yes, jump
                                ldx             #1                              ;Set IsJoyFirePressed variable to true
                                stx             IsJoyFirePressed                
                                dex                                             ;Reset handled flag
                                stx             IsJoyFireReaded                 
                                rts
JoyFireAlreadyReaded            ldx             #0                              ;Reset pressed flag
                                stx             IsJoyFirePressed                
                                rts
JoyFireIsReleased               ldx             #0                              ;Reset pressed & released
                                stx             IsJoyFirePressed                ;flags
                                stx             IsJoyFireReaded                 
                                rts

;===============================================================================
;Set Intro Sprites1 (Flappy Bird)
;===============================================================================
SetIntroSprites1                lda             #%0                             ;Nothing really fancy
                                sta             SpritePriority                  ;stuff here and above, only boring 
                                sta             SpriteXExpansion                ;sprite initalizations
                                sta             Sprite7XLo                      ;so no more comments left
                                sta             SpriteXHi                       
                                lda             #%11111110                      
                                sta             SpriteMultiColorMode            
                                lda             #%0                             
                                sta             SpritePriority                  
                                lda             #124                            
                                sta             Sprite2XLo                      
                                lda             #148                            
                                sta             Sprite3XLo                      
                                lda             #172                            
                                sta             Sprite4XLo                      
                                lda             #196                            
                                sta             Sprite5XLo                      
                                lda             #220                            
                                sta             Sprite6XLo                      
                                lda             #66                             
                                sta             Sprite2Y                        
                                sta             Sprite3Y                        
                                sta             Sprite4Y                        
                                sta             Sprite5Y                        
                                sta             Sprite6Y                        
                                lda             #195                            
                                sta             Sprite2Bank04                   
                                sta             Sprite2Bank2C                   
                                lda             #196                            
                                sta             Sprite3Bank04                   
                                sta             Sprite3Bank2C                   
                                lda             #197                            
                                sta             Sprite4Bank04                   
                                sta             Sprite4Bank2C                   
                                lda             #198                            
                                sta             Sprite5Bank04                   
                                sta             Sprite5Bank2C                   
                                lda             #199                            
                                sta             Sprite6Bank04                   
                                sta             Sprite6Bank2C                   
                                lda             IRQTitleSpriteColor             
                                sta             Sprite3Color                    
                                sta             Sprite2Color                    
                                sta             Sprite4Color                    
                                sta             Sprite5Color                    
                                sta             Sprite6Color                    
                                sta             Sprite7Color                    
                                lda             IRQTitleSpriteMCol0             
                                sta             SpriteMultiColor0               
                                lda             IRQTitleSpriteMCol1             
                                sta             SpriteMultiColor1               
                                rts

;===============================================================================
;Set Intro Sprites2 (Copyright)
;===============================================================================
SetIntroSprites2                lda             #%0
                                sta             SpritePriority                  
                                sta             SpriteXExpansion                
                                sta             Sprite6XLo                      
                                sta             Sprite7XLo                      
                                sta             SpriteXHi                       
                                lda             IRQSpriteMultiColor0            
                                sta             SpriteMultiColor0               
                                lda             IRQSpriteMultiColor1            
                                sta             SpriteMultiColor1               
                                lda             #%00000010                      
                                sta             SpriteMultiColorMode            
                                lda             #%0                             
                                sta             SpritePriority                  
                                lda             #136                            
                                sta             Sprite2XLo                      
                                lda             #160                            
                                sta             Sprite3XLo                      
                                lda             #184                            
                                sta             Sprite4XLo                      
                                lda             #208                            
                                sta             Sprite5XLo                      
                                lda             #92                             
                                sta             Sprite2Y                        
                                sta             Sprite3Y                        
                                sta             Sprite4Y                        
                                sta             Sprite5Y                        
                                lda             #252                            
                                sta             Sprite2Bank04                   
                                sta             Sprite2Bank2C                   
                                lda             #253                            
                                sta             Sprite3Bank04                   
                                sta             Sprite3Bank2C                   
                                lda             #254                            
                                sta             Sprite4Bank04                   
                                sta             Sprite4Bank2C                   
                                lda             #255                            
                                sta             Sprite5Bank04                   
                                sta             Sprite5Bank2C                   
                                lda             IRQSubTitleSpriteColor          
                                sta             Sprite2Color                    
                                sta             Sprite3Color                    
                                sta             Sprite4Color                    
                                sta             Sprite5Color                    
                                rts


;===============================================================================
;Set building sprites
;===============================================================================
SetBuildingSprites              lda             #%00000010
                                sta             SpriteMultiColorMode            
                                lda             #%11111100                      
                                sta             SpritePriority                  
                                sta             SpriteXExpansion                
                                lda             #35                             
                                sta             Sprite2XLo                      
                                lda             #85                             
                                sta             Sprite3XLo                      
                                lda             #135                            
                                sta             Sprite4XLo                      
                                lda             #185                            
                                sta             Sprite5XLo                      
                                lda             #235                            
                                sta             Sprite6XLo                      
                                lda             #29                             
                                sta             Sprite7XLo                      
                                lda             #%10000000                      
                                sta             SpriteXHi                       
                                lda             #180                            
                                sta             Sprite2Y                        
                                sta             Sprite3Y                        
                                sta             Sprite4Y                        
                                sta             Sprite5Y                        
                                sta             Sprite6Y                        
                                sta             Sprite7Y                        
                                lda             #192                            
                                sta             Sprite2Bank04                   
                                sta             Sprite3Bank04                   
                                sta             Sprite4Bank04                   
                                sta             Sprite5Bank04                   
                                sta             Sprite6Bank04                   
                                sta             Sprite7Bank04                   
                                sta             Sprite2Bank2C                   
                                sta             Sprite3Bank2C                   
                                sta             Sprite4Bank2C                   
                                sta             Sprite5Bank2C                   
                                sta             Sprite6Bank2C                   
                                sta             Sprite7Bank2C                   
                                lda             IRQSpriteBuildingColor          
                                sta             Sprite2Color                    
                                sta             Sprite3Color                    
                                sta             Sprite4Color                    
                                sta             Sprite5Color                    
                                sta             Sprite6Color                    
                                sta             Sprite7Color                    
                                rts

;===============================================================================
;Set hill sprites
;===============================================================================
SetHillSprites                  lda             #%00000010
                                sta             SpriteMultiColorMode            
                                lda             #%11111100                      
                                sta             SpritePriority                  
                                sta             SpriteXExpansion                
                                lda             #35                             
                                sta             Sprite2XLo                      
                                lda             #85                             
                                sta             Sprite3XLo                      
                                lda             #135                            
                                sta             Sprite4XLo                      
                                lda             #185                            
                                sta             Sprite5XLo                      
                                lda             #235                            
                                sta             Sprite6XLo                      
                                lda             #29                             
                                sta             Sprite7XLo                           
                                lda             #%10000000                      
                                sta             SpriteXHi                       
                                lda             #205                            
                                sta             Sprite2Y                        
                                sta             Sprite3Y                        
                                sta             Sprite4Y                        
                                sta             Sprite5Y                        
                                sta             Sprite6Y                        
                                sta             Sprite7Y                        
                                ldy             #193                            
                                sty             Sprite2Bank04                   
                                sty             Sprite2Bank2C                   
                                sty             Sprite4Bank04                   
                                sty             Sprite4Bank2C                   
                                sty             Sprite6Bank2C                                                   
                                sty             Sprite6Bank04
                                iny
                                sty             Sprite3Bank04                   
                                sty             Sprite3Bank2C                   
                                sty             Sprite5Bank04                   
                                sty             Sprite5Bank2C                   
                                sty             Sprite7Bank04                                                   
                                sty             Sprite7Bank2C                   
                                lda             IRQSpriteBuildingColor          
                                sta             Sprite2Color                    
                                sta             Sprite3Color                    
                                sta             Sprite4Color                    
                                sta             Sprite5Color                    
                                sta             Sprite6Color                    
                                sta             Sprite7Color                    
                                rts

;===============================================================================
;Set get ready 1 sprites
;===============================================================================
SetGetReadySprites1             lda             #%0
                                sta             SpritePriority                  
                                sta             SpriteXExpansion                
                                sta             Sprite7XLo                      
                                sta             SpriteXHi                       
                                lda             #%11111110                      
                                sta             SpriteMultiColorMode            
                                lda             #%0                             
                                sta             SpritePriority                  
                                lda             #124                            
                                sta             Sprite2XLo                      
                                lda             #148                            
                                sta             Sprite3XLo                      
                                lda             #172                            
                                sta             Sprite4XLo                      
                                lda             #196                            
                                sta             Sprite5XLo                      
                                lda             #220                            
                                sta             Sprite6XLo                      
                                lda             #66                             
                                sta             Sprite2Y                        
                                sta             Sprite3Y                        
                                sta             Sprite4Y                        
                                sta             Sprite5Y                        
                                sta             Sprite6Y                        
                                lda             #205                            
                                sta             Sprite2Bank04                   
                                sta             Sprite2Bank2C                   
                                lda             #206                            
                                sta             Sprite3Bank04                   
                                sta             Sprite3Bank2C                   
                                lda             #207                            
                                sta             Sprite4Bank04                   
                                sta             Sprite4Bank2C                   
                                lda             #208                            
                                sta             Sprite5Bank04                   
                                sta             Sprite5Bank2C                   
                                lda             #209                            
                                sta             Sprite6Bank04                   
                                sta             Sprite6Bank2C                   
                                lda             IRQTitleSpriteColor             
                                sta             Sprite2Color                    
                                sta             Sprite3Color                    
                                sta             Sprite4Color                    
                                sta             Sprite5Color                    
                                sta             Sprite6Color                    
                                sta             Sprite7Color                    
                                lda             IRQTitleSpriteMCol0             
                                sta             SpriteMultiColor0               
                                lda             IRQTitleSpriteMCol1             
                                sta             SpriteMultiColor1               
                                rts

;===============================================================================
;Set get ready 2 sprites
;===============================================================================
SetGetReadySprites2             lda             #%0
                                sta             SpritePriority                  
                                sta             SpriteXExpansion                
                                sta             Sprite7XLo                      
                                sta             SpriteXHi                       
                                lda             #%10100010                      
                                sta             SpriteMultiColorMode            
                                lda             #196                            
                                sta             Sprite2XLo                      
                                sta             Sprite3XLo                      
                                lda             #169                            
                                sta             Sprite4XLo                      
                                sta             Sprite5XLo                      
                                lda             #172                            
                                sta             Sprite6XLo                      
                                sta             Sprite7XLo                      
                                lda             #124                            
                                sta             Sprite2Y                        
                                sta             Sprite3Y                        
                                lda             #109                            
                                sta             Sprite4Y                        
                                sta             Sprite5Y                        
                                lda             #133                            
                                sta             Sprite6Y                        
                                sta             Sprite7Y                        
                                lda             #212                            
                                sta             Sprite2Bank04                   
                                sta             Sprite2Bank2C                   
                                lda             #215                            
                                sta             Sprite3Bank04                   
                                sta             Sprite3Bank2C                   
                                lda             #211                            
                                sta             Sprite4Bank04                   
                                sta             Sprite4Bank2C                   
                                lda             #214                            
                                sta             Sprite5Bank04                   
                                sta             Sprite5Bank2C                   
                                lda             #210                            
                                sta             Sprite6Bank04                   
                                sta             Sprite6Bank2C                   
                                lda             #213                            
                                sta             Sprite7Bank04                   
                                sta             Sprite7Bank2C                   
                                lda             #Red                            
                                sta             Sprite2Color                    
                                sta             Sprite7Color                    
                                lda             #White                          
                                sta             Sprite3Color                    
                                lda             #Yellow                         
                                sta             Sprite5Color                    
                                lda             #Gray                           
                                sta             Sprite4Color                    
                                sta             Sprite6Color                    
                                rts

;===============================================================================
;Set game sprites
;===============================================================================
SetGameSprites                  lda             #%0
                                sta             SpritePriority                  
                                sta             SpriteXExpansion                
                                sta             SpriteXHi                       
                                lda             #58                             
                                sta             Sprite2Y                        
                                sta             Sprite3Y                        
                                sta             Sprite4Y                        
                                sta             Sprite5Y                        
                                sta             Sprite6Y                        
                                sta             Sprite7Y                        
                                lda             #0                              
                                sta             Sprite6XLo                      
                                sta             Sprite7XLo                      
                                lda             #%00111110                      
                                sta             SpriteMultiColorMode            
                                lda             PointsHi                        
                                bne             SetGameSprites4Digits           
                                sta             Sprite2XLo                      
                                sta             Sprite3XLo                      
                                lda             PointsLo                        
                                cmp             #10                             
                                bcs             SetGameSprites2Digits           
                                lda             #0                              
                                sta             Sprite4XLo                      
                                lda             #173                            
                                sta             Sprite5XLo                      
                                bne             SetGameSpritesSetBanks          
SetGameSprites4Digits           cmp             #10
                                bcc             SetGameSprites3Digits           
                                lda             #149                            
                                sta             Sprite2XLo                      
                                lda             #165                            
                                sta             Sprite3XLo                      
                                lda             #181                            
                                sta             Sprite4XLo                      
                                lda             #197                            
                                sta             Sprite5XLo                      
                                bne             SetGameSpritesSetBanks          
SetGameSprites3Digits           lda             #0
                                sta             Sprite2XLo                      
                                lda             #157                            
                                sta             Sprite3XLo                      
                                lda             #173                            
                                sta             Sprite4XLo                      
                                lda             #189                            
                                sta             Sprite5XLo                      
                                bne             SetGameSpritesSetBanks          
SetGameSprites2Digits           lda             #165
                                sta             Sprite4XLo                      
                                lda             #181                            
                                sta             Sprite5XLo                      
SetGameSpritesSetBanks          lda             PointsLo
                                tax
                                and             #15                             
                                clc
                                adc             #232                            
                                sta             Sprite5Bank04                   
                                sta             Sprite5Bank2C                   
                                txa
                                lsr
                                lsr
                                lsr
                                lsr
                                clc
                                adc             #232                            
                                sta             Sprite4Bank04                   
                                sta             Sprite4Bank2C                   
                                lda             PointsHi                        
                                tax
                                and             #15                             
                                clc
                                adc             #232                            
                                sta             Sprite3Bank04                   
                                sta             Sprite3Bank2C                   
                                txa
                                lsr
                                lsr
                                lsr
                                lsr
                                clc
                                adc             #232                            
                                sta             Sprite2Bank04                   
                                sta             Sprite2Bank2C                   
                                lda             #Gray                           
                                sta             Sprite2Color                    
                                sta             Sprite3Color                    
                                sta             Sprite4Color                    
                                sta             Sprite5Color                    
                                lda             #Orange                         
                                sta             SpriteMultiColor0               
                                lda             #White                          
                                sta             SpriteMultiColor1               
                                rts


;===============================================================================
;Set game over sprites title
;===============================================================================
SetGameOverSprites1             lda             #%0
                                sta             SpritePriority                  
                                sta             SpriteXExpansion                
                                sta             Sprite7XLo                      
                                sta             SpriteXHi                       
                                lda             #%11111110                      
                                sta             SpriteMultiColorMode            
                                lda             #%0                             
                                sta             SpritePriority                  
                                lda             #124                            
                                sta             Sprite2XLo                      
                                lda             #148                            
                                sta             Sprite3XLo                      
                                lda             #172                            
                                sta             Sprite4XLo                      
                                lda             #196                            
                                sta             Sprite5XLo                      
                                lda             #220                            
                                sta             Sprite6XLo                      
                                lda             #66                             
                                sta             Sprite2Y                        
                                sta             Sprite3Y                        
                                sta             Sprite4Y                        
                                sta             Sprite5Y                        
                                sta             Sprite6Y                        
                                lda             #200                            
                                sta             Sprite2Bank04                   
                                sta             Sprite2Bank2C                   
                                lda             #201                            
                                sta             Sprite3Bank04                   
                                sta             Sprite3Bank2C                   
                                lda             #202                            
                                sta             Sprite4Bank04                   
                                sta             Sprite4Bank2C                   
                                lda             #203                            
                                sta             Sprite5Bank04                   
                                sta             Sprite5Bank2C                   
                                lda             #204                            
                                sta             Sprite6Bank04                   
                                sta             Sprite6Bank2C                   
                                lda             IRQTitleSpriteColor             
                                sta             Sprite2Color                    
                                sta             Sprite3Color                    
                                sta             Sprite4Color                    
                                sta             Sprite5Color                    
                                sta             Sprite6Color                    
                                sta             Sprite7Color                    
                                lda             IRQTitleSpriteMCol0             
                                sta             SpriteMultiColor0               
                                lda             IRQTitleSpriteMCol1             
                                sta             SpriteMultiColor1               
                                rts

;===============================================================================
;Set game over sprites on table
;===============================================================================
SetGameOverSprites2             lda             #%0
                                sta             SpritePriority                  
                                sta             SpriteXExpansion                
                                sta             Sprite7XLo                      
                                sta             SpriteXHi                       
                                lda             #%00000010                      
                                sta             SpriteMultiColorMode            
                                lda             #%0                             
                                sta             SpritePriority                  
                                jsr             SetGameOverMedals               
                                lda             IRQMedalPointer                 
                                beq             IRQGameOverNoGleam              
                                jsr             SetGameOverGleam                
IRQGameOverNoGleam              lda             IRQIsNewRecord
                                beq             IRQNoNewRecord                  
                                jsr             SetGameOverNewLabel             
IRQNoNewRecord                  rts

;===============================================================================
;Set game over medals
;===============================================================================
SetGameOverMedals               lda             #144
                                sta             Sprite3XLo                      
                                sta             Sprite4XLo                      
                                sta             Sprite5XLo                      
                                ldy             #122                            
                                sty             Sprite4Y                        
                                iny
                                sty             Sprite5Y                        
                                iny
                                sty             Sprite3Y                        
                                ldy             IRQMedalPointer                 
                                ldx             #0                              
SetNextMedalSprite              lda             MedalColors,y
                                sta             Sprite3Color,x                  
                                lda             MedalSpriteBanks,y              
                                sta             Sprite3Bank04,x                 
                                sta             Sprite3Bank2c,x                 
                                iny
                                inx
                                cpx             #3                              
                                bne             SetNextMedalSprite              
                                rts

;===============================================================================
;Set game over 'NEW' label
;===============================================================================
SetGameOverNewLabel             lda             #173
                                sta             Sprite6XLo                      
                                sta             Sprite7Xlo                      
                                lda             #123                            
                                sta             Sprite6Y                        
                                sta             Sprite7Y                        
                                lda             #247                            
                                sta             Sprite6Bank04                   
                                sta             Sprite6Bank2c                   
                                lda             #248                            
                                sta             Sprite7Bank04                   
                                sta             Sprite7Bank2c                   
                                lda             #Red                            
                                sta             Sprite6Color                    
                                lda             #White                          
                                sta             Sprite7Color                    
                                rts

;===============================================================================
;Make a gleam on game over table
;===============================================================================
SetGameOverGleam                lda             GameModeCounterLo
                                lsr
                                lsr
                                lsr
                                and             #07                             
                                tax
                                beq             ClearGleam                      
                                cmp             #04                             
                                bcs             ClearGleam                      
                                cmp             #1                              
                                bne             GleamIsReady                    
                                lda             IRQGleamX                       
                                bne             GleamIsReady                    
                                lda             SIDChannel3Oscillator           
                                and             #%00001111                      
                                adc             #135                            
                                sta             IRQGleamX                       
                                lda             SIDChannel3Oscillator           
                                and             #%00001111                      
                                adc             #114                            
                                sta             IRQGleamY                       
GleamIsReady                    lda             #White
                                sta             Sprite2Color                    
                                lda             IRQGleamX                       
                                sta             Sprite2XLo                      
                                lda             IRQGleamY                       
                                sta             Sprite2Y                        
                                txa
                                clc
                                adc             #248                            
                                sta             Sprite2Bank04                   
                                sta             Sprite2Bank2c                   
                                jmp             EndGleam                        
ClearGleam                      lda             #0
                                sta             IRQGleamX                       
                                beq             GleamIsReady                    
EndGleam                        rts
