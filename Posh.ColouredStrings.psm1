function Get-TerminalColourSelection {
    <#
        .SYNOPSIS
        This function is for generating the escape character and colour for use in coloured console terminal text
        .DESCRIPTION
        This function is for generating the escape character and colour for use in coloured console terminal text.
        If $Host.UI.SupportsVirtualTerminal is supported it will allow for text to be coloured that works in objects
        and can be piped and saved to variables and called with the colour.
        Can be used separately or in conjunction with Format-StringtoColour
        .PARAMETER EscapeCharacter
        Switch for returning Escape Character, save this output to a variable
        .PARAMETER Colour
        Returns characters for colours listed in switch statement, save this output to a variable
        .EXAMPLE
        $EscapeCharacter = Get-TerminalColourSelection -EscapeCharacter
        $ColourforText = Get-TerminalColourSelection -Colour Black
        "$EscapeCharacter" + "$ColourforText" + "ColourMeBlack"
        .NOTES
            FunctionName : Get-TerminalColourSelection
            Created by   : SillyDav
            Date Created : 2022-04-09T00-22-17
        .LINK
        https://github.com/SillyDav/Posh.ColouredStrings
        #>
    <#
    Some pointers on where I got started from this thread as my intial attempt was using writehost
    https://reddit.com/r/PowerShell/comments/mdemgi/til_you_can_color_text_without_writehost/
    #>
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'EscapeCharacterSelect')]
        [switch]$EscapeCharacter,
        [Parameter(ParameterSetName = 'ColourSelect')]
        [string]$Colour
    )
    # Check Console Supports Colour
    if ($Host.UI.SupportsVirtualTerminal) {
        if ($PSCmdlet.ParameterSetName -eq "EscapeCharacterSelect") {
            # in 5.1 the escape character we need to use is [char27]
            # in 7 we can use `e
            switch ($PSVersionTable.PSVersion) {
                { $_ -match "^5" } { $EscapeChar = "$([char]27)" }
                { $_ -match "^7" } { $EscapeChar = "`e" }
            }
            # return this value to be used in building the strings with colour
            return $EscapeChar
        }
        if ($PSCmdlet.ParameterSetName -eq "ColourSelect") {
            switch ($Colour) {
                # These were useful colours i felt like were worth having
                # Below cmd will run through the available colours most are the same but feel free to add your own
                # 0..106 | % {$_; "$([char]27)[$($_)m text colours"}
                { $_ -in "White" } { $SelectedColour = "[0m" }
                { $_ -in "Black" } { $SelectedColour = "[30m" }
                { $_ -in "DarkRed" } { $SelectedColour = "[31m" }
                { $_ -in "DarkGreen" } { $SelectedColour = "[32m" }
                { $_ -in "DarkAqua" } { $SelectedColour = "[36m" }
                { $_ -in "Red" } { $SelectedColour = "[91m" }
                { $_ -in "Green" } { $SelectedColour = "[92m" }
                { $_ -in "Yellow" } { $SelectedColour = "[93m" }
                { $_ -in "Blue" } { $SelectedColour = "[94m" }
                { $_ -in "Purple" } { $SelectedColour = "[95m" }
                { $_ -in "Aqua" } { $SelectedColour = "[96m" }
                # Green Background using for whitespaces
                { $_ -in "BGGrey" } { $SelectedColour = "[100m" }
                Default { $SelectedColour = "[0m" }
            }
            # return this value to be used in building the strings with colour
            return $SelectedColour
        }
    }
}

function Format-StringtoColour {
    <#
        .SYNOPSIS
        This function is for colouring each character in a string based on its type, uppercase, lowercase, digit, other/symbol
        .DESCRIPTION
        This function is for colouring each character in a string based on its type, uppercase, lowercase, digit, other/symbol
        If $Host.UI.SupportsVirtualTerminal is supported it will allow for text to be coloured that works in objects
        and can be piped and saved to variables and called with the colour.
        Requires Get-TerminalColourSelection
        .PARAMETER InputString
        String of characters to colour according to its type and the switch statement with regex
        .EXAMPLE
        Format-StringtoColour -InputString "LoOk50kR1Ght!"
        .EXAMPLE
        $string = Format-StringtoColour -InputString "LoOk50kR1Ght!"
        $string
        .EXAMPLE
        $object = [pscustomobject]@{
            normaltext = "normaltext"
            ColourMe   =  Format-StringtoColour -InputString "LoOk50kR1Ght!"
        }
        $object
        .NOTES
            FunctionName : Format-StringtoColour
            Created by   : SillyDav
            Date Created : 2022-04-09T00-22-17
        .LINK
        https://github.com/SillyDav/Posh.ColouredStrings
        #>
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'EscapeCharacterSelect')]
        [string]$InputString
    )
    # Gets our escape character from the function
    $EscChar = Get-TerminalColourSelection -EscapeCharacter
    $OutputString = ""
    $White = Get-TerminalColourSelection -colour White
    # Will loop through each character in our input to match the character with regex to give it a colour and then add to our outputstring
    $InputString.ToCharArray() |
    ForEach-Object {
        switch ($_ ) {
            # match Digits
            { $_ -match "[0-9]" } {
                # Set the Colour from the switch statement in this function to get that colour text
                $Colour = Get-TerminalColourSelection -colour Green
                $OutputString = $OutputString.Insert($OutputString.Length, "$($EscChar)$($Colour)$($_)")
            }
            # Use cmatch to be case sensitive
            # match lower case
            { $_ -cmatch "[a-z]" } {
                $Colour = Get-TerminalColourSelection -colour White
                $OutputString = $OutputString.Insert($OutputString.Length , "$($EscChar)$($Colour)$($_)")
            }
            # Use cmatch to be case sensitive
            # match upper case
            { $_ -cmatch "[A-Z]" } {
                $Colour = Get-TerminalColourSelection -colour Aqua
                $OutputString = $OutputString.Insert($OutputString.Length , "$($EscChar)$($Colour)$($_)")
            }
            # matches anything other than a letter, digit or underscore and any whitespace characters.
            { $_ -match "[^a-zA-Z0-9_\r\n\t\f\v ]" } {
                $Colour = Get-TerminalColourSelection -colour Red
                $OutputString = $OutputString.Insert($OutputString.Length , "$($EscChar)$($Colour)$($_)")
            }
            #  matches any whitespace character (equivalent to [\r\n\t\f\v ])
            { $_ -match "\s" } {
                $Colour = Get-TerminalColourSelection -colour BGGrey
                # We set the colour back to white after changing the background as it bleeds into the next text for some reason
                # only seems to happen with background colours
                $OutputString = $OutputString.Insert($OutputString.Length , "$($EscChar)$($Colour)$($_)$($EscChar)$($White)")
            }
            Default {
                $Colour = Get-TerminalColourSelection -colour White
                $OutputString = $OutputString.Insert($OutputString.Length , "$($EscChar)$($Colour)$($_)")
            }
        }
    }
    # returns our input string coloured
    # The extra escape char and colour is to swap the console back to white.
    return $OutputString + "$($EscChar)$($White)"
}