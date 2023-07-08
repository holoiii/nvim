-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

-- Install plugins with :PackerInstall and remove unused with :PackerClean
return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  -- Github Copilot
  use 'github/copilot.vim'
  -- Gruvbox
  use { "ellisonleao/gruvbox.nvim" }
  -- Nerdtree
  use 'preservim/nerdtree'
  -- Vim-Mark
  use 'inkarkat/vim-mark'
  -- Vim-Mark dependency
  use 'inkarkat/vim-ingo-library'
  -- Lualine
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  }
  -- Telescope
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.0',
    requires = {
      {'nvim-lua/plenary.nvim'} ,
      { "nvim-telescope/telescope-live-grep-args.nvim" },
    },
    config = function()
      require("telescope").load_extension("live_grep_args")
    end
  }
  -- Icons for vim plugins
  use 'kyazdani42/nvim-web-devicons'
  -- Mason for LSP management
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'
  -- nvim-lspconfig
  use 'neovim/nvim-lspconfig'
  -- nvim-treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
  }
  -- cmp-nvim stuff
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-vsnip'
  use 'hrsh7th/vim-vsnip'
  -- vscode pictograms
  use 'onsails/lspkind-nvim'
  -- gitsigns
  use 'lewis6991/gitsigns.nvim'
  -- nerdcommenter
  use 'preservim/nerdcommenter'
  -- autopairs (self closing brackets)
  use {
    "windwp/nvim-autopairs",
      config = function() require("nvim-autopairs").setup {} end
  }
  use 'windwp/nvim-ts-autotag'
  -- prettier
  use('jose-elias-alvarez/null-ls.nvim')
  use('MunifTanjim/prettier.nvim')
  -- tmux navigator
  use {
    'numToStr/Navigator.nvim',
    config = function()
      require('Navigator').setup()
    end
  }
  -- vim-go
  -- Need to run :GoInstallBinaries also
  use 'fatih/vim-go'
end)
