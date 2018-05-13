Intro                           jsr             FlapThatBird                    ;Make a flap
                                lda             GameModeCounterHi               
                                beq             IntroCheckFades                 
                                jmp             IntroSkipFadeCheck              
IntroCheckFades                 lda             GameModeCounterLo
                                cmp             #8                              ;In the first 8 frames...
                                bcs             IntroSkipFadeFromBlack
                                tax                                             ;...we made a fade in from black

                                lda             FadeBlackToLightBlue,x          
                                sta             IRQBackgroundColor              
                                sta             IRQTitleSpriteColor             
                                sta             IRQTitleSpriteMCol0             
                                sta             IRQTitleSpriteMCol1             
                                sta             IRQSubtitleSpriteColor          

                                lda             #%00000011                      ;Turn sprites (0-1) on (Flappy body + outline)
                                sta             SpriteVisibility                

                                lda             FadeBlackToGray,x               
                                sta             IRQSpriteBuildingColor          
                                sta             Sprite0Color                    
                                sta             MultiColor0                     

                                lda             FadeBlackToGreen,x              
                                sta             MultiColor1                     

                                lda             FadeBlackToOrange,x             
                                sta             IRQSpriteMultiColor0            

                                lda             FadeBlackToYellow,x             
                                sta             Sprite1Color                    

                                lda             FadeBlackToYellowAlt,x          
                                sta             IRQCharColor                    

                                lda             FadeBlackToWhite,x              
                                sta             IRQCloudBackgroundColor         
                                sta             IRQSpriteMultiColor1            

                                lda             FadeBlackToLightGreen,x         
                                sta             IRQGrassBackgroundColor         

                                jmp             IntroEnd                        ;Jump to the end

IntroSkipFadeFromBlack          lda             #%11111111                      ;After the frst 8 frames...
                                sta             SpriteVisibility                ;From frames 16 to 32...
                                cpx             #16                             
                                bcc             IntroEnd                        
                                cpx             #32                             
                                bcs             IntroCheckSubTitle
                                txa                                             ;...we fade in the title 'Flappy Bird'
                                and             #%00001111                      
                                lsr
                                tax
                                lda             FadeLightBlueToGray,x           
                                sta             IRQTitleSpriteColor             
                                lda             FadeLightBlueToGreen,x          
                                sta             IRQTitleSpriteMCol0             
                                lda             FadeLightBlueToYellow,x         
                                sta             IRQTitleSpriteMCol1             
                                jmp             IntroEnd                        ;Jump to the end
IntroCheckSubTitle              cpx             #32                             ;From frame 32 to 48...
                                bcc             IntroEnd                        
                                cpx             #48                             
                                bcs             IntroSkipFadeCheck              
                                txa                                             ;Again we fade in some sprites a little bit lover
                                and             #%00001111                      ;with some about box stuff
                                lsr
                                tax
                                lda             FadeLightBlueToYellow,x         
                                sta             IRQSubtitleSpriteColor          
                                jmp             IntroEnd                        ;Jump to the end

IntroSkipFadeCheck              lda             GameModeFinishLimit             ;Is game mose in its finish state?
                                beq             IntroCheckJoyFire               ;No, jump
                                lda             GameModeFinishCounter           ;Yes, fade out sprites
                                lsr
                                eor             #7                              
                                tax
                                lda             FadeLightBlueToGray,x           
                                sta             IRQTitleSpriteColor             
                                lda             FadeLightBlueToGreen,x          
                                sta             IRQTitleSpriteMCol0             
                                lda             FadeLightBlueToYellow,x         
                                sta             IRQTitleSpriteMCol1             
                                lda             FadeLightBlueToYellow,x         
                                sta             IRQSubtitleSpriteColor          
                                jsr             IsGameModeFinished              ;Is game mode finished?
                                bne             IntroEnd                        ;No, jump
                                jsr             NextGameMode                    ;Yes, set up next game mode
                                jmp             IntroEnd                        ;jump to the end
IntroCheckJoyFire               jsr             CheckJoyFire                    ;Joy pressed?
                                bcc             IntroEnd                        ;No, jump to exit
                                lda             #16                             ;Yes, prepare to finish game mode in 16 frames
                                jsr             PrepareToFinishGameMode 
                                jsr             FadeSoundDirect                 ;Play fade sound
IntroEnd                        rts
