;System
IRQVector                       = $0314
KernalIRQExit                   = $ea81
KernalResetVectors              = $fd15
KernalInit                      = $fda3
KernalResetVIC                  = $e59a
KernalClearScreen               = $e544

;Colors
Black                           = $00
White                           = $01
Red                             = $02
Cyan                            = $03
Purple                          = $04
Green                           = $05
Blue                            = $06
Yellow                          = $07
Orange                          = $08
Brown                           = $09
LightRed                        = $0a
Gray                            = $0b
MediumGray                      = $0c
LightGreen                      = $0d
LightBlue                       = $0e
LightGray                       = $0f

;VIC
VIC                             = $D000
Sprite0XLo                      = VIC
Sprite0Y                        = VIC + 1
Sprite1XLo                      = VIC + 2
Sprite1Y                        = VIC + 3
Sprite2XLo                      = VIC + 4
Sprite2Y                        = VIC + 5
Sprite3XLo                      = VIC + 6
Sprite3Y                        = VIC + 7
Sprite4XLo                      = VIC + 8
Sprite4Y                        = VIC + 9
Sprite5XLo                      = VIC + 10
Sprite5Y                        = VIC + 11
Sprite6XLo                      = VIC + 12
Sprite6Y                        = VIC + 13
Sprite7XLo                      = VIC + 14
Sprite7Y                        = VIC + 15

SpriteXHi                       = VIC + 16

SpriteVisibility                = VIC + 21

SpriteYExpansion                = VIC + 23
SpriteXExpansion                = VIC + 29

SpritePriority                  = VIC + 27
SpriteSpriteCollision           = VIC + 30
SpriteDataCollision             = VIC + 31

SpriteMultiColorMode            = VIC + 28
SpriteMultiColor0               = VIC + 37
SpriteMultiColor1               = VIC + 38

Sprite0Color                    = VIC + 39
Sprite1Color                    = VIC + 40
Sprite2Color                    = VIC + 41
Sprite3Color                    = VIC + 42
Sprite4Color                    = VIC + 43
Sprite5Color                    = VIC + 44
Sprite6Color                    = VIC + 45
Sprite7Color                    = VIC + 46

BorderColor                     = VIC + 32
BackgroundColor                 = VIC + 33
MultiColor0                     = VIC + 34
MultiColor1                     = VIC + 35

VICControlRegister1             = VIC + 17
VICControlRegister2             = VIC + 22

VICIRQRequest                   = VIC + 25
VICIRQMask                      = VIC + 26

VICAddresses                    = VIC + 24

VICIRQRasterLow                 = VIC + 18

Sprite0Bank04                   = $07f8
Sprite1Bank04                   = $07f9
Sprite2Bank04                   = $07fa
Sprite3Bank04                   = $07fb
Sprite4Bank04                   = $07fc
Sprite5Bank04                   = $07fd
Sprite6Bank04                   = $07fe
Sprite7Bank04                   = $07ff

Sprite0Bank2C                   = $2ff8
Sprite1Bank2C                   = $2ff9
Sprite2Bank2C                   = $2ffa
Sprite3Bank2C                   = $2ffb
Sprite4Bank2C                   = $2ffc
Sprite5Bank2C                   = $2ffd
Sprite6Bank2C                   = $2ffe
Sprite7Bank2C                   = $2fff

ZPIndex0Lo                      = $f9
ZPIndex0Hi                      = $fa
ZPIndex1Lo                      = $fb
ZPIndex1Hi                      = $fc
ZPIndex2Lo                      = $fd
ZPIndex2Hi                      = $fe
ZPScreenLo                      = $02
ZPScreenHi                      = $03
ZPBufferLo                      = $04
ZPBufferHi                      = $05

;SID
SIDChannel1FrequencyLo          = $d400
SIDChannel1FrequencyHi          = $d401
SIDChannel1PulseLo              = $d402
SIDChannel1PulseHi              = $d403
SIDChannel1Control              = $d404
SIDChannel1AD                   = $d405
SIDChannel1SR                   = $d406

SIDChannel2FrequencyLo          = $d407
SIDChannel2FrequencyHi          = $d408
SIDChannel2PulseLo              = $d409
SIDChannel2PulseHi              = $d40a
SIDChannel2Control              = $d40b
SIDChannel2AD                   = $d40c
SIDChannel2SR                   = $d40d

SIDChannel3FrequencyLo          = $d40e
SIDChannel3FrequencyHi          = $d40f
SIDChannel3PulseLo              = $d410
SIDChannel3PulseHi              = $d411
SIDChannel3Control              = $d412
SIDChannel3AD                   = $d413
SIDChannel3SR                   = $d414


SIDFilterCutLo                  = $d415
SIDFilterCutHi                  = $d416
SIDFilterControl                = $d417
SIDVolume                       = $d418

SIDPaddleX                      = $d419
SIDPaddleY                      = $d41a

SIDChannel3Oscillator           = $d41b
SIDChannel3Envelope             = $d41c

;Game modes
GameModeIntro                   = 0
GameModeGetReady                = 1
GameModeGame                    = 2
GameModeGameOver                = 3
GameModeHiScore                 = 4

;Joystick
Joy2Port                        = $dc00
Joy2FireMask                    = #%00010000

;Game consts
MaximumVelocity                 = 8
Gravity                         = 1
FlapForce                       = -6
PipeDifference                  = 112
FirstPipeDifference             = 1
FlappyBirdDefaultY              = 123
FlappyBirdDefaultX              = 172