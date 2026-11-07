-- Nyxz — configuração do Hyprland em camadas (ARQUITETURA.md, 2.5).
-- Este arquivo é recriado pela Nyxz se sumir; suas mudanças vão em user.lua.

local function carregar(caminho)
    local ok, err = pcall(dofile, caminho)
    if not ok and not tostring(err):find("No such file") then
        print("[nyxz] erro em " .. caminho .. ": " .. tostring(err))
    end
end

local home = os.getenv("HOME")

-- 1. Padrões da Nyxz (vêm com a imagem e atualizam sozinhos)
carregar("/usr/share/nyxz/hypr/padrao.lua")
-- 2. Arquivos gerados pelas funções da Nyxz (espaços, regras de janela, atalhos)
carregar(home .. "/.config/hypr/nyxz/init.lua")
-- 3. Suas mudanças (a Nyxz nunca mexe neste arquivo)
carregar(home .. "/.config/hypr/user.lua")
