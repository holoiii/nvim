" Load packer
lua require('plugins')

" Packer plugins setup
lua << END
  require('lualine').setup()
  require('gitsigns').setup()

  -- null-ls (for prettier/formatting)
  local status, null_ls = pcall(require, "null-ls")
  if (not status) then return end

  null_ls.setup({
    sources = {
      null_ls.builtins.diagnostics.eslint_d.with({
        diagnostics_format = '[eslint] #{m}\n(#{c})'
      }),
      null_ls.builtins.diagnostics.fish
    }
  })

  -- prettier
  local status, prettier = pcall(require, "prettier")
  if (not status) then return end

  prettier.setup {
    bin = 'prettierd',
    filetypes = {
      "css",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "json",
      "scss",
      "less"
    }
  }

  -- autotags
  local status, autotag = pcall(require, "nvim-ts-autotag")
  if (not status) then return end

  autotag.setup({})

  -- autopairs
	local status, autopairs = pcall(require, "nvim-autopairs")
	if (not status) then return end

	autopairs.setup({
		disable_filetype = { "TelescopePrompt" , "vim" },
	})

  -- lsp setup
  local status, cmp = pcall(require, "cmp")
  if (not status) then return end
  local lspkind = require 'lspkind'

  cmp.setup({
    mapping = cmp.mapping.preset.insert({
      ['<C-d>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.close(),
      ['<CR>'] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Replace,
        select = true
      }),
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'buffer' },
    }),
    formatting = {
      format = lspkind.cmp_format({ with_text = false, maxwidth = 50 })
    }
  })

  vim.cmd [[
    set completeopt=menuone,noinsert,noselect
    highlight! default link CmpItemKind CmpItemMenuDefault
  ]]

  -- nvim-treesitter setup
  local status, ts = pcall(require, "nvim-treesitter.configs")
  if (not status) then return end

  ts.setup {
    highlight = {
      enable = true,
      disable = {},
    },
    indent = {
      enable = true,
      disable = {},
    },
    ensure_installed = {
      "tsx",
      "json",
      "yaml",
      "css",
      "html",
      "lua",
      "prisma"
    },
    autotag = {
      enable = true,
    },
  }

  local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
  parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }

  -- lspconfig setup
  local status, nvim_lsp = pcall(require, "lspconfig")
  if (not status) then return end

  local protocol = require('vim.lsp.protocol')

  local on_attach = function(client, bufnr)
    -- format on save
    if client.server_capabilities.documentFormattingProvider then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("Format", { clear = true }),
        buffer = bufnr,
        callback = function() vim.lsp.buf.formatting_seq_sync() end
      })
    end

    vim.keymap.set('n', 'gd', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  end

  -- TypeScript
  nvim_lsp.tsserver.setup {
    on_attach = on_attach,
    filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
    cmd = { "typescript-language-server", "--stdio" }
  } 

  -- Mason setup
  local status, mason = pcall(require, "mason")
  if (not status) then return end
  local status2, lspconfig = pcall(require, "mason-lspconfig")
  if (not status2) then return end

  mason.setup({})

  lspconfig.setup {
    ensure_installed = { "sumneko_lua", "tailwindcss" },
  }
  local nvim_lsp = require "lspconfig"
  nvim_lsp.tailwindcss.setup {}

  -- Telescope setup
  local status, telescope = pcall(require, "telescope")
  if (not status) then return end
  local actions = require('telescope.actions')
  local builtin = require("telescope.builtin")

  local function telescope_buffer_dir()
    return vim.fn.expand('%:p:h')
  end

  telescope.setup {
    defaults = {
      mappings = {
        n = {
          ["q"] = actions.close
        },
      },
    },
  }

  -- keymaps
  vim.keymap.set('n', ';f',
    function()
      builtin.find_files({
        no_ignore = false,
        hidden = true
      })
    end)
  vim.keymap.set('n', ';r', function()
    builtin.live_grep()
  end)
  vim.keymap.set('n', '\\\\', function()
    builtin.buffers()
  end)
  vim.keymap.set('n', ';t', function()
    builtin.help_tags()
  end)
  vim.keymap.set('n', ';;', function()
    builtin.resume()
  end)
  vim.keymap.set('n', ';e', function()
    builtin.diagnostics()
  end)
END

" Use VIM settings, rather than VI settings
set nocompatible

" Search highlighting
set hlsearch

" Enable syntax highlighting
syntax on

" Line numbers
set nu

" Set leader
let mapleader = ","

" Open nerdtree to current file
nmap <Bar> :NERDTreeFind<CR>

" Open current buffer in new tab
nnoremap <silent> <Leader>t :tab split<CR>

" Clear all marks
nnoremap <silent> <Leader>M :MarkClear<CR>

" Set available mark palette
let g:mwDefaultHighlightingPalette='maximum'

" Widen/shrink split buffer with + and -
if bufwinnr(1)
  map + <c-W>>
  map - <c-W><
endif

" 2 spaces for indenting
set shiftwidth=2

" 2 stops
set tabstop=2

" Spaces instead of tabs
set expandtab

" Show the matching bracket for the last ')'?
set showmatch

" Do not keep a backup files 
set nobackup
set nowritebackup

" Show the cursor position all the time
set ruler

" Set status line
set statusline=[%02n]\ %f\ %(\[%M%R%H]%)%=\ %4l,%02c%2V\ %P%*

" Always display a status line at the bottom of the window
set laststatus=2

" Give some more height when showing commands
set cmdheight=2

" Show (partial) commands
set showcmd

" Use j/k to escape
:imap jk <Esc>

" Gruvbox colorscheme
colorscheme gruvbox
let g:gruvbox_contrast_dark = 'hard'
set background=dark

" Gruvbox search highlighting cursor color inversion
nnoremap <silent> [oh :call gruvbox#hls_show()<CR>
nnoremap <silent> ]oh :call gruvbox#hls_hide()<CR>
nnoremap <silent> coh :call gruvbox#hls_toggle()<CR>

nnoremap / :let @/ = ""<CR>:call gruvbox#hls_show()<CR>/
nnoremap ? :let @/ = ""<CR>:call gruvbox#hls_show()<CR>?
