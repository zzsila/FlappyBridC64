GetReady                        jsr             FlapThatBird                    ;Make a flap
                                lda             GameModeCounterHi               ;In the first 16 frames of the get ready mode
                                bne             GetReadySkipFlappyMove          ;We pull back the bird with some pixel
                                lda             GameModeCounterLo               ;to show the control hint
                                tay
                                cmp             #16                             ;to the player
                                bcs             GetReadySkipFlappyMove          
                                tax
                                lsr
                                tay
                                lda             FlappyGetReadyPath,x            
                                sta             Sprite0XLo                      
                                sta             Sprite1XLo                      
                                lda             FadeLightBlueToGray,y           ;And menawhile we fade in the Get Ready title
                                sta             IRQTitleSpriteColor             
                                lda             FadeLightBlueToOrange,y         
                                sta             IRQTitleSpriteMCol0             
                                lda             FadeLightBlueToYellow,y         
                                sta             IRQTitleSpriteMCol1             
                                jmp             GetReadySkipFireTest            ;No fire test in this state
GetReadySkipFlappyMove          lda             GameModeFinishLimit             ;Is it the finish state of this mode?
                                beq             GetReadyCheckJoyFire            ;No, jump & check joy
                                lda             GameModeFinishCounter           ;Otherwise fade out the title
                                lsr
                                eor             #7                              
                                tax
                                lda             FadeLightBlueToGray,x           
                                sta             IRQTitleSpriteColor             
                                lda             FadeLightBlueToOrange,x         
                                sta             IRQTitleSpriteMCol0             
                                lda             FadeLightBlueToYellow,x         
                                sta             IRQTitleSpriteMCol1             
                                jsr             IsGameModeFinished              ;If game mode finished
                                bne             GetReadySkipFireTest            
                                lda             SpriteDataCollision             ;Reset sprite-background collision
                                lda             #$00                            
                                sta             SpriteDataCollision             
                                lda             SpriteDataCollision             
                                lda             #196                            ;Set the start position of the first pipe
                                sta             PipePosition                    
                                lda             #FlapForce                      ;We start with a flap
                                sta             Velocity                        
                                jsr             FlapSound                       ;Play flap sound
                                jsr             NextGameMode                    ;Next game mode
                                jmp             GetReadySkipFireTest            ;Jump to the end

GetReadyCheckJoyFire            jsr             CheckJoyFire                    ;Check joystick
                                bcc             GetReadySkipFireTest            ;No fire, jump
                                lda             #16                             ;Set finish state to 16 frames
                                jsr             PrepareToFinishGameMode
                                jsr             FadeSoundDirect                 ;Play fade sound
GetReadySkipFireTest            rts
