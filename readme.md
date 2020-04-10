# Turing Machine Virtual Machine

> **WIP**: At the moment everything except actually outputting files is implemented, the parsing of the input file, parsing cli args and running the vm all works. Generating a template also works. Only outputting the final product is not yet implemented.

The idea is to make it easy to run **small** turing machines and visualize their state using tex.

You supply the data required to describe a *TM* (turing machine) and it will be turned into a tex document. This document will require a large amount of clean-up in regards to positioning of nodes (states) and edges, but this file (after clean-up) can then be used as an input (along side the description of the TM) and be used to generate pretty output for each state transition. This output can be a tex document, an svg, a GIF or even a React component.

## Usage

```
usage: ruby src/main.rb <optional flags> <input file>

flags:
  -o, --output     Specify the output format (tex, svg, gif, react, default: svg)
  -t, --template   Specify the file that should be used as a template for the output
  -e, --expand     Expand aliases
  -E, --no-expand  Don't expand aliases
  -d, --duration   Duration between state transitions (ms)
  -v, --version    Print version
```

Check out the `input.tm` file for an example of how the tuing machine needs to be specified

Run the example turing machine as follows:

`ruby src/main.rb --output svg input.tm`

## Requirements

- ruby
- a latex distribution (when outputting to anything other than tex)
- dvisvgm (when outputting to anything other than tex)

