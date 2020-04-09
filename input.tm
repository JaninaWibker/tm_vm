% DESCRIPTION %

states = [
  z0 $z_0$, z1 $z_1$, zr $z_r$, zrr $z'_r$, f $f$
]

start = z0

inputs = [
  'a', 'b', '0', '1' # blank symbol is implicit
]

aliases = {
  x: ['b', '0', '1']
}

transitions = {
  z0: [
    'a' | 'b' -> z0 + ,  # when 'a' is read, output 'b' and change to state z0 and move the head right (+)
    x | x -> z0 +,       # alias; this expands to: 'a' | 'a' -> z0 +, 'b' | 'b' -> z0 +, 'c' | 'c' -> z0 +
    BLANK | '0' -> zrr - # use BLANK for the blank symbol; use - to move the head left
  ],
  z1: [
    'a' | 'a' -> z0 +,
    x | x <> +,          # use <> when the state does not change (loop)
    BLANK | '1' -> zrr -
  ],
  zr: [
    'a' | 'a' <> -,
    'b' | 'b' <> -,
    BLANK | BLANK -> z0 +
  ],
  zrr: [
    'a' | 'a' -> zr -,
    x | x <> -,
    BLANK | BLANK -> f / # use / instead of + or - to indicate no movement of the head
  ],
  f: []
}


% EXECUTION %

input = ['a', 'b', '0', '1'] # each symbol is provided seperate (tokenizing is not part of this project)

step 4

% OPTIONS %

# this place can be used to provide options in order to reduce the amount of command line flags
# the options include:
# - output format,
# - duration (between state transitions for gif / react output)
#
# command line flags take precedence over the options in the file
