-- refactoring.nvim has an undeclared dependency on lewis6991/async.nvim
-- which LazyVim's extra does not include. Declare it here explicitly.
return {
  "ThePrimeagen/refactoring.nvim",
  dependencies = {
    "lewis6991/async.nvim",
  },
}
