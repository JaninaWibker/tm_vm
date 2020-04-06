# Turing Machine Virtual Machine

> **WIP**: Almost nothing is implemented as of right now, this just serves as a list of features that will be implemented sometime soon hopefully

The idea is to make it easy to run **small** turing machines and visualize their state using tex.

You supply the data required to describe a *TM* (turing machine) and it will be turned into a tex document. This document will require a large amount of clean-up in regards to positioning of nodes (states) and edges, but this file (after clean-up) can then be used as an input (along side the description of the TM) and be used to generate pretty output for each state transition. This output can be a tex document, an svg or even a React component.

## Usage

```bash
usage: ruby src/main.rb <optional flags> <input file>

flags:
  -o, --output    Specify the output format (tex, svg, react, default: svg)
  -v, --version   Print persion
```

Check out the `input.tm` file for an example of how the tuing machine needs to be specified

Run the example turing machine as follows:

`ruby src/main.rb --output svg input.tm`

Eventually standard in will be an accepted way of feeding the TM these commands 

## Requirements

- ruby
- a latex distribution (when outputting to anything other than tex)
- dvisvgm (when outputting to anything other than tex)

