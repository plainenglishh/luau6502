- [ ] Implement tests
  - [ ] https://github.com/SingleStepTests/65x02/tree/main/6502
  - [ ] https://github.com/Klaus2m5/6502_65C02_functional_tests
- [ ] Implement undocumented instructions
- [ ] Wrapper class (make a nicer class wrapper, with a burst run method to run
      x amount of cycles)
- [ ] Optimise
  - [ ] Page table based memory. (write/read 256-long tables of either buffers
        or functions)
  - [ ] Calculate flags only in the instructions that need them, store the last
        result instead.
  - [ ] Inline the instruction dispatch, instead of using the weird
        ops/instructions table we use now (use binary tree!)
  - [ ] (micro) Increment PC by instruction length
- [ ] (v2) step per cycle? (split instructions into micro-ops)
