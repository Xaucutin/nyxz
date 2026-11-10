-- Nyxz — padrões do Hyprland (formato Lua, Hyprland 0.57+).
-- Vêm com a imagem e atualizam sozinhos. Não edite aqui: mude o que quiser em
-- ~/.config/hypr/user.lua, que é carregado por último.

-- Atalhos opcionais: se um comando não existir nesta versão do Hyprland, só ele é
-- ignorado, em vez de derrubar a configuração inteira.
local function tentar(fn)
    local ok, err = pcall(fn)
    if not ok then print("[nyxz] ignorado: " .. tostring(err)) end
end

------------------
---- MONITORES ----
------------------
-- Maior taxa de atualização disponível (180 Hz no Mancer Valak), posição automática.
hl.monitor({
    output   = "",
    mode     = "highrr",
    position = "auto",
    scale    = 1,
})

------------------
---- PROGRAMAS ----
------------------
local terminal = "nyx run /usr/libexec/nyxz/terminal"
-- Busca da Nyxz (Quickshell); o fuzzel fica como reserva se o shell não estiver rodando.
local lancador = "qs -c nyxz ipc call busca alternar || nyx run fuzzel"

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- O hyprland-guiutils (diálogos do próprio Hyprland) não tem pacote para o Fedora 44
-- no COPR usado; sem isto, aparece um aviso amarelo em inglês a cada login.
-- Os diálogos que importam (senha, energia, avisos) são feitos pelo shell da Nyxz.
tentar(function() hl.config({ misc = { disable_hyprland_guiutils_check = true } }) end)
tentar(function() hl.config({ ecosystem = { no_update_news = true, no_donation_nag = true } }) end)

-------------------
---- APARÊNCIA ----
-------------------
-- Paleta Nyxz: fundo #09090D, borda #17171D, borda em foco #2A2A32.
hl.config({
    general = {
        gaps_in          = 5,
        gaps_out         = 10,
        border_size      = 1,
        col = {
            active_border   = "rgb(2A2A32)",
            inactive_border = "rgb(17171D)",
        },
        resize_on_border = true,
        layout           = "dwindle",
    },

    decoration = {
        rounding         = 8,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled      = true,
            range        = 14,
            render_power = 3,
            color        = 0x66000000,
        },
        blur = {
            enabled = false,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        background_color        = 0xff09090d,
        -- VRR (FreeSync) só em tela cheia, para não piscar no desktop.
        vrr                     = 2,
    },

    input = {
        kb_layout     = "br",
        follow_mouse  = 1,
        accel_profile = "flat",
        sensitivity   = 0,
    },
})

-------------------
---- ANIMAÇÕES ----
-------------------
-- Curva exponencial no estilo Lenis: chega rápido e assenta sem rebote.
hl.curve("nyxz",       { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.curve("nyxzRapida", { type = "bezier", points = { {0.2, 0},  {0, 1}   } })

hl.animation({ leaf = "global",     enabled = true, speed = 6, bezier = "nyxz" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4, bezier = "nyxz",       style = "popin 97%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "nyxzRapida", style = "popin 98%" })
hl.animation({ leaf = "border",     enabled = true, speed = 4, bezier = "nyxzRapida" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3, bezier = "nyxzRapida" })
hl.animation({ leaf = "layers",     enabled = true, speed = 3, bezier = "nyxz",       style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "nyxz",       style = "slide" })

-----------------
---- ATALHOS ----
-----------------
local mod = "SUPER"

hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + SPACE",  hl.dsp.exec_cmd(lancador))
-- Cola de atalhos: todos os atalhos, com busca
tentar(function() hl.bind(mod .. " + slash", hl.dsp.exec_cmd("qs -c nyxz ipc call atalhos alternar")) end)
-- Replay instantâneo: Alt+F10 salva os últimos segundos; Alt+Shift+F10 liga/desliga
tentar(function() hl.bind("ALT + F10", hl.dsp.exec_cmd("/usr/libexec/nyxz/replay salvar")) end)
tentar(function() hl.bind("ALT + SHIFT + F10", hl.dsp.exec_cmd("/usr/libexec/nyxz/replay alternar")) end)
-- Painel rápido (brilho e luz azul)
tentar(function() hl.bind(mod .. " + B", hl.dsp.exec_cmd("qs -c nyxz ipc call rapido alternar")) end)
hl.bind(mod .. " + Q",      hl.dsp.window.close())
hl.bind(mod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + E",
    hl.dsp.exec_cmd("uwsm stop || hyprctl dispatch 'hl.dsp.exit()'"))
tentar(function() hl.bind(mod .. " + F", hl.dsp.window.fullscreen()) end)

hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 5 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mover e redimensionar com Super + arrastar (o "AltDrag" da Nyxz)
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume e mídia
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })

----------------------
---- JANELAS ----
----------------------
-- O Nyxz Setup abre em tela cheia.
tentar(function()
    hl.window_rule({
        name  = "nyxz-setup-tela-cheia",
        match = { title = "^Nyxz Setup$" },
        fullscreen = true,
    })
end)

----------------------------------------
---- AJUSTES FEITOS PELAS CONFIGURAÇÕES ----
----------------------------------------
-- Gerados pelas telas de Configurações (Telas, Teclado e mouse, Ajustes). Ficam depois dos
-- padrões e antes do user.lua, que sempre tem a palavra final.
local home = os.getenv("HOME") or ""
for _, nome in ipairs({ "telas", "entrada", "ajustes", "regras" }) do
    local caminho = home .. "/.config/hypr/nyxz/" .. nome .. ".lua"
    local ok, err = pcall(dofile, caminho)
    if not ok and not tostring(err):find("No such file") then
        print("[nyxz] erro em " .. caminho .. ": " .. tostring(err))
    end
end

-----------------------
---- INICIALIZAÇÃO ----
-----------------------
hl.on("hyprland.start", function()
    -- Shell da Nyxz: barra, busca, notificações e painéis
    hl.exec_cmd("nyx run /usr/libexec/nyxz/shell")
    -- Nyxz Setup no primeiro login (escolha de apps; nada é obrigatório)
    hl.exec_cmd("/usr/libexec/nyxz/setup-primeiro-login")
    -- A janela de senha de administrador agora é do próprio shell (AgenteSenha.qml);
    -- o /usr/libexec/nyxz/polkit-agent só é ligado pelo shell se ela não carregar.
end)
