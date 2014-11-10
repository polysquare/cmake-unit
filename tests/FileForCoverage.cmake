# Commented out - LinesStartingWithCommentNotExecutable
macro (my_macro) # Executable
endmacro () # Not executable - LinesStartingWithEndNotExecutable

function (my_function ARG_ONE # Executable
                      ARGU_TWO) # LinesUntilCloseBraceNotExecutable

    # Lines above and below are \n. Both not executable
    # See LinesWithNoContentNotExecutable

    if (ARG_ONE) # Executable

        message ("Executable line") # Executable
        message ("Executable line with ; semicolon") # Executable
        # Line 15 should not be executable - SemicolonsDontBreakLines
        message ("Executable line with \n carriage return") # Executable
        # Line 17 not executable - SlashNDoesntBreakLines

    endif (ARGUMENT_ONE) # Not executable - LinesStartingWithEndNotExecutable

    set (LIST ARGUMENT_ONE # Executable
              ARGUMENT_TWO) # Not executable - LinesUntilCloseBraceNotExecutable

    foreach (ITEM ${LIST}) # Executable

        message ("Executable line") # Executable and hit - OtherLinesExecutable

    endforeach () # Not executable - LinesStartingWithEndNotExecutable

    while (OFF) # Executable and hit

        message ("Not hit") # Not hit but executable

    endwhile () # Not executable - LinesStartingWithEndNotExecutable

endfunction () # Not executable - LinesStartingWithEndNotExecutable

my_macro ("ARGUMENT_ONE" # Executable
          # LinesUntilCloseBraceWithInterleavedCommentsNotExecutable
          "ARGUMENT_TWO" # See above
          # LinesUntilCLoseBraceWithInterleavedCommentsNotExecutable
          "FINAL_ARGUMENT") # Not executable, see above