;===============================================================================
;Setup VIC
;===============================================================================
*=$0801
                                byte            $1C, $08, $0A, $00, $9E, $20    ; 10 SYS (2100):REM flappy bird
                                byte            $28, $32, $31, $30, $30, $29
                                byte            $3a, $8f, $20, $46, $4C, $41
                                byte            $50, $50, $59, $20, $42, $49
                                byte            $52, $44, $00, $00, $00, $00

*=$0834
                                jsr             KernalResetVectors              ;Reset everything
                                jsr             KernalInit                      ;Just for fun
                                jsr             KernalResetVIC                  
                                jsr             KernalClearScreen               
                                sei
                                jsr             SetupVIC                        ;Setup VIC registers
                                jsr             SetupSID                        ;Setup SID
                                jsr             ResetGame                       ;Reset game variables, and screen
                                cli                                             

GameLoop                        ;lda             GameModeCounterLo               
                                ;cmp             GameModeCounterLo               
                                ;beq             GameLoop

                                ldx             GameMode                        ;Get the address of the current game mode
                                lda             GameModeAddressesLo,x           ;handler routine from a jump table...
                                sta             GameJump+1                      
                                lda             GameModeAddressesHi,x           
                                sta             GameJump+2                      
GameJump                        jsr             GameJump                        ;..and jump to it.
                                jmp             GameLoop                        

;===============================================================================
;Setup VIC
;===============================================================================
SetupVIC
                                lda             #Black                          ;Sets black border and background
                                sta             BackgroundColor                 ;and everything
                                sta             BorderColor                     
                                sta             MultiColor0                     
                                sta             MultiColor1                     
                                sta             SpriteMultiColor0               
                                sta             SpriteMultiColor1               
                                sta             Sprite0Color                    
                                sta             Sprite1Color                    
                                lda             #00000010                       
                                sta             SpriteMultiColorMode            ;Only the bird's body will be multicolor

                                lda             #$1b                            ;25 row, standard y scroll, vic output turn on
                                sta             VICControlRegister1             
                                lda             #$10                            ;38 columns, multi color mode
                                sta             VICControlRegister2             

                                lda             #%01111111                      ;"Switch off" interrupts signals from CIA-1 & CIA-2
                                sta             $DC0D                           
                                sta             $DC0D                           
                                and             VICControlRegister1             ;Disable the 9th bit of Raster IRQ
                                sta             VICControlRegister1             
                                ldx             #250                            ;Set raster irq at row 50th
                                lda             #<IRQMain                       ;With the main IRQ routine
                                ldy             #>IRQMain                       
                                jsr             SetRasterIRQ                    
                                lda             #%00000001                      
                                sta             VICIRQMask                      ;Enable raster interrupt signals from VIC
                                lda             #%11111111                      
                                sta             SpriteVisibility                ;All sprites are visible...
                                lda             #%00000000                      
                                sta             SpriteXExpansion                ;...and none of them are expanded
                                sta             SpriteYExpansion                
                                rts

;===============================================================================
;Setup SID
;===============================================================================
SetupSID                        lda             #$FF                            ;Max frequency value
                                sta             SIDChannel3FrequencyLo          ;for channel 3
                                sta             SIDChannel3FrequencyHi          ;(for random numbers)
                                lda             #$80                            
                                sta             SIDChannel3Control              ;voice 3 control register (white noise, no gate)
                                lda             #$2f                            ;Maximumn volume
                                sta             SIDVolume
                                rts

ResetGame                       lda             #FlappyBirdDefaultY             ;Set default Y coordinate for the birdy
                                sta             Sprite0Y                        
                                sta             Sprite1Y                        
                                lda             #FlappyBirdDefaultX             ;Set default X coordinate for the birdy
                                sta             Sprite0XLo                      
                                sta             Sprite1XLo                      
                                lda             VICControlRegister2             ;X Pixel scroll is set to 0
                                and             #%11111000                      
                                sta             VICControlRegister2             
                                lda             #$18                            ;Screen memory starts at $0400, charset starts at $2000
                                sta             VICAddresses                    
                                lda             #07                             ;Inner scroll value set to default
                                sta             ScrollX                         
                                lda             #04                             ;Set screen and buffer high bytes
                                sta             CurrentScreenHi                 
                                lda             #$2c                            
                                sta             CurrentBufferHi                 
                                lda             #00                             ;Fill variables with zero
                                tay
ResetWithZeros                  sta             PipeHeights,y
                                iny
                                cpy             #<FillZeroAtResetLength         
                                bne             ResetWithZeros                  
                                ldx             #0                              ;Fill screen with default chars and colors
                                lda             #$d8                            
                                stx             ZPIndex0Lo                      ;Set default zeropage variables
                                stx             ZPIndex1Lo                      ;Index2: Color Memory
                                stx             ZPIndex2Lo                      
                                sta             ZPIndex2Hi                      ;Index1: Current screen ($0400)
                                lda             CurrentScreenHi                 
                                sta             ZPIndex1Hi                      ;Index0: Current buffer ($2c00)
                                sta             ZPScreenHi                      
                                lda             CurrentBufferHi                 
                                sta             ZPIndex0Hi                      
                                sta             ZPBufferHi                      
                                stx             ZPScreenLo                      
                                inc             ZPScreenLo                      
                                stx             ZPBufferLo                      
ResetScreenRow                  ldy             #39                             ;39 + 1 columns to fill
ResetScreenColumn               lda             DefaultScreenChars,x            ;Get next char...
                                sta             (ZPIndex1Lo),y                  ;...and fill the whole row 
                                sta             (ZPIndex0Lo),y                  ;Fill the buffer too
                                lda             IsNotFirstGame                  ;If is it the first game, the last 
                                bne             NotTheFirstGame                 ;5 rows will be black (for fading stuff)
                                lda             DefaultScreenColors,x           
                                jmp             SetColor                        
NotTheFirstGame                 lda             #LightGray                      ;Otherwise they will be yellow
SetColor                        sta             (ZPIndex2Lo),y
                                dey
                                bpl             ResetScreenColumn               
                                lda             ZPIndex0Lo                      ;Increment screen, buffer by 40
                                clc
                                adc             #40                             
                                sta             ZPIndex0Lo                      
                                sta             ZPIndex1Lo                      
                                sta             ZPIndex2Lo                      
                                bcc             ResetNextRow                    
                                inc             ZPIndex0Hi                      
                                inc             ZPIndex1Hi                      
                                inc             ZPIndex2Hi                      
ResetNextRow                    inx
                                cpx             #25                             ;25 rows
                                bne             ResetScreenRow                                                  
                                lda             #1                              ;This is not the first game anymore
                                sta             IsNotFirstGame                  
                                rts

;===============================================================================
;Checks if joy 2 fire pressed
;Out: Carry flag: Set if joy fired, and not readed
;===============================================================================

CheckJoyFire                    ldx             IsJoyFireReaded                 ;Is joystick fire state already readed
                                beq             JoyFireNotReaded                ;No, check if fire pressed
NoFirePressed                   clc                                             ;Yes, no new fire pressed (reset carry flag)
                                rts
JoyFireNotReaded                ldx             IsJoyFirePressed                ;Is joy fire down?
                                beq             NoFirePressed                   ;No
                                inc             IsJoyFireReaded                 ;Yes, set joy fire readed state to true
                                sec                                             ;Set carry flag as result
                                rts

;===============================================================================
;Jump to next game mode
;===============================================================================
NextGameMode                    sei                                             
                                lda             GameMode                        ;load the current game mode
                                cmp             #GameModeGameOver               ;Is it the last one?
                                bne             NextGameModeIsNormal            ;No, jump to increment game mode normally
                                jsr             ResetGame                       ;Otherwise reset game
                                lda             #GameModeGetReady               ;Start new game from 'Get Ready' mode
                                sta             GameMode                        
                                bne             ResetGameModeCounters           ;Skip the next line
NextGameModeIsNormal            inc             GameMode                        ;Increment game mode
ResetGameModeCounters           lda             #0                              ;Reset counters
                                sta             GameModeCounterLo               
                                sta             GameModeCounterHi               
                                sta             GameModeFinishLimit             
                                sta             GameModeFinishCounter           
                                cli
                                rts

;===============================================================================
;Flap the bird (and also set heading)
;In:  XR : base sprite
;===============================================================================
FlapThatBird                    lda             IsFlappyDead                    ;Check if flappy is dead
                                beq             FlappyIsAliveToFlapOne          ;He is alive!!!!
                                lda             #220                            ;No, he can't do flaps anymore :-(
                                clc                                             ;jump to the end
                                bcc             DeadBird                        
FlappyIsAliveToFlapOne          lda             Velocity                        ;Set sprites for vertical velocity
                                cmp             #-2                             ;-6..-2 heading is up
                                bpl             HeadingIsNotUp                  ;-2..4 heading is horizontal
                                lda             #228                            ;4..8 heading is down
                                bne             SetHeadingBase                  
HeadingIsNotUp                  cmp             #4                                      
                                bpl             HeadingIsNotHorizontal          
                                lda             #216                            
                                bne             SetHeadingBase                  
HeadingIsNotHorizontal          lda             #224
SetHeadingBase                  sta             TempBaseSpriteBank
                                lda             GameModeCounterLo               ;With the game counter we do some
                                tax                                             ;Flap animations for the current heading
                                lsr
                                lsr
                                lsr
                                and             #01                             
                                clc
                                adc             TempBaseSpriteBank              
DeadBird                        sta             Sprite0Bank04                   ;Set banks of outline and fill sprites
                                sta             Sprite0Bank2C                   
                                adc             #02                             
                                sta             Sprite1Bank04                   
                                sta             Sprite1Bank2C                   
                                rts

;===============================================================================
;Prepare to finish game mode
;In:  AC : frames to jump next game mode
;===============================================================================
PrepareToFinishGameMode
                                sta             GameModeFinishLimit             ;Set a Limit, and reset the counter
                                lda             #0                              ;(If the counter reaches the limit, the current...
                                sta             GameModeFinishCounter           ;...game mode will be finished)
                                rts

;===============================================================================
;Is game mode finished
;Out: Zero bit : 1: Game mode is finished
;===============================================================================
IsGameModeFinished
                                lda             GameModeFinishLimit             ;If there is no limit currently
                                bne             GameModeIsFinishing             ;the game mode is alive
                                lda             #1                              
                                rts
GameModeIsFinishing             lda             GameModeFinishCounter           ;Compare counter to limit
                                cmp             GameModeFinishLimit             ;If they are equals, the game mode...
                                rts                                             ;...is about to finish

;===============================================================================
;Flappy bird moving
;In: Zero bit : 1: Game mode is finished
;===============================================================================
MoveFlappyBird                  lda             GameModeFinishLimit             ;Move the bird vertically by velocity
                                bne             MoveNoFlap                      ;If the game mode is in finish state, skip fire check
                                jsr             CheckJoyFire                    ;Check if fire pressed
                                bcc             MoveNoFlap                      ;No, no new flap
                                jsr             FlapSound                       ;Play flap sound
                                lda             Sprite0Y                        ;Yes, check if the bird is on the top of the screen
                                cmp             #50                             
                                bcc             MoveNoFlap                      ;Yes, no new flap
                                lda             #FlapForce                      ;No, set the new vertical velocity
                                bne             MoveSetVelocity                 
MoveFlappyBirdGameOver
MoveNoFlap                      lda             Velocity                        ;Get velocity...
                                clc                                             ;...and adjust it by gravity
                                adc             #Gravity                        
                                bmi             MoveSetVelocity                 ;If velocity is negative, jump to set the new value
                                cmp             #MaximumVelocity                ;If velocity is greater than the maximum one
                                bcc             MoveSetVelocity                 ;Set the maximum velocity again
                                lda             #MaximumVelocity                
MoveSetVelocity                 sta             Velocity                        ;Set velocity
                                lda             Sprite0Y                        ;Adjust sprites Y coordinates with velocity
                                clc                                             
                                adc             Velocity                        
                                cmp             #50                             ;And check screen boundaries
                                bcs             MoveTestLowerYCoord             
                                lda             #50                             
                                bne             MoveSetNewYCoord                
MoveTestLowerYCoord             cmp             #204
                                bcc             MoveSetNewYCoord                
                                lda             #204                            
MoveSetNewYCoord                sta             Sprite0Y                        ;Store the new Y values
                                sta             Sprite1Y                        
                                rts

incasm                          "consts.asm"                                    ;Constants
incasm                          "irq.asm"                                       ;IRQ routines
incasm                          "intro.asm"                                     ;Intro game mode
incasm                          "getready.asm"                                  ;Get ready game mode
incasm                          "game.asm"                                      ;Game game mode
incasm                          "gameover.asm"                                  ;Game over game mode
incasm                          "effects.asm"                                   ;Sound effects                              

CurrentScreenHi                 byte            04                              ;Current screen's address (upper byte)
CurrentBufferHi                 byte            $2c                             ;Current buffer's address (upper byte)
ScrollX                         byte            7                               ;Pixel position of scroll
GameMode                        byte            0                               ;Start game mode (Intro)
FillZeroAtResetStart
PipeHeights                     byte            0, 0, 0, 0                      ;Pipe heights on screen
PipePartIndex                   byte            0                               ;Pipe part index of current pipe at render
CurrentPipeHeight               byte            0                               ;Definitely the current pipe's height
CurrentPipeIndex                byte            0                               ;Guess what
ColumnCounter                   byte            0                               ;
PointsLo                        byte            0                               ;Current points lower byte
PointsHi                        byte            0                               ;Current points upper byte
GameOverPointsLo                byte            0                               ;Temporary points lower byte (for counting)
GameOverPointsHi                byte            0                               ;Temporary points upper byte (for counting)
GameModeCounterLo               byte            0                               ;Frame counter for a game mode (lower byte)
GameModeCounterHi               byte            0                               ;Frame counter for a game mode (upper byte)
IsJoyFirePressed                byte            0                               ;1 if a joy's fire button pressed
IsJoyFireReaded                 byte            0                               ;1 if the fire is still pressed, 
                                                                                ;but it's value is already readed
PipePosition                    byte            0                               ;
Velocity                        byte            0                               ;Vertical valocity of Flappy Bird
LastGameModeCounter             byte            0                               ;Co-frame counter for game mode                                
LastGameOverModeCounter         byte            0                               ;Co-co-frame counter for game mode
TempPoints                      byte            0                               ;Temporary variable 
GameModeFinishLimit             byte            0                               ;Limit to the game mode's end (in frames)
GameModeFinishCounter           byte            0                               ;Counter for the limiter
GameOverIsTableDrawn            byte            0                               ;1 if the Game over table is drawn
IsFlappyDead                    byte            0                               ;1 if Flappy is dead
IRQMedalPointer                 byte            0                               ;Medal pointer 0: None, 1 Bronze, 2, Silver
                                                                                ;3 Gold, 4 Platinum
IRQGleamX                       byte            0                               ;Gleam coordinates for the medal
IRQGleamY                       byte            0
IRQIsNewRecord                  byte            0                               ;1 if the points are best of times
IRQScoreSoundDelay              byte            0                               ;Pause between two sound notes
IRQFadeSoundCounter             byte            0                               ;Sound filter counter
FillZeroAtResetEnd
FillZeroAtResetLength           = FillZeroAtResetEnd - FillZeroAtResetStart

BestPointsLo                    byte            0                               ;Best points lower byte
BestPointsHi                    byte            0                               ;Best points upper byte
TempBaseSpriteBank              byte            0                               ;Temp variable

GameModeAddressesLo             byte            <Intro, <GetReady               ;Game modes jump table
                                byte            <Game, <GameOver
GameModeAddressesHi             byte            >Intro, >GetReady
                                byte            >Game, >GameOver

GameModeIRQAddressesLo          byte            <IRQIntro, <IRQGetReady         ;IRQ routines jump table
                                byte            <IRQGame, <IRQGameOver          ;for game modes
GameModeIRQAddressesHi          byte            >IRQIntro, >IRQGetReady  
                                byte            >IRQGame, >IRQGameOver

PipeChars                       byte            21, 22, 23, 24, 13, 14, 15, 16  ;Character codes for pipe parts (4 for a row)
                                byte            17, 18, 19, 20, 32, 32, 32, 32
                                byte            9, 10, 11, 12, 5, 6, 7, 8
                                byte            1, 2, 3, 4
PipePartsDelta                  byte            1, 1, 6, 1, 1, 30               ;Pipe parts vertical indices
DefaultScreenChars              byte            32, 32, 32, 32, 32, 32, 32, 32  ;Default characters for screen rows
                                byte            32, 32, 32, 32, 32, 32, 32, 32  ;at game reset
                                byte            32, 32, 32, 32, 32, 0, 25, 25 
                                byte            25, 25
DefaultScreenColors             byte            15, 15, 15, 15, 15, 15, 15, 15  ;Default color codes for screen rows
                                byte            15, 15, 15, 15, 15, 15, 15, 15  ;at game reset
                                byte            15, 15, 15, 15, 15, 8, 8, 8, 8
IsNotFirstGame                  byte            0
FlappyGetReadyPath              byte            172, 172, 171, 170, 168, 166    ;Horizontal coordinates of flappy bird
                                byte            163, 161, 158, 155, 153, 150    ;for Get ready animations
                                byte            148, 146, 145, 144

FadeWhiteToLightBlue            byte            White, White, White, LightGray  ;Fade tables
                                byte            LightGray, LightGray
                                byte            LightBlue, LightBlue

FadeLightBlueToGray             byte            LightBlue, LightBlue, LightBlue
                                byte            MediumGray, MediumGray
                                byte            MediumGray,Gray,Gray
                                
FadeLightBlueToYellow           byte            LightBlue, LightBlue, LightBlue
                                byte            LightGray, LightGray, LightGray
                                byte            Yellow, Yellow
                                
FadeLightBlueToGreen            byte            LightBlue, LightBlue, LightBlue
                                byte            LightGray, LightGray, LightGray
                                byte            Green, Green
                                
FadeLightBlueToOrange           byte            LightBlue, LightBlue, LightBlue
                                byte            MediumGray, MediumGray 
                                byte            MediumGray, Orange, Orange

FadeBlackToWhite                byte            Black, Gray, Gray
                                byte            MediumGray, MediumGray
                                byte            LightGray, LightGray, White
                                
FadeBlackToLightBlue            byte            Black, Black, Black 
                                byte            Gray, Gray, Gray
                                byte            LightBlue, LightBlue
                                
FadeBlackToLightGreen           byte            Black, Black, Gray
                                byte            Gray, Green, Green
                                byte            LightGreen, LightGreen
                                
FadeBlackToGray                 byte            Black, Black, Black
                                byte            Black, Gray, Gray
                                byte            Gray, Gray
                                
FadeBlackToYellow               byte            Black, Gray, Gray
                                byte            MediumGray, MediumGray
                                byte            LightGray, LightGray, Yellow
FadeBlackToYellowAlt            byte            Orange, Orange, Orange
                                byte            LightBlue, LightBlue, LightBlue
                                byte            LightGray, LightGray
FadeBlackToOrange               byte            Black, Black, Black
                                byte            Gray, Gray, Gray
                                byte            Orange, Orange
FadeBlackToGreen                byte            Black, Black, Black
                                byte            Gray, Gray, Gray
                                byte            Green, Green

IRQBackgroundColor              byte            Black                            ;Default colors for irq routines
IRQCloudBackgroundColor         byte            Black
IRQGrassBackgroundColor         byte            Black
IRQSpriteBuildingColor          byte            Black
IRQSpriteMultiColor0            byte            Black
IRQSpriteMultiColor1            byte            Black
IRQSpriteIntroMColor0           byte            Black
IRQSpriteIntroMColor1           byte            Black
IRQCharColor                    byte            Black
IRQTitleSpriteColor             byte            Black
IRQTitleSpriteMCol0             byte            Black
IRQTitleSpriteMCol1             byte            Black
IRQSubTitleSpriteColor          byte            Black

GameOverTable                   byte            $21, $22, $22, $22, $22, $22    ;Char codes for table (16*8 characters)
                                byte            $22, $22, $22, $22, $22, $22
                                byte            $22, $22, $22, $23
                                byte            $24, $25, $2A, $2B, $2C, $2D
                                byte            $2E, $25, $25, $2F, $30, $31
                                byte            $32, $33, $25, $24
                                byte            $24, $25, $25, $25, $25, $25
                                byte            $25, $25, $25, $25, $25, $25
                                byte            $25, $25, $25, $24
                                byte            $24, $25, $25, $25, $25, $25
                                byte            $25, $25, $25, $25, $25, $25
                                byte            $25, $25, $25, $24
                                byte            $24, $25, $25, $25, $25, $25
                                byte            $25, $25, $25, $25, $34, $33
                                byte            $36, $37, $25, $24
                                byte            $24, $25, $25, $25, $25, $25
                                byte            $25, $25, $25, $25, $25, $25
                                byte            $25, $25, $25, $24
                                byte            $24, $25, $25, $25, $25, $25
                                byte            $25, $25, $25, $25, $25, $25
                                byte            $25, $25, $25, $24
                                byte            $27, $28, $28, $28, $28, $28
                                byte            $28, $28, $28, $28, $28, $28
                                byte            $28, $28, $28, $29

GameOverTableWhiteChars         byte            $56, $57, $58, $59              ;Point character color addresses (lower byte)
                                byte            $7e, $7f, $80, $81              ;(upper is $d9). This table is used to
                                byte            $ce, $cf, $d0, $d1              ;to set point character's colors to white
                                byte            $f6, $f7, $f8, $f9

MedalColors                     byte            Yellow, Gray, Green             ;Medal colors: None
                                byte            Gray, Yellow, Orange            ;Bronze
                                byte            MediumGray, White, LightGray    ;Silver
                                byte            LightGray, White, Yellow        ;Gold
                                byte            MediumGray, White, LightGray    ;Platinum
MedalSpriteBanks                byte            244, 243, 242                   ;Sprite banks for medals: None
                                byte            246, 245, 242                   ;Bronze
                                byte            246, 245, 242                   ;Silver
                                byte            246, 245, 242                   ;Gold
                                byte            246, 245, 242                   ;Platinum

*                               = $2000
incbin                          "charset.cst", 0, 255                           ;Charset

*                               = $3000
incbin                          "sprites.spt", 1, 64, true                      ;Sprites


