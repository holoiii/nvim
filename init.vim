" May need latest version of neovim:
" brew upgrade neovim
"
" Packer commands:
" :PackerInstall
" :PackerSync
" :PackerClean
"
" Other commands:
" :Mason 
" :TSInstall vim
" :TSUpdate
"
" Load packer
lua require('plugins')

" Packer plugins setup
lua << END
  require('lualine').setup({
    sections = {
      lualine_a = {'mode'},
      lualine_b = {},
      lualine_c = {'filename'},
      lualine_x = {'location'},
      lualine_y = {},
      lualine_z = {}
    }
  })
  require('gitsigns').setup()



  -- prettier
  local status, prettier = pcall(require, "prettier")
  if status then
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
  end

  require('nvim-ts-autotag').setup({})

  -- autopairs
	local status, autopairs = pcall(require, "nvim-autopairs")
	if status then
		autopairs.setup({
			disable_filetype = { "TelescopePrompt" , "vim" },
		})
	end

  -- lsp setup
  local status, cmp = pcall(require, "cmp")
  if status then
    local lspkind = require 'lspkind'

    cmp.setup({
      snippet = {
        expand = function(args)
          vim.fn["vsnip#anonymous"](args.body)
        end,
      },
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
  end

  -- nvim-treesitter setup
  local status, ts = pcall(require, "nvim-treesitter.configs")
  if status and ts.setup then
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
        "bash",
        "javascript",
        "tsx",
        "json",
        "yaml",
        "css",
        "html",
        "lua",
        "prisma",
        "solidity",
        "typescript"
      },
    }
  end

  -- LSP config (Neovim 0.12+ built-in)
  local on_attach = function(client, bufnr)
    local buf_map = function(mode, lhs, rhs, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, lhs, rhs, opts)
    end

    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr })
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr })
    
    buf_map('n', '<leader>ca', vim.lsp.buf.code_action) -- Trigger code actions
  end

  -- JSON
  -- Run this first:
  -- npm i -g vscode-langservers-extracted
  vim.lsp.config('jsonls', {})

  -- Auto lint on save (biome):
  vim.lsp.config('biome', {
    cmd = { "biome", "lsp-proxy" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "jsonc" },
    root_markers = { "biome.json", "biome.jsonc", ".git" },
  })
  vim.lsp.enable("biome")

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client.name == "biome" then
        on_attach(client, ev.buf)
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = ev.buf,
          callback = function()
            vim.lsp.buf.format({ bufnr = ev.buf, id = client.id, timeout_ms = 1000 })
          end,
        })
      end
    end,
  })

  -- TypeScript
  local capabilities = require('cmp_nvim_lsp').default_capabilities()
  vim.lsp.config('ts_ls', {
    on_attach = on_attach,
    filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
    cmd = { "typescript-language-server", "--stdio" },
    capabilities = capabilities,
    handlers = {
      -- pick the first response to a go to definition response. that way we go straight to the
      -- source definition without needing to choose from the type definition .d.ts file
      ["textDocument/definition"] = function(err, result, ...)
        result = vim.islist(result) and result[1] or result
        vim.lsp.handlers["textDocument/definition"](err, result, ...)
      end,
    },
  }) 

  -- Python
  -- https://docs.astral.sh/ruff/editors/setup/#neovim
  vim.lsp.config('ruff', {})

	vim.lsp.config('pyright', {
    on_attach = on_attach,
    -- Use ruff for all formatting and import handling
		settings = {
			pyright = {
				-- Using Ruff's import organizer
				disableOrganizeImports = true,
			},
		},
	})

  -- Mason setup
  local status, mason = pcall(require, "mason")
  if status then
    mason.setup({})
  end

  local status2, lspconfig = pcall(require, "mason-lspconfig")
  if status2 then
    lspconfig.setup {
      ensure_installed = { "lua_ls", "tailwindcss", "rust_analyzer", "pyright" },
    }
  end

  -- Setup tailwind
  vim.lsp.config('tailwindcss', {})

  -- Telescope setup
  local status, telescope = pcall(require, "telescope")
  if status then
    local actions = require('telescope.actions')
    local builtin = require("telescope.builtin")

    telescope.setup {
      defaults = {
        mappings = {
          n = {
            ["q"] = actions.close
          },
          i = {
            -- Allows moving the cursor to front/end of line in insert mode
            -- when the file finder is open
            ["<C-a>"] = { "<Home>", type = "command" },
            ["<C-e>"] = { "<End>", type = "command" },
          },
        },
      },
    }

    -- Keymaps
    -- Use <leader>f to open file finder, by filename
    vim.keymap.set('n', ';f',
      function()
        builtin.find_files({
          no_ignore = false,
          hidden = true
        })
      end)
    -- Use <leader>r to open live grep search
    vim.keymap.set('n', ';r', function()
      builtin.live_grep()
    end)
    -- Regex search 
    vim.keymap.set("n", ";R", ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>")
    vim.keymap.set('n', '\\\\', function()
      builtin.buffers()
    end)
    -- Help tags
    vim.keymap.set('n', ';t', function()
      builtin.help_tags()
    end)
    -- Repeat last search
    vim.keymap.set('n', ';;', function()
      builtin.resume()
    end)
    -- Opens diagnostics list
    vim.keymap.set('n', ';e', function()
      builtin.diagnostics()
    end)
  end

  -- Gruvbox setup
  -- Must be called before loading the colorscheme
  require("gruvbox").setup({
    contrast = "hard",
  })

  -- tmux navigator
  require('Navigator').setup()
  vim.keymap.set({'n', 't'}, '<C-h>', '<CMD>NavigatorLeft<CR>')
  vim.keymap.set({'n', 't'}, '<C-l>', '<CMD>NavigatorRight<CR>')
  vim.keymap.set({'n', 't'}, '<C-k>', '<CMD>NavigatorUp<CR>')
  vim.keymap.set({'n', 't'}, '<C-j>', '<CMD>NavigatorDown<CR>')

  -- Show diagnostics on hover
  vim.o.updatetime = 250  -- Faster CursorHold trigger
  vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
    local diagnostics = vim.diagnostic.get()
    if diagnostics and #diagnostics > 0 then
      vim.diagnostic.open_float(nil, { focus = false })
      end
    end
  })
END

" Ignore casing when searching
set ignorecase

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

" Show hidden files
let NERDTreeShowHidden=1

" Open current buffer in new tab
nnoremap <silent> <Leader>t :tab split<CR>

" Clear all marks
nnoremap <silent> <Leader>M :MarkClear<CR>

" Set available mark palette
let g:mwDefaultHighlightingPalette='maximum'

" Widen/shrink split buffer with + and -
map + <c-W>>
map - <c-W><

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

" Show (partial) commands
set showcmd

" Use j/k to escape
:imap jk <Esc>

" Gruvbox colorscheme
colorscheme gruvbox
set background=dark

" Yank to system clipboard
set clipboard+=unnamedplus
