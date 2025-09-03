#Setup
# Initial player stats and variables
# Initialize maxHealth somewhere
if (-not (Get-Variable -Name maxHealth -Scope Script -ErrorAction SilentlyContinue)) {
    $script:maxHealth = 10
}
$health = $maxHealth   # Optionally heal to full when increasing max
$gold = 0
$hasFriend = $false
$EncounterTick = 0  # to ensure encounters only happen once per room visit ( not fully implemented yet but a start )
$chestcounter = 0  # counts how many chests the player has opened, could be used for achievements or something later
$taxesTick = 0 # counts whether or not you've defeated taxes, I guess
$trapcounter = 0 # counts how many traps the player has activated
$FishingSkill = 0         # Current skill level
$FishingXP = 0            # Current experience points
$FishingXPRequired = 10   # XP required for next level
$RodQuality = 0.2
$FishCaught = 0

# Expanded weapons list
$Weapons = @(
    @{ Name = "Rusty Sword"; MinDamage = 2; MaxDamage = 5; Rarity = 1 },
    @{ Name = "Iron Sword"; MinDamage = 4; MaxDamage = 7; Rarity = 5 },
    @{ Name = "Steel Sword"; MinDamage = 5; MaxDamage = 8; Rarity = 13 },
    @{ Name = "Small Hatchet"; MinDamage = 3; MaxDamage = 4; Rarity = 3 },
    @{ Name = "Small Warhammer"; MinDamage = 3; MaxDamage = 10; Rarity = 12 },
    @{ Name = "Bronze Dagger"; MinDamage = 1; MaxDamage = 3; Rarity = 2 },
    @{ Name = "Iron Dagger"; MinDamage = 2; MaxDamage = 4; Rarity = 4 },
    @{ Name = "Battle Axe"; MinDamage = 6; MaxDamage = 12; Rarity = 10 },
    @{ Name = "Mace"; MinDamage = 5; MaxDamage = 9; Rarity = 7 },
    @{ Name = "Short Spear"; MinDamage = 3; MaxDamage = 6; Rarity = 6 },
    @{ Name = "Long Sword"; MinDamage = 7; MaxDamage = 11; Rarity = 11 },
    @{ Name = "Warhammer"; MinDamage = 8; MaxDamage = 14; Rarity = 14 },
    @{ Name = "Flail"; MinDamage = 6; MaxDamage = 10; Rarity = 9 },
    @{ Name = "Katana"; MinDamage = 7; MaxDamage = 13; Rarity = 15 },
    @{ Name = "Scimitar"; MinDamage = 5; MaxDamage = 9; Rarity = 8 },
    @{ Name = "Claymore"; MinDamage = 10; MaxDamage = 18; Rarity = 17 },
    @{ Name = "Great Axe"; MinDamage = 12; MaxDamage = 20; Rarity = 18 },
    @{ Name = "Sledgehammer"; MinDamage = 9; MaxDamage = 15; Rarity = 16 },
    @{ Name = "Halberd"; MinDamage = 8; MaxDamage = 14; Rarity = 15 },
    @{ Name = "Rapier"; MinDamage = 5; MaxDamage = 10; Rarity = 9 },
    @{ Name = "Morning Star"; MinDamage = 7; MaxDamage = 13; Rarity = 12 },
    @{ Name = "Glaive"; MinDamage = 15; MaxDamage = 20; Rarity = 30 },
    @{ Name = "Commically Large Spoon"; MinDamage = -100; MaxDamage = 100; Rarity = 100 }
)

$Armors = @(
    @{ Name = "Leather Armor"; Type = "Flat"; Value = 2; Rarity = 5 },
    @{ Name = "Chainmail"; Type = "Flat"; Value = 10; Rarity = 10 },
    @{ Name = "Plate Armor"; Type = "Flat"; Value = 25; Rarity = 15 },
    @{ Name = "Mystic Robe"; Type = "Percent"; Value = 0.15; Rarity = 20 },  # 15% damage reduction
    @{ Name = "Dragon Scale"; Type = "Percent"; Value = 0.25; Rarity = 50 } # 25% damage reduction
)




#initialize stats of different enemies here so they can be used in multiple places
$goblin = @{
    Name        = "Goblin"
    MaxHealth   = 3
    Health      = 3
    MinDamage   = 1
    MaxDamage   = 4
    GoldReward  = 7
    DemChance = 4 # 1 in 3 chance to negotiate successfully
    IntroText   = "You find yourself face to face with a goblin! Well, crotch to face."
    AttackText  = "The goblin hurls itself at your ankles!"
    DefeatText  = "You punt the goblin into a subspace dimension!"
    FriendText  = "The goblin agrees to be your friend!"
    IgnoreText  = "You ignore the goblin and it leaves you alone."
    FleeText    = "You run away from the goblin!"
}
$skeleton = @{
    Name       = "Skeleton"
    MaxHealth  = 7
    Health     = 7
    MinDamage  = 2
    MaxDamage  = 6
    GoldReward = 12
    DemChance = 6 # 1 in 5 chance to negotiate successfully
    IntroText  = "A skeleton rattles into the room!"
    AttackText = "The skeleton slashes with its rusty blade!"
    DefeatText = "The skeleton crumbles into dust!"
    FriendText = "The skeleton bows. Strange, but loyal."
    IgnoreText = "You ignore the skeleton. It loses interest."
    FleeText   = "You tell the skeleton it says gullible on the ceiling and manage to get away!"
}
$taxes = @{
    Name       = "Taxes"
    MaxHealth  = 10000
    Health     = 10000
    GoldReward = 0
    DemChance = 328 # 1 in 327 chance to negotiate successfully
    IntroText  = "Oh no! Taxes appeared!"
    AttackText = "Taxes comes for your gold!"
    DefeatText = "I- how? You uh, you beat taxes... I guess..."
    FriendText = "You learn how to commit tax fraud."
    IgnoreText = "You simply don't pay your taxes."
    FleeText   = "You evade your taxes. Taxes is very upset by this."
}
$mimic = @{
    Name       = "Mimic"
    MaxHealth  = 25
    Health     = 25
    MinDamage  = 10
    MaxDamage  = 15
    GoldReward = 150
    DemChance = 31 # 1 in 30 chance to negotiate successfully
    IntroText  = "The chest turns out to be a mimic!"
    AttackText = "The mimic's tongue pulls you into it's mouth."
    DefeatText = "The mimic receds back to its homeplane. Oh look! A chest!"
    FriendText = "The mimic buys into your words, but it still wants your gold..."
    IgnoreText = "You step away from the mimic, it can no longer reach you."
    FleeText   = "You run away from the mimic! You then realize you could have walked, it can not move on its own."
}







# Traps stats
$spikeTrap = @{
    Name        = "Spike Trap"
    MinDamage   = 2
    MaxDamage   = 5
    TriggerText = "You step on a loose tile, and spikes shoot up from the floor!"
    AvoidText   = "You see a pressure plate on the floor. Curious, you step on it to see what it does and you hear mechanical grinding when suddenly, a spike tries attacking you! You wonder what the pressure plate did."
}
$poisonDarts = @{
    Name        = "Poison Dart Trap"
    MinDamage   = 1
    MaxDamage   = 3
    TriggerText = "A dart shoots out of the wall and hits you!"
    AvoidText   = "You duck just in time to avoid a poison dart!"
}
$fallingrocks = @{
    Name        = "Falling Rocks"
    MinDamage   = 5
    MaxDamage   = 10
    TriggerText = "You activate a tripwire and rocks fall from the ceiling onto you!"
    AvoidText   = "You activate a tripwire and rocks fall from the ceiling! But you were moving too slow and they fall in front of you."
}
$ballistatrap = @{
    Name        = "Ballista Trap"
    MinDamage   = 10
    MaxDamage   = 30
    TriggerText = "A ballista bolt flies out from ahead of you and impales you!"
    AvoidText   = "You trip and fall, narrowly avoiding a ballista bolt!"
}
#Trap Trigger
function TriggerTrap($trap) {
    Clear-Host
    $luck = Get-Random -Minimum 1 -Maximum 4  # 1 in 3 chance to dodge
    if ($luck -eq 1) {
        Write-Host $trap.AvoidText -ForegroundColor Green
    } else {
        Write-Host $trap.TriggerText -ForegroundColor Red
        $trapDamage = Get-Random -Minimum $trap.MinDamage -Maximum $trap.MaxDamage
        $script:health = [math]::Max(0, $script:health - $trapDamage)
        Write-Host "You take $trapDamage damage!" -ForegroundColor Red
        Pause
        Stats
        Pause
        if (CheckHealth) { return }
    }
}






# Encounter logic for when the player meets a creature

function creatureAttacks($creature) {
    clear-host
    Write-Host $creature.IntroText
    start-sleep -Milliseconds 2500
    FlashVFX "White" "Red"
    Write-Host $creature.AttackText -ForegroundColor Red
    $creatureDamage = Get-Random -Minimum $creature.MinDamage -Maximum $creature.MaxDamage
        # Apply armor reduction first
    if ($currentArmor.Type -eq "Flat") {
        $reducedDamage = [math]::Max(0, $creatureDamage - $currentArmor.Value)
    } elseif ($currentArmor.Type -eq "Percent") {
        $reducedDamage = [math]::Max(1, [math]::Round($creatureDamage * (1 - $currentArmor.Value)))
    } else {
        $reducedDamage = $creatureDamage
    }
    # Subtract from health
    $script:health = [math]::Max(0, $script:health - $reducedDamage)
    start-sleep -Milliseconds 1000
    write-host "You take $creatureDamage damage!" -ForegroundColor Red
    start-sleep -Milliseconds 1000
    pause
    Clear-Host
    Stats
    pause
    CheckHealth

    $validChoice = $false
    while (-not $validChoice) {
        set-title "Text Adventure Game - $($creature.name) Room"
        clear-host
        Stats
        write-host "What do you do?"
        write-host "1) Fight"
        write-host "2) Negotiate"
        write-host "3) Run away"
        write-host "4) Ignore the" $creature.Name
        
        $choice = Read-Host -Prompt "Choose an option (1-4)"
        switch ($choice.ToLower()) {
            "1" { $validChoice = $true; CreatureFight }
            "2" { $validChoice = $true; CreatureDem }
            "3" { $validChoice = $true; Write-Host $creature.FleeText; pause; startroom }
            "4" { $validChoice = $true; Write-Host $creature.ignoretext; write-host "This has not been fully implemented yet"; write-host "Thank you for playing!"; pause; Exit } 
            "exit" { $validChoice = $true; Write-Host "Thanks for playing! Goodbye!"; Exit }
            default { Write-Host "Invalid choice: $choice. Please choose a valid option (1-4)." -ForegroundColor Red; pause }
        }
    }
}


# Creature Fight Function
function CreatureFight {

    $defend = $false

    do {
        Clear-Host
        Set-Title "Text Adventure Game - $($creature.name) Battle"
        Stats
        write-host 
        CreatureHealthblock
        Write-Host 
        write-host 
        Write-Host "1) Attack"
        Write-Host "2) Defend"
        Write-Host "3) Run Away"
        Write-Host 

        $choice = Read-Host -Prompt "Choose an option (1-3)"

        switch ($choice) {
            "1" {
                # Player attacks
                Clear-Host
                $damage = Get-Random -Minimum 1 -Maximum 4
                Write-Host "You strike the $($creature.name) for $damage damage!" -ForegroundColor Green
                $newCreaturehealth = $creature.health - $damage
                $creature.Health = $newCreaturehealth
                if ($Creature.health -lt 0) { $creature.Health = 0 }
                Pause
                write-host "The $($creature.name)'s health is now $($creature.health)" -ForegroundColor Red
                Pause
            }
            "2" {
                Clear-Host
                Write-Host "You brace yourself for the $($creature.name)'s attack!"
                $defend = $true
                Pause
            }
            "3" {
                Write-Host $($creature.FleeText)
                Pause
                { if ($script:lastScreen -and (Get-Command $script:lastScreen -ErrorAction SilentlyContinue)) { & $script:lastScreen } else { startroom } }
                return
            }
            default {
                Write-Host "Invalid choice. Try again." -ForegroundColor Red
                Pause
                
            }
        }

        # Check if creature is defeated after player action
        if ($creature.Health -le 0) {
            CreatureDefeated; return
        } else {
            clear-host; Write-Host $creature.AttackText -ForegroundColor Red; pause
        }

        # Creature attacks only if still alive
        Clear-Host
        $creatureDamage = Get-Random -Minimum $creature.MinDamage -Maximum $creature.MaxDamage

        if ($defend) {
            Write-Host "You defend and reduce the damage!" -ForegroundColor Blue
            $oldDamage = $creatureDamage
            $creatureDamage = [math]::Max(0, $creatureDamage / 2)
            Write-Host "$($creature.name) damage reduced from $oldDamage to $creatureDamage!" -ForegroundColor Blue
            Pause
            $defend = $false
        }

        # Flash effect
        FlashVFX "Red" "White"

        # apply damage
            # Apply armor reduction first
        if ($currentArmor.Type -eq "Flat") {
            $reducedDamage = [math]::Max(1, $creatureDamage - $currentArmor.Value)  # minimum 1 damage
        } elseif ($currentArmor.Type -eq "Percent") {
            $reducedDamage = [math]::Max(1, [math]::Round($creatureDamage * (1 - $currentArmor.Value)))
        } else {
            $reducedDamage = $creatureDamage
        }
        # Subtract from health
        $script:health = [math]::Max(0, $script:health - $reducedDamage)
        Write-Host "The $($creature.name) hits you for $creatureDamage damage!" -ForegroundColor Red
        Write-Host "Your health is now $script:health."
        Pause
        if (CheckHealth) { return }

    } while ($creature.Health -gt 0)
}


# Creature defeated function
function CreatureDefeated {
    Clear-Host
        # Flash effect
    FlashVFX "Green" "White"
    Set-Title "Text Adventure Game - $($creature.name) Defeated"
    Write-Host "==========================================================="
    Write-Host "      $($creature.name) DEFEATED!"
    Write-Host "==========================================================="
    start-sleep -Milliseconds 1500
    # Reward player
    $script:gold += $damage + 7
    $encounterTick += 1
    Write-Host "You earned $($damage + $creature.goldreward) gold!" -ForegroundColor Yellow
    start-sleep -Milliseconds 1000
    Write-Host "You now have $gold gold." -ForegroundColor Yellow
    start-sleep -Milliseconds 1000
     
    do {
        $choice = Read-Host -Prompt "Type '1' to move on."
        switch ($choice) {
            "1" {
                if ($script:lastScreen -and (Get-Command $script:lastScreen -ErrorAction SilentlyContinue)) { & $script:lastScreen } 
      else { write-host "Something went wrong! Returning to startroom." 
      start-sleep -Milliseconds 1000
       startroom
                }
                return      # exit CreatureDefeated cleanly
            }
            default { 
                Write-Host "Invalid choice. Try again." -ForegroundColor Red
            }
        }
    } while ($true)
}



# Creature Democracy Function

function CreatureDem {
    $script:lastScreen = "CreatureDem"  # remember this screen
    write-host "You try to negotiate with the $($creature.name)."
    pause
    $trust = Get-Random -Minimum 1 -Maximum $creature.DemChance
    if ($trust -eq 1) {
        write-host "The $($creature.name) agrees to be your friend!" -ForegroundColor Cyan
        pause
        clear-host
        DemTrue $creature
    } else {
        write-host "The $($creature.name) doesn't trust you and attacks!" -ForegroundColor Red
        pause
        clear-host
        return creatureAttacks $creature
    }
}




function DemTrue ($creature) {
    clear-host
    write-host "The $($creature.name) is willing to be your friend!" -ForegroundColor Green
    if (-not $hasFriend) {
        $script:hasFriend = $true
        write-host "You and the $($creature.name) are now friends!" -ForegroundColor Cyan
        pause
        Write-Host "What would you like to name your new $($creature.name) friend?"
    do {
        $friendName = (Read-Host -Prompt "Enter a name").Trim() + " the $($creature.name)"
        # Reject empty or all-space input
    if (-not $friendName.Trim(" the $($creature.name)")) {
        Write-Host "Please enter a valid name." -ForegroundColor Red
    }
} while (-not $friendName.Trim(" the $($creature.name)"))

    $friendName = "$((Get-Culture).TextInfo.ToTitleCase($friendName.ToLower()))"
    Write-Host "Your friend's name is $friendName." -ForegroundColor Cyan
    pause

    } else {
        write-host "You already have a friend: $friendName." -ForegroundColor Cyan
        write-host "Replace your friend? (y/n)" -ForegroundColor Yellow
        $choice = Read-Host -Prompt "Choose an option"
        switch ($choice.ToLower()) {
            "y" {
                write-host "You decide to replace your friend." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "You put down $friendName." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "All that's left of $friendName is it's final stare of confusion and fear." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "$friendName's insides are now outsides." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "You feel a bit sad, but you know it's for the best." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "You stand up and look at the goblin." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "The goblin seems to understand." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "What have you done?" -ForegroundColor Red
                start-sleep -Milliseconds 1500
                $script:hasFriend = $false
                DemTrue $goblin
            }
            "n" {
                write-host "You keep your current friend: $friendName." -ForegroundColor Green
                pause
            }
            default {
                write-host "Invalid choice. Choose a valid option." -ForegroundColor Red
                pause
                DemTrue $goblin
            }
        }
        pause
    }
}
#====================================================================================================
#====================================================================================================
#====================================================================================================















# Function to display creature health with color coding
function CreatureHealthblock {
    # Determine health percentage
    $creaturehealthPercent = ($creature.health / $creature.maxHealth) * 100

    # Determine color based on percentage
    if ($creaturehealthPercent -ge 70) {
        $creaturehealthColor = "Green"
    } elseif ($creaturehealthPercent -ge 30) {
        $creaturehealthColor = "Yellow"
    } else {
        $creaturehealthColor = "Red"
    }

    Write-Host "$($creature.name)'s Health: $($creature.health)/$($creature.maxhealth)" -ForegroundColor $creaturehealthColor
}














# Check if player is dead and handle end of game
function CheckHealth {
    if ($health -le 0) {
        $script:health = 0
        EndScreen
        return $true
    }
    return $false
}


# Set window title and background color
function Set-Title($t) { $host.ui.RawUI.WindowTitle = $t }
set-title "Text Adventure Game"
#Make background Black
$host.UI.RawUI.BackgroundColor = "Black"
Clear-Host


# Function to flash the background color for visual effects
# This function alternates the background color between two colors for a quick flash effect
function FlashVFX($color, $color2) {
    for ($i = 0; $i -lt 3; $i++) {
                    $host.UI.RawUI.BackgroundColor = "$color"
                    Start-Sleep -Milliseconds 40
                    Clear-Host
                    $host.UI.RawUI.BackgroundColor = "$color2"
                    Start-Sleep -Milliseconds 40
                    Clear-Host
                    
    }
    $host.UI.RawUI.BackgroundColor = "Black"
    Clear-Host
}
# Sets a variable to remember the last screen for returning after debug commands or just general use. Probably useful
$script:lastScreen = $null


# Function to display player stats
function Stats {
    # Determine health percentage
    $healthPercent = ($health / $maxHealth) * 100

    # Determine color based on percentage
    if ($healthPercent -ge 70) {
        $healthColor = "Green"
    } elseif ($healthPercent -ge 30) {
        $healthColor = "Yellow"
    } else {
        $healthColor = "Red"
    }

    Write-Host "Health: $health" -ForegroundColor $healthColor
        if ($gold -lt 0) {
        Write-Host "Debt: $gold" -ForegroundColor Red
    } else {
        Write-Host "Gold: $gold" -ForegroundColor Yellow
    }
}



function Sleep {
    Clear-Host
    Write-Host "You try to get some rest..."
    Start-Sleep -Milliseconds 1000

    $chance = Get-Random -Minimum 1 -Maximum 100
    if ($chance -le 80) {  # 80% chance of peaceful sleep
        $healAmount = [math]::Min($maxHealth - $health, 20)
        $health += $healAmount
        Write-Host "You feel rested. Recovered $healAmount health."
    } else {
        Write-Host "Oh no! You were disturbed by a nightmare and lost 5 gold."
        $gold = [math]::Max(0, $gold - 5)
    }

    Write-Host "Current health: $health / $maxHealth"
    Write-Host "Current gold: $gold"
    Start-Sleep -Milliseconds 1000
    ($script:lastScreen -and (Get-Command $script:lastScreen -ErrorAction SilentlyContinue))
    & $script:lastScreen
}



# End screen function               edit as more stats and traits are added
# This function displays the end screen with the player's final stats and a thank you message
function EndScreen {
    clear-host
    $script:lastScreen = "EndScreen"  # remember this screen
    $host.UI.RawUI.BackgroundColor = "Red"
    write-host "=================================================" -ForegroundColor Black
    write-host "         YOU DIED!" -ForegroundColor Black
    write-host "==================================================" -ForegroundColor Black
    write-host     
    Write-Host "Game Over!"
        Write-Host "Final Gold: $gold"
        if ($hasFriend) {
            Write-Host "You had a friend: $friendName" -ForegroundColor Magenta
        } else {
            Write-Host "You had no friends." -ForegroundColor Gray
        }
        Write-Host "Fish Caught: $FishCaught"
        pause
        Write-Host "Thanks for playing!"
        Exit
}




#Rooms:


    #Start room
    set-title "Text Adventure Game - Start Room"
function startroom {
    Clear-Host
    $script:lastScreen = "startroom"  # remember this screen
    Stats
    Write-Host
    Write-Host "You find yourself in a dark room with two doors. One to your left and one to your right."
    Write-Host

    $choice = Read-Host -Prompt "Which door do you choose? (left/right)"

    switch ($choice.ToLower()) {
        "left" { chestroom }
        "right" { goblinroom }
        "exit" { Write-Host "Thanks for playing! Goodbye!"; start-sleep -milliseconds 1000; exit }
        "stocks" { SecretStocks } # secret command to open stock screen
        "heal" { SecretHeal }  # debug command to heal player
        "gold50" { SecretGold50 }  # debug command to give player 50 gold
        "maxhealth" { SecretMaxHealth }  # debug command to change max health
        "sethealth" { SecretSetHealth }  # debug command to set current health
        "index" { SecretIndex } # secret command to open index fund screen
        "gold-50" { gold-50 } # debug command to subtract 50 gold
        "fishing" { ChooseBait } # secret command to fish (until it becomes a feature later)
        default { Write-Host "Invalid choice. Please choose 'left' or 'right'." -ForegroundColor Red; startroom }
    }
}






    #chest room
function chestroom {
    Clear-Host
    $script:lastScreen = "chestroom"  # remember this screen
    Write-Host "You enter the left door"
    Pause

    $validChoice = $false
        if ($chestcounter -lt 1){
    while (-not $validChoice) {
        Set-Title "Text Adventure Game - Chest Room"
        Clear-Host
        Write-Host "You find a treasure chest in the corner of the room."
        write-host "1) Open the chest"
        write-host "2) Go into the next room"
        write-host "3) Go back the previous room"
        $choice = Read-Host -Prompt "Do you want to open the chest?"

        switch ($choice.ToLower()) {
            "1" {
                $validChoice = $true
                $script:chestcounter = $chestcounter + 1
                $number = Get-Random -Minimum 5 -Maximum 16

             Set-Location $PSScriptRoot
            $player = New-Object System.Media.SoundPlayer ".\ItemGet.wav"
            $player.Play()

                # Flash effect: alternate White and DarkYellow backgrounds
                FlashVFX "White" "Yellow"

                # Show gold message
                Write-Host "You open the chest and find $number gold coins!" -ForegroundColor Yellow
                $script:gold += $number
                Write-Host "You now have $gold gold coins."
                Pause
            }
            "2" { Hallway }
            "3" { startroom }
            "exit" {
                $validChoice = $true
                Write-Host "Thanks for playing! Goodbye!"
                start-sleep -milliseconds 1000
                Exit
            }
            default {
                Write-Host "Invalid choice: $choice. Please choose 1-3." -ForegroundColor Red
                Pause
            } 
        }
    }
 } 
        if ($chestcounter -ge 1) {
            clear-host
            Write-Host "You have already opened the chest in this room." -ForegroundColor Yellow
            pause
            clear-host
            write-host "You look around the room but there is nothing else of interest."
            pause
            write-host 
            write-host "What do you do now?"
            write-host "1) Go into the next room"
            write-host "2) Go back the previous room"
            $choice = Read-Host -Prompt " "

            switch ($choice.toLower()) {
                "1" { Hallway }
                "2" { startroom }
                "exit" { Write-Host "Thanks for playing! Goodbye!"; start-sleep -milliseconds 1000; exit }
                "stocks" { SecretStocks } # secret command to open stock screen
                "heal" { SecretHeal }  # debug command to heal player
                "gold50" { SecretGold50 }  # debug command to give player 50 gold
                "maxhealth" { SecretMaxHealth }  # debug command to change max health
                "sethealth" { SecretSetHealth }  # debug command to set current health
                "index" { SecretIndex } # secret command to open index fund screen
                "gold-50" { gold-50 } # debug command to subtract 50 gold
                default { Write-Host "Invalid choice." -ForegroundColor Red; pause; $script:lastscreen; & $lastscreen }
        }
    }
}




    #Right door
    set-title "Text Adventure Game - Right Door"

function goblinroom {
    clear-host
    $script:lastScreen = "goblinroom"
    write-host "You enter the right door"
    pause
    if ($EncounterTick -lt 1) { creatureAttacks $goblin  # <-- actually run the encounter, but only once (I think)
    } elseif ($encounterTick -ge 1) {
        write-host "You have already encountered the goblin here." -ForegroundColor Yellow
        pause
        Clear-Host
        write-host "You look around the room but there is nothing else of interest."
            pause
            write-host 
            write-host "What do you do now?"
            write-host "1) Go into the next room #not yet implemented"
            write-host "2) Go back the previous room"
            $choice = Read-Host -Prompt " "

            switch ($choice.toLower()) {
                "1" { Hallway1 }
                "2" { startroom }
                "exit" { Write-Host "Thanks for playing! Goodbye!"; start-sleep -milliseconds 1000; exit }
                "stocks" { SecretStocks } # secret command to open stock screen
                "heal" { SecretHeal }  # debug command to heal player
                "gold50" { SecretGold50 }  # debug command to give player 50 gold
                "maxhealth" { SecretMaxHealth }  # debug command to change max health
                "sethealth" { SecretSetHealth }  # debug command to set current health
                "index" { SecretIndex } # secret command to open index fund screen
                "gold-50" { gold-50 } # debug command to subtract 50 gold
                default { Write-Host "Invalid choice." -ForegroundColor Red; pause; $script:lastscreen; & $lastscreen }
        }
    }
}


function Hallway {
    Clear-Host
    $script:lastScreen = "Hallway"
    Write-Host "You step cautiously into a dark hallway..."
    Start-Sleep -Milliseconds 1000
    Clear-Host

    $trapChance = Get-Random -Minimum 1 -Maximum 5  # 1 in 4 chance
    if ($HallwayTrap -ge 1) {
        Write-Host "The hallway is empty." -ForegroundColor Yellow
        Pause
        Clear-Host
    } elseif ($trapChance -eq 1) {
        TriggerTrap $spikeTrap
        $Script:Hallwaytrap = 1
    } elseif ($trapChance -eq 2) {
        TriggerTrap $poisonDarts
        $Script:Hallwaytrap = 1
    } else {
        Write-Host "The hallway is eerily quiet..."
        $Script:trapcounter = 1
    }

    Write-Host
    Write-Host "You're in the hallway."
    Pause
    Write-Host "What do you do now?"
    Write-Host "1) Next Room # Not yet implemented, sorry"
    Write-Host "2) Previous room"
$choice = Read-Host -Prompt " "

    switch ($choice.ToLower()) {
        "1" { skeletonroom }
        "2" { chestroom }
        "exit" { Write-Host "Thanks for playing! Goodbye!"; start-sleep -milliseconds 1000; exit }
        "stocks" { SecretStocks } # secret command to open stock screen
        "heal" { SecretHeal }  # debug command to heal player
        "gold50" { SecretGold50 }  # debug command to give player 50 gold
        "maxhealth" { SecretMaxHealth }  # debug command to change max health
        "sethealth" { SecretSetHealth }  # debug command to set current health
        "index" { SecretIndex } # secret command to open index fund screen
        "gold-50" { gold-50 } # debug command to subtract 50 gold
        default { Write-Host "Invalid choice. Please choose '1' or '2'." -ForegroundColor Red; pause; Hallway }
    }
}

function Hallway1 {
        Clear-Host
    $script:lastScreen = "Hallway1"
    Write-Host "You step hesitantly into the hallway..."
    Start-Sleep -Milliseconds 1000
    Clear-Host
    Write-Host "You find what appears to be a previous adventurer's camp!" -ForegroundColor Blue
    Write-Host "What do you do?"
    Write-Host "1) Move on"; Write-Host "2) Rest"; Write-Host "3) Look around"; Write-Host "4) Go to the previous room"
    $choice = Read-Host -Prompt " "
    switch ($choice) {
        "1" { write-host "placeholder" } 
        "2" {  }
        "3" {
            $foundSomething = $false  # track if anything is found

            # Check for sword
            if ($SwordLVL -gt 0) {
                Write-Host "You find a [placeholder sword]!" -ForegroundColor Gray
                Pause
                $foundSomething = $true
            }

            # Check for armor
            if ($ArmorLVL -gt 0) {
                Write-Host "You find a [placeholder armor]!" -ForegroundColor Gray
                Pause
                $foundSomething = $true
            }

            # If nothing found
            if (-not $foundSomething) {
                Write-Host "There is nothing of interest in this room."
                Pause
            }

            Clear-Host
        }
        "4" { goblinroom }
        "exit" { Write-Host "Thanks for playing! Goodbye!"; start-sleep -milliseconds 1000; exit }
        "stocks" { SecretStocks } # secret command to open stock screen
        "heal" { SecretHeal }  # debug command to heal player
        "gold50" { SecretGold50 }  # debug command to give player 50 gold
        "maxhealth" { SecretMaxHealth }  # debug command to change max health
        "sethealth" { SecretSetHealth }  # debug command to set current health
        "index" { SecretIndex } # secret command to open index fund screen
        "gold-50" { gold-50 } # debug command to subtract 50 gold
        Default { Write-Host "Invalid choice, please choose (1-4)"; Hallway1 }
    }
}
























































#These are the secret commands the player can use in select places to cheat or debug
#They are not listed in the options


#Fully heals the player
#need to add a max health variable later so that health can be upgraded
function SecretHeal {
    $script:health = $maxHealth
    Write-Host "You have been healed to full health!" -ForegroundColor Green
    pause
    CheckHealth
    if ($script:lastScreen) {
        & $script:lastScreen   # calls the function by name
    }
}

#Change max health
function SecretMaxHealth {
    $newMax = Read-Host -Prompt "Enter new max health (current max is $maxHealth)"
    if ($newMax -match '^\d+$' -and $newMax -gt 0) {
        $script:maxHealth = [int]$newMax
        Write-Host "Max health set to $maxHealth." -ForegroundColor Green
        # Optionally heal to full when increasing max
        $script:health = $maxHealth
        Write-Host "You have been healed to full health!" -ForegroundColor Green
    } else {
        Write-Host "Invalid input. Max health must be a positive integer." -ForegroundColor Red
    }
    pause
    CheckHealth
    if ($script:lastScreen) {
        & $script:lastScreen   # calls the function by name
    }
}

#Sets the player's health to provided value
function SecretSetHealth {
    $newHealth = Read-Host -Prompt "Enter new health (current health is $health)"
    if ($newHealth -match '^\d+$' -and $newHealth -ge 0 -and $newHealth -le $maxHealth) {
        $script:health = [int]$newHealth
        Write-Host "Health set to $health." -ForegroundColor Magenta
    } else {
        Write-Host "Invalid input. Health must be a non-negative integer up to max health ($maxHealth)." -ForegroundColor Red
    }
    pause
    CheckHealth
    if ($script:lastScreen) {
        & $script:lastScreen   # calls the function by name
    }
}


#Gives the player 50 gold
function SecretGold50 {
    $script:gold = $gold + 50
    Write-Host "You have been given 50 gold!" -ForegroundColor Yellow
    pause
    if ($script:lastScreen) {
        & $script:lastScreen   # calls the function by name
    }
}

# Takes away 50 gold
function gold-50 {
    $script:gold = $gold - 50
    Write-Host "You lost 50 gold!" -ForegroundColor Yellow
    pause
    if ($script:lastScreen) {
        & $script:lastScreen   # calls the function by name
    }
}

#Stocks screen to allow stock market simulation because apparently people want that
function SecretStocks {
    clear-host
    write-host "============================"
    write-host "        STOCK MARKET"
    write-host "============================"
    write-host "Current Gold: $gold" -ForegroundColor Yellow
    write-host 
    #Generate a random stock price between 10 and 100
    $stockPrice = Get-Random -Minimum 10 -Maximum 101
    write-host "Current Stock Price: $stockPrice"
    write-host 
    #If player has shares, show how many they have
    if (-not (Get-Variable -Name shares -Scope Script -ErrorAction SilentlyContinue)) {
        $script:shares = 0
    } else {
        write-host "You currently own $shares shares."
    }
    write-host 
    write-host "What would you like to do?"
    write-host "1) Buy Shares"
    write-host "2) Sell Shares"
    write-host "3) Exit Stock Market"
    write-host 
    $choice = Read-Host -Prompt "Choose an option (1-3)"
    switch ($choice) {
        "1" {
            $maxShares = [math]::Floor($gold / $stockPrice)
            if ($maxShares -le 0) {
                write-host "You don't have enough gold to buy any shares." -ForegroundColor Red
                pause
                SecretStocks
                return
            }
            write-host "You can buy up to $maxShares shares."
            $numShares = Read-Host -Prompt "How many shares do you want to buy?"
            if ($numShares -match '^\d+$' -and $numShares -gt 0 -and $numShares -le $maxShares) {
                $numShares = [int]$numShares
                $cost = $numShares * $stockPrice
                $script:gold -= $cost
                $script:shares += $numShares
                write-host "You bought $numShares shares for $cost gold." -ForegroundColor Green
            } else {
                write-host "Invalid number of shares." -ForegroundColor Red
            } 
            pause
            SecretStocks
        }
        "2" {
            if ($shares -le 0) {
                write-host "You don't own any shares to sell." -ForegroundColor Red
                pause
                SecretStocks
                return
            }
            write-host "You currently own $shares shares."
            $numShares = Read-Host -Prompt "How many shares do you want to sell?"
            if ($numShares -match '^\d+$' -and $numShares -gt 0 -and $numShares -le $shares) {
                $numShares = [int]$numShares
                $revenue = $numShares * $stockPrice
                $script:gold += $revenue
                $script:shares -= $numShares
                write-host "You sold $numShares shares for $revenue gold." -ForegroundColor Green
                pause
                taxesattacks $taxes
            } else {
                write-host "Invalid number of shares." -ForegroundColor Red
            }
            pause
            SecretStocks
        }
        "3" {
            write-host "Exiting Stock Market..."
            pause
        }
        default {
            write-host "Invalid choice. Try again." -ForegroundColor Red
            pause
            SecretStocks
        }
    }

    if ($script:lastScreen) {
        & $script:lastScreen   # calls the function by name
    }
}

function SecretIndex {
    clear-host
    write-host "============================"
    write-host "         INDEX FUND"
    write-host "============================"
    write-host "Current Gold: $gold" -ForegroundColor Yellow
    write-host 
    #Generate a random stock price between 10 and 100
    $stockPrice = Get-Random -Minimum 10 -Maximum 101
    write-host "Current Stock Price: $stockPrice"
    write-host 
    #If player has shares, show how many they have
    if (-not (Get-Variable -Name shares -Scope Script -ErrorAction SilentlyContinue)) {
        $script:shares = 0
    } else {
        write-host "You currently own $shares shares."
    }
    write-host 
    write-host "What would you like to do?"
    write-host "1) Buy Shares"
    write-host "2) Sell Shares"
    write-host "3) Exit SMP 500"
    write-host 
    $choice = Read-Host -Prompt "Choose an option (1-3)"
    switch ($choice) {
        "1" {
            $maxShares = [math]::Floor($gold / $stockPrice)
            if ($maxShares -le 0) {
                write-host "You don't have enough gold to buy any shares." -ForegroundColor Red
                pause
                SecretStocks
                return
            }
            write-host "You can buy up to $maxShares shares."
            $numShares = Read-Host -Prompt "How many shares do you want to buy?"
            if ($numShares -match '^\d+$' -and $numShares -gt 0 -and $numShares -le $maxShares) {
                $numShares = [int]$numShares
                $cost = $numShares * $stockPrice
                $script:gold -= $cost
                $script:shares += $numShares
                write-host "You bought $numShares shares for $cost gold." -ForegroundColor Green
            } else {
                write-host "Invalid number of shares." -ForegroundColor Red
            } 
            pause
            SecretIndex
        }
        "2" {
            if ($shares -le 0) {
                write-host "You don't own any shares to sell." -ForegroundColor Red
                pause
                SecretIndex
                return
            }
            write-host "You currently own $shares shares."
            $numShares = Read-Host -Prompt "How many shares do you want to sell?"
            if ($numShares -match '^\d+$' -and $numShares -gt 0 -and $numShares -le $shares) {
                $numShares = [int]$numShares
                $revenue = $numShares * $stockPrice
                $script:gold += $revenue
                $script:shares -= $numShares
                write-host "You sold $numShares shares for $revenue gold." -ForegroundColor Green
                pause
                taxesattacks $taxes
            } else {
                write-host "Invalid number of shares." -ForegroundColor Red
            }
            pause
            SecretIndex
        }
        "3" {
            write-host "Exiting SMP 500..."
            pause
        }
        default {
            write-host "Invalid choice. Try again." -ForegroundColor Red
            pause
            SecretIndex
        }
    }

    if ($script:lastScreen) {
        & $script:lastScreen   # calls the function by name
    }
}
#I've been told to add taxes. Here you go
function TaxesAttacks($creature) {
    clear-host
    Write-Host $creature.IntroText
    start-sleep -Milliseconds 1000
    FlashVFX "Yellow" "Red"
    Write-Host $creature.AttackText -ForegroundColor Red
            if ($gold -le 0) {
            $creatureDamage = 0
        } else {
            $minDamage = [math]::Max(1, [int]($gold / 3))
            $maxDamage = [math]::Min($gold, [int]($gold / 2 + 10))  # safer max
            $creatureDamage = Get-Random -Minimum $minDamage -Maximum $maxDamage
    $script:gold = $script:gold - $creaturedamage
    start-sleep -Milliseconds 1000
    write-host "You lose $creaturedamage gold!" -ForegroundColor Red
    start-sleep -Milliseconds 1000
    pause
    Clear-Host
    Stats
    pause
    CheckHealth

    $validChoice = $false
    while (-not $validChoice) {
        clear-host
        Stats
        write-host "What do you do?"
        write-host "1) Fight"
        write-host "2) Negotiate"
        write-host "3) Run away"
        write-host "4) Ignore the" $creature.Name
        
        $choice = Read-Host -Prompt "Choose an option (1-4)"
        switch ($choice.ToLower()) {
            "1" { $validChoice = $true; TaxesFight $taxes }
            "2" { $validChoice = $true; TaxesDem $taxes }
            "3" { $validChoice = $true; Write-Host $creature.FleeText; pause; write-host "You run to the start!" startroom }
            "4" { $validChoice = $true; Write-Host $creature.ignoretext; } 
            "exit" { $validChoice = $true; Write-Host "Thanks for playing! Goodbye!"; Exit }
            default { Write-Host "Invalid choice: $choice. Please choose a valid option (1-4)." -ForegroundColor Red; pause }
        }
    }
}
}

# Taxes Fight Function
function TaxesFight ($creature) {

    $defend = $false

    do {
        Clear-Host
        Set-Title "Text Adventure Game - $($creature.name) Battle"
        Stats
        Write-Host
        CreatureHealthblock
        Write-Host
        Write-Host "1) Attack"
        Write-Host "2) Defend"
        Write-Host "3) Run Away"
        Write-Host

        $choice = Read-Host -Prompt "Choose an option (1-3)"

        switch ($choice) {
            "1" {
                # Player attacks
                Clear-Host
                $damage = Get-Random -Minimum 1 -Maximum 4
                Write-Host "You strike the $($creature.name) for $damage damage!" -ForegroundColor Green
                $creature.Health = [math]::Max(0, $creature.Health - $damage)
                Write-Host "The $($creature.name)'s health is now $($creature.Health)" -ForegroundColor Red
                Pause
            }
            "2" {
                Clear-Host
                Write-Host "You brace yourself for the $($creature.name)'s attack!"
                Write-Host "It doesn't work!" -ForegroundColor Yellow
                Pause
                $defend = $true
            }
            "3" {
                Write-Host $($creature.FleeText)
                Pause
                if ($script:lastScreen -and (Get-Command $script:lastScreen -ErrorAction SilentlyContinue)) {
                    & $script:lastScreen
                } else {
                    startroom
                }
                return
            }
            default {
                Write-Host "Invalid choice. Try again." -ForegroundColor Red
                Pause
            }
        }

        # Check if creature is defeated
        if ($creature.Health -le 0) {
            TaxesDefeated $taxes
            return
        }

        # Creature attacks only if alive
        Clear-Host
        Write-Host $creature.AttackText -ForegroundColor Red
        Pause

        # Calculate creature damage safely
        if ($gold -le 0) {
            $creatureDamage = 0
        } else {
            $minDamage = [math]::Max(1, [int]($gold / 3))
            $maxDamage = [math]::Min($gold, [int]($gold / 2 + 10))  # safer max
            $creatureDamage = Get-Random -Minimum $minDamage -Maximum $maxDamage
        }

        if ($defend) {
            Write-Host "You defend and reduce the damage!" -ForegroundColor Blue
            $oldDamage = $creatureDamage
            $creatureDamage = [math]::Max(0, [math]::Floor($creatureDamage / 2))
            Write-Host "$($creature.name) damage reduced from $oldDamage to $creatureDamage!" -ForegroundColor Blue
            Pause
            $defend = $false
        }

        # Flash effect
        FlashVFX "Red" "Yellow"

        # Apply damage
        $script:gold -= $creatureDamage
        Write-Host "The $($creature.name) takes $creatureDamage of your gold!" -ForegroundColor Red
        Write-Host "You now have $gold gold left." -ForegroundColor Yellow
        Pause

        if (CheckHealth) { return }

    } while ($creature.Health -gt 0)
}



# Creature defeated function
function TaxesDefeated ($creature) {
    Clear-Host
        # Flash effect
    FlashVFX "Green" "White"
    Set-Title "Text Adventure Game - TAXES Defeated"
    Write-Host "==========================================================="
    Write-Host "      TAXES DEFEATED!"
    Write-Host "==========================================================="
    start-sleep -Milliseconds 1500
    # Reward player
    $script:gold += $damage + $creature.goldreward
    Write-Host "You earned $($damage + $creature.goldreward) gold!" -ForegroundColor Yellow
    start-sleep -Milliseconds 1000
    Write-Host "You now have $gold gold." -ForegroundColor Yellow
    start-sleep -Milliseconds 1000
    $script:taxesTick = 1

     
    do {
        $choice = Read-Host -Prompt "Type '1' to move on."
        switch ($choice) {
            "1" { 
                start-sleep -milliseconds 1000
                startroom
                return      # exit CreatureDefeated cleanly
            }
            default { 
                Write-Host "Invalid choice. Try again." -ForegroundColor Red
            }
        }
    } while ($true)
}



# Creature Democracy Function

function TaxesDem ($creature) {
    write-host "You try to negotiate with the $($creature.name)."
    pause
    $trust = Get-Random -Minimum 1 -Maximum $creature.DemChance
    if ($trust -eq 1) {
        write-host "$($creature.friendtext)" -ForegroundColor Cyan
        pause
        clear-host
        TaxesDemTrue $taxes
    } else {
        write-host "The $($creature.name) doesn't trust you and attacks!" -ForegroundColor Red
        pause
        clear-host
        return taxesAttacks $taxes
    }
}




function TaxesDemTrue ($creature) {
    clear-host
    write-host "The $($creature.name) is willing to be your friend!" -ForegroundColor Green
    if (-not $hasFriend) {
        $script:hasFriend = $true
        write-host "You and the $($creature.name) are now friends!" -ForegroundColor Cyan
        pause
        Write-Host "What would you like to name your new $($creature.name) friend?"
    do {
        $friendName = (Read-Host -Prompt "Enter a name").Trim() + " the $($creature.name)"
        # Reject empty or all-space input
    if (-not $friendName.Trim(" the $($creature.name)")) {
        Write-Host "Please enter a valid name." -ForegroundColor Red
    }
} while (-not $friendName.Trim(" the $($creature.name)"))

    $friendName = "$((Get-Culture).TextInfo.ToTitleCase($friendName.ToLower()))"
    Write-Host "Your friend's name is $friendName." -ForegroundColor Cyan
    pause

    } else {
        write-host "You already have a friend: $friendName." -ForegroundColor Cyan
        write-host "Replace your friend? (y/n)" -ForegroundColor Yellow
        $choice = Read-Host -Prompt "Choose an option"
        switch ($choice.ToLower()) {
            "y" {
                write-host "You decide to replace your friend." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "You put down $friendName." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "All that's left of $friendName is it's final stare of confusion and fear." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "$friendName's insides are now outsides." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "You feel a bit sad, but you know it's for the best." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "You stand up and look at the goblin." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "The goblin seems to understand." -ForegroundColor Red
                start-sleep -Milliseconds 1500
                write-host "What have you done?" -ForegroundColor Red
                start-sleep -Milliseconds 1500
                $script:hasFriend = $false
                TaxesDemTrue $taxes
            }
            "n" {
                write-host "You keep your current friend: $friendName." -ForegroundColor Green
                pause
            }
            default {
                write-host "Invalid choice. Choose a valid option." -ForegroundColor Red
                pause
                TaxesDemTrue $taxes
            }
        }
        pause
    }
}


























#Fishing because why not

# Bait definitions
$None = @{
    Name            = "No Bait"
    Price           = 0
    BiteBonus       = 0
    CatchBonus      = 0
    PreferredFish   = @()
}
$Worm = @{
    Name            = "Worm"
    Price           = 1
    BiteBonus       = 5
    CatchBonus      = 3
    PreferredFish   = @("Blue Gill","Perch","Anchovy")
}

$Frog = @{
    Name            = "Frog"
    Price           = 3
    BiteBonus       = 3
    CatchBonus      = 1
    PreferredFish   = @("Walleye","Small Bass")
}

$BasicLure = @{
    Name            = "Basic Lure"
    Price           = 5
    BiteBonus       = 2
    CatchBonus      = 5
    PreferredFish   = @("Rainbow Trout","Blue Gill","Tilapia")
}

$NoviceLure = @{
    Name            = "Novice Lure"
    Price           = 10
    BiteBonus       = 4
    CatchBonus      = 10
    PreferredFish   = @("Rainbow Trout","BassSmall","Catfish")
}

$MasterLure = @{
    Name            = "Master Lure"
    Price           = 25
    BiteBonus       = 8
    CatchBonus      = 15
    PreferredFish   = @("MahiMahi","Tuna","Amberjack")
}

$FishBait = @{
    Name            = "Fish Bait"
    Price           = 50
    BiteBonus       = 10
    CatchBonus      = 7
    PreferredFish   = @("Tuna","Sailfish","Swordfish","Marlin")
}

$ExoticLure = @{
    Name            = "Exotic Lure"
    Price           = 100
    BiteBonus       = 15
    CatchBonus      = 20
    PreferredFish   = @("Marlin","Swordfish","Sturgeon","Sailfish")
}

# Bait collection
$BaitTypes = @($None,$Worm,$Frog,$BasicLure,$NoviceLure,$MasterLure,$FishBait,$ExoticLure)


# Player selected bait
$CurrentBait = $None

# Fish definitions
$BlueGill = @{
    Name            = "Blue Gill"
    MinWeight       = 0.09
    MaxWeight       = 4.68
    BaseGoldValue   = 2
    GoldPerPound    = 0.5
    CatchDifficulty = 2.5
    Rarity          = "Common"
    Location        = @("River","Lake","Ocean")
    BiteChance      = 10
    FightStrength   = 3
}
$Perch = @{
    Name            = "Perch"
    MinWeight       = 0.5
    MaxWeight       = 5
    GoldPerPound    = 0.6
    CatchDifficulty = 3
    Rarity          = "Common"
    Location        = @("River","Lake")
    BiteChance      = 9
    FightStrength   = 3
}
$Carp = @{
    Name            = "Common Carp"
    MinWeight       = 2
    MaxWeight       = 15
    GoldPerPound    = 0.7
    CatchDifficulty = 6
    Rarity          = "Common"
    Location        = @("River","Lake")
    BiteChance      = 8
    FightStrength   = 4
}
$Catfish = @{
    Name            = "Channel Catfish"
    MinWeight       = 5
    MaxWeight       = 25
    GoldPerPound    = 1
    CatchDifficulty = 10
    Rarity          = "Uncommon"
    Location        = @("River","Lake")
    BiteChance      = 6
    FightStrength   = 6
}
$Walleye = @{
    Name            = "Walleye"
    MinWeight       = 1
    MaxWeight       = 10
    GoldPerPound    = 1
    CatchDifficulty = 8
    Rarity          = "Common"
    Location        = @("River","Lake")
    BiteChance      = 7
    FightStrength   = 4
}
$Pike = @{
    Name            = "Northern Pike"
    MinWeight       = 5
    MaxWeight       = 30
    GoldPerPound    = 1.5
    CatchDifficulty = 15
    Rarity          = "Uncommon"
    Location        = @("Lake","River")
    BiteChance      = 5
    FightStrength   = 8
}
$Salmon = @{
    Name            = "Atlantic Salmon"
    MinWeight       = 8
    MaxWeight       = 40
    GoldPerPound    = 2
    CatchDifficulty = 18
    Rarity          = "Uncommon"
    Location        = @("River","Ocean")
    BiteChance      = 6
    FightStrength   = 9
}
$Mackerel = @{
    Name            = "Mackerel"
    MinWeight       = 2
    MaxWeight       = 12
    GoldPerPound    = 1.2
    CatchDifficulty = 7
    Rarity          = "Common"
    Location        = @("Ocean")
    BiteChance      = 8
    FightStrength   = 4
}
$Herring = @{
    Name            = "Herring"
    MinWeight       = 0.5
    MaxWeight       = 2
    GoldPerPound    = 0.5
    CatchDifficulty = 3
    Rarity          = "Common"
    Location        = @("Ocean")
    BiteChance      = 9
    FightStrength   = 2
}
$Snapper = @{
    Name            = "Red Snapper"
    MinWeight       = 5
    MaxWeight       = 35
    GoldPerPound    = 2.5
    CatchDifficulty = 20
    Rarity          = "Uncommon"
    Location        = @("Ocean")
    BiteChance      = 5
    FightStrength   = 10
}
$Grouper = @{
    Name            = "Grouper"
    MinWeight       = 15
    MaxWeight       = 80
    GoldPerPound    = 3
    CatchDifficulty = 35
    Rarity          = "Rare"
    Location        = @("Ocean")
    BiteChance      = 3
    FightStrength   = 40
}
$Halibut = @{
    Name            = "Halibut"
    MinWeight       = 20
    MaxWeight       = 150
    GoldPerPound    = 4
    CatchDifficulty = 45
    Rarity          = "Rare"
    Location        = @("Ocean")
    BiteChance      = 2
    FightStrength   = 70
}
$Swordfish = @{
    Name            = "Swordfish"
    MinWeight       = 50
    MaxWeight       = 300
    GoldPerPound    = 5
    CatchDifficulty = 60
    Rarity          = "Epic"
    Location        = @("Ocean")
    BiteChance      = 1
    FightStrength   = 100
}
$Marlin = @{
    Name            = "Blue Marlin"
    MinWeight       = 80
    MaxWeight       = 400
    GoldPerPound    = 6
    CatchDifficulty = 65
    Rarity          = "Epic"
    Location        = @("Ocean")
    BiteChance      = 1
    FightStrength   = 120
}
$BassSmall = @{
    Name            = "Smallmouth Bass"
    MinWeight       = 2
    MaxWeight       = 8
    GoldPerPound    = 1
    CatchDifficulty = 5
    Rarity          = "Common"
    Location        = @("River","Lake")
    BiteChance      = 9
    FightStrength   = 3
}
$Bluefish = @{
    Name            = "Bluefish"
    MinWeight       = 5
    MaxWeight       = 35
    GoldPerPound    = 2
    CatchDifficulty = 15
    Rarity          = "Uncommon"
    Location        = @("Ocean")
    BiteChance      = 5
    FightStrength   = 10
}
$Flounder = @{
    Name            = "Flounder"
    MinWeight       = 1
    MaxWeight       = 20
    GoldPerPound    = 1.5
    CatchDifficulty = 8
    Rarity          = "Common"
    Location        = @("Ocean","Lake")
    BiteChance      = 7
    FightStrength   = 5
}
$Tilapia = @{
    Name            = "Tilapia"
    MinWeight       = 1
    MaxWeight       = 10
    GoldPerPound    = 0.75
    CatchDifficulty = 4
    Rarity          = "Common"
    Location        = @("Lake","River")
    BiteChance      = 8
    FightStrength   = 3
}
$Cod = @{
    Name            = "Cod"
    MinWeight       = 10
    MaxWeight       = 50
    GoldPerPound    = 2.5
    CatchDifficulty = 25
    Rarity          = "Uncommon"
    Location        = @("Ocean")
    BiteChance      = 4
    FightStrength   = 15
}
$Pollock = @{
    Name            = "Pollock"
    MinWeight       = 5
    MaxWeight       = 25
    GoldPerPound    = 1.5
    CatchDifficulty = 12
    Rarity          = "Uncommon"
    Location        = @("Ocean")
    BiteChance      = 6
    FightStrength   = 8
}
$Anchovy = @{
    Name            = "Anchovy"
    MinWeight       = 0.1
    MaxWeight       = 0.5
    GoldPerPound    = 0.2
    CatchDifficulty = 1
    Rarity          = "Common"
    Location        = @("River","Lake","Ocean")
    BiteChance      = 10
    FightStrength   = 1
}
$Sardine = @{
    Name            = "Sardine"
    MinWeight       = 0.1
    MaxWeight       = 1
    GoldPerPound    = 0.3
    CatchDifficulty = 1
    Rarity          = "Common"
    Location        = @("Ocean")
    BiteChance      = 10
    FightStrength   = 1
}
$TroutBrown = @{
    Name            = "Brown Trout"
    MinWeight       = 2
    MaxWeight       = 15
    GoldPerPound    = 1
    CatchDifficulty = 7
    Rarity          = "Common"
    Location        = @("River","Lake")
    BiteChance      = 8
    FightStrength   = 4
}
$Sturgeon = @{
    Name            = "Sturgeon"
    MinWeight       = 50
    MaxWeight       = 400
    GoldPerPound    = 6
    CatchDifficulty = 70
    Rarity          = "Epic"
    Location        = @("River","Lake","Ocean")
    BiteChance      = 1
    FightStrength   = 120
}
$PeruvianAnchovy = @{
    Name            = "Peruvian Anchovy"
    MinWeight       = 0.2
    MaxWeight       = 0.8
    GoldPerPound    = 0.25
    CatchDifficulty = 1
    Rarity          = "Common"
    Location        = @("Ocean")
    BiteChance      = 10
    FightStrength   = 1
}
$Garfish = @{
    Name            = "Garfish"
    MinWeight       = 2
    MaxWeight       = 20
    GoldPerPound    = 1.2
    CatchDifficulty = 10
    Rarity          = "Uncommon"
    Location        = @("Ocean")
    BiteChance      = 5
    FightStrength   = 7
}
$MahiMahi = @{
    Name            = "Mahi Mahi"
    MinWeight       = 10
    MaxWeight       = 50
    GoldPerPound    = 3
    CatchDifficulty = 30
    Rarity          = "Rare"
    Location        = @("Ocean")
    BiteChance      = 3
    FightStrength   = 30
}
$Kingfish = @{
    Name            = "Kingfish"
    MinWeight       = 20
    MaxWeight       = 70
    GoldPerPound    = 4
    CatchDifficulty = 35
    Rarity          = "Rare"
    Location        = @("Ocean")
    BiteChance      = 3
    FightStrength   = 40
}
$Amberjack = @{
    Name            = "Amberjack"
    MinWeight       = 25
    MaxWeight       = 100
    GoldPerPound    = 4
    CatchDifficulty = 40
    Rarity          = "Rare"
    Location        = @("Ocean")
    BiteChance      = 2
    FightStrength   = 50
}
$Tilefish = @{
    Name            = "Tilefish"
    MinWeight       = 10
    MaxWeight       = 60
    GoldPerPound    = 3.5
    CatchDifficulty = 25
    Rarity          = "Uncommon"
    Location        = @("Ocean")
    BiteChance      = 4
    FightStrength   = 20
}


# Fish collection
$FishTypes = @(
    $Anchovy,
    $Sardine,
    $PeruvianAnchovy,
    $BlueGill,
    $Perch,
    $Tilapia,
    $Walleye,
    $Trout,
    $TroutBrown,
    $BassSmall,
    $Carp,
    $Catfish,
    $Pike,
    $Garfish,
    $Pollock,
    $Mackerel,
    $Flounder,
    $Bluefish,
    $Cod,
    $Snapper,
    $Tilefish,
    $Salmon,
    $MahiMahi,
    $Kingfish,
    $Amberjack,
    $Grouper,
    $Tuna,
    $Sailfish,
    $Swordfish,
    $Marlin,
    $Sturgeon,
    $Halibut,
    $Herring
)





function ChooseBait {
    Clear-Host
    Write-Host "Choose your bait:"
    for ($i=0; $i -lt $BaitTypes.Count; $i++) {
        $bait = $BaitTypes[$i]
        Write-Host "$($i+1)) $($bait.Name) ($($bait.Price) gold)"
    }
    $choice = Read-Host " "
    if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $BaitTypes.Count) {
        $script:CurrentBait = $BaitTypes[$choice-1]
        Write-Host "You equipped $($CurrentBait.Name)." -ForegroundColor Cyan
        Pause
        FishingArea
    } else {
        Write-Host "Invalid choice." -ForegroundColor Red
        Pause
        ChooseBait
    }
}





function Fishing {
    param(
        [string]$Location = "Lake"
    )

    # Check if player has enough gold for bait
    if ($gold -lt $CurrentBait.Price) {
        Write-Host "You don't have enough gold to use $($CurrentBait.Name)!" -ForegroundColor Red
        Start-Sleep 1
        FishingArea
        return
    }

    # Deduct gold for bait
    $script:gold -= $CurrentBait.Price
    Write-Host "You used $($CurrentBait.Name). (-$($CurrentBait.Price) gold)" -ForegroundColor Cyan
    Write-Host "Casting your line into the $Location..."
    Start-Sleep -Seconds 2

    # Filter for fish that can actually be caught
    $availableFish = $FishTypes | Where-Object {
        ($_.Location -contains $Location) -and
        (($FishingSkill + ($RodQuality*10) + $CurrentBait.CatchBonus) - $_.CatchDifficulty -gt 0)
    }

    if (-not $availableFish) {
        Write-Host "No fish are biting here with your current setup..." -ForegroundColor Red
        Start-Sleep 2
        FishingArea
        return
    }

    # Build weighted pool
    $weightedFish = foreach ($fish in $availableFish) {
        $extraWeight = $CurrentBait.BiteBonus
        if ($CurrentBait.PreferredFish -contains $fish.Name) {
            $extraWeight += 5  # bonus for preferred species
        }
        for ($i=0; $i -lt ($fish.BiteChance + $extraWeight); $i++) { $fish }
    }

    # Select a random fish from the weighted pool
    $catch = Get-Random -InputObject $weightedFish

    # Roll chance to actually catch it
    $roll = Get-Random -Minimum 0 -Maximum 100
    $chanceToCatch = ($FishingSkill + ($RodQuality*10) + $CurrentBait.CatchBonus) - $catch.CatchDifficulty

    if ($roll -lt $chanceToCatch) {
        "Something bit!"
        $fightTime = [Math]::Round(($catch.FightStrength) * (Get-Random -Minimum 1 -Maximum 5),2)
        Start-Sleep -Seconds $fightTime
        $FishWeight = [Math]::Round((Get-Random -Minimum $catch.MinWeight -Maximum $catch.MaxWeight),2)
        $goldEarned = [Math]::Round(($FishWeight * $catch.GoldPerPound),0)
        # Gold (always at least 1 on a success)
        $goldEarned = [Math]::Round(($FishWeight * $catch.GoldPerPound),0)
        if ($goldEarned -lt 1) { $goldEarned = 1 }

        Write-Host "You caught a $FishWeight lb $($catch.Name)! (+$goldEarned gold)" -ForegroundColor Yellow
        $script:gold += $goldEarned
        $script:fishcaught += 1

        # XP (always at least 0.01 on a success)
        $xpGained = $FishWeight / 100
        if ($xpGained -lt 0.01) { $xpGained = 0.01 }

        $script:FishingXP += $xpGained
        Write-Host "You gained $([Math]::Round($xpGained,2)) XP!" -ForegroundColor Cyan
        Start-Sleep -Milliseconds 2500


        # Check for level up
        while ($FishingXP -ge $FishingXPRequired) {
            $script:FishingSkill += 1
            $script:FishingXP -= $FishingXPRequired
            $script:FishingXPRequired = [Math]::Round($FishingXPRequired * 1.5,0)
            Write-Host "You leveled up! Fishing skill is now $FishingSkill" -ForegroundColor Green
            Start-Sleep -Milliseconds 1000
        }
    } else {
        Write-Host "The catch got away!" -ForegroundColor Red
    }

    do {
        $input = Read-Host -Prompt "type 1 to continue"
    } while ($input -ne "1")
    FishingArea
}



function FishingArea {
    Clear-Host
    Stats
    $xpRemaining = [Math]::Round($FishingXPRequired - $FishingXP, 2)
    Write-Host "Fishing Level: $fishingSkill" -ForegroundColor Cyan
    Write-Host "Fishing exp needed for level up: $xpRemaining" -ForegroundColor Cyan
    Write-Host 
    Write-Host 
    Write-Host "You enter the fishing area."
    Write-Host "Where would you like to fish?"
    Write-Host "1) River"
    Write-Host "2) Lake"
    Write-Host "3) Ocean"
    Write-Host "4) Change Bait"
    Write-Host "5) Go to start"
    $choice = Read-Host -Prompt " "
        switch ($choice.ToLower()) {
            "1" { Fishing -Location "River" }
            "2" { Fishing -Location "Lake" }
            "3" { Fishing -Location "Ocean" }
            "4" { ChooseBait }
            "5" { startroom }
            Default { Write-Host "Invalid choice, please choose an option (1-4)" -ForegroundColor Red; Pause; FishingArea }
        }
}



































































# ATTENTION
write-host "============================"
write-host "         ATTENTION"
write-host "============================"
start-sleep -Milliseconds 5000
write-host "This game is a DEMO."
start-sleep -Milliseconds 2000
write-host "It is not complete and may contain bugs."
start-sleep -Milliseconds 2000
write-host "Please report any bugs to the developer."
start-sleep -Milliseconds 2000
write-host "Enjoy the game!"
start-sleep -Milliseconds 1000
do {
    $input = Read-Host -Prompt "type 1 to continue"
} while ($input -ne "1")
clear-host
#Start of game
write-host "To exit the game at any time, type 'exit'."
pause
Clear-Host
write-host "v0.5.1"
write-host "============================"
write-host "  WELCOME TO THE ADVENTURE"
write-host "============================"
write-host "      Made by Citrus"
pause



startroom